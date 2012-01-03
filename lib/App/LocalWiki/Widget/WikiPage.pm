package App::LocalWiki::Widget::WikiPage;

use Moose;
use namespace::autoclean;
use common::sense;
use Gtk2::ExEx::Declarative 'widget';
use Smart::Comments;
use IO::File;

extends 'Gtk2::ExEx::Widget';

use Gtk2::Ex::HyperTextView;
use Gtk2::Ex::HyperTextBuffer;

our $VERSION = '0.000_01';

use Document::Store::Types ':all';

has '+widget_name' => (default => 'wah wah');
has buffer => (
    is => 'ro', isa => 'Gtk2::Ex::HyperTextBuffer', lazy_build => 1,
    handles => {
        toggle_bold      => [ apply_format => 'bold'      ],
        toggle_italic    => [ apply_format => 'italic'    ],
        toggle_underline => [ apply_format => 'underline' ],
        toggle_strike    => [ apply_format => 'strike'    ],

        ( map { $_ => $_ } qw{ set_parse_tree get_parse_tree } ),
    },
);

has config => (is => 'ro', isa => 'HashRef', default => sub { { } });
has title  => (is => 'ro', isa => 'Str', default => 'wah-wah');

has page       => (is => 'rw', isa => 'App::LocalWiki::Page');
#has repository => (is => 'ro', isa => 'App::LocalWiki::Repository', required => 1);
#has store => (is => 'ro', isa => Backend, required => 1);
has store => (is => 'ro', isa => 'App::LocalWiki::Store', required => 1);

has window => (
    is => 'ro', isa => 'App::LocalWiki::Window::Main', required => 1, weak_ref => 1,
    handles => [ qw{
        push_status
        pop_status
        brief_status
    } ],
);

has target_list => (
    is => 'ro', isa => 'Gtk2::TargetList', lazy_build => 1,
    #handles => {
);

sub _build_buffer {
    my $self = shift @_;

    my $buffer = Gtk2::Ex::HyperTextBuffer->new();
    $buffer->create_default_tags;

    return $buffer;
}

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

    my $page = $self->store->load_page($link_name);
    #$self->set_parse_tree($page->get_parse_tree);
    $self->set_parse_tree($page->parse_tree);
    $self->page($page);
}

sub save_page {
    my $self = shift @_;

    $self->page->parse_tree($self->get_parse_tree);
    $self->page->save_page;
    return;
}

# UGH FIXME
has _current_file => (is => 'rw', isa => 'Str');

# FIXME
use App::LocalWiki::Format::Zim;

sub BUILD {
    my $self = shift @_;

    $self->load_page('Home');
    return;
}

## WARNING: here there be dragons

sub _user_action_ (&$) {
    # This is a macro needed to make actions undo-able
    # wrap all interactive operations with this method.
    $_[1]->signal_emit('begin_user_action');
    $_[0]->();
    $_[1]->signal_emit('end_user_action');
}

sub as_user {
    my ($self, $action_sub) = (shift, shift);

    $self->signal_emit('begin_user_action');
    $action_sub->(@_);
    $self->signal_emit('end_user_action');
}

my ($k_tab, $k_l_tab, $k_return, $k_kp_enter, $k_backspace, $k_escape, $k_multiply, $k_home, $k_F3) =
    @Gtk2::Gdk::Keysyms{qw/Tab ISO_Left_Tab Return KP_Enter BackSpace Escape KP_Multiply Home F3/};
#my @k_parse_word = ($k_tab, map ord($_), ' ', qw/. ; , ' "/);

