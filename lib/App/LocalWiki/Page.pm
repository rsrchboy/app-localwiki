#
#===============================================================================
#
#         FILE:  Page.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  09/26/2010 12:57:18 AM
#     REVISION:  ---
#===============================================================================

package App::LocalWiki::Page;

use Moose;
use namespace::autoclean;
use MooseX::InstanceTracking;

has id
display_name
link_id
in_store

metadata

cached

sub save
reload_from_store

__PACKAGE__->meta->make_immutable;
