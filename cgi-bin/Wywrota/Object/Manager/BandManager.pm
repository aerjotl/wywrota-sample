package Wywrota::Object::Manager::BandManager;

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
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';


sub onAddToFavorites {
# --------------------------------------------------------
	my $self = shift;
	my $id = shift;
	Wywrota->db->execWriteQuery(qq~
		INSERT INTO notification_record (content_id, record_id, user_id, status) 
		VALUES (15, $id, $Wywrota::session->{user}{id}, 1)
	~);
}


sub onRemoveFromFavorites  {
# --------------------------------------------------------
	my $self = shift;
	my $id = shift;
	Wywrota->db->execWriteQuery(qq~
		DELETE FROM notification_record WHERE 
		content_id=15 AND record_id=$id AND user_id= $Wywrota::session->{user}{id}
	~);
}


sub landingPage {
# --------------------------------------------------------
	Wywrota->cListView->viewRecords({sb=>'_fav_cnt', so=>'descend', '_fav_cnt-gt'=>1});
}



sub getSqlAddFields {
#-----------------------------------------------------------------------
	return ", rec.image_id, rec.nazwa_pliku";
}

1;