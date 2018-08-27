package HTTPSim::Frontend::Tk::MainWindow;

use MooseX::POE;
use Carp;
with 'MooseX::Log::Log4perl';

use Tk;
use Tk::Table;
use Tk::NoteBook;
use Log::Dispatch::TkText;
use DateTime;
use HTTPSim;

# Main window
has mw => (
    is => 'ro',
    isa => 'Tk::MainWindow',
    #default => sub { Tk::MainWindow->new },
    default => sub {
        my $this = shift;
        my $mw = $POE::Kernel::poe_main_window;
        $mw->OnDestroy(sub { $this->yield('shutdown') });
        return $mw;
    },
    lazy => 1,
);

# Level 1
has frame_top => (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->mw->Frame->pack(-side => 'top') },
    lazy => 1,
);

has frame_bot => (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->mw->Frame->pack(-side => 'bottom') },
    lazy => 1,
);

# Level 2: Top
has frame_status=> (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->frame_top->Labelframe(-text => 'Status')->pack(-side => 'left', -fill => 'both') },
    lazy => 1,
);

has frame_control => (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->frame_top->Labelframe(-text => 'Control')->pack(-side => 'right', -fill => 'y') },
    lazy => 1,
);

# Level 3: Server status
has label_server_status => (
    is => 'ro',
    isa => 'Tk::Label',
    default => sub { $_[0]->frame_status->Label(-text => 'Server status:')->grid(-row => 0, -column => 0) },
);

has entry_server_status => (
    is => 'ro',
    isa => 'Tk::Entry',
    default => sub { $_[0]->frame_status->Entry(-state => 'disabled')->grid(-row => 0, -column => 1) },
);

# Level 4: Last access
has label_last_access => (
    is => 'ro',
    isa => 'Tk::Label',
    default => sub { $_[0]->frame_status->Label(-text => 'Last access:')->grid(-row => 1, -column => 0) },
);

has entry_last_access => (
    is => 'ro',
    isa => 'Tk::Entry',
    default => sub { $_[0]->frame_status->Entry(-state => 'disabled')->grid(-row => 1, -column => 1) },
);

# Level 3: Mode
has label_mode => (
    is => 'ro',
    isa => 'Tk::Label',
    default => sub { $_[0]->frame_control->Label(-text => 'Mode:')->grid(-row => 0, -column => 0) },
);

has frame_mode => (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->frame_control->Frame->grid(-row => 0, -column => 1, -sticky => 'we') },
    lazy => 1,
);

has button_dump => (
    is => 'ro',
    isa => 'Tk::Button',
    default => sub {
        my $this = shift;
        $this->frame_mode->Button(
            -text => 'Dump',
            -relief => 'sunken',
            -command => sub { $this->select_mode('dump') },
        )->pack(-side => 'right', -fill => 'x')
    },
    lazy => 1,
);

has button_replay => (
    is => 'ro',
    isa => 'Tk::Button',
    default => sub {
        my $this = shift;
        $this->frame_mode->Button(
            -text => 'Replay',
            -command => sub { $this->select_mode('replay') },
        )->pack(-side => 'right', -fill => 'x', -before => $this->button_dump)
    },
);

# Level 3: Port
has label_port => (
    is => 'ro',
    isa => 'Tk::Label',
    default => sub { $_[0]->frame_control->Label(-text => 'Port:')->grid(-row => 1, -column => 0) },
);

has spinbox_port => (
    is => 'ro',
    isa => 'Tk::Spinbox',
    default => sub {
        my $this = shift;
        my $spinbox = $this->frame_control->Spinbox(
            -from => 1,
            -to => 65535,
            -command => sub {
                $this->settings_changed
            },
        )->grid(-row => 1, -column => 1, -stick => 'e');
        $spinbox->set(9090);
        return $spinbox;
    },
);

has label_static => (
    is => 'ro',
    isa => 'Tk::Label',
    default => sub { $_[0]->frame_control->Label(-text => 'Static remote:')->grid(-row => 2, -column => 0) },
);

has entry_static => (
    is => 'ro',
    isa => 'Tk::Entry',
    default => sub {
        my $this = shift;
        $this->frame_control->Entry(
            -validatecommand => sub {
                $this->settings_changed;
            }
        )->grid(-row => 2, -column => 1)
    },
);

# Level 4: Dir
has label_dir => (
    is => 'ro',
    isa => 'Tk::Label',
    default => sub { $_[0]->frame_control->Label(-text => 'Dump directory:')->grid(-row => 3, -column => 0) },
);

has frame_dir => (
    is => 'ro',
    isa => 'Tk::Frame',
    default => sub { $_[0]->frame_control->Frame->grid(-row => 3, -column => 1) },
    lazy => 1,
);

has entry_dir => (
    is => 'ro',
    isa => 'Tk::Entry',
    default => sub {
        my $this = shift;
        my $entry = $this->frame_dir->Entry(
            -validatecommand => sub {
                $this->settings_changed;
            },
            -state => 'disabled',
        )->pack(-side => 'left', -fill => 'x');
        $entry->insert(0, './dump') if HTTPSim::development_build;
        return $entry;
    },
);

has button_dir => (
    is => 'ro',
    isa => 'Tk::Button',
    default => sub {
        my $this = shift;
        $this->frame_dir->Button(
            -text => '...',
            -command => sub {
                my $selected = $this->mw->chooseDirectory(-initialdir => '.');
                if ($selected) {
                    $this->entry_dir->delete(0, 'end');
                    $this->entry_dir->insert(0, $selected);
                    $this->settings_changed;
                }
            },
        )->pack(-side => 'right')
    },
);

