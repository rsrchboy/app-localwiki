package App::LocalWiki::Window::Main;

use Moose;
use namespace::autoclean;
use common::sense;
use MooseX::AttributeShortcuts;
use Gtk2::ExEx::Declarative 'widget';
use Smart::Comments;

extends 'Gtk2::ExEx::Widget';
with    'Gtk2::ExEx::With::Builder';

use App::LocalWiki::Widget::WikiPage;
use App::LocalWiki::Window::About;
use App::LocalWiki::Store;

use File::ShareDir;

our $VERSION = '0.000_01';

has '+filename'    => (default => 'share/WikiWiki.glade');
has '+widget_name' => (default => 'window1');

has app => (is => 'ro', isa => 'App::LocalWiki', required => 1);

has statusbar  => (
    is         => 'ro',
    isa        => 'Gtk2::Statusbar',
    lazy_build => 1,
    handles    => {

        push_status => 'push',
        pop_status  => 'pop',
    },
);

has store   => (
    is      => 'ro',
    isa     => 'App::LocalWiki::Store',
    required => 1,
    #lazy    => 1,
    #builder => 1,
);


sub _build_store {
    my $self = shift @_;

    my $store = $self
        ->app
        ->store_class
        ->new(
            name     => 'default',
            location => "$ENV{HOME}/.zimrepo",
            backend  => 'Filesystem'
        )
        ;
    return $store;
}

sub brief_status {
    my ($self, %arg) = @_;

    %arg = (id => 'brief-status', timeout => 5_000, %arg);

    #$self->push_status($arg{status}, $arg{id});
    my $id = $self->push_status(@arg{qw/id status/});

    Glib::Timeout->add($arg{timeout}, sub { $self->pop_status($arg{id}) });
    #Glib::Timeout->add($arg{timeout}, sub { $self->pop_status($id) });
    return;
}

has accel_group => (
    is => 'ro', isa => 'Gtk2::AccelGroup', lazy_build => 1,
    handles => { },
);

sub _build_accel_group {
    my $self = shift @_;

    my $ctrl = sub { (Gtk2::Gdk->keyval_from_name(@_), [ 'control-mask' ]) };

    my $group = widget AccelGroup => (
        connect => [
            # formatting
            [ $ctrl->('B'), [], sub { $self->get_current_page->toggle_bold      } ],
            [ $ctrl->('I'), [], sub { $self->get_current_page->toggle_italic    } ],
            [ $ctrl->('U'), [], sub { $self->get_current_page->toggle_underline } ],
            [ $ctrl->('K'), [], sub { $self->get_current_page->toggle_strike    } ],

            # commands
            [ $ctrl->('S'), [], sub { $self->on_save_action_activate            } ],
        ],
    );
    return $group;
}

has notebook => (
    is => 'ro', isa => 'Gtk2::Notebook', lazy_build => 1,
    handles => {
        append_notebook_page      => 'append_page',
        get_current_notebook_page => 'get_current_page',
        set_current_notebook_page => 'set_current_page',
        remove_notebook_page      => 'remove_page',
    },
);

sub _build_statusbar { shift->builder->get_object('statusbar') }
sub _build_notebook  { shift->builder->get_object('notebook1') }

around append_notebook_page => sub {
    my ($orig, $self) = (shift, shift);
    my $page = shift @_;

    my $scroller = widget ScrolledWindow => (
        BUILD => sub { shift->add($page) },
        set => {
            'hscrollbar-policy' => 'automatic',
            'vscrollbar-policy' => 'automatic',
        }
    );

    $scroller->show();
    my $img = Gtk2::Image->new_from_icon_name('gtk-close', Gtk2::IconSize->from_name('button'));
    my $button = widget Button => (
        signal_connect => { pressed => sub { ... } },
        set => {
            relief         => 'none',
            image          => $img,
            image_position => 'right',
        },
    );

    my $box = Gtk2::HBox->new;
    $box->pack_start_defaults(Gtk2::Label->new(shift @_));
    $box->pack_start_defaults($button);
    $box->show_all;

    return $self->$orig($scroller, $box);
};

after remove_notebook_page => sub { ... };

has about_dialog => (
    is => 'ro', isa => 'App::LocalWiki::Window::About', lazy_build => 1,
    handles => {
        show_about_dialog => 'show_all',
        hide_about_dialog => 'hide_all',
    },
);

sub _build_about_dialog { App::LocalWiki::Window::About->new(window => shift) }

sub on_help_menu_about_activate { shift->show_about_dialog }

has status_icon => (
    is => 'ro', isa => 'Gtk2::StatusIcon', builder => '_build_status_icon',
    handles => {
        notify_message => 'send_message',
        clear_notify_message => 'cancel_message',
    },
);

sub _build_status_icon {
    my $self = shift @_;

    my $icon = widget StatusIcon => (
        signal_connect => {
            activate => sub { $self->visible ? $self->hide_all : $self->show_all },
        },
        set => {
            'tooltip-text' => 'App::LocalWiki!',
            stock          => 'gtk-indent',
            visible        => 1,
        },
    );

    return $icon;
}

has wiki_pages => (
    traits => [ 'Hash' ],
    is => 'ro', isa => 'HashRef', default => sub { { } },
    handles => {
        has_pages => 'count',
        no_pages  => 'is_empty',

        get_page => 'get',
        _add_page => 'set',
        remove_page => 'delete',
    },
);

before remove_page => sub {
    my ($self, $num) = @_;

    $self->remove_notebook_page($num);
};

sub get_current_page {
    my $self = shift @_;

    return $self->get_page($self->get_current_notebook_page);
}

sub add_page {
    my ($self, $view) = @_;

    my $num = $self->append_notebook_page($view->widget, $view->title);
    $view->show_all;
    $self->_add_page($num => $view);
    return $num;
}

sub new_page {
    my $self = shift @_; # FIXME ...
    my %arg = @_; # title, etc

    %arg = (title => 'wah-wah', store => $self->store, %arg);
    my $view = $self->app->wikipage_widget_class->new(window => $self, %arg);
    return $self->add_page($view);
}

sub BUILD {
    my $self = shift @_;

    $self->widget->add_accel_group($self->accel_group);
    $self->new_page;
    $self->widget->show_all;
    return;
}

sub on_notebook1_change_current_page {
    my ($self, $notebook, $arg1) = @_;

    warn "changed page: $arg1";
    $self->notify_message("changed page: $arg1");
    return;
}

sub on_save_action_activate {
    my ($self) = @_;

    ### on_save_action_activate...
    $self->get_current_page->save_page;
}

sub home_button_clicked { shift->get_current_page->load_page('Home') }

sub new_page_button_clicked {
    my $self = shift @_;

    $self->new_page();
}

sub gtk_main_quit { Gtk2->main_quit }

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

App::LocalWiki::Window::Main

=head1 SEE ALSO

L<App::Localwiki>

=head1 BUGS AND LIMITATIONS

All complex software has bugs lurking in it, and this module is no exception.

Please report bugs to the author, preferably via the github issue tracker for
this project.  (Pull requests welcomed enthuseastically!)

Patches are welcome.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

This program is based in part on work done by Japp Karssenberg,
as part of the Zim project.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Chris Weyl.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Contains some code by and under an original license as follows:

Jaap Karssenberg (Pardus) E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2006 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

