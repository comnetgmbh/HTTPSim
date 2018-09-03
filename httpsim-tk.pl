#!/usr/bin/perl

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

use strict;
use warnings;
use Tk;
use POE;
use HTTPSim::Frontend::Tk::MainWindow;
use Log::Log4perl qw/:levels/;

my $main_window = HTTPSim::Frontend::Tk::MainWindow->new;

# Initialize logging
my $logger = Log::Log4perl->get_logger('');
my $layout = Log::Log4perl::Layout::PatternLayout->new('%d [%c] %m%n');
my $tk_appender = Log::Log4perl::Appender->new('Log::Dispatch::ToTk', widget => $main_window->logtext_log);
my $sc_appender = Log::Log4perl::Appender->new('Log::Log4perl::Appender::Screen');
$tk_appender->layout($layout);
$sc_appender->layout($layout);
$logger->add_appender($tk_appender);
$logger->add_appender($sc_appender);
$logger->level($DEBUG);

=cut

use HTTPSim::Server;
use HTTPSim::Transaction;

my $server = HTTPSim::Server->new(dump_path => './dump');
my ($t) = HTTPSim::Transaction->from_file('./dump/wikipedia.org/http___wikipedia.org_foo_bar.yaml',  $server);
use HTTPSim::Frontend::Tk::TransactionWidget;
my $w = HTTPSim::Frontend::Tk::TransactionWidget->new(transaction => $t);

#for (1..20) {
#    POE::Kernel->call($main_window->get_session_id, 'httpsim_transaction', $t);
#}

=cut

POE::Kernel::run;
#Tk::MainLoop
