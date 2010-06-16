package Acme::AGMorse;

use 5.010000;
use strict;
use warnings;
use Time::HiRes qw(usleep gettimeofday tv_interval);
use Audio::Beep;
use Switch;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(SetMorseVals SendMorseChr SendMorseMsg);

our $VERSION = '0.02';


##### Subroutines
sub _CreateMorseTable;
sub SetMorseVals;
sub _CalMorseVals;
sub _CompileMorseChr;
sub _SendMorseCode;
sub SendMorseChr;
sub SendMorseMsg;
##### GLOBALS

  my $Tone;					#  Tone in Hz to be used for morse monitor
  my $wpm;                  #  words per minute
  my $dahWeight;            #  x 10 for integer resolution
  my $ditEle_mSec;          #  dit elemetn in mSec
  my $dahEle_mSec;          #  dah element in mSec
  my $intrEle_mSec;         #  inter element space
  my $intrChr_mSec;         #  inter character space for msgs
  my $intrWord_mSec;        #  inter word space for msgs
  my $ditFist_mSec;         #  for future paddle interface
  my $dahFist_mSec;         #  for future paddle interface
  my $calibrate;            #  Factor for machine specific timeing adjustment

  my %MorseCode;            # Hash table of character key and Morse value pairs




sub SetMorseVals{                                                            
# I won't go into the details here but this is how to
# determine the various timing parameters for dits, dahs, 
# inter element spacing, inter character spacing and inter word spacing
# This is based on the number of times the word 'paris' can be sent in
# one minute and has been used as a standard for Morse Code WPM over the years

	my ($wpmIn, $dahWeightIn, $toneIn) = @_;
	if (defined $toneIn) {
		$Tone = $toneIn; # sort of out of place but needed to set tone values
	}
	$wpm = $wpmIn;
	$dahWeight = $dahWeightIn;
	my $parisLength = (38 + (4*$dahWeight)/10);
	$ditEle_mSec = 1000/((($parisLength)*$wpm*$calibrate)/60);
	$dahEle_mSec = ($ditEle_mSec * $dahWeight)/10;
	$intrEle_mSec = $ditEle_mSec;
	$intrChr_mSec = 4 * $intrEle_mSec;
	$intrWord_mSec = 7 * $intrEle_mSec;

	return ($wpmIn + $dahWeightIn + $toneIn); # this is a diagnostic return val
}

sub _CalMorseVals{
# uses Time:HiRes to determine how close the machines standard timing
# is to actual timing for Morse charachters.  It runs a test with a
# calibration factor of '1' first, measures the difference between expected
# and actual, creates a new factor and sets the $calibration value to that
# factor so that it may be used through the rest of the session

	my ($wpmIn, $dahWeightIn, $fistDelay) = @_;
	SetMorseVals($wpmIn, $dahWeightIn, $fistDelay);
	my $strTime =  [gettimeofday()];
	for (my $i = 0; $i < 2; $i++) {
		SendMorseMsg("Paris");
	}
	$calibrate = 1+(tv_interval($strTime,[gettimeofday()]) - 6)/6;
	SetMorseVals($wpmIn, $dahWeightIn, $fistDelay);

	return 1;
}

sub _CreateMorseTable{
# This is a psuedo code for Morse characters.  It uses 0 for a dit and 1 for
# a dah.  It also uses 2 for inter character spacing.  
# It builds a hash table for
# all morse characters                                                   
# Note:  This is a perl implementation and is very memory wasteful.  I
# was not concerned given this would be run on comparitively large machines.
# however,  the first version of the psuedo code was done in 1989 and use a 
# bit map of a single word (2 bytes)
	
	%MorseCode = (	# Static hash  of Morse Code element def		
	'@'=>'', 		# 0 @ */ 
	'A'=>'01',		# 1 A */ 
	'B'=>'1000',  	# 2 B */ 
	'C'=>"1010",   	# 3 C */ 
	'D'=>"100",		# 4 D */ 
	'E'=>"0",		# 5 E */ 
	'F'=>"0010",   	# 6 F */ 
	'G'=>"110",		# 7 G */ 
	'H'=>"0000",   	# 8 H */ 
	'I'=>"00",		# 9 I */ 
	'J'=>"0111",   	# 10 J */ 
    'K'=>"101",		# 11 K */ 
    'L'=>"0100",   	# 12 L */ 
    'M'=>"11",		# 13 M */ 
    'N'=>"10",		# 14 N */ 
    'O'=>"111",		# 15 O */ 
    'P'=>"0110",   	# 16 P */ 
    'Q'=>"1101",   	# 17 Q */ 
    'R'=>"010",		# 18 R */ 
    'S'=>"000",		# 19 S */ 
    'T'=>"1",		# 20 T */ 
    'U'=>"001",		# 21 U */ 
    'V'=>"0001",   	# 22 V */ 
    'W'=>"011",		# 23 W */ 
    'X'=>"1001",   	# 24 X */ 
    'Y'=>"1011",   	# 25 Y */ 
    'Z'=>"1100",   	# 26 Z */ 
    '-'=>"",	   	# 27 ~ */ 
    '['=>"",	   	# 28 ~ */ 
    '0'=>"11111",	# 29 0 */ 
    '1'=>"01111",	# 30 1 */ 
    '2'=>"00111",	# 31 2 */ 
    '3'=>"00011",	# 32 3 */ 
    '4'=>"00001",	# 33 4 */ 
    '5'=>"00000",	# 34 5 */ 
    '6'=>"10000",	# 35 6 */ 
    '7'=>"11000",	# 36 7 */ 
    '8'=>"11100",	# 37 8 */ 
    '9'=>"11110",	# 38 9 */ 
    '0'=>"11111",	# 39 0 */ 
    '=>',"110011",	# 40 , */ 
    '.'=>"010101",	# 41 . */ 
    '?'=>"001100",	# 42 ? */ 
    '='=>"10001",	# 43 =  */ 
    '+'=>"01000",	# 44 wait*/
    '!'=>"01010",	# 45 end of message*/ 
    '|'=>"000101",	# 46end of work	*/ 
    '/'=>"10010",	# 47 / */ 
    '('=>"10110",	# 48 ( */   
    '-'=>"100001",	# 49 - */ 
    ':'=>"111000",	# 50 : */ 
    ')'=>"101101",	# 51 ) */ 
    ';'=>"101010",	# 52 ; */ 
    '"'=>"010010",	# 53 " */ 
    '$'=>"0001001",	# 54 $ */ 
    '\''=>"011110",	# 55 ' */ 
    '_'=>"001101",	# 56 _ */ 
    '&'=>"10101",	# 57 start */ 
    '~'=>"00010"   	# 58 understood */ 
    );

	return 1;
}

