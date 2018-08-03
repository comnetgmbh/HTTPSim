# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl App-HTTPSim.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('App::HTTPSim') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Initialize
use POE;
use App::HTTPSim::Server::Dump;

use Log::Log4perl qw/:easy/;
BEGIN { Log::Log4perl->easy_init() };

#my $server = App::HTTPSim::Server::Dump->new(dump_path => './dump');
#$server->start;

my $ua = LWP::UserAgent->new(
    proxy => ['http', 'http://127.0.0.1:9090'],
);

my $res = $ua->get('http://wikipedia.org?foo=bar');
print($res->message, "\n");
is($res->code, 200, 'a');
