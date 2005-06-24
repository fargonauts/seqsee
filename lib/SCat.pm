package SCat;
use strict;
use SUtil;
use SBuiltObj;
use Set::Scalar;
use SInstance;
use SPos;

use SCat::Derive::assuming;
use SCat::Derive::blemished;

use Class::Std;
use Carp;

our @ISA = qw{SInstance};
our %Cats;

my $yada = sub { die "yada yada yada" };

my %att_of                 :ATTR(:get<att> 
				 :set<att>  
				 :init_arg<att>  
				);
my %builder_of             :ATTR(:get<builder> 
				 :set<builder>
				 :init_arg<builder>
				 :default(yada)
				);
my %instancer_of           :ATTR(:get<instancer>
				 :set<instancer>
				);
my %position_finder_of_of  :ATTR;
my %_blemished_of          :ATTR(:set<blemished>
				 :get<blemished>
				);
my %guesser_of_of          :ATTR(:init_arg<guesser_of>,
				 :default({})

				);
my %empty_ok_of            :ATTR(:get<empty_ok> 
				 :set<empty_ok>
				 :init_arg<empty_ok>
				 :default<0>
				);
my %guesser_pos_of_of      :ATTR( :init_arg<guesser_pos_of>
				  :default({})
				);

our %Global_attributes = map { $_ => 1 }
  qw{what};

sub BUILD{
  my ( $self, $id, $opts ) = @_;
  $instancer_of{$id} = delete $opts->{instancer};
  $att_of{$id} = new Set::Scalar;
  if (exists $opts->{attributes}) {
    $att_of{$id}->insert(@{ $opts->{attributes} });
  }
}

sub add_attributes{
  my $self = shift;
  $att_of{ident $self}->insert(@_);
  $self;
}

sub has_attribute{
  my ( $self, $what ) = @_;
  $Global_attributes{$what} or $att_of{ident $self}->has($what);
}

sub build{
  (@_ == 2) or croak "build of any category only takes two arguments";
  my ($self, $opts) = @_;
  return $builder_of{ident $self}->($self, $opts);
}

sub is_instance{
  my $self = shift;
  my @args = map { ref($_) ? $_ : SInt->new({mag => $_}) } @_;
  return $instancer_of{ident $self}->($self, @args);
}


sub has_named_position{
  my ( $self, $str ) = @_;
  return (exists $position_finder_of_of{ident $self}{$str});
}

sub is_blemished_cat{
  $_blemished_of{ident shift};
}

sub guess_attribute{
  my ( $self, $obj, $att ) = @_;
  UNIVERSAL::isa($obj, "SBuiltObj") or die "need SBuiltObj";
  my $guesser = $guesser_of_of{ident $self}{$att};
  die "Don't know how to guess attribute $att" unless $guesser;
  return $guesser->($self, $obj);
}

sub generate_instancer{
  my $self = shift;
  my $ident = ident $self;
  die "generate instancer called when instancer already present" 
	if $instancer_of{$ident};
  my @atts = $att_of{$ident}->members;
  foreach (@atts) {
    die "cannot generate instancer: do not know how to guess attribute $_"
       unless exists $guesser_of_of{$ident}{$_};
  }
  my $empty_ok = $empty_ok_of{$ident} || 0;
  $instancer_of{$ident} = sub {
	my ($me, $builtobj) = @_;
	if (not($builtobj) or $builtobj->is_empty) {
	   return SBindings->new() if $empty_ok;
	   return undef;
	}
	my %guess;
	for (@atts){
	  my $guess = $me->guess_attribute($builtobj, $_);
	  return undef unless defined $guess;
	  $guess{$_} = $guess;
	}
	my $guess_built = $me->build(\%guess);
	my $bindings = $builtobj->structure_blearily_ok($guess_built);
	if ($bindings) {
	  for (keys %guess) {
	    $bindings->{$_} = $guess{$_};
	  }
	}
	return $bindings;
  };
}

sub generate_guesser_from_pos{
  my ( $self, $attribute, $pos ) = @_;
  $guesser_of_of{ident $self}{$attribute} = sub {
	my ($self, $bo) = @_;
	my $obj = $bo->items()->[$pos];
	my @int_vals = $obj->as_int();
	if (@int_vals == 1) { return $int_vals[0]; }
	return undef;
  };
}

sub generate_guesser_from_pos_finder{
  my ( $self, $attribute, $finder ) = @_;
  $guesser_of_of{ident $self}{$attribute} = sub {
	my ($self, $bo) = @_;
	my $range = eval { $finder->($bo) };
	return undef if $@;
	my @objs = $bo->subobj_given_range($range);
	return undef unless (@objs == 1);
	my @int_vals = $objs[0]->as_int();
	if (@int_vals == 1) { return $int_vals[0]; }
	return undef;
   };		    
}

sub compose{
  my $self  = shift;
  my $ident = ident $self;
  # The task of this is to tie all loose ends, check sanity etc

  # must have a builder...
  die "New category has no builder!" unless $builder_of{$ident};
  unless ($instancer_of{$ident}) {
	# Must define what to do with empty objects...
	defined($empty_ok_of{$ident}) or die "No instancer given, and I was not told what to do with empty objects, and so I cannot provide my own instancer"; 

	# Try and generate guessers for those that are missing
	for ($att_of{$ident}->members) {
	  next if $guesser_of_of{$ident}{$_}; # already defined
	  unless (exists($guesser_pos_of_of{$ident}{$_}) 
		  or $position_finder_of_of{$ident}{$_}) {
	    die "Cannot generate guesser for $_: need at least a guesser_pos";
	  }
	  if (exists $guesser_pos_of_of{$ident}{$_}){
	    $self->generate_guesser_from_pos($_, $guesser_pos_of_of{$ident}{$_});
	  } else {
	    $self->generate_guesser_from_pos_finder($_, 
						    $position_finder_of_of{$ident}{$_});
	  }
	}

	eval { $self->generate_instancer };
	die "No instancer given, and something went wrong when I attempted 
to provide one: $@" if $@;
      }
  
}

sub install_position_finder{
  (@_ == 4) or die "install_position_finder requires 4 args";
  my ($self, $name, $sub, $multi) = @_;
  SPos->new($name)->install_finder
    ( cat    => $self,
      finder => new SPosFinder( multi => $multi,
				sub => $sub
			      )
    );
  $position_finder_of_of{ident $self}{$name} = $sub; 
  #XXX. SHould use the Finder object!!
}

1;
