package SCat::descending;
use SCat;

our $descending = new SCat
  ({
    builder =>  sub {
      my ($self, $args_ref) = @_;
      die "need start" unless $args_ref->{start};
      die "need end"   unless $args_ref->{end};
      my $ret = new SBuiltObj;
      $ret->set_items([ reverse($args_ref->{end} .. $args_ref->{start}) ]);
      $ret->add_cat($self, $args_ref);
      $ret;
    },
    guesser_pos_of => { start => 0, end => -1 },
    guesser_of => {},
    empty_ok  => 1,
   });
my $cat = $descending;

$cat->add_attributes(qw/start end/);

$cat->compose();

1;