# Level 4: Action
has button_action => (
    is => 'ro',
    isa => 'Tk::Button',
    default => sub {
        my $this = shift;
        $this->frame_control->Button(
            -text => 'Start',
            -command => sub { $this->action },
        )->grid(-row => 4, -column => 0, -columnspan => 2,)
    },
);

# Level 2: Status detail
has notebook_detail => (
    is => 'ro',
    isa => 'Tk::NoteBook',
    default => sub { $_[0]->frame_bot->NoteBook->pack },
    lazy => 1,
);

# Level 3: Detail pages
has page_log => (
    is => 'ro',
    default => sub { $_[0]->notebook_detail->add('page_log', -label => 'Log' ) },
    lazy => 1,
);

has page_transactions => (
    is => 'ro',
    default => sub {
        $_[0]->page_log; # Make sure we're created after that
        $_[0]->notebook_detail->add('page_transactions', -label => 'Transactions')
    },
    lazy => 1,
);

# Level 3: Log
has logtext_log => (
    is => 'ro',
    default => sub { 
        my $s = $_[0]->page_log->Scrolled(
            'LogText',
            min_level => 'debug',
            hide_label => 1
        )->pack(-fill => 'x', -expand => 1);
        return $s;
    },
);

has table_transactions => (
    is => 'ro',
    isa => 'Tk::Table',
    default => sub {
        my $table = $_[0]->page_transactions->Table(
            -rows => 10,
            -columns => 6,
            -fixedrows => 1,
            -fixedcolumns => 6,
            -takefocus => 1,
        )->pack(-fill => 'both', -expand => 1);
        my $col = 0;
        for (qw/Time Client Method URI Result Source/) {
            $table->put(0, $col++, $table->Label(-text => $_));
        }
        return $table;
    },
);

has server => (
    is => 'ro',
    isa => 'HTTPSim::Server',
    builder => 'build_server',
    clearer => '_clear_server',
    predicate => 'has_server',
    lazy => 1,
);

sub clear_server($) {
    my $this = shift;

    unless (POE::Kernel->post($this->server->get_session_id, 'shutdown')) {
        croak("Can't shutdown server: $!");
    }
    $this->_clear_server;

    # Update UI
    $this->button_action->configure(-text => 'Start');
}

sub select_mode($$) {
    my ($this, $mode) = @_;

    # What button should be active / inactive
    my $active = $this->button_dump;
    my $inactive = $this->button_replay;

    if ($mode eq 'replay') {
        $active = $this->button_replay;
        $inactive = $this->button_dump;
    }

    # Carry out
    $active->configure(-relief => 'sunken');
    $inactive->configure(-relief => 'raised');

    # Update UI
    $this->settings_changed;
}

sub action($) {
    my $this = shift;

    $this->clear_server if $this->has_server;
    $this->server;
}

sub build_server($) {
    my $this = shift;
    my %args = ( status_session => $this->get_session_id );

    # Proibit multiple presses
    $this->button_action->configure(-state => 'disabled');

    # Collect mode
    my $mode = 'Dump';
    if ($this->button_replay->cget(-relief) eq 'sunken') {
        $mode = 'Replay';
    }

    # Collect port
    $args{port} = $this->spinbox_port->get;

    # Collect static remote
    my $static = $this->entry_static->get;
    $args{static_remote} = $static if $static;

    # Collect dump directory
    $args{dump_path} = $this->entry_dir->get;
    unless ($args{dump_path}) {
        $this->mw->messageBox(
            -type => 'Ok',
            -title => 'No dump directory selected',
            -message => 'You need to specify a dump directory!',
            -icon => 'error',
        );
        return undef;
    }

    # Create
    my $server = eval("use HTTPSim::Server::$mode; HTTPSim::Server::$mode->new(\%args)");
    croak($@) if $@;

    # Wait until it's fully realized
    POE::Kernel->run_one_timeslice;

    # Start
    $server->start;

    return $server;
}

sub settings_changed($) {
    my $this = shift;

    return unless $this->has_server;

    $this->button_action->configure(-text => 'Apply');
    $this->button_action->configure(-state => 'normal');
    return 1;
}

sub START {
    my $this = shift;

    POE::Kernel->refcount_increment($this->get_session_id, 'alive');
}

event shutdown => sub {
    my $this = shift;

    $this->clear_server if $this->has_server;
    POE::Kernel->refcount_decrement($this->get_session_id, 'alive');
};

event httpsim_running => sub {
    my ($this, $running) = ($_[0], @_[ARG0..$#_]);

    $this->entry_server_status->delete(0, 'end');
    $this->entry_server_status->insert(0, $running);
};

event httpsim_transaction => sub {
    my ($this, %transaction) = ($_[0], @_[ARG0..$#_]);
    my $now = DateTime->now;

    # Append to transaction log
    my $row = $this->table_transactions->totalRows;
    $this->table_transactions->put($row, 0, $now->ymd . ' ' . $now->hms);
    $this->table_transactions->put($row, 1, $transaction{client});
    $this->table_transactions->put($row, 2, $transaction{transaction}->request->method);
    $this->table_transactions->put($row, 3, $transaction{transaction}->request->uri . '');
    $this->table_transactions->put($row, 4, $transaction{transaction}->response->code);
    $this->table_transactions->put($row, 5, $transaction{result_source});

    # Update last access
    $this->entry_last_access->delete(0, 'end');
    $this->entry_last_access->insert(0, $transaction{transaction}->request->uri->path);
};

1;
