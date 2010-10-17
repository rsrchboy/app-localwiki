package App::LocalWiki::Repository;

use Moose;
use common::sense;
use namespace::autoclean;
use MooseX::Types              ':all';
use MooseX::Types::Path::Class ':all';
use MooseX::Types::URI         ':all';

with 'MooseX::Traits';

use Path::Class;
use Readonly;

# FIXME
use App::LocalWiki::Store::File;
use App::LocalWiki::Interface::Store;

sub default_store_class { 'App::LocalWiki::Store::File' }

has name => (is => 'rw', isa => 'Str', required => 1, trigger => sub { shift->_name_set });
has _uri  => (is => 'ro', isa => 'Str', required => 1, trigger => sub { shift->_uri_set }, init_arg => 'uri');

sub _name_set { warn }
sub _uri_set  { warn }

has store => (
    is => 'ro', does => 'App::LocalWiki::Interface::Store',
    builder => '_build_store', lazy => 1,
    handles => [ qw{ load_page save_page } ],
    #handles => 'App::LocalWiki::Interface::Store',
);

sub _build_store { $_[0]->default_store_class->new(uri => $_[0]->_uri) }


__PACKAGE__->meta->make_immutable;
