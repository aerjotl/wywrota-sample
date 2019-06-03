package Wywrota::Chords;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Wywrota::Config;
use Wywrota::Utils;
 
our @ISA = qw(Exporter);
our @EXPORT = qw(
	findChord
	);


sub findChord {
#-------------------------------
# match to the files in /gfx/chords/...

	my $chord = trim(shift);
	
	$chord =~ s/#/_/g;
	
	
	if ($chord =~ "is") { return $chord;}
	
	#my $substitute = {
	#	'cis'	=> 'C_m'
	#};
	
	#foreach (keys %{$substitute}) {
	#	return $substitute->{$_} if ($chord eq $_);
	#}
	
	
	if ($chord =~ /^([a-z])(_*)(.*)$/) {	# one small letter at the front
		return uc($1).$2."m".$3;
	}
	
	return $chord;
}

1;
