package Style;
use Carp;
sub AUTOLOAD{
    our $AUTOLOAD;
    confess "Unknown method $AUTOLOAD called. Have you defined this style?";
}

package Themes::Std;
use Memoize;
use SColor;
use Carp;

*HSV = \&SColor::HSV2Color;

use Compile::Style;
[style] Element
[font]  '-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4'
[anchor]'center'
[fill] HSV(160,20,20)

no Compile::Style;

use Compile::Style;
[style] Starred
[font]  '-adobe-helvetica-bold-r-normal--20-140-100-100-p-105-iso8859-4'
[anchor]'center'
[fill] HSV(240,50,50)
no Compile::Style;


use Compile::Style;
[style] Relation
[arrow] 'last'
[width] 3
[params] $strength
[fill] HSV(180,40,80-0.5*$strength)
[smooth] 1
no Compile::Style;

use Compile::Style;
[style] Group
[params] $meto, $hilit, $strength
<fill>
    my ($s, $v) = (40, 80 - 0.5 * $strength);
    $meto ? HSV(240, $s, $v) : HSV(160, $s, $v);
</fill>
<outline>
    my ($s, $v) = (50, 70 - 0.5 * $strength);
if ($hilit) {
'#FF0000'
} else {$meto ? HSV(240, $s, $v) : HSV(160, $s, $v);}
</outline>
[width] 1 + 4 *$hilit 
no Compile::Style;

use Compile::Style;
[style] NetActivation
[fill] HSV(240,30,80)
no Compile::Style;
