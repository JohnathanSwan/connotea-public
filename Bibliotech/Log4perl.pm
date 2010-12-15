use strict;
use warnings;

package Bibliotech::Log4perl;
# ABSTRACT: A Bibliotech wrapper for Log4perl.

# Added by Johnathan.Swan@semantico.com for debugging without interfering with
# the existing logging.

# Based on SEMANTICO::Log by Dominic Mitchell, Ben Stevens and Johnathan Swan

use Exporter qw( import );
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use Log::Log4perl;

use constant DEFAULT_CONF_FILE => '/etc/log4perl.config';
use constant DEFAULT_CONF      => <<CONF;
log4perl.rootLogger = WARN, STDERR
log4perl.appender.STDERR = Log::Log4perl::Appender::Screen
log4perl.appender.STDERR.layout = PatternLayout
log4perl.appender.STDERR.layout.ConversionPattern = %d %F{1} %L %c{2} %m%n
CONF

our $VERSION   = ( qw( $Revision$ ) )[1];
our @EXPORT_OK = qw(  logger debug_context name_of_object_or_class
                      init_logging default_init_logging get_log_conf_file );

{
    my $conf_file;

    sub init_logging {
        ( $conf_file ) = @_;

        # We don't want code to be run in our config files
        Log::Log4perl::Config->allow_code(0);

        Log::Log4perl->init( $conf_file );
        my $log = logger();
        $log->debug( "Configured by $conf_file" );

        return;
    }

    sub get_log_conf_file {
        return $conf_file;
    }
}

# Gets called when no config file has been provided.
sub default_init_logging {
    my ( $user ) = @_;

    return if Log::Log4perl->initialized();

    # Ensure that we create the log file as the specified user, if
    # necessary.
    local ( $), $> );
    if ( $user ) {
        my ( $uid, $gid ) = ( getpwbynam( $user ) )[ 2, 3 ];
        $) = $gid;
        $> = $uid;
    }

    # If we've been given an explicit config file, then use that.
    if (
          $ENV{ LOG4PERL_CONFIG } &&
          -f $ENV{ LOG4PERL_CONFIG } &&
          $ENV{ LOG4PERL_CONFIG } ne 'DEFAULT'
    ) {
        return init_logging( $ENV{ LOG4PERL_CONFIG } );
    }

    # look for a default in /etc
    if ( !defined $ENV{ LOG4PERL_CONFIG } ||
         $ENV{ LOG4PERL_CONFIG } ne 'DEFAULT'
         && -f DEFAULT_CONF_FILE ) {
        return init_logging( DEFAULT_CONF_FILE );
    }

    # Finally, fall back to the built in config.
    my $conf = DEFAULT_CONF;
    init_logging( \$conf );
    my $log = logger();
    $log->debug( "Configured by default" );

    return;
}

sub debug_context {
    my ($key, $val) = @_;

    default_init_logging() unless Log::Log4perl->initialized();

    Log::Log4perl::MDC->put($key, $val);
    return;
}

sub logger {
    my ($category) = @_;

    default_init_logging() unless Log::Log4perl->initialized();

    $category = scalar caller unless defined $category;

    return Log::Log4perl->get_logger( $category );
}

sub name_of_object_or_class {
    my ($scalar) = @_;
    return ref $scalar ? ref $scalar : $scalar;
}

1;
__END__
