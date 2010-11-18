# Copyright 2007 Nature Publishing Group
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# The Bibliotech::OpenID class provides an interface between OpenID
# utiltity classes and Bibliotech::Component::OpenIDForm.

package Bibliotech::OpenID;
use strict;
use base 'Class::Accessor::Fast';
use CGI::Session;
use CGI::Session::ID::md5;
use CGI::Session::Serialize::default;
use Net::OpenID::JanRain::Consumer;
use Net::OpenID::JanRain::Stores;
use Net::OpenID::JanRain::Util qw/normalizeUrl/;
use Bibliotech::DBI;
use Bibliotech::Cache;
use Bibliotech::Util;
use Bibliotech::Component::LoginForm;

__PACKAGE__->mk_accessors(qw/consumer root root_ret/);

# A login is two passes; one to accept a form from the user with an
# openid URL, and another one when the provider comes back to us with
# an answer. It's up to the calling instance to keep the state of
# where we are in those two passes.  An instance of Bibliotech::OpenID
# will be created each time. The first time the caller should call
# start_and_get_url(), and the second time login(). They both return a
# redirect URL to continue upon success; they die on error. All other
# code in this file is to support these functions and provide
# Bibliotech-style services for CGI, memcached, etc. to make the
# JanRain library work.

sub new {
  my ($class, $sid, $location, $memcache) = @_;
  my $session  = CGI::Session->new('driver:bibcache;serializer:default;id:md5', $sid, {memcache => $memcache}) or die 'no session';
  my $scache   = Bibliotech::OpenID::Store::Memcache->new($memcache) or die 'no scache';
  my $consumer = Net::OpenID::JanRain::Consumer->new($session, $scache) or die 'no consumer';
  my $root     = "$location";
  my $root_ret = $root.'openid?ret=1&cssid='.$session->id;
  return $class->SUPER::new({consumer => $consumer, root => $root, root_ret => $root_ret});
}

sub start_and_get_url {
  my ($self, $openid, $in_db_sub) = @_;
  $openid or die "Must supply an OpenID.\n";
  my $instance = $self->consumer->begin("$openid");
  my $status = $instance->status;
  return do { $instance->addExtensionArg('sreg', 'optional', 'nickname,fullname,email')
		  unless $in_db_sub->(normalizeUrl($openid));  # request sreg if not in db
	      $instance->redirectURL($self->root,
				     $self->root_ret); }            if $status eq 'in_progress';
  die 'OpenID error: '.($instance->message || 'Unknown error')."\n" if $status eq 'failure';
  die 'bad begin instance status';
}

sub login {
  my ($self, $param_hashref, $allow_login_sub, $do_login_sub) = @_;
  my $instance = $self->consumer->complete($param_hashref);
  my $status   = $instance->status;
  if ($status eq 'success') {
    my $verified_url = $instance->identity_url;
    my $sreg_values = $instance->extensionResponse('sreg');
    my $user = $allow_login_sub->("$verified_url", sub { $self->parse_sreg($sreg_values) })
	or die "OpenID problem - no user.\n";
    return $do_login_sub->($user);
  }
  return $instance->setup_url                  			    if $status eq 'setup_needed';
  die "OpenID login aborted.\n"                			    if $status eq 'cancel';
  die 'OpenID error: '.($instance->message || 'Unknown error')."\n" if $status eq 'failure';
  die 'bad complete instance status';
}

# input:  {nickname => ..., fullname => ..., email => ...}
# output: (username, firstname, lastname, email)
sub parse_sreg {
  my $sreg = pop or return;
  my %sreg = %{$sreg} or return;
  my $username = $sreg{nickname};
  my $fullname = $sreg{fullname};
  my ($firstname, $lastname) = split(/\s+/, $fullname, 2);
  my $email = $sreg{email};
  return ($username, $firstname, $lastname, $email);
}


package CGI::Session::Driver::bibcache;
use base qw(CGI::Session::Driver CGI::Session::ErrorHandler);

sub memcache {
  shift->{memcache};
}

sub full_key {
  my ($self, $key) = @_;
  return Bibliotech::Cache::Key->new(class => ref $self, id => 'Bibliotech', id => $key);
}

sub get {
  my ($self, $key) = @_;
  return $self->memcache->get($self->full_key($key));
}

sub set {
  my ($self, $key, $value) = @_;
  return $self->memcache->set($self->full_key($key), $value, 3600);
}

sub delete {
  my ($self, $key) = @_;
  return $self->memcache->delete($self->full_key($key));
}

