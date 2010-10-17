#############################################################################
#
# Copyright (c) |YEAR| |COPYRIGHTHOLDER| <|EMAIL|>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package App::LocalWiki::Window::Main;

use Moose;
use namespace::autoclean;
use common::sense;
use Gtk2::ExEx::Declarative 'widget';
use Smart::Comments;

extends 'Gtk2::ExEx::Widget';
with    'Gtk2::ExEx::With::Builder';

use App::LocalWiki::Widget::WikiPage;
use App::LocalWiki::Window::About;
use App::LocalWiki::Repository;

use File::ShareDir;

our $VERSION = '0.000_01';

has '+filename'    => (default => 'share/WikiWiki.glade');
has '+widget_name' => (default => 'window1');

has app => (is => 'ro', isa => 'App::LocalWiki', required => 1);

has statusbar => (
    is => 'ro', isa => 'Gtk2::Statusbar', lazy_build => 1,
    handles => {
        push_status => 'push',
        pop_status  => 'pop',
    },
);

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
            [ $ctrl->('B'), [], sub { $self->get_current_page->toggle_bold      } ],
            [ $ctrl->('I'), [], sub { $self->get_current_page->toggle_italic    } ],
            [ $ctrl->('U'), [], sub { $self->get_current_page->toggle_underline } ],
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
        BUILD => sub { shift->add_with_viewport($page) },
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

    # FIXME hardcoded at one repo, at the moment
    state $repo = $self
        ->app
        ->repository_class
        ->new(name => 'default', uri => "$ENV{HOME}/.zimrepo")
        ;

    %arg = (title => 'wah-wah', repository => $repo, %arg);
    #my $view = App::LocalWiki::Widget::WikiPage->new(window => $self, %arg);
    my $view = $self->app->wikipage_widget_class->new(window => $self, %arg);
    return $self->add_page($view);

    #my $view = WikiPage->new(window => $self);
    #my $num = $self->append_notebook_page($view->widget, $arg{title});
    #$view->show;
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

package main;

use Gtk2 -init;

my $win = App::LocalWiki::Window::Main->new();
$win->widget->show();

Gtk2->main();

__END__

=head1 NAME

<Module::Name> - <One line description of module's purpose>

=head1 VERSION

The initial template usually just has:

This documentation refers to <Module::Name> version 0.0.1


=head1 SYNOPSIS

	use <Module::Name>;
	# Brief but working code example(s) here showing the most common usage(s)

	# This section will be as far as many users bother reading
	# so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the
form "An object of this class represents...", to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.


=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).

=head1 SEE ALSO

L<...>

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication
whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to |AUTHOR| <|EMAIL|>, or (preferred)
to this package's RT tracker at E<bug-PACKAGE@rt.cpan.org>.

Patches are welcome.

=head1 AUTHOR

|AUTHOR|  <|EMAIL|>


=head1 LICENSE AND COPYRIGHT

Copyright (c) |YEAR| |COPYRIGHTHOLDER| <|EMAIL|>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut


