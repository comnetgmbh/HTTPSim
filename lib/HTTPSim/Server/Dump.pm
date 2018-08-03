package HTTPSim::Server::Dump;

use Moose;
use Moose::Autobox;
use Carp;
extends 'HTTPSim::Server';

use LWP::UserAgent;
use HTTPSim::Transaction;
use PerlIO::gzip;
use File::Slurp qw//;

has ua => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
    lazy => 1,
);

sub handle($$) {
    my ($this, $request) = @_;

    $this->log->info("Fetching @{[$request->uri]}...");
    my $response = $this->ua->request($request);

    # Reverse gzip compression
    if (defined($response->headers->header('Content-Encoding')) and ($response->headers->header('Content-Encoding') eq 'gzip')) {
        my $gzipped = $response->content;
        my $content = '';
        if (open(my $fh, '<:gzip', \$gzipped,)) {
            while (read($fh, $content, 128, length($content))) {
            }
            $response->content($content);
            $response->headers->remove_header('Content-Encoding');
            $response->headers->header('Content-Length', length($content));
        }
        else {
            $this->log->warn('Content marked as gzipped, but can\'t decompress it');
        }
    }

    $this->log->info("Writing dump...");
    my $transaction = HTTPSim::Transaction->new(
        server => $this,
        request => $request,
        response => $response,
    );
    $transaction->save;
    
    $this->_post_transaction('unk', $transaction, 'remote');

    return $response;
}

1;