# API conformance: (store, retrieve, remove)

sub store {
  my ($self, $sid, $datastr) = @_;
  $self->set($sid, $datastr);
}

sub retrieve {
  my ($self, $sid) = @_;
  my $value = $self->get($sid);
  return 0 unless defined $value;
  return $value;
}

sub remove {
  my ($self, $sid) = @_;
  $self->delete($sid);
}

# traverse() is not implemented as this would complicate matters
# greatly and is not required by the JanRain consumer.


package Bibliotech::OpenID::Store::Memcache;
use base 'Net::OpenID::JanRain::Stores';
use Net::OpenID::JanRain::CryptUtil qw/randomString/;

sub new {
  my ($class, $memcache) = @_;
  return bless [$memcache], ref $class || $class;
}

sub memcache {
  shift->[0];
}

sub full_key {
  my ($self, $key) = @_;
  return Bibliotech::Cache::Key->new(class => ref $self, id => $key);
}

sub add {
  my ($self, $key, $value) = @_;
  return $self->memcache->add($self->full_key($key), $value, 3600);
}

sub get {
  my ($self, $key) = @_;
  return $self->memcache->get($self->full_key($key));
}

sub set {
  my ($self, $key, $value) = @_;
  return $self->memcache->set($self->full_key($key), $value, 3600);
}

sub lock {
  my ($self, $key) = @_;
  return $self->memcache->lock($self->full_key($key));
}

sub unlock {
  my ($self, $key) = @_;
  return $self->memcache->unlock($self->full_key($key));
}

sub with_lock {
  my ($self, $key, $action) = @_;
  $self->lock($key) or die 'lock failed on '.$key;
  my $ret = eval { $action->() };
  my $e = $@;
  $self->unlock($key);
  die $e if $e;
  return $ret;
}

sub getAuthKey {
  my $self = shift;
  my $key = '_authkey';
  my $value = $self->get($key);
  return $value if $value;
  $value = randomString(8);
  $self->add($key => $value);
  return $self->get($key);
}

sub storeAssociation {
  my ($self, $server_url, $association) = @_;
  my $key = '_associations';
  $self->with_lock
      ($key,
       sub {
	 $self->set($key => [(grep { $_->[1]->expiresIn > 0 } @{$self->get($key)||[]}),
			     [$server_url, $association]]);
       });
}

sub getAssociation {
  my ($self, $server_url, $handle) = @_;
  my $key = '_associations';
  $self->with_lock
      ($key,
       sub {
	 my @results = sort { $a->{issued} <=> $b->{issued} }
	 map  { $_->[1] }
	 grep { $_->[1]->expiresIn > 0 &&
		    (not defined $server_url or $_->[0] eq $server_url) &&
		    (not defined $handle     or $_->[1]->handle eq $handle)
	 } @{$self->get($key)||[]};
	 return pop @results;
       });
}

sub removeAssociation {
  my ($self, $server_url, $handle) = @_;
  my $key = '_associations';
  $self->with_lock
      ($key,
       sub {
	 my @results = grep { $_->[1]->expiresIn > 0 &&
				  (not defined $server_url or $_->[0] ne $server_url) &&
				  (not defined $handle     or $_->[1]->handle ne $handle)
	 } @{$self->get($key)||[]};
	 $self->set($key => \@results);
       });
}

sub _expire_nonces {
  my ($time, %nonces) = @_;
  my $max_age = 6*60*60;
  foreach (keys %nonces) {
    delete $nonces{$_} if $time - $nonces{$_} > $max_age;
  }
  return %nonces;
}

sub storeNonce {
  my ($self, $nonce) = @_;
  my $key = '_nonces';
  $self->with_lock
      ($key,
       sub {
	 my $time = Bibliotech::Util::time();
	 my %nonces = _expire_nonces($time, %{$self->get($key)||{}});
	 $nonces{$nonce} = $time;
	 $self->set($key => \%nonces);
       });
}

sub useNonce {
  my ($self, $nonce) = @_;
  my $key = '_nonces';
  $self->with_lock
      ($key,
       sub {
	 my $time = Bibliotech::Util::time();
	 my %nonces = _expire_nonces($time, %{$self->get($key)||{}});
	 my $value = $nonces{$nonce};
	 delete $nonces{$nonce};
	 $self->set($key => \%nonces);
	 return $value ? 1 : 0;
       });
}

sub isDumb {
  undef;
}

1;
__END__
