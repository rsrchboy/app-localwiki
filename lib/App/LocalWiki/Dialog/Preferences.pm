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

package App::LocalWiki::Dialog::Preferences;

use Moose;
use namespace::autoclean;
use common::sense;
use Gtk2::ExEx::Declarative 'widget';
use Smart::Comments;

extends 'Gtk2::ExEx::Widget';
with    'Gtk2::ExEx::With::Builder';

our $VERSION = '0.000_01';

has '+filename'    => (default => 'share/preferences_dialog.glade');
has '+widget_name' => (default => 'dialog1');

...;

__PACKAGE__->meta->make_immutable;

