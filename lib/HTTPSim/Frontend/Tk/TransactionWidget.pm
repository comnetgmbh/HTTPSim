package HTTPSim::Frontend::Tk::TransactionWidget;

use Moose;
use Tk;

has top => (
    is => 'ro',
    isa => 'Tk::Widget',
     default => sub {
        my $this = shift;
        my $mw = $POE::Kernel::poe_main_window;
        return $mw;
    },
    lazy => 1,
);

has transaction => (
    is => 'ro',
    isa => 'HTTPSim::Transaction',
    required => 1,
);

has frame_left => (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->top->Frame->pack(-side => 'left') },
    lazy => 1,
);

has frame_right => (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->top->Frame->pack(-side => 'right') },
    lazy => 1,
);

has frame_meta => (
    is => 'ro',
    isa => 'Tk::Labelframe',
    default => sub { $_[0]->frame_left->Labelframe(-text => 'Info')->pack(-side => 'top', -fill => 'x', -expand => 1) },
    lazy => 1,
);

has entry_meta_filepath => (
    is => 'ro',
    isa => 'Tk::Entry',
    default => sub {
        $_[0]->frame_meta->Label(-text => 'File:')->grid(-row => 0, -column => 0);
        my $e = $_[0]->frame_meta->Entry(-width => 30)->grid(-row => 0, -column => 1, -sticky => 'we');
        $e->insert(0, $_[0]->transaction->path);
        $_[0]->frame_meta->Button(-text => 'Open')->grid(-row => 0, -column => 2, -sticky => 'e');
        return $e;
    },
    lazy => 1,
);

has frame_rules => (
    is => 'ro',
    isa => 'Tk::Labelframe',
    default => sub { $_[0]->frame_right->Labelframe(-text => 'Matching rules')->pack(-side => 'top', -fill => 'both', -expand => 1) },
    lazy => 1,
);

has text_rules => (
    is => 'ro',
    isa => 'Tk::Text',
    default => sub { $_[0]->frame_rules->Text(-height => 10, -width => 40)->pack },
    lazy => 1,
);

has frame_request => (
    is => 'ro',
    isa => 'Tk::Labelframe',
    default => sub { $_[0]->frame_left->Labelframe(-text => 'Request')->pack(-side => 'bottom') },
    lazy => 1,
);

has request_method => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_request->Label(-text => 'Method:')->grid(-row => 0, -column => 0);
         my $e = $_[0]->frame_request->Entry->grid(-row => 0, -column => 1, -sticky => 'we');
         $e->insert(0, $_[0]->transaction->request->method);
         return $e;
    },
    lazy => 1,
);

has request_headers => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_request->Label(-text => 'Headers:')->grid(-row => 2, -column => 0);
         $_[0]->_table_from_hash($_[0]->frame_request, { $_[0]->transaction->request->headers->flatten })->grid(-row => 2, -column => 1, -sticky => 'we');
    },
    lazy => 1,
);

has uri_scheme => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_request->Label(-text => 'Protocol:')->grid(-row => 3, -column => 0);
         my $e = $_[0]->frame_request->Entry->grid(-row => 3, -column => 1, -sticky => 'we');
         $e->insert(0, $_[0]->transaction->request->uri->scheme);
         return $e;
    },
    lazy => 1,
);

has uri_host => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_request->Label(-text => 'Host:')->grid(-row => 4, -column => 0);
         my $e = $_[0]->frame_request->Entry->grid(-row => 4, -column => 1, -sticky => 'we');
         $e->insert(0, $_[0]->transaction->request->uri->host);
         return $e;
    },
    lazy => 1,
);

has uri_path => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_request->Label(-text => 'Path:')->grid(-row => 5, -column => 0);
         my $e = $_[0]->frame_request->Entry->grid(-row => 5, -column => 1, -sticky => 'we');
         $e->insert(0, $_[0]->transaction->request->uri->path);
         return $e;
    },
    lazy => 1,
);

has uri_query => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_request->Label(-text => 'Query:')->grid(-row => 6, -column => 0);
         return $_[0]->_table_from_hash($_[0]->frame_request, { $_[0]->transaction->request->uri->query_form })->grid(-row => 6, -column => 1, -sticky => 'we');
    },
    lazy => 1,
);

has request_content => (
    is => 'ro',
    isa => 'Tk::Text',
    default => sub {
         $_[0]->frame_request->Label(-text => 'Content:')->grid(-row => 7, -column => 0);
         my $text = $_[0]->frame_request->Text(-height => 10, -width => 40)->grid(-row => 7, -column => 1, -sticky => 'we');
         $text->insert('1.0', $_[0]->transaction->request->content);
         return $text;
    },
    lazy => 1,
);

has frame_response => (
    is => 'ro',
    isa => 'Tk::Labelframe',
    default => sub { $_[0]->frame_right->Labelframe(-text => 'Response')->pack(-side => 'bottom') },
    lazy => 1,
);

has response_code => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_response->Label(-text => 'Code:')->grid(-row => 0, -column => 0);
         my $e = $_[0]->frame_response->Entry->grid(-row => 0, -column => 1, -sticky => 'we');
         $e->insert(0, $_[0]->transaction->response->code . ' ' . $_[0]->transaction->response->message);
         return $e;
    },
    lazy => 1,
);

has response_headers => (
    is => 'ro',
    isa => 'Tk::Widget',
    default => sub {
         $_[0]->frame_response->Label(-text => 'Headers:')->grid(-row => 1, -column => 0);
         return $_[0]->_table_from_hash($_[0]->frame_response, { $_[0]->transaction->response->headers->flatten })->grid(-row => 1, -column => 1, -sticky => 'we');
    },
    lazy => 1,
);

has response_content => (
    is => 'ro',
    isa => 'Tk::Text',
    default => sub {
         $_[0]->frame_response->Label(-text => 'Content:')->grid(-row => 2, -column => 0);
         my $e = $_[0]->frame_response->Text(-height => 10, width => 40)->grid(-row => 2, -column => 1, -sticky => 'we');
         $e->insert('1.0', $_[0]->transaction->response->content);
         return $e;
    },
    lazy => 1,
);


sub BUILD {
    my $this = shift;
    
    $this->entry_meta_filepath;
    $this->text_rules;
    
    $this->request_method;
    $this->request_headers;
    $this->uri_scheme;
    $this->uri_host;
    $this->uri_path;
    $this->uri_query;
    $this->request_content;
    
    $this->response_code;
    $this->response_headers;
    $this->response_content;
}

# UI helpers
sub _table_from_hash {
    my ($this, $parent, $hash) = @_;

    my $table = $parent->Table(
        -rows => 5,
        -columns => 2,
        -fixedrows => 1,
        -fixedcolumns => 2,
        -takefocus => 1,
    );

    my $row = 0;
    $table->put($row, 0, 'Name');
    $table->put($row++, 1, 'Value');
    for my $key (sort(keys(%{$hash}))) {
        $table->put($row, 0, $key);
        $table->put($row++, 1, $hash->{$key});
    }

    return $table;
}

1;
