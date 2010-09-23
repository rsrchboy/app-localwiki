package App::LocalWiki::Interface::Store;

# ABSTRACT: required store methods

use Moose::Role;
use namespace::autoclean;

requires qw{

    shortname
    description

    uri
    page_tree

    has_page
    get_page
    set_page
    delete_page

    is_clean
    is_dirty

    has_remote

    flush
};

1;
