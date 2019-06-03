package Wywrota::Object::Manager::UserGroupManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';



sub landingPage {
# --------------------------------------------------------
	my $self = shift;
	return Wywrota->cListView->viewRecords({ 'id-gt'=>-10, 'sb'=>'id' });
}


sub storeUserGroups {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift;
	my ($query, $id, $status, $ids);

	return -1 if (!$user_id);

	Wywrota->db->execWriteQuery("DELETE FROM user_to_ugroup WHERE user_id=?", $user_id); 

	foreach $id ( split(",", $Wywrota::in->{group_ids}) ) {

		$query = qq~
			INSERT INTO user_to_ugroup 
			(ugroup_id, user_id) VALUES ($id, $user_id) 
		~;
		if ($Wywrota::in->{"group".$id}) {
			Wywrota->db->execWriteQuery($query) ; 
			$ids .= "$id,";
		}
	}

	Wywrota->db->execWriteQuery(qq~UPDATE ludzie SET _grupy = ? WHERE id= ?~, $ids, $user_id) ; 
	
	Wywrota::Log::logFile("user_groups_change", "user_id: $user_id | groups: $ids | changed_by: $Wywrota::session->{user}{id}");
	
	return "Zapisano grupy użytkownika";
}


sub readUserGroups {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift;
	my ($data);
	my ($ugroup, $ugroupStruct);

	return if ($user_id <= 0);

	$data = Wywrota->db->buildHashRefArrayRef(qq~
		SELECT g.id, g.nazwa, g.sortorder FROM user_to_ugroup lg JOIN ugroup g on lg.ugroup_id = g.id WHERE user_id=$user_id~);

	foreach $ugroup (@$data) {
		$ugroupStruct->{$ugroup->{id}}=$ugroup;
	}

	return $ugroupStruct;
}


1;