sub _CompileMorseChr{
# Convert a character into a series of dits and dahs
my ($ca) = @_;
my $i;  		#counter
my $j;			# morse array offset;
my $eles;		#string to be returned;

$ca = uc $ca;
if ($ca eq ' ') {
	$eles = '7';
}
else {$eles = $MorseCode{$ca};}
return $eles;
}

sub _SendMorseCode{
#Send the dits and dahs using the most convenient 
# sound interface (note, feel free to replace Audio:Beep with
# somthing better or develop your own 'keyer' interface to key a
# transmitter or other external device 

my ($eles) = @_;
my $ele;
for (my $i = 0; $i < length ($eles); $i++) {
 $ele = substr($eles,$i,1);
 switch ($ele) {
	 case (1) { 
	 	beep($Tone,$dahEle_mSec);
	 }
	case (0) { 
		beep($Tone,$ditEle_mSec);
  	}
	case (2) { # inter word spacing
		usleep(($intrWord_mSec-$intrEle_mSec-$intrChr_mSec)*1000);
	}
  }
  usleep($intrEle_mSec*1000);
 }
 usleep($intrChr_mSec*1000);

 return 1;
}

sub SendMorseChr {
# Use when sending a single character, useful for keyboard input of
# Morse Code
	my ($Chr) = @_;
	_SendMorseCode(_CompileMorseChr($Chr));
	return $Chr;
}

sub SendMorseMsg {
# Use when sending a word or a message 
	my ($Msg) = @_;
	for (my $i = 0; $i < length ($Msg); $i++) {
		_SendMorseCode(_CompileMorseChr(substr($Msg,$i,1)));
	}
	return $Msg;
}

BEGIN {
   $Tone = 600;
   $calibrate=1;
   _CreateMorseTable();
print STDERR "Calibrating Morse Speed\n";
   _CalMorseVals(20,30,50);
print STDERR "End Calibration\n";
}

1;
__END__

=head1 Name

Acme::AGMorse - Perl extension for compiling and sending Morse code      

Note:  This has been tested on Ubuntu Karmic only.  

=head1 SYNOPSIS


#The following will send "Hello World" in Morse Code at 20 wpm and a dah
#weight of three dits or 30 (1/10 resolution for dah weight control) 
# and a tone of 400 Hz.

  use Acme::AGMorse qw(SetMorseVals SendMorseChr SendMorseMsg);
  SetMorseVals(20,30,400);
  SendMorseMsg("Hello World");  #note, caps are ingnored in Morse Code
  exit;

=head1 DESCRIPTION

This is a library that allows the user to set up a Morse code output engine for a user defined wpm and dah weight, then send morse code messages or characters through the exportable routines.  This library uses the Beep(<tone freq>,<duration>) routine for sounds and the Time::HiRes for the no sound timing and calibration.  

The original code for sending Morse code was derived from programs developed by the author in 1989-1994 Ham Radio logging and rig control applications written
for early Windoze

=head2 EXPORT

qw(SetMorseVals SendMorseChr SendMorseMsg);

None by default.

=head1 TODO

Provide more options for sound
Provide option to 'key' using the printer port or serial port
Provide option to input 'paddle' 

=head1 SEE ALSO

Audio::Beep 
	You must install Audio::Beep and test by typing Beep at the command line
	If you hear a beep all is good.  If not you will need to fix Beep before
	continuing.  Some known problems on Ubuntu:
	1) pcspkr may not be available by default.  run:
		sudo modprobe pcspkr ..... check results
	2) pcspkr may be available but muted.  Check:
		your sound prefrences, usually a right click over the speaker icon

Time::HiRes

MorseJeapordy.pl script  (which is why I built this library)

=head1 AUTHOR

paula Keezer nx1p @at@ arrl.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Paula Keezer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
