package Wywrota::Object::Manager::EventManager;

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



sub landingPage {
# --------------------------------------------------------
	Wywrota->cListView->viewRecords( {'id-gt'=>0} );
}

sub getSqlAddFields {
#-----------------------------------------------------------------------
	return ", a.stan as stan, a.tytul as atitle, a._image_filename as _image_filename ";
}

sub getSqlAddJoin {
#-----------------------------------------------------------------------
	return " RIGHT JOIN article a on rec.article_id=a.id AND a._active=1 ";
}

sub customQuery {
#-----------------------------------------------------------------------
	my $self = shift;
	my $key = shift;
	my $now = Wywrota->db->quote( getDate(time()) );
	my $monthago = Wywrota->db->quote( getDate(time() - 2*2592000 ) );
	# for auspices links, that are not events

	if ($key eq 'current') {
		return qq~
			auspices=1 AND (
				(rec.date_from > $now ) OR
				(rec.date_to > $now ) OR
				( (rec.date_added > $monthago) 
			      AND (rec.date_from = '0000-00-00 00:00:00' OR rec.date_from IS NULL)  
			      AND (rec.date_to = '0000-00-00 00:00:00' OR rec.date_to IS NULL) 
			    )
			)
		~;
	}
}



1;