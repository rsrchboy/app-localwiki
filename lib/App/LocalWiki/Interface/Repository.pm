package App::LocalWiki::Interface::Repository;

# ABSTRACT: required repository methods

use Moose::Role;
use namespace::autoclean;

requires qw{

    shortname
    description

    uri

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
