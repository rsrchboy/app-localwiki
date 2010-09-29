package Gtk2::ExEx::HasWidget;

use strict;
use warnings;

use Gtk2 ();

{
    package Gtk2::ExEx::HasWidget::Trait::Attribute;
    use Moose::Role;
    use namespace::autoclean;

    qw{ signals after_signals signals_swapped };

    my $gen_handles = sub { 
        my $name = shift @_;
        chomp my $singular = $name;

        return {
            "has_$name" => 'count',
            "no_$name"  => 'empty',
            "num_$name" => 'count',
            "get_$singular" => 'get',
            # no set atm...
            "all_$name" => 'keys',
        };
    };

    my @signal_defn = (
        traits => [ 'Hash' ],
        is => 'ro', isa => 'HashRef[CodeRef]', default => { { } },
    );

    has $_ => (@signal_defn, handles => $gen_handles->($_))
        for qw{ signals after_signals swapped_signals };

    has gtk2_builder => (is => 'ro', isa => 'Gtk2::Builder', ...);

    # has widget => (
    #   traits => [ 'Widget' ],
    #   is => 'ro', isa => 'Gtk2::Something', ...,
    #   handles => { ... }, # probably externally defined
    #   signals_connect

    # after BUILD?

    sub connect_gtk_signals { ... }

}


use Moose ();
use namespace::autoclean;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(with_meta => [ 'has_widget' ]);

sub has_widget {
    my ($meta, $name => %arg) = @_;

    my %signals;

    # FIXME add "properties" stanza

    my @signal_types =
        qw{ signal_connect signals_connect_after signal_connect_swapped };

    ### first, setup our default builder and lazy options...
    my $isa = $arg{isa};
    $arg{builder} = sub { $isa->new() } unless $arg{builder};
    $arg{lazy} = 1 unless exists $arg{lazy};

    ### create and setup our initializer to connect signals...
    my $initializer = sub {
        my ($self, $value, $setter, $meta) = @_;


    };

    # check to see if we have any signals; if so, attach!
    do { $signals{$_} = delete $options{$_} if $options{$_} }
        for @signal_types;
    
    my $connector = sub { 
        my ($widget, $setter, $attribute_meta) = @_;
        
        for my $type (keys %signals) {

            my $subs = $signals{$type};
            $widget->$type($_ => $subs->{$_}) for keys %$subs;
        }
        
        $setter->($widget);
    };

    my $widget_type = $options{isa};
    $options{lazy} = 1;
    $options{default} = sub { $widget_type->new() };

    $meta->add_attribute(%options);
    return;
}

1;

=head2 has_widget

Syntactic sugar for 'has' enabling signals

=cut
