#!/usr/bin/perl

package HTTPSim::Server::Dummy;

use Moose;
extends 'HTTPSim::Server';

sub handle($) {
}

package main;

use strict;
use warnings;
use Test::More tests => 37;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;

use Log::Log4perl qw/:easy/;
BEGIN { Log::Log4perl->easy_init($WARN) };

my $server = HTTPSim::Server::Dummy->new(
    dump_path => './test'
);
my $response = HTTP::Response->new(200, 'OK', HTTP::Headers->new, '');

BEGIN { use_ok('HTTPSim::Transaction'); }
new_ok('HTTPSim::Transaction', [ server => $server, request => HTTP::Request->new, response => $response ]);

my %match_tests = (
    match        => [ 'GET', 'http://example.org/baz?get1=val1&get2=val2',   [ 'A-Value' => 'foo', 'Another-Value' => 'bar' ] ],
    switch_query => [ 'GET', 'http://example.org/baz?get2=val2&get1=val1',   [ 'A-Value' => 'foo', 'Another-Value' => 'bar' ] ],
    wrong_method => [ 'PUT', 'http://example.org/baz?get1=val1&get2=val2',   [ 'A-Value' => 'foo', 'Another-Value' => 'bar' ] ],
    wrong_host   => [ 'GET', 'http://another.org/baz?get1=val1&get2=val2',   [ 'A-Value' => 'foo', 'Another-Value' => 'bar' ] ],
    wrong_path   => [ 'GET', 'http://example.org/quux?get1=val1&get2=val2',  [ 'A-Value' => 'foo', 'Another-Value' => 'bar' ] ],
    wrong_query  => [ 'GET', 'http://example.org/baz?get1=val3&get2=val2',   [ 'A-Value' => 'foo', 'Another-Value' => 'bar' ] ],
    wrong_scheme => [ 'GET', 'https://example.org/baz?get1=val1&get2=val2',  [ 'A-Value' => 'foo', 'Another-Value' => 'bar' ] ],
);

my %match_rules = (
    default => undef,
    no_host => {
        method => 'match',
        uri => {
            scheme => 'match',
            path => 'match',
            query_form => 'match',
        },
    },
    detail_query => {
        method => 'match',
        uri => {
            scheme => 'match',
            host => 'match',
            path => 'match',
            query_form => {
                get1 => 'match',
                get2 => 'match',
            },
        },
    },
    regex_query => {
        method => 'match',
        uri => {
            scheme => 'match',
            host => 'match',
            path => 'match',
            query_form => {
                get1 => 'val\d',
                get2 => 'val\d',
            },
        },
    },
    regex_host => {
        method => 'match',
        uri => {
            scheme => 'match',
            host => '^.+\.org$',
            path => 'match',
            query_form => 'match',
        },
        headers => 'match',
    },
);

my %match_results = (
    default => { match => 1, wrong_method => 0, wrong_host => 0, wrong_path => 0, wrong_query => 0, switch_query => 1, wrong_scheme => 0 },
    no_host => { match => 1, wrong_method => 0, wrong_host => 1, wrong_path => 0, wrong_query => 0, switch_query => 1, wrong_scheme => 0 },
    detail_query => { match => 1, wrong_method => 0, wrong_host => 0, wrong_path => 0, wrong_query => 0, switch_query => 1, wrong_scheme => 0 },
    regex_query =>  { match => 1, wrong_method => 0, wrong_host => 0, wrong_path => 0, wrong_query => 1, switch_query => 1, wrong_scheme => 0 },
    regex_host => { match => 1, wrong_method => 0, wrong_host => 1, wrong_path => 0, wrong_query => 0, switch_query => 1, wrong_scheme => 0 },
);

while (my ($rules, $results) = each(%match_results)) {
    my %rules;
    unless ($rules eq 'default')  {
        %rules = (
            rules => $match_rules{$rules},
        );
    }

    my $transaction = HTTPSim::Transaction->new(
        server => $server,
        request => HTTP::Request->new(@{$match_tests{match}}),
        response => $response,
        %rules,
    );

    while (my ($test, $result) = each(%{$results })) {
        my $got = $transaction->match(
            HTTP::Request->new(@{$match_tests{$test}}),
        );
        $got //= 0;
        is($got, $result, "$rules: $test");
    }
}

$server->shutdown;
POE::Kernel->run;
