#
#===============================================================================
#
#         FILE:  Types.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  10/03/2010 08:20:51 PM
#     REVISION:  ---
#===============================================================================

package App::LocalWiki::Types;

use MooseX::Types -declare => [ qw{ MainWindow } ];
use common::sense;

class_type 'App::LocalWiki::Window::Main';

subtype MainWindow, as 'App::LocalWiki::Window::Main';

1;
