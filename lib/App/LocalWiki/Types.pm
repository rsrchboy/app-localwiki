package App::LocalWiki::Types;

use MooseX::Types -declare => [ qw{ MainWindow } ];
use common::sense;

class_type 'App::LocalWiki::Window::Main';

subtype MainWindow, as 'App::LocalWiki::Window::Main';

1;
