package Transform;
use 5.10.0;
use Class::Std;
use Class::Multimethods;
use strict;
use Carp;

multimethod FindTransform => ( '*', '*', '*' ) => sub {
    *__ANON__ = "((__ANON__ FindTransform ***))";
    my ( $a, $b, $cat ) = @_;
    $cat->FindTransformForCat( $a, $b );
};

{
    my $numeric_FindTransorm = sub {
        *__ANON__ = "((__ANON__ FindTransform SInt/SElement SInt/SElement))";
        my ( $a, $b ) = @_;
        my @common_categories = $a->get_common_categories($b) or confess;
        my $cat = SLTM::SpikeAndChoose( 0, @common_categories ) // $S::NUMBER;
        if ($cat->IsNumeric()) {
            $cat->FindTransformForCat( $a->get_mag(), $b->get_mag() );
        } else {
            $cat->FindTransformForCat( $a, $b );
        }
    };
    multimethod FindTransform => qw{SInt SInt}         => $numeric_FindTransorm;
    multimethod FindTransform => qw{SElement SElement} => $numeric_FindTransorm;
}

{
    my $Fail = sub  {
        return
    };
    multimethod FindTransform => qw{SInt SElement} => $Fail;
    multimethod FindTransform => qw{SElement SInt} => $Fail;
    multimethod FindTransform => qw{SAnchored SInt} => $Fail;
    multimethod FindTransform => qw{SInt SAnchored} => $Fail;
}

multimethod FindTransform => qw(# #) => sub {
    *__ANON__ = "((__ANON__ FindTransform ##))";
    my ( $a, $b ) = @_;
    $S::NUMBER->FindTransformForCat( $a, $b );
};

multimethod FindTransform => qw(SAnchored SAnchored) => sub {
    *__ANON__ = "((__ANON__ FindTransform SAnchored SAnchored))";
    my ( $a, $b ) = @_;
    my @common_categories = $a->get_common_categories($b) or return;
    my $cat = SLTM::SpikeAndChoose( 10, @common_categories ) or return;
    $cat->FindTransformForCat( $a, $b );
};

# More FindTransform in Transform::Dir

multimethod ApplyTransform => qw(Transform::Numeric #) => sub {
    *__ANON__ = "((__ANON__ ApplyTransform Transform::Numeric #))";
    my ( $transform, $num ) = @_;
    $transform->get_category()->ApplyTransformForCat($transform, $num);
};

multimethod ApplyTransform => qw(Transform::Numeric SInt) => sub {
    *__ANON__ = "((__ANON__ ApplyTransform Transform::Numeric SInt))";
    my ( $transform, $num ) = @_;
    my $new_mag = $transform->get_category()->ApplyTransformForCat( $transform, $num->get_mag() ) // return;
    SInt->new($new_mag);
};

multimethod ApplyTransform => qw(Transform::Numeric SElement) => sub {
    *__ANON__ = "((__ANON__ ApplyTransform Transform::Numeric SElement))";
    my ( $transform, $num ) = @_;
    my $new_mag = $transform->get_category()->ApplyTransformForCat( $transform, $num->get_mag() ) // return;
    SElement->create( $new_mag, -1 );
};

multimethod ApplyTransform => qw(Transform::Structural SObject) => sub {
    my ( $transform, $object ) = @_;
    $transform->get_category()->ApplyTransformForCat($transform, $object);
};

1;
