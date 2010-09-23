package Zim::Formats::Wiki;

use strict;
no warnings;

{
    package App::LocalWiki::Format::Zim;
    use base 'Zim::Formats::Wiki';
}
{
    package Zim::Formats;

    # TODO: extensions hahsed in Store::Files
    # TODO: hash with aliases from names to modules

    use strict;
    use Carp;
    use constant {
        READ   => 1,	# we can input this format
        WRITE  => 2,	# we can output this format
        NATIVE => 4,	# we can read/write instead of import/export
    };
    use POSIX qw/strftime/;
    use File::BaseDir 0.03 qw/data_home data_dirs/;
    #use Zim::Utils;

    our $VERSION = '0.29';

=head1 NAME

    Zim::Formats - Common routines for Zim formats

=head1 DESCRIPTION

    TODO

=head1 METHODS

=head2 Registration

=over 4

=cut

    our %formats = (
        man  => READ | NATIVE,
        wiki => READ | WRITE | NATIVE,
        html => WRITE,
        txt2tags => WRITE,
    );

=item C<register_format()>

    TODO

=cut

    sub register_format {
        my ($class, $name, $mode, $native) = @_;
        my $mask = ($mode eq 'r')  ? READ  :
                ($mode eq 'w')  ? WRITE :
            ($mode eq 'rw') ? READ | WRITE : undef ;
    }

=item C<list_formats()>

    TODO

=cut

    sub list_formats {
        my ($class, $mode, $native) = @_;
        my $mask = ($mode eq 'r') ? READ  :
                ($mode eq 'w') ? WRITE : undef ;
        die "BUG: unknown mode: $mode" unless defined $mask;
        $mask |= NATIVE if $native;
        return grep { ($formats{$_} & $mask) == $mask } keys %formats;
    }

=back

=head2 Using templates

=over 4

=item C<lookup_template(FORMATE, NAME)> 

    Returns a file name or undef.

=cut

    sub lookup_template {
        my ($class, $format, $name) = @_;
        my $map = $class->list_templates($format);
        return $$map{$name} if exists $$map{$name};
        my ($key) = grep {lc $_ eq lc $name} keys %$map;
        return $$map{$key} if defined $key;
        return undef;
    }

=item C<list_templates(FORMAT)>

    Returns a hash with name => filename pairs of available templates.
    Used for exporting.

    TODO: also look in NOTEBOOK/_templates/

=cut

    sub list_templates {
        my ($class, $format) = @_;
        $format = lc $format;

        my %templates;
        for my $dir (data_dirs('zim', 'templates', $format)) {
            $dir = dir($dir);
            for my $f ($dir->list) {
                $f =~ /(.*?)(\.|$)/;
                $templates{$1} = $dir->file($f)
                    unless defined $templates{$1};
            }
        }

        return \%templates;
    }


=item C<bootstrap_template(TEMPLATE, PAGE)>

    Setup TEMPLATE to export PAGE.

=cut

    sub bootstrap_template {
        my ($class, $template, $page);
        
    }

=item C<save_tree(IO, TREE, PAGE)>

    TODO

    ---

    When a subclass has defined a C<%Tags> this method
    will wrap the text context of each parse-tree node in this tag.

    The hash C<%Tags> uses the tag names as keys and has as values
    array refs consisting of a start string, a closing string and a
    boolean whether this tag can span multiple lines.

    For all tags not found in this hash a method C<dump_TAG()> is
    called, where TAG is the tag name.

=cut

    sub save_tree {
        no strict 'refs';
        my ($class, $io, $tree, $page) = @_;
        my $tags = \%{$class.'::Tags'};

        my $nodes;
        if ($$tree[0] eq 'Page') {
            splice @$tree, 0, 2;
            $nodes = $tree;
        }
        else { $nodes = [ $tree ] }

        $class->_dump_nodes($nodes, $tags, $io, $page, 1);
    }

    sub _dump_nodes {
        my ($class, $nodes, $tags, $io, $page, $mline) = @_;
        for my $node (@$nodes) {
            unless (ref $node) {
                print {$io} $node;
            }

            my $type = $$node[0];
            if ($$tags{$type}) {

            }
            else {
            }
        }
    }

=item C<parse_page_properties(PAGE, TEXT)>

    Parse a block with headers and add them to the properties hash.

=item C<dump_page_properties(PAGE)>

    Returns a header block containing page properties.
    All properties with lower case names are ignored and care is taken to
    have the Content-Type header et. al. on the first line.

=item C<parse_rfc822_headers(TEXT)>

    Parse a block with headers and return a hash.
    All headers will be upper-cased properly.

=item C<dump_rfc822_headers(\%HEADERS)>

=item C<dump_rfc822_headers(%HEADERS)>

    Returns a header block from a hash. If the hash is passed as reference keys 
    are sorted alphabetically, if passed as a list the order is preserved.

=cut

    sub parse_page_properties {
        my ($class, $page, $text) = @_;
        my $headers = $class->parse_rfc822_headers($text);
        $$page{properties}{$_} = $$headers{$_} for keys %$headers;
    }

    sub parse_rfc822_headers {
        my (undef, $text) = @_;
        my %headers;
        my $h;
        for (split /\n/, $text) {
            if (s/^([\w\-]+):\s+//) {
                $h = $1;
                $h =~ s/(^\w|-\w)/\U$1\E/g;
                    # upper case all words - headers should be
                    # case insensitive and we want to distinct
                    # from other properties in the page hash
                    # which use lower case
                s/\n$//;
                $headers{$h} = $_;
            }
            elsif (defined $h and s/^\s+//) {
                s/\n$//;
                $headers{$h} .= "\n" . $_;
            }
            else { last }
        }
        return \%headers;
    }

    sub dump_page_properties {
        my ($class, $page) = @_;
        my @meta = qw/Content-Type Wiki-Format Creation-Date Modification-Date/;
        my @keys = sort grep /^[A-Z]/, keys %{$$page{properties}};
        
        # shuffle meta keys to the front
        for my $h (reverse @meta) {
            next unless grep {$_ eq $h} @keys;
            @keys = ($h, grep {$_ ne $h} @keys);
        }

        my @headers = map { ($_ => $$page{properties}{$_} ) } @keys;
        return $class->dump_rfc822_headers(@headers);
    }

    sub dump_rfc822_headers {
        shift; # class;
        my @headers;
        if (ref $_[0]) {
            my @keys = sort keys %{$_[0]};
            @headers = map { ($_ => $_[0]{$_} ) } @keys;
        }
        else { @headers = @_ }
        
        my $text = '';
        while (@headers) {
            my ($k, $v) = splice @headers, 0, 2;
            $v =~ s/\n/\n\t/g;
            $v =~ s/\s*\z/\n/;
            $text .= $k.": ".$v;
        }
        
        return $text;
    }

=item C<header_date_string(TIME)>

    Returns TIME as a string following the rfc822 format for date/time headers.
    TIME can be given in seconds or as a C<localtime> array.

=cut

    sub header_date_string {
        shift; #class
        my @time = (@_ == 1) ? (localtime shift) : (@_);
        my $date = strftime('%a, %d %b %Y %H:%M:%S %z', @time);
        return utf8::decode($date);
    }

    1;


=back

=head2 Parse-tree manipulation

=over 4

=item C<parse_link(LINK, PAGE, NO_RESOLVE)>

    Returns the link type and link target for LINK. The type can be e.g. 'page',
    'file', 'mail' or 'man' - for urls the protocol is used as type.

    The link target is e.g. a fully specified page name, a fully specified path,
    or an url. For file:// urls the path is returned. For mail a 'mailto:' url is
    returned.

    If NO_RESOLVE is set we only check the type, but do not try to fully specify
    the target.

=cut

    sub parse_link {
        my (undef, $link, $page, $no_resolve) = @_;
        #warn "Parsing link: $link ($page)\n";

        # Interwiki links e.g. foo?bar:baz
        if ($link =~ m#^(\w[\w\+\-\.]+)\?(.*)#) {
            my ($name, $page) = ($1, $2);
            my $url = Zim->interwiki_lookup($name, $page);
            $link = $url if defined($url);
            # Returns e.g. http://, file:// or zim:// on success
            # When lookup fails we pass on trough, this ensures 
            # that things like "man?zim" will also work.
        }
        
        my $type;
        # URLS e.g. file://foo or http://foo
        if ($link =~ m#^(\w+[\w\+\-\.]+)://#) {
            $type = $1;
            $link = $page->resolve_file($link)
                if $type eq 'file' and ! $no_resolve;
        }
        # mail e.g. mailto:foo@bar or foo@bar
        elsif ($link =~ m#^mailto:|^\S+\@\S+\.\w+$#) { #
            $type = 'mail';
            $link =~ s#^(mailto:)?#mailto:#;
        }
        # Any other special types e.g. man?test (passtrough from interwiki)
        elsif ($link =~ m#^(\w[\w\+\-\.]+)\?(.*)#) {
            ($type, $link) = ($1, $2);
        }
        # Files and directories - anything containing a '/'
        elsif ($link =~ m#/#) {
            $type = 'file';
            $link = $page->resolve_file($link) unless $no_resolve;
        }
        # Page - default type
        else {
            $type = 'page';
            $link = Zim::Store->clean_name($link, 'RELATIVE');
            $link =~ s#^\.:*#$page:#; # sub-page - FIXME does this belong here?
            $link = $page->resolve_name($link) unless $no_resolve;
        }

        #warn "type: $type link: $link\n";
        return $type, $link;
    }


=item C<extract_refs(TYPE, TREE)>

    Returns a list with references to nodes of type TYPE in the tree.

=cut

    sub extract_refs { # returns references to nodes of type TYPE
        my ($class, $type, $tree) = @_;
        my @nodes;
        for (2 .. $#$tree) {
            my $node = $$tree[$_];
            next unless ref $node;
            push @nodes, ($$node[0] eq $type)
                ? $node : $class->extract_refs($type, $node) ; # recurs
        }
        return grep defined($_), @nodes;
    }

=item C<delete_first(TYPE, TREE)>

    Deletes and returns the first node of type TYPE from the tree.

=cut

    sub delete_first {
        my ($class, $type, $tree) = @_;
        for my $i (2 .. $#$tree) {
            next unless ref $$tree[$i];
            return splice @$tree, $i, 1 if $$tree[$i][0] eq $type;
            my $r = $class->delete_first($type, $$tree[$i]); # recurs
            return $r if $r;
        }
        return undef;
    }

=item C<get_first_head(TREE, STRIP)>

    Returns the level and the text content of the first head.

    STRIP is a boolean, if set to TRUE the head is removed from the tree.

=cut

    sub get_first_head {
        my ($class, $tree, $strip) = @_;
        # remove empty paragraphs from begin of tree ?
        return unless ref $$tree[2] and $$tree[2][0] =~ /^head/;
        my $title = $strip ? splice(@$tree, 2, 1) : $$tree[2];
        $$title[0] =~ /^head(\d+)/;
        my $lvl = $1;
        $title = join '', @$title[2 .. $#$title];
        return ($lvl, $title);
    }

=item C<update_heads(TREE, MIN, MAX)>

    Given a parse tree this method updates the level of all headings.
    MIN is the minimum level, so all headings will be shifted down with
    this amount (default is 1).
    MAX is the max level, any heading below this level will be flattened
    to the maximum level (default is undefined).

    It is assumed that heads can only occur toplevel in the parse tree.
    (They can not be nested indside paragraphs etc.)

=cut

    sub update_heads {
        my ($class, $tree, $min, $max) = @_;
        $min ||= 1;
        $min -= 1;
        for (2 .. $#$tree) {
            next unless ref $$tree[$_] and $$tree[$_][0] =~ /^head/;
            $$tree[$_][0] =~ /^head(\d+)/;
            my $lvl = $1;
            $lvl += $min;
            $lvl = $max if $max and $lvl > $max;
            $$tree[$_][0] = 'head'.$lvl;
        }
    }

=item C<fix_file_ending(TREE)>

    Make sure that the last piece of text in the tree ends
    with a newline. This increases the change of the file
    resulting from dumping the tree to end in a newline.

=cut

    sub fix_file_ending {
        my $tree = pop;
        my $l = $tree;
        while (@$l > 2) {
            if (ref $$l[-1]) {
                if ($$l[-1][0] =~ /^[A-Z]/) { $l = $$l[-1] }
                else {
                    push @$l, "\n";
                    last;
                }
            }
            else {
                #warn "Last element was $$l[0]\n";
                #warn ">>>$$l[-1]<<\n";
                $$l[-1] =~ s/\n?$/\n/;
                last;
            }
        }
        # We assume multi-line blocks a name
        # that starts with a capital, like 'Param'.
        # We assume nodes without content to be objects
        # like images.
    }

=back

=head1 AUTHOR

    Jaap Karssenberg (Pardus) E<lt>pardus@cpan.orgE<gt>

    Copyright (c) 2006 Jaap G Karssenberg. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=head1 SEE ALSO

    L<Zim>

=cut

}

## BEGIN Zim::Formats::Wiki <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

use base 'Zim::Formats';
#use Zim::Formats;

our $VERSION = '0.28';
#our @ISA = qw/Zim::Formats/;

# TODO: some tags can be nested: email links for example

=head1 NAME

Zim::Formats::Wiki - Wiki text parser

=head1 DESCRIPTION

This is the default parser for Zim.
It uses a wiki-style syntax to format plain text.

FIXME more verbose description

All format types are signified by double characters,
this is done to prevent accidental formatting when the same
characters are used normally in a text. For the same reason
the strike character is '~' instead of '-' because '--' can
occur in normal ascii text. In the regexes we try to always
match the inner pair if more than two of these characters
are encountered. (Thus if we see C<***bold***> we should match
C<*(**bold**)*>.)


=head1 METHODS

=over 4

=item C<load_tree(IO, PAGE)>

Reads plain text from a filehandle and returns a parse tree.

=cut

sub load_tree { # TODO whitelines between verbatim blocks should be preserved
	my ($class, $io, $page) = @_;

	my @tree;
	my $para = ''; # paragraph buffer
	my $first = 1; # used to detect the first paragraph
	my $verbatim = 0; # true when inside a verbatim block
	while (<$io>) {
		s/\r?\n$/\n/; # DOS to Unix conversion
		unless (/\S/) { # empty line
			if ($verbatim and $para !~ /^\s*'''\s*\Z/m) {
				$para .= $_;
				next;
			}
			else { $verbatim = 0 }

			if ($first and $para =~ 
				/^Content-Type:\s+text\/x-zim-wiki/i
			) {
				# First paragraph looking like meta header
				$class->parse_page_properties($page, $para);
			}
			elsif (length $para) {
				# All other para, verbatim and headers
				push @tree, $class->parse_para($para, $page);
			}
			$tree[-1][1]{empty_lines}++ if scalar @tree;
				# count empty lines
			$para = '';
			$first = 0;
		}
		else { # non-empty line
			# next four lines by SIMON
			if (/^\s*'''\s*$/ and $para ne '' and $verbatim == 0) {
				push @tree, $class->parse_para($para, $page);
				$para = '';
			}
			$verbatim = 1 if /^\s*'''\s*$/ and $para eq '';
				# toggle verbatim at start of para
			$para .= $_;
		}
	}
	push @tree, $class->parse_para($para, $page) if length $para;
	
	#use Data::Dumper; print STDERR Dumper \@tree;
	return ['Page', $$page{properties}, @tree];
}

sub parse_para {
	my ($class, $text, $page) = @_;

	# check Verbatim paragraphs
	my $version = $$page{properties}{'Wiki-Format'};
	$version =~ s/zim\s+//;
	if ( (!$version or $version < 0.26) and $text !~ /^(?!\t|\s\s+)/m) {
		# verbatim blocks before 0.26 need to start
		# with all whitespace, either tab or multiple spaces
		my ($indent) = ($text =~ /^(\s+)/);
		$text =~ s/^$indent//mg;
		return ['Verbatim', {}, $text];
	}
	if ($text =~ m/\A\s*'''\s*$/m and $text =~ m/^\s*'''\s*\Z/m) {
		# parsing Verbatim paragraphs for version >= 0.26
		# just remove surrounding "'''" quotes
		$text =~ s/\A\s*'''\s*$|^\s*'''\s*\Z//mg;
		$text =~ s/^\n//;
		return ['Verbatim', {}, $text];
	}

	# Separate headers and paragraphs
	return grep defined($_), map {
		if (!/\S/) { undef }
		elsif (/^==+\s+\S+/ and ! /\n/) { # header
			$class->parse_head($_);
		}
		else { # paragraph
			s/^\n//;
			s/^(\s*)\*(\s+)/$1\x{2022}$2/mg; # bullet lists
			['Para', {}, $class->parse_block($_, $page)];
		}
	} split /^(==+[^\n\S]+\S+.*)$/m, $text;
}

sub parse_head { # parse a header
	my ($class, $head) = @_;
	chomp $head;
	$head =~ s/^(==+)\s+(.*?)(\s+==+\s*|\s*)$/$2/;
	my $level = 7 - length($1); # =X6 => head1, =X5 => head2 etc.
	$level = 1 if $level < 1;
	$level = 5 if $level > 5; # just to be sure
	return ['head'.$level, {}, $head];
}

our @parser_subs = qw/
	parse_checkbox
	parse_verbatim
	parse_links
	parse_images
	parse_styles
	parse_urls
/;

sub parse_block { # parse a block of text
	my ($class, $text, $page) = @_;
	my @text = ($text);
	for my $sub (@parser_subs) {
		@text = map {ref($_) ? $_ : ($class->$sub($_, $page))} @text;
	}
	return @text;
}

sub parse_checkbox {
	my ($class, $text) = @_;
	my $i = 0;
	return	map {
		unless ($i++ % 2) { $_ }
		else {
			/^(\s*)/;
			my $space = $1;
			my $state = /\[\*\]/ ? 1 : /\[x\]/i ? 2 : 0 ;
			my $check = ['checkbox',  {state => $state}];
			length($space) ? ($space, $check) : $check;
		}
	} split /^(\s*\[[\s\*x]?\])/mi, $text;
}

sub parse_verbatim { # like parse_style() but needs to be done earlier
	my ($class, $text) = @_;
	my $i = 0;
	return	map {
		unless ($i++ % 2) { $_ }
		elsif (/^\'\'(.+)\'\'$/) { ['verbatim',  {}, $1] }
	} split /(\'\'(?!\').+?\'\')/, $text;
}

sub parse_links {
	my ($class, $text) = @_;
	my $i = 0;
	return
		map   { ($i++ % 2) ? _parse_link($_) : $_ }
		split m#(\[\[(?!\[).+?\]\])#, $text;
}

sub _parse_link {
	my $l = shift;
	my $text;
	if ($l =~ /^\[\[([^|]*)\|?(.*)\]\]$/) { # [[link]] or [[link|text]]
		($l, $text) = ($1, $2);
		$l = $text unless length $l; # [[|link]] bug
	}
	if ($l =~ /^mailto:|^\S+\@\S+\.\w+$/) {
		$text = $l unless length $text;
		$l =~ s/^(mailto:)?/mailto:/;
	}
	return ['link', {to => $l}, length($text) ? $text : $l ];
}

sub parse_urls {
	my ($class, $text) = @_;
	my $i = 0;
	my $C = q/[^\s\"\<\>\']/; # limit the character class a bit
	return
		map   { ($i++ % 2) ? _parse_link($_) : $_ }
		split m#(
			\b\w[\w\+\-\.]+://  $C*\[$C+\](?:$C+[\w\/])? |
			\b\w[\w\+\-\.]+://  $C+[\w\/]                |
			\bmailto:$C+\@      $C*\[$C+\](?:$C+[\w/])?  |
			\bmailto:$C+\@      $C+[\w/]                 |
			\b$C+\@$C+\.\w+\b
		)#x, $text;
		# The host name in an uri can be "[hex:hex:..]" for ipv6
		# but we do not want to match "[http://foo.org]"
		# See rfc/3986 for the official -but unpractical- regex
}

sub parse_styles { # parse blocks of bold, italic and underline
	my ($class, $text) = @_;
	my $i = 0;
	return	map {
		unless ($i++ % 2) { $_ }
		elsif (/^\*\*(.+)\*\*$/) { ['bold',      {}, $1] }
		elsif (/^\/\/(.+)\/\/$/) { ['italic',    {}, $1] }
		elsif (/^\~\~(.+)\~\~$/) { ['strike',    {}, $1] }
		elsif (/^\_\_(.+)\_\_$/) { ['underline', {}, $1] }
	} split /(
		\*\*(?!\*).+?\*\* |
		(?<!\:)\/\/(?!\/).+?\/\/ |
		\~\~(?!\~).+?\~\~ |
		__(?!_).+?__
	)/x, $text;
}

sub parse_images {
	my ($class, $text, $page) = @_;
	my $i = 0;
	my @parts =
		map   { ($i++ % 2) ? ['image', {src => $_}] : $_ }
		split /\{\{(?!\{)(.+?)\}\}/, $text;
	for my $p (@parts) {
		next unless ref $p and $$p[0] eq 'image';
		if ($$p[1]{src} =~ s/\?(\w+=\w+(?:&\w+=\w+)*)$//) {
			my %arg = split /[=&]/, $1;
			$$p[1]{$_} = $arg{$_} for keys %arg;
		}
		$$p[1]{file} = $page->resolve_file($$p[1]{src});
		#use Data::Dumper; warn "IMAGE: ", Dumper $p;
	}
	return @parts;
}

=item C<save_tree(IO, TREE, PAGE)>

Serializes the parse tree into a piece of plain text and writes this
to a filehandle.

=cut

# CKW somewhat tweaked
sub save_tree {
	# TODO add support for recursive tags
	my ($class, $io, $tree, $properties) = @_;

    # my @meta = qw/Content-Type Wiki-Format Creation-Date Modification-Date/;
	#my $p = $$page{properties};
	my $p = $properties;
	$p->{'Content-Type'} = 'text/x-zim-wiki';
	$p->{'Wiki-Format'} = 'zim 0.26';
	print $io $class->dump_page_properties($p), "\n";

	my $old_fh = select $io;
	eval { $class->_save_tree($tree) };
	select $old_fh;
	die $@ if $@;
}

sub _save_tree {
	my ($class, $tree) = @_;
	
	my ($name, $opt) = splice @$tree, 0, 2;
	die "Invalid parse tree"
		unless length $name and ref($opt) eq 'HASH';

	while (@$tree) {
		my $node = shift @$tree;
		unless (ref $node) {
			$node =~ s/^(\s*)\x{2022}(\s+)/$1*$2/mg;
			print $node;
			next;
		}
	
		my ($tag, $meta) = @$node[0, 1];
		
		# Blocks
		if ($tag eq 'Para') {
			$class->_save_tree($node); # recurs
			# except for the last, a para always needs a newline
			$$meta{empty_lines} ||= (@$tree ? 1 : 0);
			print "\n"x$$meta{empty_lines};
			next;
		}
		elsif ($tag eq 'Verbatim') {
			my $text = _dump($node);
			# make sure there are no empty lines between the
			# paragraph and the block quotes
			$text =~ s/(\n?)$/\n/;
			$$meta{empty_lines}-- if defined $1;
			$text =~ s/^(\n*)/$1'''\n/;
			$text =~ s/(\n*)$/\n'''$1/;
			print $text;
			# except for the last, a para always needs a newline
			$$meta{empty_lines} ||= (@$tree ? 1 : 0);
			print "\n"x$$meta{empty_lines};
			next;
		}

		# inline tags
		my $text = _dump($node);
		if ($tag =~ /^head(\d)$/) {
			my $n = 7 - $1;
			print ( ('='x$n)." $text ".('='x$n)."\n" );
		}
		elsif ($tag eq 'image') {
			my $file = $$meta{src};
			my @k = sort grep {$_ !~ /^(src|file)$/} keys %$meta;
			$file .= '?' . join '&', map "$_=$$meta{$_}", @k if @k;
			print '{{'.$file.'}}';
		}
		elsif ($tag eq 'link') {
			my $to = $$meta{to};
			$to =~ s/^mailto:// unless $text =~ /^mailto:/;
			print (
				($to ne $text) ? "[[$to|$text]]" :
				($to !~ /\s/ and $to =~ m#^\w[\w\+\-\.]+://|^(?:mailto:)?\S+\@\S+\.\w+#)
					? $to : "[[$to]]" );
		}
		elsif ($tag eq 'checkbox') {
			my $box = ($$meta{state} == 1) ? '[*]' :
			          ($$meta{state} == 2) ? '[x]' : '[ ]' ;
			print $box;
		}
		# per line markup for remaining tags ...
		elsif ($tag eq 'bold') {
			print map { /\S/ ? "**$_**" : $_} split /(\n)/, $text
		}
		elsif ($tag eq 'italic') {
			print map { /\S/ ? "//$_//" : $_} split /(\n)/, $text
		}
		elsif ($tag eq 'strike') {
			print map { /\S/ ? "~~$_~~" : $_} split /(\n)/, $text
		}
		elsif ($tag eq 'underline') {
			print map { /\S/ ? "__$_\__" : $_} split /(\n)/, $text
		}
		elsif ($tag eq 'verbatim') {
			print map { /\S/ ? "''$_''" : $_} split /(\n)/, $text
		}
		else { die "Unkown tag in wiki parse tree: $tag\n" }
		
		print "\n"x$$meta{empty_lines} if $$meta{empty_lines};
	}
}

sub _dump {
	my $node = shift;
	splice @$node, 0, 2;
	for (@$node) { $_ = _dump($_) if ref $_ }
	return join '', @$node;
}

1;

__END__

=back

=head1 AUTHOR

Jaap Karssenberg (Pardus) E<lt>pardus@cpan.orgE<gt>

Copyright (c) 2005 Jaap G Karssenberg. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Zim>,
L<Zim::Page>

=cut

