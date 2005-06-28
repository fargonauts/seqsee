package SPos::Named;
use strict;
use Carp;
use base "SPos";

use Class::Std;
my %name_of           :ATTR;
my %find_by_cat_of_of :ATTR;

sub BUILD{
  my ( $self, $id, $opts ) = @_;
  $name_of{$id} = $opts->{str} || croak "Need str!";
  $find_by_cat_of_of{$id} = {};
}

sub install_finder {
  my ( $self, %opts ) = @_;
  my $cat    = delete $opts{cat};
  my $finder = delete $opts{finder};
  $find_by_cat_of_of{ident $self}{$cat} = $finder;
}

sub find_range {
  my ( $self, $built_obj ) = @_;
  my $id = ident $self;
  my @cats = $built_obj->get_cats;
  my @matching_cats = grep { exists $find_by_cat_of_of{$id}{$_} } @cats;
  return undef unless @matching_cats;
  my @matching_ranges =
    map { $find_by_cat_of_of{$id}{$_}->find_range($built_obj);} @matching_cats;
  return $matching_ranges[0] if @matching_ranges == 1;

  # XXX I should check whether the different answers are the same,
  #  but right now I think I'll just throw..
  SErr::Pos::MultipleNamed->throw("$name_of{$id} for $built_obj");
}

1;
