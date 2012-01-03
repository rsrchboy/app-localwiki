package App::LocalWiki::Store;

# ABSTRACT: A thin(ish) wrapper around Document::Store

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use MooseX::Types::Path::Class ':all';
use MooseX::Types::URI         ':all';

use Document::Store;
use Document::Store::Types ':all';
use Path::Class;

use App::LocalWiki::Page;

use Smart::Comments;

has location => (
    is => 'rw', isa => Dir, required => 1, coerce => 1,
    handles => {

        path_root          => 'file',
        location_as_string => 'stringify',
    },
);

has _store => (
    is => 'lazy',
    isa => Backend,

    handles => {

        backend_name   => 'name',
        contains_page  => 'contains',
        fetch_raw_page => 'fetch',
        #save_page     => 'update',
    },
);

sub _build__store {
    my $self = shift @_;

    return Document::Store->open(
        backend  => 'Filesystem',
        location => $self->location_as_string,
    );
}

sub page_class { 'App::LocalWiki::Page' }

#sub _link_to_file { file shift->path_root, split(/:/, shift) }
sub _link_to_file {
    my ($self, $link_name) = @_;

    (my $file = $link_name) =~ s!:!/!g;
    # FIXME
    $link_name =~ s/^\.//;
    #return file $self->uri, "$file.txt";
    return file "$file.txt";
}

sub load_page {
    my ($self, $link_name) = @_;

    my $file = $self->_link_to_file($link_name);

    warn "link id: $link_name; file: $file";
    my $doc = $self->fetch_raw_page($file);

    ### docid: $doc->id

    return $self->page_class->new(
        store      => $self,
        #parse_tree => $parse_tree,
        link_id    => $link_name,
        save_page  => sub { $self->save_page($doc, @_) },

        # XXX
        raw => $doc->content,
    );
}

sub save_page {
    my ($self, $doc, $page, $wpage) = @_;

    my @ser = $wpage->widget->serialise;
    $doc->content(join("\n", @ser));

    $self->_store->update($doc);
    return;
}

sub get_page    { ... }
sub set_page    { ... }
sub delete_page { ... }
sub is_clean    { ... }
sub is_dirty    { ... }
sub has_remote  { ... }
sub flush       { ... }

__PACKAGE__->meta->make_immutable;

!!42;
