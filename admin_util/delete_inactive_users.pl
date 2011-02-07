#!/usr/bin/perl -w

use strict;
use warnings;

use DBI;
use DBD::mysql;

use Getopt::Long;

my $verbose = undef;
my $debug = undef;
my $opt_noop = undef;
my $dbpw = undef;
my $opt_date_limit;

my $result = GetOptions (
        'verbose' => \$verbose, 
        'debug' => \$debug, 
        'noop' => \$opt_noop,
        'dbpass=s' => \$dbpw,
        'date_limit=s' => \$opt_date_limit,
    );

die 'please specify a date for --date_limit=YYYY-mm-dd' unless $opt_date_limit =~ m{\A\d\d\d\d-\d\d-\d\d\z}ms;

# CONFIG VARIABLES
my $database = "connotea";
my $host = "192.168.10.25";
my $port = "3306";
my $dbuser = "connotea";

# DATA SOURCE NAME
my $dsn = "dbi:mysql:database=$database;host=$host;port=$port";

sub mydate {
    return scalar(localtime);
}

sub verbose {
    my $msg = shift;
    print mydate . ": $msg" if $verbose; 
}

sub debug {
    my $msg = shift;
    print mydate . ": [DEBUG] $msg" if $debug;
}

sub delete_user_cascade {

    my $dbh = shift;
    my ($user_list) = @_;
    my $qh;


    my $user_count = @{ $user_list };

    verbose "Deleting $user_count users\n";
    foreach my $u (map { $_->[0] } @{ $user_list }) {

	if ( $opt_noop ) { 
            debug "(noop) not deleting user $u\n";
	} else { 
            debug "Deleting user $u\n";

	    my $ua_sth = $dbh->prepare('SELECT user_article_id FROM user_article WHERE user = ?');
            $ua_sth->execute($u);
            my $row;
	    while ( $row = $ua_sth->fetchrow_hashref ) {
		my $ua = $row->{user_article_id};
		debug "About to delete user_article $ua\n";

                $qh = $dbh->prepare('delete from user_article_tag where user_article = ?');
                $qh->execute($ua);
                $qh = $dbh->prepare('delete from user_article_comment where user_article = ?');
                $qh->execute($ua);
                $qh = $dbh->prepare('delete from user_article_details where user_article_id = ?');
                $qh->execute($ua);
                $qh = $dbh->prepare('delete from user_article where user_article_id = ?');
                $qh->execute($ua);

	    } 


            $qh = $dbh->prepare('update bookmark set first_user = null where first_user = ?');
            $qh->execute($u);

            $qh = $dbh->prepare('delete from user_gang where user = ?');
            $qh->execute($u);
      
            $qh = $dbh->prepare('delete from user_openid where user = ?');
            $qh->execute($u);
            
            $qh = $dbh->prepare('delete from user_tag_annotation where user = ?');
            $qh->execute($u);

            $qh = $dbh->prepare('delete from user where user_id = ?');
            $qh->execute($u);
        }
    }

}

sub get_inactive_users {
    my ($dbh) = @_;

    return $dbh->selectall_arrayref("SELECT user_id FROM user WHERE active = 0 AND updated < '$opt_date_limit' AND created < '$opt_date_limit' AND verifycode IS NULL" );
}

sub main {

    my @user_id_list;
    verbose "Connecting to DB\n";
    my $connect = DBI->connect($dsn, $dbuser, $dbpw, { RaiseError => 1 });

    delete_user_cascade($connect, get_inactive_users($connect) );

    $connect->disconnect();
    verbose "Disconnected from DB\n";

}

main();
