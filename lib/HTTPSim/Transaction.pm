package HTTPSim::Transaction;

use Moose;
use Moose::Autobox;
use Carp;

with 'MooseX::Log::Log4perl';

use IO::File;
use Fcntl;

use HTTP::Headers;

use YAML qw//;
use Scalar::Util qw//;
use File::Path qw//;
use File::Slurp qw//;
use Data::Compare qw//;

has server => (
    is => 'ro',
    isa => 'HTTPSim::Server',
    predicate => 'has_server',
);

has request => (
    is => 'ro',
    isa => 'HTTP::Message',
    required => 1,
);

has response => (
    is => 'ro',
    isa => 'HTTP::Message',
    required => 1,
);

has rules => (
    is => 'ro',
    isa => 'HashRef',
    default => sub {
        {
            method => 'match',
            uri => {
                scheme => 'match',
                host => 'match',
                path => 'match',
                query_form => 'match',
            },
            headers => 'match',
        }
    },
);

has dir => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        croak('Can\'t save: No associated HTTPSim::Server') unless $_[0]->has_server;
        $_[0]->server->dump_path . '/' .
        $_[0]->_fs_safe($_[0]->request->uri->host);
    },
    lazy => 1,
);

has path => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        $_[0]->dir . '/' .
        $_[0]->_fs_safe($_[0]->request->uri) . '.yaml'
    },
    lazy => 1,
);

has key => (
    is => 'ro',
    isa => 'Str',
    default => sub { request_key(undef, $_[0]->request) },
    lazy => 1,
);

sub _fs_safe($$) {
    my ($this, $thing) = @_;

    return $thing =~ s/[^a-zA-Z0-9_.-]/_/gr;
}

## Serialization helpers

# HTTP::Headers
sub _serialize_headers($) {
    my $headers = shift;
    my %ret;

    for ($headers->header_field_names) {
        $ret{$_} = $headers->header($_);
    }

    return \%ret;
}
sub _deserialize_headers($) {
    return $_[0];
}

# URI
sub _serialize_uri($) {
    my $uri = shift;
    my %ret;

    for (qw/scheme host path/) {
        $ret{$_} = $uri->$_;
    }

    my %query = $uri->query_form;
    $ret{query} = {};
    for (keys(%query)) {
        $ret{query}->{$_} = $query{$_};
    }

    return \%ret;
}

sub deserialize_uri($) {
    my $uri = shift;
    return URI->new($uri) unless ref $uri;
    my $ret = URI->new;

    for (qw/scheme host path/) {
        $ret->$_($uri->{$_}) if defined $uri->{$_};
    }

    if (defined($uri->{query}) and (%{$uri->{query}})) {
         $uri->query_form(%{$uri->{query}});
    }

    return $ret;
}

# HTTP::Request / HTTP::Response
sub _serialize_message($) {
    my $message = shift;

    # Mandatory fields
    my %fields = (
        headers => _serialize_headers($message->headers),
        content => $message->content,
    );

    # Optional fields
    #$fields{uri} = _serialize_uri($message->uri) if $message->can('uri');
    for (qw/uri method  code message/) {
        $fields{$_} = $message->$_ . '' if $message->can($_);
    }

    return {
        class => Scalar::Util::blessed($message),
        fields => \%fields,
    };
}
sub _deserialize_message($) {
    my $dump = shift;

    ## Prepare
    # Args
    my $class = $dump->{class};
    my %args = %{$dump->{fields} // {}};

    # Construct message type in question
    my $message = eval("use $class; $class->new()");
    croak($@) if $@;

    ## Apply data
    # Headers need special treatment
    my $headers = _deserialize_headers($args{headers});
    if ((defined($headers)) and (keys(%{$headers}))) {
        $message->headers->header(%{$headers});
    }
    delete $args{headers};

    # And go for everything else
    while (my ($key, $value) = each(%args)) {
        $message->$key($value);
    }

    return $message;
}

# Class methods
sub from_file($$$) {
    my (undef, $path, $server) = @_;
    my @ret;

    my @documents = YAML::LoadFile($path);

    # Do we have a server argument?
    my %server;
    $server{server} = $server if defined $server;

    # Create
    for (@documents) {
        my %rules;
        %rules = ( rules => $_->{rules} ) if defined $_->{rules};

        @ret->push(__PACKAGE__->new(
            request => _deserialize_message($_->{request}),
            response => _deserialize_message($_->{response}),
            %rules,
            %server,
        ));
    }

    return @ret;
}

sub request_key($$) {
    my (undef, $request) = @_;

    confess unless defined $request;
    my $uri = $request->uri->canonical;
    return $uri->host . '|' . $uri->path;
}


# Object methods
sub save($$$) {
    my $this = shift;

    # Make sure the directory exists
    File::Path::make_path($this->dir);

    # Serialize
    my $document = YAML::Dump({
        request => _serialize_message($this->request),
        response => _serialize_message($this->response),
        rules => $this->rules,
    });

    # Write out
    my $fh = IO::File->new($this->path, 'a');
    croak("Can't open @{[$this->path]} for appending") unless defined $fh;
    $fh->print($document);
}

sub _match_get_value {
    my ($this, $subject, @path) = @_;

    my $object = shift(@path);
    my $value;

    # Fetch value
    if ((Scalar::Util::blessed($subject)) and ($subject->can($object))) {
        # Methods may return multiple values
        my @v = $subject->$object;
        if (@v > 1) {
            # Take values as a hash if possible
            $value = @v & 1 ? [ @v ] : { @v };
        }
        else {
            # Just a single value
            $value = $v[0];
        }
    }
    else {
         $value = $subject->{$object};
    }

    # Recurse?
    if (@path) {
        return $this->_match_get_value($value, @path);
    }

    # We're done
    return $value;
}

sub _match_recurse {
    my ($this, $request, $subject, @path) = @_;

    my $ref = ref($subject);

    if ($ref eq 'HASH') {
        keys(%{$subject});
        while (my ($key, $value) = each(%{$subject})) {
            return unless $this->_match_recurse($request, $value, (@path, $key));
        }
    }
    elsif ($ref eq '') {
        my $first = $this->_match_get_value($this->request, @path);
        my $second = $this->_match_get_value($request, @path);
        my $ret = $this->_match_eval($subject, $first, $second);
        unless ($ret) {
            $this->log->debug(join('::', @path) . " did not match. First: \"$first\", Second: \"$second\"");
        }
        return $ret;
    }

    return 1;
}

sub _match_eval {
    my ($this, $expr, $our, $their) = @_;

    if ($expr eq 'match') {
        return Data::Compare::Compare($our, $their);
    }
    else {
        return $their =~ /$expr/;
    }
}

sub match($$) {
    my ($this, $request) = @_;

    return $this->_match_recurse($request, $this->rules);
}

1;
