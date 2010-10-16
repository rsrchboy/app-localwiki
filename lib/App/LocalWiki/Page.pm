package App::LocalWiki::Page;

use Moose;
use namespace::autoclean;
use MooseX::InstanceTracking;

has id
display_name
link_id
in_store

has store => (is => 'ro', does => 'App::LocalWiki::Interface::Store', required => 1);

has _metadata => (
    is => 'ro', isa => 'HashRef',
    handles => {

    },
);

cached

sub save
reload_from_store

__PACKAGE__->meta->make_immutable;
