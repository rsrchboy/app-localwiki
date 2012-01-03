package Gtk2::ExEx::With::Builder;

use Moose::Role;
use namespace::autoclean;
use common::sense;

use MooseX::Types::Path::Class ':all';
use MooseX::Types::Perl        ':all';

use Gtk2::ExEx::MooseTypes ':all';

use Path::Class;
use File::ShareDir;

has filename   => (is => 'ro', isa => File, coerce => 1, required => 1);
has signals_to => (is => 'ro', isa => 'Object', lazy_build => 1);

has xml     => (
    traits  => [ 'String' ],
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => '',
);

has builder    => (
    is         => 'ro',
    isa        => Gtk2Builder,
    lazy_build => 1,
    handles    => [ qw{ get_object } ],
);

sub _build_builder         { Gtk2::Builder->new() }
sub _build_signals_to      { shift @_             }
sub _build_widget          { $_[0]->builder->get_object($_[0]->widget_name) }

requires 'BUILD';

before BUILD => sub {
    my $self = shift @_;

    my $builder = $self->builder;
    $builder->add_from_file($self->filename);
    $self->builder->connect_signals({}, $self->signals_to);
};

1;

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

L<...>

=cut
