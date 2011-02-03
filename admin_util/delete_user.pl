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

my $result = GetOptions (
        'verbose' => \$verbose, 
        'debug' => \$debug, 
        'noop' => \$opt_noop,
        'dbpass=s' => \$dbpw,
    );

# CONFIG VARIABLES
my $database = "connotea";
my $host = "localhost";
my $port = "3306";
my $dbuser = "root";

# DATA SOURCE NAME
my $dsn = "dbi:mysql:$database:$host:$port";

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
    my @user_list = @_;
    my $qh;

    if ($opt_noop) {
        verbose "(noop) NOT Deleting $#user_list user_articles\n";
    } else {
        verbose "Deleting $#user_list users\n";
        foreach my $u (@user_list) {
            debug "Deleting user $u\n";


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

sub get_list_of_user_ids_from_user_list {
    my $dbh = shift;
    my @user_list = @_;
    my @u_list;
    my $u_id;

    foreach my $u (@user_list) {
        verbose "Getting list of user_ids for user $u\n";
        my $query = 'SELECT u.user_id FROM user u WHERE u.username = ?';
        my $qh = $dbh->prepare($query);

        # EXECUTE THE QUERY
        $qh->execute($u);

        # BIND TABLE COLUMNS TO VARIABLES
        $qh->bind_columns(\$u_id);

        # LOOP THROUGH RESULTS
        while($qh->fetch()) {
            push(@u_list, $u_id);
        }
    }
    
    return @u_list;

}

sub main {

    my @user_id_list;
    verbose "Connecting to DB\n";
    my $connect = DBI->connect($dsn, $dbuser, $dbpw, { RaiseError => 1 });

    my @users = @ARGV;

    @user_id_list = get_list_of_user_ids_from_user_list($connect, @users);
    delete_user_cascade($connect, @user_id_list);

    $connect->disconnect();
    verbose "Disconnected from DB\n";

}

main();
