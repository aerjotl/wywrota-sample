package Wywrota::AJAX;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict; 
use Exporter; 

use Data::Dumper;
use Wywrota;
use Wywrota::Nut;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Favorites;
use Wywrota::Language;
use Wywrota::Utils;

use Class::Singleton;
use base 'Class::Singleton';
use Data::Structure::Util qw(_utf8_off utf8_off utf8_on _utf8_on);
use HTML::Entities;
use JSON; 

my $instance;

sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;

	$self->{w} = Wywrota->instance();

	$instance = $self;
	return $self;
}

# -- CGI::Fast request processing
sub main {
# --------------------------------------------------------
# 
	my $self = shift;
	my $nut = shift;
	my $in = $nut->in;
	my $action = $Wywrota::in->{a};
	my $output;

	$output = eval {

		if ( $action eq '_registernewuser' and $in->{wywrotid}) {
			return $self->checkWywrotID($in->{wywrotid});

		} elsif (( $action eq 'addFav' || $in->{addFav}) and $in->{id} and $in->{cid}) {
			return $self->addToFav($in->{id}, $in->{set}, $in->{cid});

		} elsif (( $action eq 'removeFav' || $in->{removeFav}) and $in->{id} and $in->{cid}) {
			return $self->removeFav($in->{id}, $in->{set}, $in->{cid});

		} elsif (( $action eq 'watch' || $in->{watch}) and $in->{id} and $in->{cid}) {
			return $self->watch($in->{id}, $in->{cid});

		} elsif (( $action eq 'readmsg' || $in->{readmsg})) {
			return $self->readMessage();		

		} elsif (( $action eq 'joinSoc' || $in->{joinSoc}) and $in->{id} and $in->{cid}) {
			return $self->joinSoc($in->{id}, $in->{cid}, $in->{flag});

		} elsif (( $action eq 'deleteRec' || $in->{deleteRec}) and $in->{id} and $in->{cid}) {
			return "unauthorised" if (!Wywrota->per('del', $in->{cid}));
			return $self->deleteRec($in->{id}, $in->{cid});

		} elsif ( $action eq 'quickAnswer' and $in->{parent_id} and $in->{kat_id}) {
			return $self->quickAnswer($in);

		} elsif ( $action eq 'addComment' and $in->{id} and $in->{cid}) {
			return $self->addComment($in);

		} elsif ( $action eq 'moderate' and $in->{id} and $in->{cid} and $in->{state} ) {
			return "unauthorised" if (!Wywrota->per('admin', $in->{cid}));
			return $self->moderate($in);

		} elsif ( $action eq 'distinction' and $in->{id} and $in->{cid} and $in->{state} ) {
			return "unauthorised" if (!Wywrota->per('admin', $in->{cid}));
			return $self->distinction($in);

		} elsif ( $action eq 'getObject' and int($in->{id}) and $in->{cid} ) {
			return $self->getObject($in);

		} elsif ( $action eq 'closeMsg' and int($in->{id}) ) {
			return $self->closeMsg($in);		

		} elsif ( $action eq 'upload' ) {
			return $self->upload($in);

		} elsif ( $action eq 'uploadAudio' ) {
			return $self->uploadAudio($in);

		} elsif ( $action eq 'uploadImage' ) {
			return $self->uploadImage($in);

		} elsif ( $action eq 'uploadSWFImage' ) {
			return $self->uploadSWFImage($in);

		} elsif ( $action eq 'openFBsession' ) {
			return $self->openFBsession($in);

		} elsif ( $action eq 'find' ) {
			return $self->find($in);

		} elsif ( $action eq 'addVideo' ) {
			return "unauthorised" if (!Wywrota->per('mod', 7));
			return $self->addVideo($in);

		} elsif ( $action eq 'addChords' ) {
			return "unauthorised" if (!Wywrota->per('mod', 7));
			return $self->addChords($in);

		} elsif ( $in->{rating} and $in->{id} and $in->{cid} ) {
			return $self->vote($in);

		} elsif (  $action eq 'setUserPhoto' and $in->{id}) {
			return "unauthorised" if (!$Wywrota::session->{user}{id});
			return $self->setUserPhoto($nut);

		} elsif (  $action eq 'xspf') {
			return $self->xspf($nut);

		} else {
			Wywrota->debug($in);
			return "klops.";
		}
	};
	return "ERROR ".$@ if ($@);
	
	return $output;
	
}


