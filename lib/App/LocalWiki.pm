package App::LocalWiki;

# ABSTRACT: A little desktop wiki

use Moose;
use namespace::autoclean;
use common::sense;
use MooseX::AttributeShortcuts;

use Path::Class;
use Config::Tiny;

use App::LocalWiki::Types ':all';

extends 'MooseX::App::Cmd';
with 'MooseX::Traits';

# debug
use Smart::Comments;

sub default_command          { 'run'                                 }
sub main_window_class        { 'App::LocalWiki::Window::Main'        }
sub wikipage_widget_class    { 'App::LocalWiki::Widget::WikiPage'    }
sub store_class              { 'App::LocalWiki::Store'               }
sub preferences_dialog_class { 'App::LocalWiki::Dialog::Preferences' }

has config => (is => 'lazy', isa => 'Config::Tiny');
sub _build_config { Config::Tiny->read("$ENV{HOME}/.localwiki") }

has window    => (
    is        => 'rwp',
    isa       => MainWindow,
    predicate => 1,
    handles   => {

        show_window => 'show_all',
    },
);

sub run_wiki {
    my ($self, $opts, $args) = @_;

    Class::MOP::load_class($_)
        for 'Gtk2', $self->main_window_class;

    my $dump = $self->config;
    ### $dump

    Gtk2->init();

    $self->load_pixmaps();
    $self->_set_window($self->main_window_class->new(app => $self));
    $self->show_window();

    Gtk2->main();

    return;
}

sub load_pixmaps {
    my $self = shift @_;

    my $dir = dir qw{ share pixmaps };

    my @files;
    while (my $file = $dir->next) {

        push @files, $file->absolute unless $file->is_dir;
        warn "$file";
    }

	my $factory = Gtk2::IconFactory->new;
	$factory->add_default;
	my %icons;
	for my $f (@files) {
		my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file("$f") || die $@;
		my $icon_set = Gtk2::IconSet->new_from_pixbuf($pixbuf) || die $@;
		my $n = "$f";
		$n =~ s/.*[\/\\]//;
		$n =~ s/\..*//;
		#next if exists $icons{$n};
		$icons{"$n"} = "$f";
		warn "Icon: $n => $f\n";
		$factory->add($n => $icon_set);
	}
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 DESCRIPTION

This is a local, Gtk2, desktop wiki.  It is in an extremely early stage of development, and
may have radical changes made.

=head1 SEE ALSO

L<App::LocalWiki>

=head1 BUGS AND LIMITATIONS

All complex software has bugs lurking in it, and this module is no exception.

Please report bugs to the author, preferably via the github issue tracker for
this project.  (Pull requests welcomed enthuseastically!)

Patches are welcome.

=cut
