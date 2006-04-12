use strict;
use Test::More;
use Test::Exception;
use Test::Deep;
use Test::Stochastic qw(stochastic_all_seen_ok stochastic_all_seen_nok
                        stochastic_all_and_only_ok
                        stochastic_all_and_only_nok
                            );
use English qw(-no_match_vars);
use Carp;
use List::MoreUtils;

use S;

## useful to turn a few features off...
$::TESTING_MODE = 1;

sub undef_ok {
    my ( $what, $msg ) = @_;
    if ( not( defined $what ) ) {
        $msg ||= "is undefined";
        ok( 1, $msg );
    }
    else {
        $msg ||= "expected undef, got $what";
        ok( 0, $msg );
    }
}

sub instance_of_cat_ok {
    my ( $what, $cat, $msg ) = @_;
    no warnings;
    $msg ||= "$what is an instance of $cat";
    ok( $what->instance_of_cat($cat), $msg );
}

sub SInt::structure_ok {
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self";
    Test::More::ok( $self->structure_is($potential_struct), $msg );
}

sub SInt::structure_nok {    # ONLY TO BE USED FROM TEST SCRIPTS
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self isn't";
    Test::More::ok( !$self->structure_is($potential_struct), $msg );
}

sub SBuiltObj::structure_ok {    # ONLY TO BE USED FROM TEST SCRIPTS
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self";
    Test::More::ok( $self->structure_is($potential_struct), $msg );
}

sub SBuiltObj::structure_nok {    # ONLY TO BE USED FROM TEST SCRIPTS
    my ( $self, $potential_struct, $msg ) = @_;
    $msg ||= "structure of $self isn't";
    Test::More::ok( !$self->structure_is($potential_struct), $msg );
}

sub SBindings::Blemish::where_ok {
    my ( $self, $what ) = @_;
    is $self->get_where(), $what, "$self where okay";
}

sub SBindings::Blemish::starred_ok {
    my ( $self, $what ) = @_;
    is $self->get_starred(), $what, "$self starred okay";
}

sub SBindings::Blemish::real_ok {
    my ( $self, $what ) = @_;
    ok $self->get_real()->structure_is($what), "$self real okay";
}

sub SBindings::where_ok {
    my ( $self, $what_ref ) = @_;
    my @blemishes = @{ $self->get_blemishes() };
    my $msg       = "$self where okay";
    unless ( @blemishes == @$what_ref ) {
        ok 0, $msg;
        return;
    }
    for ( my $i = 0; $i < @blemishes; $i++ ) {
        next if $blemishes[$i]->get_where() == $what_ref->[$i];
        ok 0, $msg;
    }
    ok 1, $msg;
}

sub SBindings::starred_ok {
    my ( $self, $what_ref ) = @_;
    my @blemishes = @{ $self->get_blemishes() };
    my $msg       = "$self starred okay";
    unless ( @blemishes == @$what_ref ) {
        ok 0, $msg;
        return;
    }
    for ( my $i = 0; $i < @blemishes; $i++ ) {
        next if $blemishes[$i]->get_starred() eq $what_ref->[$i];
        ok 0, $msg;
    }
    ok 1, $msg;
}

sub SBindings::real_ok {
    my ( $self, $what_ref ) = @_;
    my @blemishes = @{ $self->get_blemishes() };
    my $msg       = "$self real okay";
    unless ( @blemishes == @$what_ref ) {
        ok 0, $msg;
        return;
    }
    for ( my $i = 0; $i < @blemishes; $i++ ) {
        next if $blemishes[$i]->get_real()->structure_is( $what_ref->[$i] );
        ok 0, $msg;
    }
    ok 1, $msg;
}

sub SBindings::value_ok {
    my ( $self, $name, $val ) = @_;
    my $got_val = $self->get_values_of()->{$name};
    if ( ref $got_val ) {
        ok $got_val->structure_is($val);
    }
    else {
        ok( $got_val eq $val );
    }
}

sub SBindings::blemished_ok {
    my ($self) = shift;
    my $msg = "$self is blemished";
    ok scalar( @{ $self->get_blemishes() } ), $msg;
}

sub SBindings::non_blemished_ok {
    my ($self) = shift;
    my $msg = "$self is blemished";
    ok !scalar( @{ $self->get_blemishes() } ), $msg;
}

sub blemished_where_ok {
    my ( $bindings, $where_ref ) = @_;
    my @where = map { $_->get_where() } @{ $bindings->get_blemishes };
    cmp_deeply \@where, $where_ref, "Location of Blemished";
}

