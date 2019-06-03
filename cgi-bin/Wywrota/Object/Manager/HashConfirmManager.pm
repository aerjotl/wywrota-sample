package Wywrota::Object::Manager::HashConfirmManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Language;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';



sub verify {
# --------------------------------------------------------
	my $self = shift;
	my $hash = shift;
	my ($user_id) = Wywrota->db->quickArray( "SELECT user_id FROM `hash_confirm` WHERE hash=? AND _active=1", $hash );
	if ($user_id) {
		Wywrota->db->execWriteQuery( "UPDATE `hash_confirm` SET _active=0 WHERE hash=?", $hash );
	}
	return $user_id;
}


sub get {
# --------------------------------------------------------
	my $self = shift;
	my $hash = shift;
	my ($val) = Wywrota->db->quickArray( "SELECT hash_value FROM `hash_confirm` WHERE hash=? AND _active=1", $hash );
	if ($val) {
		Wywrota->db->execWriteQuery( "UPDATE `hash_confirm` SET _active=0 WHERE hash=?", $hash );
	}
	return $val;
}


sub getSqlAddConditions {}	# needs to be defined empty



1;