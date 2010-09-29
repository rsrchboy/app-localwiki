#############################################################################
#
# |CURSOR|
#
# Author:  |AUTHOR| (|AUTHORREF|), <|EMAIL|>
# Company: |COMPANY|
# Created: |DATE|
#
# Copyright (c) |YEAR| |COPYRIGHTHOLDER| <|EMAIL|>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Gtk2::ExEx::Widget;

use Moose;
use namespace::autoclean;
use common::sense;

use MooseX::Types::Path::Class ':all';

use Gtk2::ExEx::MooseTypes ':all';
use Gtk2;

use Path::Class;

our $VERSION = '0.000_01';

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

sub gtk_widget_hide { shift->widget->hide }
sub gtk_widget_show { shift->widget->show }

has widget_name => (is => 'ro', isa => 'Str', required => 1);

has stash  => (
    traits => [ 'Hash' ],
    is => 'ro', isa => 'HashRef', default => sub { { } }, clearer => 'clear_stash',
    handles => {
        get_stashed => 'get',
        set_stashed => 'set',
        has_stashed => 'count',
        no_stash    => 'is_empty',
    },
);

has _signals_to_connect => (
    traits => [ 'Hash' ],
    is => 'ro', isa => 'HashRef[CodeRef|Str]', # default => sub { { } },
    builder => '_build__signals_to_connect',
    clearer => '_clear_signals_to_connect',
    init_arg => 'signals_to_connect',
    handles => {
        _get_signal_method => 'get',
        _set_signal_method => 'set',

        _has_signal_method_for => 'exists',

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

sub BUILD {
    my $self = shift @_;

    $self->_connect_initial_signals();
    return;
}

1;

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


