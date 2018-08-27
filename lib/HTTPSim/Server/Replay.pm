package HTTPSim::Server::Replay;

use Moose;
use Moose::Autobox;
use Carp;
extends 'HTTPSim::Server';

use IO::Dir;
use Template;
use HTTPSim::Transaction;

has index => (
    is => 'ro',
    isa => 'HashRef',
    builder => 'build_index',
    lazy => 1,
);

has template => (
    is => 'ro',
    isa => 'Template',
    default => sub { Template->new({
        INCLUDE_PATH => $_[0]->dump_path,
        POST_CHOMP => 1,
        EVAL_PERL => 1,
    })},
    lazy => 1,
);

has continous_request_count => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

sub build_index($) {
    my $this = shift;
    my %ret;

    my $dump_dh = IO::Dir->new($this->dump_path);
    croak("Can't open @{[$this->dump_path]}") unless defined $dump_dh;

    while (my $dump_entry = $dump_dh->read) {
        next if $dump_entry =~ /^\.+$/;

        $this->log->debug("Processing $dump_entry");
        my $host_path = $this->dump_path . '/' . $dump_entry;

        my $host_dh = IO::Dir->new($host_path);
        croak("Can't open $host_path") unless defined $host_dh;

        while (my $host_entry = $host_dh->read) {
            next if $host_entry =~ /^\.+$/;

            $this->log->debug("- Processing $host_entry");
            my $transaction_path = "$host_path/$host_entry";
            my @transactions = HTTPSim::Transaction->from_file(
                $transaction_path,
                $this,
            );

            for (@transactions) {
                $ret{$_->key} //= [];
                $ret{$_->key}->push($transaction_path);
                $this->log->debug("Adding $transaction_path as @{[$_->key]}");
            }
        }
    }

    return \%ret;
}

sub match_transaction($$) {
    my ($this, $request) = @_;

    my $key = HTTPSim::Transaction->request_key($request);
    $this->log->debug("Looking for $key");
    my @candidates = @{$this->index->{$key} // []};

    for my $candidate (@candidates) {
        $this->log->debug("Considering $candidate");
        my @transactions = HTTPSim::Transaction->from_file($candidate, $this);

        for my $transaction (@transactions) {
            return $transaction->response if $transaction->match($request);
            $this->log->debug("Candidate $candidate did not match");
        }
    }

    die("Don't know how to handle request\n");
}

sub handle($$) {
    my ($this, $request) = @_;

    # Search for first match
    my $response = $this->match_transaction($request);

    # Build template stash
    my %stash = (
        request  => $request,
        response => $response,
        server   => $this,
    );

    # Expand template
    my $input = $response->content;
    my $output = '';
    $this->template->process(\$input, \%stash, \$output) or croak("Processing template failed: @{[$this->template->error]}");
    $response->content($output);
    
    $this->continous_request_count($this->continous_request_count + 1);
    
    return $response;
}

1;
