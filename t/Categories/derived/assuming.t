use strict;
use blib;
use Test::Seqsee;
BEGIN { plan tests => 16; }


my $cat = $S::ascending;

my $cat2 = $cat->derive_assuming( { start => 1 } );
my $ret;
dies_ok  { $ret = $cat2->build() } "Needs the missing arguments";
lives_ok { $ret = $cat2->build( { end => 4 } ) } "all arguments present";

isa_ok( $ret, "SBuiltObj", "Built object is a SBuiltObj" );
$ret->structure_ok( [ 1, 2, 3, 4 ], "derived built the right object" );

my $bindings;
$bindings = $cat2->is_instance($ret);
$bindings->value_ok(end => 4);
blemished_where_ok     ( $bindings, [] );
blemished_starred_okay ( $bindings, [] );
blemished_real_okay    ( $bindings, []);


$bindings =
  $cat2->is_instance( SBuiltObj->new( { items => [ 1, 2, 3, 4, 5, 6 ] } ) );
$bindings->value_ok(start => 1);
$bindings->value_ok(end => 6);

$bindings = $cat2->is_instance( SBuiltObj->new( { items => [ 3, 4, 5 ] } ) );
undef_ok($bindings);

{
  my $blemished_obj2 = SBuiltObj->new(
    {
      items => [
        3, $S::double->blemish( SInt->new( { mag => 4 } ) ),
        5, 6, 7
      ]
    }
  );

  my $bindings = $cat2->is_instance($blemished_obj2);
  undef_ok $bindings;

  #diag $bindings->{start};
}

#diag "cat  instancer is: $cat->{instancer}";
#diag "cat2 instancer is: $cat2->{instancer}";

{
  use SBlemishType::double;
  my $blemished_obj = SBuiltObj->new(
    {
      items => [
        1, $S::double->blemish( SInt->new( { mag => 2 } ) ),
        3, 4, 5
      ]
    }
  );
  $blemished_obj->structure_ok( [ 1, [ 2, 2 ], 3, 4, 5 ] );

  my $bindings = $cat->is_instance($blemished_obj);
  $bindings->value_ok( start => 1);
  $bindings->value_ok( end   => 5);
}

#diag "cat  instancer is: $cat->{instancer}";
#diag "cat2 instancer is: $cat2->{instancer}";

{
  my $blemished_obj2 = SBuiltObj->new(
    {
      items => [
        3, $S::double->blemish( SBuiltObj->new( { mag => 4 } ) ),
        5, 6, 7
      ]
    }
  );

  my $bindings = $cat2->is_instance($blemished_obj2);
  undef_ok $bindings;

  #diag $bindings->{start};
}

