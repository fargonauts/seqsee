package SBlemishType::double;
use strict;

my $builder = sub {
    my ( $self, $args ) = @_;
    my $what    = delete $args->{what};
    my $new_obj = new SBuiltObj;
    $new_obj->set_items( [ $what, $what ] );
    $new_obj;
};

my $guesser = {
    what => sub {
        my ( $self, $bo ) = @_;
        $bo->items()->[0];
    },
};

my $guesser_flat = {
    what => sub {
        my ( $self, @bo ) = @_;
        return undef if @bo % 2;
        return SBuiltObj->new( @bo[ 0 .. ( @bo / 2 ) - 1 ] );
    },
};

our $double = new SBlemishType(
    {   att             => new SSet(),
        builder         => $builder,
        empty_ok        => 1,
        empty_what      => SBuiltObj->new_deep(),
        guesser_of      => $guesser,
        guesser_flat_of => $guesser_flat,
        guesser_pos_of  => {}
    }
);
my $blemish = $double;

1;
