package App::LocalWiki;

# ABSTRACT: A little desktop wiki

use Moose;
use common::sense;

extends 'MooseX::App::Cmd';
# FIXME do we want to do some sort of apply-to-instance dealie here?
#with 'MooseX::Traits';

sub default_command          { 'run'                                 }
sub main_window_class        { 'App::LocalWiki::Window::Main'        }
sub wikipage_widget_class    { 'App::LocalWiki::Widget::WikiPage'    }
sub default_store_class      { 'App::LocalWiki::Store::File'         }
sub repository_class         { 'App::LocalWiki::Repository'          }
sub preferences_dialog_class { 'App::LocalWiki::Dialog::Preferences' }

# FIXME
has store => (is => 'ro', does => 'App::LocalWiki::Interface::Store', lazy_build => 1);
sub _build_store { shift->default_store_class->new }

# XXX some sort of MooseX::Hooks here

__PACKAGE__->meta->make_immutable;

__END__

=head1 DESCRIPTION

This is a local, Gtk2, desktop wiki.  It is in an extremely early stage of development, and
may have radical changes made.

=head1 SEE ALSO

L<App::LocalWiki>

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


