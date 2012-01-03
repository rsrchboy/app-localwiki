package Gtk2::ExEx::Widget;

use Moose;
use namespace::autoclean;
use common::sense;

use MooseX::Types::Path::Class ':all';

use Gtk2::ExEx::MooseTypes ':all';
use Gtk2;

use Path::Class;

has widget => (
    is => 'ro', isa => Gtk2Widget, lazy_build => 1,

    handles => [ qw{
        signal_connect
        signal_connect_after
        signal_connect_swapped
        signal_emit
        show
        hide
        show_all
        hide_all
        visible
    }],
);

# XXX delegation?
sub gtk_widget_hide { shift->widget->hide }
sub gtk_widget_show { shift->widget->show }

has widget_name => (is => 'ro', isa => 'Str', required => 1);

has stash   => (
    traits  => [ 'Hash' ],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { { } },
    clearer => 'clear_stash',

    handles => {
        get_stashed => 'get',
        set_stashed => 'set',
        has_stashed => 'count',
        no_stash    => 'is_empty',
    },
);

has _signals_to_connect => (

    traits   => [ 'Hash' ],
    is       => 'ro',
    isa      => 'HashRef[CodeRef|Str]',
    builder  => '_build__signals_to_connect',
    clearer  => '_clear_signals_to_connect',
    init_arg => 'signals_to_connect',
    handles  => {

        _get_signal_method      => 'get',
        _set_signal_method      => 'set',
        _has_signal_method_for  => 'exists',
        _get_signals_to_connect => 'keys',
    },
);

sub _connect_initial_signals {
    my $self = shift @_;

    for my $signal ($self->_get_signals_to_connect) {

        warn "connecting: $signal";
        my $cb = $self->_get_signal_method($signal);
        $self->signal_connect($signal => sub { $self->$cb(@_) });
    }

    return;
}

sub _build__signals_to_connect { { } }

sub BUILD {
    my $self = shift @_;

    $self->_connect_initial_signals;
    return;
}

1;

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut
