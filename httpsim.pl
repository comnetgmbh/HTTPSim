#!/usr/bin/perl

use strict;
use warnings;
use POE;
use HTTPSim::Server::Dump;
use HTTPSim::Server::Replay;
use Getopt::Long;

use Log::Log4perl qw/:easy/;
use Log::Log4perl::Level;
BEGIN { Log::Log4perl->easy_init($DEBUG) };

my $mode = 'dump';
my $port = 9090;
my $static_remote = undef;
my $dump_directory = undef;
my $help;

GetOptions(
    'mode=s', \$mode,
    'port=i', \$port,
    'static=s', \$static_remote,
    'dump=s', \$dump_directory,
    'help', \$help,
);

# Check dump directory
die("No dump directory specified") unless defined $dump_directory;

# Handle mode
$mode =~ tr/A-Z/a-z/;
if ($mode eq 'dump') {
    $mode = 'Dump';
}
elsif ($mode eq 'replay') {
    $mode = 'Replay';
}
else {
    die("Invalid mode specified: \"$mode\"");
}

# Prepare
my $server_class = "HTTPSim::Server::$mode";
my %server_args = (
    port => $port,
    dump_path => $dump_directory,
);
$server_args{static_remote} = $static_remote if $static_remote;

# Construct server
my $server = $server_class->new(%server_args);
POE::Kernel->run_one_timeslice;

# Go
$server->start;
POE::Kernel->run;