sub processRequestNut {
#-----------------------------------------------------------------------

	my $nut = shift;
	my ($ok, $output);


	eval {
	$output =  Wywrota->template->HTTPheader(1);
	$output =  $instance->main($nut);
	};
	utf8_off($output);

#	Wywrota->onRequestEnd();

	Wywrota->error($@) if ($@);
	return $output;


}


sub getObject {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	my $output = "";

	eval {
		my $object = Wywrota->content->getObject($in->{id},  Wywrota->cc->{$in->{cid}}{package} );
		
		if (!$object) {
			$output = "Object not found."
		} elsif ($in->{small}) {
			$output = $object->preProcess->recordSmall;
		} elsif ($in->{big}) {
			$output = $object->preProcess->recordBig;
		} else {
			$output = $object->preProcess->record;
		}
	};

	return $output.$@;

}


sub upload {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	
	return Dumper($in);

}

sub uploadAudio {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;

	my $fileName = Wywrota->file->fileUpload($Wywrota::in->{'file'}, 'wav');


	return "$fileName";
}


sub uploadImage {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	my ($status, $object);

	# save the object
	$object = Wywrota->content->createObject($in, 'SiteImages');
	($status, $object) = Wywrota->content->addObject($object);

	return $object->id;

}

sub openFBsession {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;

	my $fbUser = from_json($in->{content});
	_utf8_off($fbUser);
	
	return "openFBsession" . Dumper($fbUser);
	
}


sub uploadSWFImage {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	my ($status, $object);

	$in->{nazwa_pliku} = $in->{Filedata};
	$in->{opis} = $in->{Filename};
	$in->{user_id} = $Wywrota::session->{user}{id};
	$in->{typ} = $in->{typ} || 1;

	# save the object
	$object = Wywrota->content->createObject($in, 'SiteImages');
	($status, $object) = Wywrota->content->addObject($object);

	if ($status eq 'ok') {
		return "FILEID:".$object->rec->{nazwa_pliku};
	} else {
		return "ERROR: $status";
	}

}

sub vote {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	
	return Wywrota->vote->rateIt($in);

}

sub addComment {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	
	_utf8_off($in); 
	return Wywrota->mng('Comment')->addComment($in);

}

sub closeMsg {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	
	return "";

}

sub quickAnswer {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	my ($status, $object);

	$in->{tresc_} = $in->{txt_txt};
	$in->{user_id} = $Wywrota::session->{user}{id};

	# save the object
	$object = Wywrota->content->createObject($in, 'ForumPost');
	($status, $object) = Wywrota->content->addObject($object);

	if ($status eq 'ok') {
		return $object->record();
	} else { 
		return $status;
	};


}



sub joinSoc {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = shift;
	my $cid = shift;
	my $flag = shift;
	
	if ($flag) {
		Wywrota->fav->remove($id, 0, $cid);
		return msg('join', $cid);
	} else {
		Wywrota->fav->add($id, 0, $cid);
		return msg('leave', $cid);
	}

}


sub readMessage {
# --------------------------------------------------------
# 
	my $self = shift;
	Wywrota::UserSettings::storeSettings();
	return "";
}


sub distinction {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;

	my $object = Wywrota->content->getObject($in->{id}, 
			Wywrota->cc->{$in->{cid}}{'package'});
	$object->preProcess();

	return Wywrota->content->quickDistinction($object, $in->{state});

}

sub moderate {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;

	my $object = Wywrota->content->getObject($in->{id}, 
			Wywrota->cc->{$in->{cid}}{'package'});

	return Wywrota->content->quickModerate($object, $in->{state}, $in->{recommend});

}


sub deleteRec {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = shift;
	my $cid = shift;

	Wywrota->content->dao->deleteObject($id, $cid);
	Wywrota->content->mng($cid)->onObjectDelete($id);

	return "";
}

