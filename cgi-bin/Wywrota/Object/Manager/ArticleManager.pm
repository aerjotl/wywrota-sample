package Wywrota::Object::Manager::ArticleManager;

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
use Wywrota::Object::Event;
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';




sub initContentTemplate {
# --------------------------------------------------------

	my $self=shift;
	my $nut=shift;
	my ($object);

	if ($nut->in('view')) {
		$object = Wywrota->content->getObject( $nut->in('view') );
		return if (!$object);
		$object->preProcess();		
		$nut->request->{content}{current}{page_id} = 
			Wywrota->dict->getPageId('typ', $object->val('typ'), 'Article');
		$nut->request->{nav}{crumbLinks} = 
			Wywrota->nav->crumbTrailLinks( Wywrota->dict->getPageId('typ', $object->val('typ'), 'Article') );
	} 


}


sub landingPage {
# --------------------------------------------------------
	return Wywrota->content->includeFile("index.html");
}


sub onObjectAdd {
# --------------------------------------------------------
	my $self=shift;
	my $object = shift;
	Wywrota->db->execWriteQuery( "UPDATE site_images SET article_id="
		. Wywrota->db->quote( $object->rec->{id} )
		. " WHERE user_id=".Wywrota->db->quote($Wywrota::session->{user}{id}) 
		. " AND typ=3 AND article_id IS NULL"
	); 
	$self->onObjectEdit($object);
}

sub onObjectEdit {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($id, $filename, $event, $tag, $query);

	Wywrota->debug("ArticleManager : onObjectEdit"); #, $in, $request
	

	# update image information
	if (!$rec->{_image_id} || !$rec->{_image_filename}) {
		($id, $filename) =  Wywrota->db->quickArray("SELECT id, nazwa_pliku FROM site_images WHERE article_id=? AND _active=1 LIMIT 0,1", $object->id );
		if ($id) {
			$object->rec->{_image_id} = $id;
			$object->rec->{_image_filename} = $filename;
			Wywrota->db->execWriteQuery( "UPDATE article SET _image_id=?, _image_filename=? WHERE id=?", $id, $filename, $object->id ); 
		}
	}


	# saving tags
	eval {
			Wywrota->db->execWriteQuery( "DELETE FROM `tag` WHERE content_id=? and record_id=?", $object->cid, $object->id );

			my @tags = split(/,/, $rec->{tags});
			foreach $tag (@tags) {
				$tag = simpleAscii(trim($tag));
				$query = "INSERT INTO `tag` (`tag`, `content_id`, `record_id`) VALUES (?, ?, ?)";
				Wywrota->db->execWriteQuery( $query, $tag, $object->cid, $object->id );
			}

	};
	Wywrota->error("Error while saving tags:", $@) if ($@);


	# saving event information
	eval {
		$event = Wywrota->content->createObject($rec, 'Event', 'event_' );
		$event->rec->{article_id} = $rec->{id};
		if ($rec->{event_id}) {

			Wywrota->debug("ArticleManager : exists event ID");
			Wywrota->content->modifyObject($event);

		} elsif ( ($rec->{event_date_from} && $rec->{event_date_from} !~ /0000-00-00/) 
				|| ($rec->{event_date_to} && $rec->{event_date_to} !~ /0000-00-00/) 
				|| $rec->{event_location} )  {
			Wywrota->debug("ArticleManager : adding event");
			$event->rec->{user_id} = $rec->{user_id};
			$event->rec->{id}=undef;

			# persist
			Wywrota->content->addObject($event);

		} else {
			Wywrota->debug("ArticleManager : no event");
		}
	};
	Wywrota->error("Error while saving event information:", $@) if ($@);

}

sub getSqlAddFields {
#-----------------------------------------------------------------------
# additional fields that are added to list queries

	return ", e.id as event_id, e.auspices as event_auspices, e.location as event_location, e.date_from as event_date_from, e.date_to as event_date_to, e.city as event_city ";	#, si.img_width, si.img_height
}

sub getSqlAddJoin {
#-----------------------------------------------------------------------
# additional join tables added to list queries

	return " LEFT JOIN event e on rec.id=e.article_id ";	# LEFT JOIN site_images si ON rec._image_id = si.id
}

1;