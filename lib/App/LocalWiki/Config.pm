package App::LocalWiki::Config;

use Moose;
use common::sense;
use MooseX::MarkAsMethods autoclean => 1;
use MooseX::Types              ':all';
use MooseX::Types::Path::Class ':all';

with 'MooseX::Traits';

use Path::Class;
use Readonly;

our $VERSION = '0.000_01';

has config => (
    # traits => ...
    # is => 'ro', 
    reader => 'config', writer => '_config',
    isa => 'HashRef', default => sub { { } },
    # handles => ...
);

sub BUILD {
    my $self = shift @_;

    my $config = {

        'window/main' => {

        },

        'window/about' => {

        },

        'widget/wikipage' => {


        },

    };
    
    $self->_config($config);
}

__PACKAGE__->meta->make_immutable;

__END__

