use Test::More tests => 16;
use Test::Exception;

use strict;
use blib;


BEGIN{
  use_ok("SWorkspace");
  use_ok("SElement");
}

SWorkspace->setup(1, 2, 3, 4);

cmp_ok($SWorkspace::elements_count, '==', 4);
cmp_ok($SWorkspace::elements[2]->{mag},    '==', 3);
cmp_ok($SWorkspace::bonds_count,    '==', 0);
cmp_ok($SWorkspace::bonds_p_count,  '==', 0);
cmp_ok($SWorkspace::groups_count,   '==', 0);
cmp_ok($SWorkspace::groups_p_count, '==', 0);

isa_ok($SWorkspace::elements[2], "SElement");
cmp_ok($SWorkspace::elements[2]->{left_edge}, '==', 2);

SWorkspace->insert(5,6);
cmp_ok($SWorkspace::elements_count, '==', 6);
cmp_ok($SWorkspace::elements[5]->{mag},    '==', 6);
isa_ok($SWorkspace::elements[5], "SElement");
cmp_ok($SWorkspace::elements[4]->{left_edge}, '==', 4);

SWorkspace->setup(8,9,10,11);
cmp_ok($SWorkspace::elements_count, '==', 4);
cmp_ok($SWorkspace::elements[2]->{mag},    '==', 10);