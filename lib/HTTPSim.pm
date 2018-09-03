package HTTPSim;

use 5.020000;
use strict;
use warnings;

require Exporter;

our @ISA = qw/Exporter/;

our %EXPORT_TAGS = ( 'all' => [ qw/	
/ ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw//;

our $VERSION = '0.01';

sub development_build {
    return (-f 'Makefile') && (-d 'lib');
}

1;
