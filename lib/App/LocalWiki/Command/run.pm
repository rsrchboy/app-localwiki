package App::LocalWiki::Command::run;

# ABSTRACT: Run the wiki

use Moose;
use namespace::autoclean;
use common::sense;

extends 'MooseX::App::Cmd::Command';

sub abstract { 'Launch localwiki' }

sub execute {
    my ($self, $opts, $args) = @_;

    $self->app->run_wiki;
    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 DESCRIPTION

Run the application.

=head1 SEE ALSO

L<App::Localwiki>

=cut