sub watch {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = shift;
	my $cid = shift;
	
	# store notification settings
	Wywrota::Notification::storeRecordNotificationData(
		$id,  $cid,  $Wywrota::session->{user}{id},  ($Wywrota::in->{notifyFlag}) ? (1) : (0) );

	if ($Wywrota::in->{notifyFlag}) {
		return msg('started_tracking');
		#return msg('stop_tracking_comments', $cid);
	} else {
		return msg('stopped_tracking'); 
		#return msg('track_comments', $cid);
	}
	
}

sub addToFav {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = shift;
	my $set_id = shift;
	my $cid = shift;
	
	if ( Wywrota->fav->add($id, $set_id, $cid) ) {
		return msg('already_in_favorites', $cid);
	};

	return;
}

sub removeFav {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = shift;
	my $set_id = shift;
	my $cid = shift;
	
	Wywrota->fav->remove($id, $set_id, $cid);

	return;
}

sub checkWywrotID {
# --------------------------------------------------------
# 
	my $self = shift;
	my $wywrotid = shift;
	my $exists = Wywrota->db->selectCount("ludzie", "wywrotid=".Wywrota->db->quote($wywrotid)." AND _active=1");
	if ($exists) {
		return 1;		
	} else {
		return 0; 
	}

}

sub find {
# --------------------------------------------------------
	my $self = shift;
	my $in = shift;

	my $queryRes = Wywrota->cListEngine->query($in);

	return $queryRes->hitsJSON();

}



sub addChords {
# --------------------------------------------------------
	my $self = shift;
	my $in = shift;
	
	Wywrota->db->execWriteQuery("UPDATE spiewnik SET chords = ? WHERE id= ?", $in->{chords}, $in->{id});
	Wywrota::Log::log(7, $in->{id}, 31);

	return msg('chords_added');
}


sub addVideo {
# --------------------------------------------------------
	my $self = shift;
	my $in = shift;

	Wywrota->db->execWriteQuery("UPDATE spiewnik SET youtube = ? WHERE id= ?", $in->{youtube}, $in->{id});
	Wywrota::Log::log(7, $in->{id}, 32);
	
	return msg('video_added');
}




sub setUserPhoto {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $in = $nut->in;

	my ($filename) = Wywrota->db->quickArray("SELECT nazwa_pliku FROM site_images WHERE id=$in->{id}");

	if (length($filename)) {
		Wywrota->db->execWriteQuery("UPDATE ludzie SET _image_filename=?, _image_id=? WHERE id=?", $filename, $in->{id}, $Wywrota::session->{user}{id});
		return msg('def_photo_changed');
	} else {
		return msg('def_photo_not_changed');
	}

}

sub xspf {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $in = $nut->in;



	my $queryRes = Wywrota->cListEngine->query($nut->in);
	return if ($queryRes->{status} ne "ok");

	#eval {

	use XML::XSPF;
	use XML::XSPF::Track;

	my $xspf  = XML::XSPF->new();
	my ($track, @tracks, $object, $rec, $output);

	$xspf->title($nut->request->{content}{current}{title}." - $config{'site_name'}");
	$xspf->location($config{'site_url'});
	$xspf->creator($config{'generator'});

	#		'identifier' => 1,
	#		'image'      => 1,
	#		'info'       => 1,
	#		'license'    => 1,
	#		'link'       => 1,
	#		'location'   => 1,
	#		'meta'       => 1,

		for (0 .. $#{$queryRes->{hits}}) {
			$object = Wywrota->content->getObject($queryRes->{hits}[$_]->{id});
			$object->preProcess();
			$rec = $object->rec;

			$track = XML::XSPF::Track->new;
			#		'identifier' => 1,
			#		'image'      => 1,
			#		'info'       => 1,
			#		'link'       => 1,
			#		'location'   => 1,
			#		'meta'       => 1,
			$track->title( ($rec->{tytul} || $rec->{podpis}) ." - ".$rec->{ludzie_imie}  );
			$track->location($rec->{url_image}."/get.jpg");
			$track->trace($rec->{url});

			push @tracks, $track;

		}

	$xspf->trackList(@tracks);

	$output = $xspf->toString;	
	$output = HTML::Entities::decode($output);
	return $output;
	#};

}


1;
