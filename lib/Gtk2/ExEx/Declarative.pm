#
#===============================================================================
#
#         FILE:  Declarative.pm
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  10/03/2010 09:41:05 PM
#     REVISION:  ---
#===============================================================================

package Gtk2::ExEx::Declarative;

use strict;
use warnings;

use Smart::Comments;
use Sub::Exporter -setup => { exports => [ qw{ widget } ] };

use Gtk2;

    # FIXME for Gtk2::Declarative
    # Widget => { 
    #   new => sub { ... },  # only if needed
    #   set => { ... },
    #   signals => { ... },
    #   # children handling???

sub widget {
    #my %arg = { @_ };
    my ($name, %arg) = (shift, @_);

    my $class = $name =~ s/^\+// ? $name : _name_to_widget($name)->new();

    ### $class
    my $widget = $arg{new} ? $arg{new}->() : $class->new(); # _name_to_widget($name)->new();

    $widget->set(%{ $arg{set} }) if $arg{set};

    for my $method (qw{ signal_connect signal_connect_after signal_connect_swapped}) {

        my %signal = %{ $arg{$method} || {} };
        $widget->$method($_ => $signal{$_}) for keys %signal;
    }
    
    $widget->connect(@{$_}) for @{ $arg{connect} };

    my %call_methods = %{ $arg{call_methods} || {} };
    $widget->$_(@{ $call_methods{$_} }) for keys %call_methods;

    # FIXME I'm not so sure I like this...
    $arg{BUILD}->($widget) if $arg{BUILD};

    return $widget;
}

sub _name_to_widget {
    my $name = shift @_;

    $name =~ s/_(.)/\u$1/g;
    $name = "Gtk2::$name";
    
    return $name;
}

1;

