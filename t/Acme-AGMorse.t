# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-AGMorse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::Simple tests => 3;

use Acme::AGMorse qw(SetMorseVals SendMorseChr SendMorseMsg);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(SetMorseVals(20,30,700) == 750,"SetMorseVals");
ok(SendMorseChr('v') eq 'v', "SendMorseChr");
ok(SendMorseMsg("vv de Hello World") eq "vv de Hello World", "SendMorseMsg");

