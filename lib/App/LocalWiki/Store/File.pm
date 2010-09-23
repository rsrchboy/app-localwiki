package App::LocalWiki::Store::File;

{
    package App::LocalWiki::Store::File::Tree;

}

use Moose;
use namespace::autoclean;

with 'App::LocalWiki::Interface::Store';

use Tree::File;
use Path::Class;





__PACKAGE__->meta->make_immutable;
