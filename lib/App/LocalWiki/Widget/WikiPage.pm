package App::LocalWiki::Widget::WikiPage;

# ABSTRACT: A representation of a given page

use Reindeer;
#use namespace::autoclean;
use common::sense;

use Document::Store::Types ':all';
use Gtk2::ExEx::Declarative 'widget';
use Gtk2::Ex::HyperTextView::Markdown;
use Gtk2::Ex::HyperTextView::Pod;
use Gtk2::Spell;
use IO::File;

extends 'Gtk2::ExEx::Widget';

# Debugging
use Smart::Comments;

sub _textview_class { 'Gtk2::Ex::HyperTextView::Pod' }

has '+widget_name' => (default => 'wah wah');

has buffer => (

    is  => 'lazy',
    isa => 'Gtk2::TextBuffer',

    handles => {
        toggle_bold      => [ apply_format => 'bold'      ],
        toggle_italic    => [ apply_format => 'italic'    ],
        toggle_underline => [ apply_format => 'underline' ],
        toggle_strike    => [ apply_format => 'strike'    ],

        ( map { $_ => $_ } qw{ set_parse_tree get_parse_tree } ),
    },
);

has config => (is => 'ro', isa => 'HashRef', default => sub { { } });
has title  => (is => 'ro', isa => 'Str',     default => 'wah-wah');

has page  => (is => 'rw', isa => 'App::LocalWiki::Page');
has store => (is => 'ro', isa => 'App::LocalWiki::Store', required => 1);

has window => (
    is => 'ro', isa => 'App::LocalWiki::Window::Main', required => 1, weak_ref => 1,
    handles => [ qw{
        push_status
        pop_status
        brief_status
    } ],
);

has target_list => (is => 'ro', isa => 'Gtk2::TargetList', lazy_build => 1);

sub _build_buffer { shift->widget->buffer }

sub _build_target_list {
    my $self = shift @_;

    # XXX note, minimum required version here
    #if (Gtk2->CHECK_VERSION(2, 6, 0)) {

    my $tlist = widget TargetList => (
        call_methods => {
            add_uri_targets  => [ 0 ],
            add_text_targets => [ 1 ],
            add_table        => [ ['text/x-zim-page-list', [], 2] ],
        },
    );
    return $tlist;
}

sub _build_widget {
    my $self = shift @_;

    #my $text = widget '+Gtk2::Ex::WYSIWYG' => (
    my $text = widget '+Gtk2::Ex::HyperTextView::Markdown' => (
        signal_connect => {

            #key_press_event => sub { warn 'kpe'; $self->on_key_press_event(@_) },
            link_enter       => sub { warn "Entered link: $_[1]" },
            link_leave       => sub { warn "Left link: $_[1]" },
            link_clicked     => sub { warn 'link clicked!' },
        },
        set => {

            editable    => 1,
            'wrap-mode' => 'word',
        },
    );

    # FIXME
    # $text->set('check-spelling' => 1);
    #$text->set('debug' => 1);
    return $text;
}

sub _build_widget_XX {
    my $self = shift @_;

    my $htext = widget '+Gtk2::Ex::HyperTextView' => (

        signal_connect => {
            link_enter      => sub { $self->push_status('in link', 'link' ) },
            link_leave      => sub { $self->pop_status('link') },
            link_clicked    => sub { $self->link_clicked(@_) },
            key_press_event => sub { $self->on_key_press_event(@_) },
            populate_popup  => sub { ... },
        },
        signal_connect_after => {
            toggle_overwrite => sub { $self->on_toggle_overwrite },
        },
        signal_connect_swapped => {
            drag_data_received => sub { warn },
        },
        call_methods => {
            set_left_margin  => [ 10 ],
            set_right_margin => [  5 ],
            drag_dest_set => [
                ['motion', 'highlight'],
                ['link', 'copy', 'move'], # We would prefer only 'link' here, but KDE needs 'move'
            ],
            drag_dest_set_target_list => [ $self->target_list ],
            set_buffer => [ $self->buffer ],
        },

    );

    return $htext;
}

sub link_clicked {
    my ($self, $view, $link_name) = @_;

    $self->load_page($link_name);
    return;
}

sub load_page {
    my ($self, $link_name) = @_;

    ### in wikipage load_page()...
    my $page = $self->store->load_page($link_name);
    warn;
    #$self->widget->deserialise($page->raw);
    $self->widget->load_string($page->raw);

    warn;
    $self->page($page);
    warn;

    return;
}

sub save_page {
    my $self = shift @_;

    $self->page->parse_tree($self->get_parse_tree);
    $self->page->save_page($self);
    return;
}

# UGH FIXME
has _current_file => (is => 'rw', isa => 'Str');

sub BUILD {
    my $self = shift @_;

    $self->load_page('Home');
    return;
}

## WARNING: here there be dragons

has _save_timeout => (is => 'ro', lazy_build => 1);

sub _build__save_timeout {
    my $self = shift @_;

    return Glib::Timeout->add(
        5_000,
        sub { $self->save_page(); $self->_clear_save_timeout },
    );
}

sub on_key_press_event { # some extra keybindings
    # FIXME for more consistent behaviour test for selections
    #my ($htext, $event, $self) = @_;

    # XXX
    return;

    my ($self, $textview, $event) = @_;
    my $val = $event->keyval();

    my $wysiwyg = $self->widget;

    my $htext = $wysiwyg->get_text;
    my $buffer = $wysiwyg->get_buffer;

    # set up our save callback, if not otherwise
    do { warn 'timeout create'; $self->_save_timeout } unless $self->_has_save_timeout;

    warn blessed $_ for $self, $htext, $event;

    return 0;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 SEE ALSO

L<App::LocalWiki>

=cut
