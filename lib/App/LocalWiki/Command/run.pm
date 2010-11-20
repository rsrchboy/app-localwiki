package App::LocalWiki::Command::run;

use Moose;
use namespace::autoclean;
use common::sense;
use App::LocalWiki::Types ':all';
use Path::Class;

extends 'MooseX::App::Cmd::Command';

my @TO_LOAD = qw{
    Gtk2
    App::LocalWiki::Window::Main
};

has window => (
    traits => ['NoGetopt'],
    is => 'ro', isa => MainWindow, lazy_build => 1,
    handles => { show_window => 'show_all' },
);

sub execute {
    my ($self, $opts, $args) = @_;

    Class::MOP::load_class($_) for @TO_LOAD;

    # FIXME this may need to take place before loading other packages
    Gtk2->init();

    $self->load_pixmaps();

    #my $win = App::LocalWiki::Window::Main->new();
    my $win = $self->app->main_window_class->new(app => $self->app);
    #$win->widget->show();
    $win->show_all();

    Gtk2->main();
    ...
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

=head1 NAME

App::LocalWiki::Command::run - run the wiki!

=head1 SEE ALSO

L<App::Localwiki>

=head1 BUGS AND LIMITATIONS

All complex software has bugs lurking in it, and this module is no exception.

Please report bugs to the author, preferably via the github issue tracker for
this project.  (Pull requests welcomed enthuseastically!)

Patches are welcome.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

This program is based in part on work done by Japp Karssenberg,
as part of the Zim project.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Chris Weyl.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Contains some code by and under an original license as follows:

Jaap Karssenberg (Pardus) E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2006 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


