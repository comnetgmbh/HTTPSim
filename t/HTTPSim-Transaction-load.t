#!/usr/bin/perl

use strict;
use warnings;
use HTTPSim::Transaction;
use Test::More tests => 13;

use Log::Log4perl qw/:easy/;
BEGIN { Log::Log4perl->easy_init() };


my @transactions = HTTPSim::Transaction->from_file('t/test_transaction.yaml');
is(scalar(@transactions), 5, 'Loaded 5 transactions');

my $i = 1;
for (@transactions) {
    isa_ok($_, 'HTTPSim::Transaction', "Transaction @{[$i++]}");
}

my $t = $transactions[0];

is($t->request->method, 'GET', 'Correct method');
is_deeply(
    { $t->request->headers->flatten },
    {
        Accept => '*/*',
        'Accept-Encoding' => 'identity',
        Connection => 'Keep-Alive',
        Host => 'wikipedia.org',
        'Proxy-Connection' => 'Keep-Alive',
        'User-Agent' => 'Wget/1.18 (linux-gnu)',
    },
    'Correct headers',
);
is($t->request->uri->scheme, 'http', 'Correct scheme');
is($t->request->uri->host, 'wikipedia.org', 'Correct host');
is($t->request->uri->path, '/foo', 'Correct path');
is_deeply({ $t->request->uri->query_form }, { bar => 'baz', quux => 'quuux' }, 'Correct query');
is($t->request->content, '', 'Correct content');
