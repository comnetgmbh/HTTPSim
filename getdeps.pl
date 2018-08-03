#!/usr/bin/perl

use strict;
use warnings;
use YAML;

my $meta = YAML::LoadFile('MYMETA.yml');
print(join(' ', keys(%{$meta->{requires}})) . "\n");
