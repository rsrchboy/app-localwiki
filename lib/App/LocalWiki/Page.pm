package App::LocalWiki::Page;

use Moose;
use namespace::autoclean;
use Document::Store::Types ':all';
use MooseX::InstanceTracking;

#has id
#display_name
#link_id
#in_store

#has store      => (is => 'ro', isa => Backend, required => 1);
has store      => (is => 'ro', isa => 'App::LocalWiki::Store', required => 1);
has parse_tree => (is => 'rw', trigger => sub { shift->mark_dirty });
has link_id    => (is => 'ro', isa => 'Str');

# XXX
has raw => (is => 'rw');

has is_dirty => (
    traits => [ 'Bool' ],
    is => 'ro', isa => 'Bool', default => 0,
    handles => {
        mark_dirty  => 'set',
        _mark_clean => 'unset',
        is_clean    => 'not',
    },
);

has save_page_sub => (
    traits => [ 'Code' ],
    is => 'ro', isa => 'CodeRef', required => 1, init_arg => 'save_page',
    handles => { save_page => 'execute_method' },
);

has _metadata => (
    is => 'ro', isa => 'HashRef',
    handles => {

    },
);

__PACKAGE__->meta->make_immutable;