my $punctuation = qr/[\.\!\?]*/;

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
    my ($self, $htext, $event) = @_;
    my $val = $event->keyval();

    # set up our save callback, if not otherwise
    do { warn 'timeout create'; $self->_save_timeout } unless $self->_has_save_timeout;

    #warn blessed $_ for $self, $htext, $event;

    #no strict 'vars'; # sigh FIXME

    if ($$self{app}{read_only}) {
        # Unix like key bindings for read-only mode
        if ($val == ord '/') {
            $self->Find;
            return 1;
        }
        elsif ($val == ord ' ') {
            my $step = ($event->state >= 'shift-mask') ? -1 : 1 ;
            $htext->signal_emit('move-cursor', 'pages', $step, 0);
            return 1;
        }
        else { return 0 }
    }

    if ($val == $k_return or $val == $k_kp_enter) { # Enter
        my $buffer = $htext->get_buffer;
        my $iter = $buffer->get_iter_at_mark($buffer->get_insert());
        #return 1 if defined $htext->click_if_link_at_iter($iter); # ?
        $self->parse_word($iter); # end-of-line is also end-of-word
        $iter = $buffer->get_iter_at_mark($buffer->get_insert());
        $self->parse_line($iter) or return 0;
        $htext->scroll_mark_onscreen( $buffer->get_insert );
        return 1;
    }
    elsif (
        $self->{app}{settings}{backsp_unindent} and $val == $k_backspace
        or $val == $k_l_tab
        or $val == $k_tab and $event->state >= 'shift-mask'
    ) { # BackSpace or Shift-Tab
        my $buffer = $htext->get_buffer;
        my ($start, $end) = $buffer->get_selection_bounds;
        if ($end and $end != $start) {
            my $cont = $self->selection_backspace($start, $end);
            return $val == $k_tab ? 1 : $cont;
        }
        my $iter = $buffer->get_iter_at_mark($buffer->get_insert());
        if ($self->parse_backspace($iter)) {
            $htext->scroll_mark_onscreen( $buffer->get_insert );
            return 1;
        }
    }
    elsif ($val == $k_tab or $val == ord(' ')) { # WhiteSpace
        my $buffer = $htext->get_buffer;
        if ($val == $k_tab) { # TAB
            my ($start, $end) = $buffer->get_selection_bounds;
            if ($end and $end != $start) {
                $self->selection_tab($start, $end);
                return 1;
            }
        }
        my $iter = $buffer->get_iter_at_mark($buffer->get_insert());
        my $string = ($val == $k_tab) ? "\t" : ' ';
        if ($self->parse_word($iter, $string)) {
            $htext->scroll_mark_onscreen( $buffer->get_insert );
            return 1;
        }
    }
    elsif ($val == ord('*') or $val == $k_multiply or $val == ord('>')) { # Bullet or Quote
        my $buffer = $htext->get_buffer;
        my ($start, $end) = $buffer->get_selection_bounds;
        return 0 if !$end or $end == $start;
        my $char = ($val == ord('>')) ? '>' : '' ;
        $self->toggle_bullets($start, $end, $char);
        return 1;
    }
    elsif ($val == $k_home and not $event->state >= 'control-mask') { # Home toggle
        my $buffer = $htext->get_buffer;
        my $insert = $buffer->get_iter_at_mark($buffer->get_insert());
        my $start  = $insert->copy;
        $htext->backward_display_line_start($start)
            unless $htext->starts_display_line($start);
        my $begin  = $start->copy;
        my $indent = '';
        while ($indent =~ /^\s*([^\s\w]\s*)?$/) {
            last if $begin->ends_line or ! $begin->forward_char;
            $indent = $start->get_text($begin);
        }
        $indent =~ /^(\s*([^\s\w]\s+)?)/;
        my $back = length($indent) - length($1);
        $begin->backward_chars($back) if $back > 0;
        $insert = ($begin->ends_line || $insert->equal($begin)) ? $start : $begin;
        if ($event->state >= 'shift-mask') {
            $buffer->move_mark_by_name('insert', $insert);
            # leaving the "selection_bound" mark behind
        }
        else { $buffer->place_cursor($insert) }
        return 1;
    }

    #else { printf "key %x pressed\n", $val } # perldoc -m Gtk2::Gdk::Keysyms

    return 0;
}

sub _is_verbatim {
    my ($self, $iter) = @_;
    for ($iter->get_tags) {
        return 1 if lc($_->get_property('name')) eq 'verbatim';
    }
    return 0;
}

=item C<parse_backspace(ITER)>

This method is called when the user types a backspace.
It tries to update the formatting of the current line.
 
When TRUE is returned the widget does not receive the backspace.

=cut

sub parse_backspace {
	my ($self, $iter) = @_;
	my $buffer = $self->buffer;
	my $lf = $buffer->get_iter_at_line( $iter->get_line );
	my $line = $buffer->get_slice($lf, $iter, 0);
	if ($line =~ /\t([\*\x{2022}\x{FFFC}]\s)$/) {
		$iter->backward_chars(length $1);
		my $begin = $iter->copy;
		$begin->backward_char;
		_user_action_ {
			$buffer->delete($begin, $iter);
		} $buffer;
		return 1;
	}
	elsif ($line =~ /\t$/) {
		my $back = $iter->copy;
		$back->backward_char;
		_user_action_ { $buffer->delete($back, $iter) } $buffer;
		return 1;
	}
	return 0;
}
=item C<parse_line(ITER)>

