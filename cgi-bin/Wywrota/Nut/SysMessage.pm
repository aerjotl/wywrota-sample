package Wywrota::Nut::SysMessage;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# USAGE:
#	Wywrota->sysMsg->push( $message, $class);
#   classes: 'ok', 'warn', 'err', 'tip', 'tip_sm', 'tip_big'
#
# --------------------------------------------------------

use strict;
use Data::Dumper;

my @msgArray;

sub new {
# --------------------------------------------------------
	my $class = shift;
	my $nut = shift;
	bless {_nut=>$nut}, $class;
}

sub DESTROY {
# --------------------------------------------------------
	my $self = shift;
	undef $self;
}

sub nut {
# --------------------------------------------------------
	my $self = shift;
	return $self->{_nut};
}


sub push {
# --------------------------------------------------------
	my $self = shift;
	my $msg = shift;
	my $class = shift || 'ok';

	push (@msgArray, [$msg, $class]);

}

sub getAll {
# --------------------------------------------------------
	my $self = shift;
	my ($msg, $class, $output);
	
	$output = qq~<div id="msgDiv">~;

	foreach (@msgArray) {
		($msg, $class) = @$_;
		$output .= qq~<div><div class="div_msg_$class">$msg</div></div><p>~;
	}
	$output .= qq~</div>~;
	@msgArray = ();

	return $output ;
}

1;