sub blemished_starred_okay {
    my ( $bindings, $star_ref ) = @_;
    my @starred = map { $_->get_starred } @{ $bindings->get_blemishes };
    cmp_deeply \@starred, $star_ref, "Starred versions of Blemished";
}

sub blemished_real_okay {
    use Smart::Comments;
    my ( $bindings, $real_ref ) = @_;
    my @real = map { $_->get_real } @{ $bindings->get_blemishes };
    my $msg = "Original (unstarred) versions of Blemished";
    if ( @real == @$real_ref ) {
        for ( my $i = 0; $i < @real; $i++ ) {
            next if $real[$i]->structure_is( $real_ref->[$i] );
            ok 0, $msg;
        }
        ok 1, $msg;
    }
    else {
        ok 0, $msg;
    }
}

sub throws_thought_ok{
    my ( $cl, $type ) = @_;

    my @types = (ref($type) eq "ARRAY") ? @$type : ($type);
    @types = map { /^SThought::/ ? $_ : "SThought::$_" } @types;

    eval { $cl->run; };
    my $e;
    unless ($e = $EVAL_ERROR) {
        ok( 0, "No thought returned" );
        return;
    }
    my $payload = $e->payload;
    
    unless ($payload) {
        ok( 0, "Died without payload" );
        return;
    }

    for (@types) {
        if ($payload->isa($_)) {
            ok( 1, "$payload returned" );
            return $payload;
        }
    }

    ok( 0, "Wrong type: $payload. Expected one of: " . join(", ", @types) );
}

sub throws_no_thought_ok{
    my ( $cl ) = @_;

    eval { $cl->run; };
    my $e;
    if ($e = $EVAL_ERROR) {
        ok( 0, "Should return no thought! $e" );
        return;
    }
    ok( 1, "Lived Ok" );
}

sub _wrap_to_get_payload_type{
    my ( $subr ) = @_;
    return sub {
        eval { $subr->( ) };
        if (my $e = $EVAL_ERROR ) {
            if (UNIVERSAL::can($e, 'payload')) {
                my $type = ref($e->payload);
                if ($type =~ /^(SCF|SThought)::(.*)/){
                    return $2;
                } 
            }
            die $e;
        }
        return "";
    };
}


sub code_throws_stochastic_ok{
    my ( $subr, $arr_ref ) = @_;
    my $new_sub = _wrap_to_get_payload_type( $subr );
    stochastic_all_seen_ok $new_sub, $arr_ref;
}

sub code_throws_stochastic_nok{
    my ( $subr, $arr_ref ) = @_;
    my $new_sub = _wrap_to_get_payload_type( $subr );
    stochastic_all_seen_nok $new_sub, $arr_ref;
}

sub code_throws_stochastic_all_and_only_ok{
    my ( $subr, $arr_ref ) = @_;
    my $new_sub = _wrap_to_get_payload_type( $subr );
    stochastic_all_and_only_ok $new_sub, $arr_ref;
}

sub code_throws_stochastic_all_and_only_nok{
    my ( $subr, $arr_ref ) = @_;
    my $new_sub = _wrap_to_get_payload_type( $subr );
    stochastic_all_and_only_nok $new_sub, $arr_ref;
}

sub INITIALIZE_for_testing{ 

    Seqsee->initialize_codefamilies();
    Seqsee->initialize_thoughttypes();
            Log::Log4perl::init(\<<'NOLOG');
log4perl.logger                  = FATAL, file

log4perl.appender.file           = Log::Log4perl::Appender::File
log4perl.appender.file.filename  = log/nolog
log4perl.appender.file.autoflush = 1
log4perl.appender.file.mode      = write
log4perl.appender.file.layout    = PatternLayout

NOLOG

}


sub stochastic_test_codelet{
    my ( %opts_ref ) = @_;
    my ($setup_sub, $expected_throws, $check_sub, $codefamily) =
        @opts_ref{ qw(setup throws post_run codefamily)};

    if ($check_sub) {
        confess ' defining a check_sub when there can be exceptions is useless..  here, we are expecting' . "@$expected_throws" unless List::MoreUtils::all { $_ eq '' } @$expected_throws;
    }

    code_throws_stochastic_all_and_only_ok
        sub {
            SUtil::clear_all();
            my $opts_ref = $setup_sub->();
            my $cl = new SCodelet($codefamily, 100, $opts_ref );
            ## $cl
            $cl->run;
        }, $expected_throws;
    if ($check_sub) {
        ok( $check_sub->(), 'checking the after effects');
    } else {
        ok( 1, 'nothing to check' );

    }

}