This method is called when the user is about to insert a linebreak.
It checks the line left of the cursor of any markup that needs
updating. It also takes care of autoindenting.

When TRUE is returned the widget does not receive the linebreak.

=cut

#use Roman;

# FIXME
sub parse_line {
    my ($self, $iter) = @_;
    my $buffer = $self->buffer;
    my $Verbatim = $buffer->get_tag_table->lookup('Verbatim');
    $buffer->set_edit_mode_tags(
        grep {$_ eq $Verbatim}
        $buffer->get_edit_mode_tags() ); # reset all tags except Verbatim
    my $lf = $buffer->get_iter_at_line( $iter->get_line );
    my $line = $buffer->get_slice($lf, $iter, 0);
        # Need to use get_slice instead of get_text to avoid deleting
        # images because we think a range is empty
    #print ">>$line<<\n";
    if ($line =~ s/^(=+)\s*(\w)/$2/) { # heading
        my $offset;
        ($lf, $offset) = ($lf->get_offset, $iter->get_offset);
        _user_action_ { $buffer->insert($iter, "\n") } $buffer;
        ($lf, $iter) = map $buffer->get_iter_at_offset($_), $lf, $offset;
        $iter->forward_char;
        my $h = length($1); # no (7 - x) monkey bussiness here
        $h = 5 if $h > 5;
        $line =~ s/\s+=+\s*$//;
        $offset = $lf->get_offset + length $line;
        _user_action_ {
            $buffer->delete($lf, $iter);
            $buffer->insert_with_tags_by_name($lf, $line, "head$h");
            $iter = $buffer->get_iter_at_offset($offset);
            $buffer->insert($iter, "\n");
        } $buffer;
        return 1;
    }
    elsif ($line =~ /^(\s*(:?\W+|\d+\W?|\w\W)(\s+)|\s+)$/) { # empty bullet or list item
        my $post = $2;
        # TODO check previous line for same pattern !
        if ($line =~ /\x{FFFC}/) { # embedded image or checkbox
            my $i = $iter->copy;
            $i->backward_chars(length($post)+1);
            my $pixbuf = $i->get_pixbuf;
            return 0 unless $pixbuf and $$pixbuf{image_data}{type} eq 'checkbox';
        }
        _user_action_ { $buffer->delete($lf, $iter) } $buffer;
    }
#    elsif ($line =~ /^(\s*(\w+)\W\s+)/ and isroman($2)) {
#        my ($indent, $num) = ($1, Roman(arabic($2)+1));
#        $indent =~ s/\w+/$num/;
#        my $offset = $iter->get_offset;
#        _user_action_ { $buffer->insert($iter, "\n") } $buffer;
#        $iter = $buffer->get_iter_at_offset($offset);
#        $iter->forward_char;
#        _user_action_ { $buffer->insert($iter, "$indent") } $buffer;
#        $self->{htext}->scroll_mark_onscreen( $buffer->get_insert() );
#        return 1;
#    }
    elsif ($line =~ /^(\s*(\W+|\d+\W?|\w\W)(\s+)|\s+)/) { # auto indenting + aotu incremnt lists
        my ($indent, $number, $post) = ($1, $2, $3);
        $number =~ s/\W//g;
        if ($indent =~ /\x{FFFC}/) { # embedded image or checkbox
            my $i = $lf->copy;
            $i->forward_chars(length($indent)-length($post)-1);
            my $pixbuf = $i->get_pixbuf;
            return 0 unless $pixbuf and $$pixbuf{image_data}{type} eq 'checkbox';
        }
        elsif (length $number) { # numbered list
            return 0 unless $$self{app}{settings}{use_autoincr};
            $number = ($number =~ /\d/)
                ? $number+1
                : chr(ord($number)+1) ;
            $indent =~ s/(\d+|\w)/$number/;
        }
        my $offset = $iter->get_offset;
        _user_action_ { $buffer->insert($iter, "\n") } $buffer;
        $iter = $buffer->get_iter_at_offset($offset);
        $iter->forward_char;
        if ($indent =~ /\x{FFFC}/) { # checkbox
            my ($begin, $end) = split /\x{FFFC}/, $indent, 2;
            $buffer->insert_blocks_at_cursor(
                $begin, ['checkbox', {state => 0}], $end)
        }
        else {
            _user_action_ {
                $buffer->insert($iter, "$indent")
            } $buffer;
        }
        $self->widget->scroll_mark_onscreen( $buffer->get_insert() );
        return 1;
    }
    return 0;
}

