use lib ".";

package Main;
require "./Interface.pm";

my $main = Interface->new();
$main->terrain();
