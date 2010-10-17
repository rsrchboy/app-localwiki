package App::LocalWiki::Store::File;

use Moose;
use namespace::autoclean;
use MooseX::Types::Path::Class ':all';
use MooseX::Types::URI         ':all';

use Path::Class;
use App::LocalWiki::Page;

sub shortname   { 'filesystem'                                 }
sub description { 'A simple store for a directory/file layout' }

has uri => (
    is => 'rw', isa => Dir, required => 1, coerce => 1,
    handles => { path_root => 'file' },
    # FIXME
    default => "$ENV{HOME}/.zimrepo",
);

sub page_class { 'App::LocalWiki::Page' }

sub has_page { defined shift->_link_to_file(shift)->stat }

#sub _link_to_file { file shift->path_root, split(/:/, shift) }
sub _link_to_file {
    my ($self, $link_name) = @_;

    (my $file = $link_name) =~ s!:!/!g;
    # FIXME
    $link_name =~ s/^\.//;
    #$file = "$ENV{HOME}/.zimrepo/$file.txt";
    return file $self->uri, "$file.txt";
}

sub get_page { ... }
sub set_page { ... }

# UGH FIXME
#has _current_file => (is => 'rw');

sub load_page {
    my ($self, $link_name) = @_;

    #my $file = file $self->path_root, split(/:/, $link_name);
    my $file = $self->_link_to_file($link_name);

    warn "link id: $link_name; file: $file";

    my $fh = IO::File->new("< $file");
    #$self->_current_file($file);

    my $page = {};
    my $parse_tree = App::LocalWiki::Format::Zim->load_tree($fh, $page); 
    #$self->buffer->set_parse_tree($parse_tree);
    #$self->set_parse_tree($parse_tree);

    return $self->page_class->new(
        store      => $self,
        parse_tree => $parse_tree,
        link_id    => $link_name,
        save_page  => sub { $self->save_page($file, @_) },

    );
}

sub save_page    {
    my ($self, $file, $page) = @_;

    #$self->{_links} = [ $self->list_links($tree) ];

    my $tree = $page->parse_tree;
    #my $file = $self->_current_file();

    warn "Saving buffer to $file";
    my $fh = IO::File->new("> $file");

    Zim::Formats->fix_file_ending($tree);

    # store tree
    my $date = Zim::Formats->header_date_string( time );
    # my @meta = qw/Content-Type Wiki-Format Creation-Date Modification-Date/;
    my $p = {
        'Modification-Date' => $date,
        'Creation-Date'     => $date,
    };
    
    # FIXME
    App::LocalWiki::Format::Zim->save_tree($fh, $tree, $p);
    $fh->close;
        
    #$self->brief_status(status => "$file saved");
    return;
}

sub delete_page { ... }

sub is_clean { ... }
sub is_dirty { ... }

sub has_remote { ... }

sub flush { ... }

with 'App::LocalWiki::Interface::Store';

__PACKAGE__->meta->make_immutable;
