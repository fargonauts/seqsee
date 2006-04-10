#####################################################
#
#    Package: SCat::descending
#
#####################################################
#   Sets up the category "descending"
#####################################################

package SCat::descending;
use strict;
use Carp;
use base qw{};

my $builder = sub {
    my ( $self, $args_ref ) = @_;
    croak "need start" unless $args_ref->{start};
    croak "need end"   unless $args_ref->{end};

    my $ret = SObject->create
        ( reverse($args_ref->{end} .. $args_ref->{start} ));
    $ret->add_category( $self, 
                   SBindings->create( {}, $args_ref, $ret)
                       );
    $ret->set_reln_scheme( RELN_SCHEME::CHAIN() );
    return $ret;
};

our $descending =
    SCat::OfObj->new(
        {
            name    => "descending",
            builder => $builder,
            
            to_guess  => [qw/start end/],
            att_type => { start => "int", end => "int" },
            positions => { start => SPos->new(1),
                           end   => SPos->new(-1),
                       },
        }
            );

1;

