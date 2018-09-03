#
# Copyright Rika Lena Denia, comNET GmbH <rika.denia@comnetgmbh.com>
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

our $VERSION = '1.00';

sub development_build {
    return (-f 'Makefile') && (-d 'lib');
}

1;
