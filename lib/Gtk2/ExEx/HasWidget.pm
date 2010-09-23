#
#===============================================================================
#
#         FILE:  HasWidget.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  09/27/2010 07:37:57 PM
#     REVISION:  ---
#===============================================================================

package Gtk2::ExEx::HasWidget;

use strict;
use warnings;

use Moose ();
use namespace::autoclean;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(with_meta => [ 'has_widget' ]);

sub has_widget {
    my ($meta, $name => %options) = @_;

    my %signals;

    my @signal_types =
        qw{ signal_connect signals_connect_after signal_connect_swapped };

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