=item C<parse_word(ITER, CHAR)>

This method is called after the user ended typing a word.
It checks the word left of the cursor for any markup that
needs updating.

CHAR can be the key that caused a word to end, returning TRUE
makes it never reaching the widget.

=cut

sub parse_word {
    my $self = shift @_;
    my ($iter, $char) = @_;
    my $htext = $self->widget;

    #no strict 'vars'; # sigh FIXME

    # remember that $char can be empty
    # first insert the char, then replace it, keep undo stack in proper order
    return 0 if $self->_is_verbatim($iter);
    my $buffer = $self->buffer;
    my $lf = $iter->copy;
    $htext->backward_display_line_start($lf)
        unless $htext->starts_display_line($lf);
    my $line = $buffer->get_slice($lf, $iter, 0);
    #warn ">>$line<< >>$char<<\n";
    if ($line =~ /^\s*([\*\x{2022}\x{FFFC}]|(?:[\*\x{2022}]\s*)?\[[ *xX]?\])(\s*)$/) {
        # bullet or checkbox (or checkbox prefixed with bullet)
        return unless $lf->starts_line; # starts_display_line != starts_line
        my ($bullet, $post) = ($1, $2);
        if ($bullet eq "\x{FFFC}") {
            my $i = $iter->copy;
            $i->backward_chars(length($bullet.$post));
            my $pixbuf = $i->get_pixbuf;
            return unless $pixbuf and $$pixbuf{image_data}{type} eq 'checkbox';
        }
        my $offset;
        if (defined $char) {
            # insert char
            $offset = $iter->get_offset;
            _user_action_ { $buffer->insert($iter, $char) } $buffer;
            $iter = $buffer->get_iter_at_offset($offset);
            if (defined $char and $char eq "\t") {
                # delete the char again and indent
                my $end = $iter->copy;
                $end->forward_char;
                _user_action_ {
                    $buffer->delete($iter, $end);
                    $iter = $buffer->get_iter_at_offset($offset);
                    $buffer->insert($iter, ' ') unless length $post;
                    $iter = $buffer->get_iter_at_offset($offset);
                    $iter->backward_chars(length $bullet.$post);
                    $buffer->insert($iter, "\t");
                } $buffer;
                $iter = $buffer->get_iter_at_offset($offset+1);
            }
        }
        my $end = $iter->copy;
        $iter->backward_chars(length $bullet.$post);
        $end->backward_chars(length $post);
        if ($bullet eq '*') {
            # format bullet
            _user_action_ {
                $buffer->delete($iter, $end);
                $buffer->insert($iter, "\x{2022}");
            } $buffer;
        }
        elsif ($bullet =~ /\[([ *xX]?)\]/) {
            # format checkbox
            my $state = ($1 eq '*') ? 1 : (lc($1) eq 'x') ? 2 : 0 ;
            $offset = $iter->get_offset;
            _user_action_ {
                $buffer->delete($iter, $end);
                $buffer->place_cursor($iter);
                $buffer->insert_blocks_at_cursor(['checkbox', {state => $state}]);
            } $buffer;
            $iter = $buffer->get_iter_at_offset($offset+1);
            $iter->forward_chars(length($post)+1);
            $buffer->place_cursor($iter);
        }
        return 1;
    }
    elsif (
        $line =~ qr{(?<!\S)(\w[\w\+\-\.]+://\S+)$} # url
        or $line =~ qr{ (?<!\S)(
                [\w\.\-\(\)]*(?: :[\w\.\-\(\)]{2,} )+:?
              | \.\w[\w\.\-\(\)]+(?: :[\w\.\-\(\)]{2,} )*:?
                    )($punctuation)$  }x # page (ns:page .subpage)
        or $line =~ qr{(?<!\S)(
              \w[\w\+\-\.]+\?\w\S+
                    )($punctuation)$}x # interwiki (name?page)
        or ( $self->{app}{settings}{use_linkfiles}
          and $line =~ qr{ (?<!\S)( (?:
                ~/[^/\s] | ~[^/\s]*/ | \.\.?/ | /[^/\s]
                       ) \S* )($punctuation)$  }x ) # file (~/ ~name/ ../ ./ /)
        #or ( $self->{app}{settings}{use_camelcase}
        #or ( $self->config->{settings}->{use_camelcase}
        or ( 1
          and $line =~ qr{(?<!\S)(
                [[:upper:]]*[[:lower:]]+[[:upper:]]+\w*
                       )($punctuation)$}x  ) # CamelCase
    ) { # any kind of link
        my $word = $1;
        my $punct = $2;
        return 0 if $word !~ /[[:alpha:]]{2}/; # at least two letters in there
        return 0 if $word =~ /^\d+:/; # do not link "10:20h", "10:20PM" etc.
        my ($start, $end) = ($iter->copy, $iter->copy);
        $start->backward_chars(length $word.$punct );
        $end->backward_chars(length $punct);
        return 0 if grep {$_->get_property('name') !~ /spell/}
            $start->get_tags, $end->get_tags;
        if (defined $char) {
            ($start, $end) = ($start->get_offset, $end->get_offset);
            #_user_action_ { $buffer->insert($iter, $char) } $buffer;
            _user_action_(sub { $buffer->insert($iter, $char) }, $buffer);
            ($start, $end) = map $buffer->get_iter_at_offset($_), $start, $end;
        }
        _user_action_ {
            $htext->apply_link(undef, $start, $end);
        } $buffer;
        return 1;

    }
    elsif ( $self->{app}{settings}{use_utf8_ent} &&
        $line =~ /(?<!\S)\\(\w+)$/
    ) { # utf8 chars
        my $word = $1;
        my $chr = _entity($word);
        return 0 unless defined $chr;

        if (defined $char) {
            my $offset = $iter->get_offset;
            _user_action_ { $buffer->insert($iter, $char) } $buffer;
            $iter = $buffer->get_iter_at_offset($offset)
        }
        my $begin = $iter->copy;
        $begin->backward_chars(1 + length $word);
        _user_action_ {
            $buffer->delete($begin, $iter);
            $buffer->insert($begin, $chr);
        } $buffer;
        return 1;
    }
#    elsif ($line =~ /^(\t|  )/) { # pre
#        # FIXME \s* => \t
#        $iter->forward_char unless $iter->is_end; # FIXME somthing at end
#        $buffer->apply_tag_by_name('pre', $lf, $iter);
#    }
    #elsif ($self->{app}{settings}{use_autolink}) {
    else {
        $self->_match_words($buffer, $iter);
    }

    return 0;
}

sub _is_verbatim {
    my ($self, $iter) = @_;

    do { return 1 if lc($_->get_property('name')) eq 'verbatim' }
        for $iter->get_tags;

    return 0;
}

# FIXME
sub _match_words {
    my ($self, $buffer, $iter, $page) = @_;
    return if $iter->starts_line;
    $page ||= $self; #->{app}{page};
    my $start = $iter->copy;
    $start->backward_chars( $iter->get_line_offset );
    my $line = $start->get_text($iter);

    while ($line =~ /\w/) {
        my ($word) = ($line =~ /(\w+)/);
        #warn "Checking: >>$word<<\n";
        while ($_ = $page->match_word($word)) {
            warn "Matching: $_ for >>$word<<\n";
            # match_word returns 1 for single match
            #            and 2 for multiple or partial matches
            if ($_ == 1) {
                my $start = $iter->copy;
                $start->backward_chars(length $line);
                my $end = $start->copy;
                $end->forward_chars(length $word);
                last if $start->get_tags or $end->get_tags;
                $self->widget->apply_link(undef, $start, $end);
                last;
            }
            else {
                ($word) = ($line =~ /(\Q$word\E\W+\w+)/);
                last unless $word;
            }
        }
        $line =~ s/^\W*\w+\W*//;
        #warn "line: >>$line<<\n";
    }
}

sub _match_all_words { # call _match_words on all lines
    my ($self, $buffer, $page) = @_;
    my ($iter, undef) = $buffer->get_bounds;
    while ($iter->forward_to_line_end) {
        $self->_match_words($buffer, $iter, $page);
    }
}

# FIXME
# originally from Zim::Page
sub match_word { # TODO optimize by caching found links
    my ($self, $word) = @_;
    return;

    # FIXME no store yet
    return $self->{store}->can('_match_word')
        ? $self->{store}->_match_word($self, $word)
        : undef ;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

App::LocalWiki::Widget::WikiPage - Page display widget

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


