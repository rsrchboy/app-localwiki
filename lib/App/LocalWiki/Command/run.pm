package App::LocalWiki::Command::run;

use Moose;
use namespace::autoclean;
use common::sense;
use App::LocalWiki::Types ':all';

extends 'MooseX::App::Cmd::Command';

my @TO_LOAD = qw{
    Gtk2
    App::LocalWiki::Window::Main
};

has window => (
    traits => ['NoGetopt'],
    is => 'ro', isa => MainWindow, lazy_build => 1,
    handles => { show_window => 'show_all' },
);

sub execute {
    my ($self, $opts, $args) = @_;

    Class::MOP::load_class($_) for @TO_LOAD;

    # FIXME this may need to take place before loading other packages
    Gtk2->init();

    my $win = App::LocalWiki::Window::Main->new();
    $win->widget->show();

    Gtk2->main();
    ...
}

__PACKAGE__->meta->make_immutable;