sub output_contains{
    my ( $subr, %scope ) = @_;
    my $msg = delete($scope{msg}) || "output_contains";
    my %seen;
    my $times = 5;
    for (1..$times) {
        my $ret = $subr->();
        my %seen_here;
        for (@$ret) {
            ## $_
            $seen_here{$_}++;
        }
        for (keys %seen_here) {
            $seen{$_}++;
        }
    }

    my $problems_found = 0;
  LOOP: while (my ($k, $v) = each %scope) {
        if ($k eq 'always') {
            foreach (@$v) {
                $seen{$_} ||= 0;
                unless ($seen{$_} == $times) {
                    $problems_found = 1;
                    $msg .= "$_ was not always seen. Seen $seen{$_} times out of $times";
                    last LOOP;
                }
            }
        } elsif ($k eq 'never') {
            foreach (@$v) {
                $seen{$_} ||= 0;
                unless ($seen{$_} == 0) {
                    $problems_found = 1;
                    $msg .= "$_ was not never seen. Seen $seen{$_} times out of $times";
                    last LOOP;
                }
            }
        } elsif ($k eq 'sometimes') {
            foreach (@$v) {
                $seen{$_} ||= 0;
                unless ($seen{$_} > 0) {
                    $problems_found = 1;
                    $msg .= "$_ was not seen anytime. Seen $seen{$_} times out of $times";
                    last LOOP;
                }
            }

        } elsif ($k eq 'sometimes_but_not_always') {
            foreach (@$v) {
                $seen{$_} ||= 0;
                unless ($seen{$_} > 0 and $seen{$_} < $times) {
                    $problems_found = 1;
                    $msg .= "Expected to see $_ sometimes but not always, but it was ";
                    $msg .= ( $seen{$_} ? 'always' : 'never' );
                    $msg .= ' seen';
                    last LOOP;
                }
            }

        } else {
            confess "unknown quantifier $k";
        }
    }
    ok( 1 - $problems_found, $msg );
}

sub output_always_contains{
    my ( $subr, $arg ) = @_;
    $arg = [ $arg ] unless ref($arg) eq "ARRAY";
    output_contains $subr, always => $arg;
}

sub output_never_contains{
    my ( $subr, $arg ) = @_;
    $arg = [ $arg ] unless ref($arg) eq "ARRAY";
    output_contains $subr, never => $arg;
}

sub output_sometimes_contains{
    my ( $subr, $arg ) = @_;
    $arg = [ $arg ] unless ref($arg) eq "ARRAY";
    output_contains $subr, sometimes => $arg;
}

sub output_sometimes_but_not_always_contains{
    my ( $subr, $arg ) = @_;
    $arg = [ $arg ] unless ref($arg) eq "ARRAY";
    output_contains $subr, sometimes_but_not_always => $arg;
}

sub fringe_contains{
    my ( $self, %options ) = @_;
    my $setup_sub;
    
    if (ref($self) eq "CODE") {
        $setup_sub = $self;
    }

    my $subr;
    if ($setup_sub) {
        $subr = sub {
            SUtil::clear_all();
            $self = $setup_sub->();
            return [map { $_->[0] } @{$self->get_fringe()}];
        };

    } else {
        $subr = sub {
            return [map { $_->[0] } @{$self->get_fringe()}];
        };
    }
    output_contains($subr, msg => "fringe_contains  ", %options);
}

sub extended_fringe_contains{
    my ( $self, %options ) = @_;
    my $setup_sub;
    
    if (ref($self) eq "CODE") {
        $setup_sub = $self;
    }

    my $subr;
    if ($setup_sub) {
        $subr = sub {
            SUtil::clear_all();
            $self = $setup_sub->();
            return [map { $_->[0] } @{$self->get_extended_fringe()}];
        };

    } else {
        $subr = sub {
            return [map { $_->[0] } @{$self->get_extended_fringe()}];
        };
    }
    output_contains($subr, msg => "extended_fringe_contains  ", %options);
}

sub action_contains{
    my ( $self, %options ) = @_;
    my $setup_sub;
    
    if (ref($self) eq "CODE") {
        $setup_sub = $self;
    }

    my $subr;
    if ($setup_sub) {
        $subr = sub {
            SUtil::clear_all();
            $self = $setup_sub->();
            return [map { ref($_) } $self->get_actions()];
        };

    } else {
        $subr = sub {
            return [map { ref($_) } $self->get_actions()];
        };
    }
    output_contains($subr, msg => "action_contains  ", %options);
}


1;
