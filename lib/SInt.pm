package SInt;
use strict;
use Class::Std;

our @ISA = qw{SInstance};

my %mag :ATTR( :get<mag> );

sub BUILD {
  $mag{ $_[1] } = $_[2]->{mag};
}

sub flatten {
  $mag{ ident shift };
}

sub clone {
  my $self = shift;
  return SInt->new( { mag => $mag{ ident $self } } );
}

sub show_shallow {
  my ( $self, $depth ) = @_;
  print "\t" x $depth, $mag{ ident $self }, "\n";
}

sub structure_is {
  my ( $self, $struct ) = @_;
  
  #my @parts = ( ref $struct ) ? @$struct : ($struct);
  #return 0 unless ( @parts == 1 );
  return ( $mag{ ident $self} == $struct );
}

sub get_structure {
  $mag{ ident shift };
}

sub as_int {
  $mag{ ident shift };
}

sub can_be_as_int {
  my ( $self, $int ) = @_;
  $mag{ ident $self} == $int;
}

sub can_be_seen_as_int {
  my ( $self, $int ) = @_;
  return 1 if $mag{ident $self} == $int;
  return;
}

sub is_empty { 0 }

sub structure_blearily_ok{
  # XXX could easily be wrong.. check
  my ( $self, $template ) = @_;
  return if ref $template;
  return unless $mag{ident $self} == $template;
  return SBindings->new();
}

1;
