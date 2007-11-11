package SCat::OfObj::RelationTypeBased;
use strict;
use base qw{SCat::OfObj};
use Class::Std;
use Smart::Comments;
use Class::Multimethods;
use Memoize;

multimethod 'find_reln';
multimethod 'apply_reln';

my %RelationType_of : ATTR(:name<relation_type>);

{
    my %MEMO;

    sub Create {
        my ( $package, $relation_type ) = @_;
        if ( $relation_type->isa('SReln') ) {
            $relation_type = $relation_type->get_type;
        }
        ### require: $relation_type->isa("SRelnType");
        return ( $MEMO{$relation_type} ||= $package->new( { relation_type => $relation_type,
                                                            to_recreate => 'confess',
                                                        } ) );
    }
}

sub Instancer {
    my ( $self, $object ) = @_;
    my $id            = ident $self;
    my $relation_type = $RelationType_of{$id};

    my @parts           = @$object;
    my $parts_count     = scalar(@parts);
    my @effective_parts = map { $_->GetEffectiveObject() } @parts;

    return if $parts_count == 0;

    for my $idx ( 0 .. $parts_count - 2 ) {
        my $relation = find_reln( $parts[$idx], $parts[ $idx + 1 ] ) or return;
        return unless $relation->get_type() eq $relation_type;
    }

    return SBindings->new(
        {   raw_slippages => $object->GetEffectiveSlippages(),
            bindings      => { first => $parts[0], last => $parts[-1], length => $parts_count },
            object        => $object,
        }
    );
}

# Create an instance of the category stored in $self.
sub build {
    my ( $self, $opts_ref ) = @_;
    my $id            = ident $self;
    my $relation_type = $RelationType_of{$id};

    # xxx: only uses start and length for now.
    my $start  = $opts_ref->{first}  or return;
    my $length = $opts_ref->{length} or return;
    return unless $length > 0;
    my @ret         = ($start);
    my $current_end = $start;
    for ( 1 .. $length - 1 ) {
        my $next = apply_reln( $relation_type, $current_end ) or return;
        push @ret, $next;
        $current_end = $next;
    }
    my $ret = SObject->create(@ret);
    $ret->add_category(
        $self,
        SBindings->new(
            {   raw_slippages => {},
                bindings      => {
                    first  => $ret->[0],
                    last   => $ret->[-1],
                    length => $length,
                },
                object => $ret
            }
        )
    );
    $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );
    return $ret;
}

sub get_name {
    my ( $self ) = @_;
    my $relation_type = $RelationType_of{ident $self};
    return 'Gp based on '.$relation_type->as_text();
}
sub as_text {
    my ( $self ) = @_;
    return $self->get_name();
}

memoize('get_name');
memoize('as_text');

sub AreAttributesSufficientToBuild {
    my ( $self, @atts ) = @_;
    my $string = join(':', sort @atts);
    return 1 if ($string eq 'first:length' or $string eq 'first:last:length');
    return 0;
}


1;
