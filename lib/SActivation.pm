use Compile::ExpandVars;

package SActivation;
use Carp;

my @PRECALCULATED;
for ( 0 .. 200 ) {
    $PRECALCULATED[$_] = 0.4815 + 0.342 * atan2( 12 * ( $_ / 100 - 0.5 ), 1 );    # change!
}

# Note that new assumes positions mentioned later...
sub new {
    my $package = shift;
    bless [ 1, 1, 100, 100, $PRECALCULATED[1], $PRECALCULATED[1] ], $package;
}

<@:RAW_ACTIVATION 0:@>;
<@:RAW_SIGNIFICANCE 1:@>;
<@:STABILITY 2:@>;
<@:TIME_STEPS 3:@>;
<@:REAL_ACTIVATION 4:@>;
<@:REAL_SIGNIFICANCE 5:@>;

<@:DECAY_CODE $_->[<@REAL_ACTIVATION@>] = $PRECALCULATED[ --$_->[<@RAW_ACTIVATION@>]
                                                                + $_->[<@RAW_SIGNIFICANCE@>]
                                                                ];
$_->[<@RAW_ACTIVATION@>] ||= 1;
unless ( --$_->[<@TIME_STEPS@>] ) {
    $_->[<@REAL_SIGNIFICANCE@>] = $PRECALCULATED[ --$_->[<@RAW_SIGNIFICANCE@>] ];
    $_->[<@RAW_SIGNIFICANCE@>] ||= 1;
    $_->[<@TIME_STEPS@>] = $_->[<@STABILITY@>];
}
:@>;

<@:SPIKE_CODE $_->[<@RAW_ACTIVATION@>] += $spike;
if ( $_->[<@RAW_ACTIVATION@>] > 100 ) {
    $_->[<@RAW_ACTIVATION@>] = 100;
    $_->[<@RAW_SIGNIFICANCE@>]++;
    if ( $_->[<@RAW_SIGNIFICANCE@>] > 100 ) {
        $_->[<@RAW_SIGNIFICANCE@>] = 100;
        $_->[<@STABILITY@>]++;
    }
}
:@>;

sub GetRawActivation               { return $_[0]->[<@RAW_ACTIVATION@>]; }
sub GetRawSignificance             { return $_[0]->[<@RAW_SIGNIFICANCE@>]; }
sub GetStability                   { return $_[0]->[<@STABILITY@>]; }
sub GetTimeToDecrementSignificance { return $_[0]->[<@TIME_STEPS@>]; }

sub Decay {
    $_ = $_[0];
    <@DECAY_CODE@>;
}

sub DecayMany {
    @_ == 2 or confess "DecayMany needs 2 args";
    my ( $arr_ref, $cnt ) = @_;
    for my $i ( 1 .. $cnt ) {
        $_ = $arr_ref->[$i];
        <@DECAY_CODE@>;
    }
}

sub Spike {
    my $spike;
    ( $_, $spike ) = @_;
    <@SPIKE_CODE@>;
}

1;
