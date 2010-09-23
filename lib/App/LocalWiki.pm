#############################################################################
#
# A great new module!
#
# Author:  Chris Weyl <cweyl@alumni.drew.edu>
# Company: No company, personal work
#
# See the end of this file for copyright and author information.
#
#############################################################################

package ;

use Moose;
use common::sense;
# one or the other
use namespace::autoclean;
use MooseX::MarkAsMethods autoclean => 1;

use MooseX::Types ':all';

with 'MooseX::Traits';

use Path::Class;
use Readonly;

our $VERSION = '0.000_01';

# ...

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

 - A great new module!

=head1 VERSION

This documentation refers to  version 0.000_01.

=head1 SYNOPSIS

    use ;
    # Brief but working code example(s) here showing the most common usage(s)

    # This section will be as far as many users bother reading
    # so make it as educational and exemplary as possible.


=head1 DESCRIPTION



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

All complex software has bugs lurking in it, and this module is no
exception.

Please report problems to Chris Weyl <cweyl@alumni.drew.edu>, or (preferred)
to this package's RT tracker at E<bug-@rt.cpan.org>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c)  Chris Weyl <cweyl@alumni.drew.edu>

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


