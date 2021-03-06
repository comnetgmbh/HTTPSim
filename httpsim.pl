#!/usr/bin/perl

# Copyright 2018 Rika Lena Denia, comNET GmbH <rika.denia@comnetgmbh.com>
#
# This file is part of HTTPSim.
#
# HTTPSim is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# HTTPSim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with HTTPSim.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
use POE;
use HTTPSim::Server::Dump;
use HTTPSim::Server::Replay;
use Getopt::Long;
use Pod::Usage;

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

if ($help) {
    pod2usage(
        -exitval => 0,
        -verbose => 1,
    );
}

# Check dump directory
unless (defined($dump_directory)) {
    pod2usage(
        -message => 'No dump directory specified',
        -exitval => 1,
        -verbose => 0,
    );
}

# Handle mode
$mode =~ tr/A-Z/a-z/;
if ($mode eq 'dump') {
    $mode = 'Dump';
}
elsif ($mode eq 'replay') {
    $mode = 'Replay';
}
else {
    pod2usage(
        -message => "Invalid mode specified: \"$mode\"",
        -exitval => 1,
        -verbose => 0,
    );
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

=pod

=head1 SYNOPSIS

httpsim --dump DIR [--mode dump|replay] [--port NUMERIC] [--static HOST] [--help]

=head1 ARGUMENTS

=over

=item --dump DIR

Write dumps to or load dumps from directory I<DIR>.

=item --mode dump|replay

Start proxy in dump or replay mode.

Default: dump

=item --port NUMERIC

Start proxy on TCP port I<NUMERIC>.

=item --static HOST

Act as if accessing remote host I<HOST> when receiving a non-proxy request.

=item --help

Show this help

=back
