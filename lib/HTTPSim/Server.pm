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

package HTTPSim::Server;

use MooseX::POE;
use Carp;
with 'MooseX::Log::Log4perl';

use POE::Component::Server::SimpleHTTP;
use YAML qw//;
use Scalar::Util qw//;
use HTTP::Status qw/:constants :is status_message/;

has dump_path => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has port => (
    is => 'ro',
    isa => 'Int',
    default => 9090,
);

has static_remote => (
    is => 'ro',
    isa => 'Str',
    predicate => 'has_static_remote',
);

has status_session => (
    is => 'ro',
    predicate => 'has_status_session',
);

has httpd_id => (
    is => 'ro',
    isa => 'Str',
    default => sub { $_[0]->get_session_id . '_httpd' },
    lazy => 1,
);

has httpd => (
    is => 'ro',
    isa => 'POE::Component::Server::SimpleHTTP',
    default => sub {
        POE::Component::Server::SimpleHTTP->new(
            ALIAS => $_[0]->httpd_id,
            PORT => $_[0]->port,
            HANDLERS => [
                {
                    DIR => '^.*$',
                    SESSION => $_[0]->get_session_id,
                    EVENT => 'request',
                }
            ],
            PROXYMODE => 1,
        );
    },
    lazy => 1,
);

has class => (
    is => 'ro',
    isa => 'Str',
    default => sub { Scalar::Util::blessed($_[0]) },
);

event request => sub {
    my ($this, $request, $response) = ($_[OBJECT], @_[ARG0..$#_]);
    eval {
        $this->log->info("Request for @{[$request->uri]}");

        unless ($request->uri->scheme) {
            $request->uri->scheme('http');
        }

        # Handle requests of clients that are not proxy aware
        unless ($request->uri->host) {
            unless ($this->has_static_remote) {
                die("No host in request and no static remote configured\n");
            }
            $request->uri->host($this->static_remote);
        }

        # Filter it
        my $real_response = $this->handle($request);

        # Copy response over
        for (qw/code message content/) {
            $response->$_($real_response->$_);
        }

        # Headers need special handling
        my %headers = $real_response->headers->flatten;
        while (my ($key, $value) = each(%headers)) {
            $response->headers->header($key, $value);
        }
    };

    # Handle exceptions gracefully
    my $e = $@;
    if ($e) {
        $this->log->error($e);
        $response->code(HTTP_INTERNAL_SERVER_ERROR);
        $response->message('INTERNAL PROXY ERROR');
        $response->headers->header('Content-Type', 'text/html');
        $response->content(<<EOF
<html>
    <body>
        <h1>HTTPSIM INTERNAL ERROR</h1>
        <h2>Description</h2>
        <p>While processing your request, HTTPSim encountered the following error:<p>
        <p>@{[$e =~ s/\n/<br>/grm]}</p>
        <h2>Request</h2>
        <p>@{[$request->as_string =~ s/\n/<br>/grm]}<p>
    </body>
</html>
EOF
        );
    }

    # We're done
    POE::Kernel->post($this->httpd_id, 'DONE', $response);
};

sub handle($$) {
    ...
}

sub START {
    my $this = shift;

    POE::Kernel->refcount_increment($this->get_session_id, 'alive');
    $this->_post_running('READY');
}

sub start {
    my $this = shift;

    $this->httpd;
    $this->_post_running("LISTENING (:@{[$this->port]})");
}

event shutdown => sub {
    my $this = shift;

    POE::Kernel->post($this->httpd_id, 'SHUTDOWN');
    POE::Kernel->refcount_decrement($this->get_session_id, 'alive');
    $this->_post_running('SHUTDOWN');
};

sub _post_status {
    my ($this, $event, @args) = @_;

    return unless $this->has_status_session;
    POE::Kernel->post($this->status_session, "httpsim_$event", @args);
}

sub _post_running($$) {
    my ($this, $running) = @_;

    $this->log->info("@{[$this->class]} $running");
    $this->_post_status('running', $running);
}

sub _post_transaction($$) {
    my ($this, $client, $transaction, $result_source) = @_;

    $this->_post_status(
        'transaction',
        (
            client => $client,
            transaction => $transaction,
            result_source => $result_source,
        ),
    );
}

1;
