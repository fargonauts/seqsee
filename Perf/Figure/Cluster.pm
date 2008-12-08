package Perf::Figure::Cluster;

## STANDARD MODULES THAT I INCLUDE EVERYWHERE
use strict;
use warnings;

use List::Util qw{min max sum first};
use Time::HiRes;
use Getopt::Long;
use Storable;

use File::Slurp;
use Smart::Comments;
use IO::Prompt;
use Class::Std;
use Class::Multimethods;

use Carp;
## END OF STANDARD INCLUDES


my %Source_of : ATTR(:name<source>);
my %Constraints_Ref_of : ATTR(:name<constraints_ref>);
my %Color_of : ATTR(:name<color>);

sub BUILD {
    my ( $self, $id, $opts_ref ) = @_;
    my $config = $opts_ref->{config}
      // confess "Missing required argument 'config'";
    my $figure_type = $opts_ref->{figure_type}
      // confess "Missing required argument 'figure_type'";

    my $source = $Source_of{$id} = $config->{source} // 'Seqsee';
    my %Data_Constraints;
    my %config           = %{$config};
    my @constraint_types = qw{min_version max_version exact_feature_set};
    @Data_Constraints{@constraint_types} = @config{@constraint_types};

    if ($figure_type eq 'LTM_WITH_CONTEXT' and $source eq 'LTM') {
        $Data_Constraints{context} = $config{context} // confess "context needed for every cluster that has LTM as its source";
    }
    $Constraints_Ref_of{$id} = \%Data_Constraints;
    $Color_of{$id} = _GetColor($source);
}

sub _GetColor {
    my ($source) = @_;
    return '#FF0000' if $source eq 'Human';
    return '#00FF00' if $source eq 'LTM';
    return '#0000FF';
}

sub get_constraints {
    my ($self) = @_;
    my $id = ident $self;
    return %{$Constraints_Ref_of{$id}};
}
               
    


1;
