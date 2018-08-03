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
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HTTPSim - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HTTPSim;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for HTTPSim, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Rika Denia, E<lt>rika@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Rika Denia

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
