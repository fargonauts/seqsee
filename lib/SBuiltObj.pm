package SBuiltObj;

sub new{
  my $package = shift;
  my $self = bless {}, $package;
  $self->set_items(@_);
}

sub set_items{
  my $self = shift;
  $self->{items} = [@_];
  $self;
}

sub items{
  shift->{items};
}

sub flatten{
  my $self = shift;
  return map { ref $_ ? $_->flatten() : $_ } @{$self->{items}};
}

sub find_at_position{
  my ($self, $position) = @_;
  my $range = $self->range_given_position($position);
  return $self->subobj_given_range($range);
}

sub range_given_position{
  my ($self, $position) = @_;
  return $position->{rangesub}->($self);
}

sub subobj_given_range{
  my ($self, $range) = @_;
  my @ret;
  my $items = $self->items;
  for (@$range) {
    my $what = $items->[$_];
    return undef if not defined $what;
    push @ret, $what;
  }
  if (scalar(@ret) == 1) {
    return $ret[0] if ref $ret[0];
    return SBuiltObj->new($ret[0]);
  }
  return SBuiltObj->new(@ret);
}

sub get_position_finder{ #XXX should really deal with the category of the built object, and I have not dealt with that yet....
  my ($self, $str) = @_;
  my $sub = $self->{position_finder}{$str};
  die "Could not find any way for finding the position '$str' for $self" unless $sub;
  return $sub;
}

sub splice{
  my $self = shift;
  my $from = shift;
  my $len = shift;
  my $items = $self->{items};
  splice(@$items, $from, $len, @_);
  $self;
}

sub apply_blemish_at{
  my ($self, $blemish, $position) = @_;
  my $range = $self->range_given_position($position);
  die "position $position undefined for $self" unless $range;
  # XXX should check that range is contiguous....
  my $subobj = $self->subobj_given_range($range);
  my $blemished = $blemish->blemish($subobj);
  my $range_start = $range->[0];
  my $range_length = scalar(@$range);
  $self->splice($range_start, $range_length, $blemished);
  $self;
}

1;
