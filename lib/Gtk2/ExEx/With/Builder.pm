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

package Gtk2::ExEx::With::Builder;

use Moose::Role;
use namespace::autoclean;
use common::sense;

use MooseX::Types::Path::Class ':all';
use MooseX::Types::Perl        ':all';

use Gtk2::ExEx::MooseTypes ':all';

use Path::Class;
use File::ShareDir;

#use English qw{ -no_match_vars };  # Avoids regex performance penalty

our $VERSION = '0.000_01';

has filename   => (is => 'ro', isa => File, coerce => 1, required => 1);
has signals_to => (is => 'ro', isa => 'Object', lazy_build => 1);

has builder    => (
    is => 'ro', isa => Gtk2Builder, lazy_build => 1,
    handles => [ qw{ get_object } ],
);

sub _build_builder         { Gtk2::Builder->new() }
sub _build_signals_to      { shift @_             }
sub _build_widget          { $_[0]->builder->get_object($_[0]->widget_name) }

requires 'BUILD';

before BUILD => sub {
    my $self = shift @_;
    
    my $builder = $self->builder;
    $builder->add_from_file($self->filename);
    $self->builder->connect_signals({}, $self->signals_to);
};

sub _build_widget { 
    my $self = shift @_;

    return $self->builder->get_object($self->widget_name);
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


