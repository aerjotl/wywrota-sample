package Wywrota::Object::Manager::UserManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Object::HashConfirm;
use Wywrota::QueryRes;
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';



sub action {
# -------------------------------------------------------------------------------------
	my ($output, $object );
	my $self = shift;
	my $nut = shift;
	my $action = $nut->in->{a} || $nut->in->{action};
	
	if ($action eq 'photos') { 
		
		$object = $self->getByWywrotid( $nut->in->{wywrotid} );
		$output = Wywrota::Object::View::UserView->viewPhotos($object);
		
	} 
		
	else { 
		$output = Wywrota->unknownAction($action);
	}

	
	return $output;
}


sub getByWywrotid {
# --------------------------------------------------------
	my $self = shift;
	my $wywrotid = shift;
	my ($object, $queryRes);
	eval {
		$queryRes = Wywrota->cListEngine->query({
			wywrotid =>$wywrotid, 
			ww => 1, 
			db=>'ludzie'}
		);
		
		if ($queryRes->status eq "ok") {
			$object = Wywrota->content->createObject(@{$queryRes->hits}[0]);
		}
	};
	Wywrota->error($@) if ($@);
	return $object;
}


sub storeProfileData {
# --------------------------------------------------------
	my $self = shift;
	my $id = shift;
	my ($key, $qstring);

	foreach $key (keys %{$Wywrota::in}) {
		next if (!$Wywrota::in->{$key});
		if ($key =~ /^profile_(.*)$/) {
			$key=$1;
			$qstring .= " (".Wywrota->db->quote($key) . ",". 
				Wywrota->db->quote($Wywrota::in->{'profile_'.$key}) .", ".
				Wywrota->db->quote($id) . "),";
		}
	};

	chop $qstring;
	if ($qstring) {
		Wywrota->db->execWriteQuery("DELETE FROM `user_profile_field` WHERE user_id=?", $id);
		Wywrota->db->execWriteQuery("INSERT INTO `user_profile_field` (label, value, user_id) VALUES $qstring");
	}

	return $self;
}


sub onObjectAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;

	eval {
	
#	$self->storeProfileData( $object->rec->{id} );
	$self->sendNewAccountEmail( $object );

	Wywrota::Notification::setDefaultNotificationData( $object->id );

	};
	Wywrota->error("UserManager : onObjectAdd", $@) if ($@);

}



sub sendNewAccountEmail {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my ($hashObject);

	eval {

		$hashObject = Wywrota->content->createObject( {user_id => $object->id}, 'HashConfirm' );
		Wywrota->content->persist($hashObject);

		Wywrota::EMail::sendEmail({
			to			=> $object,
			subject		=> "Witamy w serwisie www.Wywrota.pl!",
			style		=> 'new_account',
			hashlink	=> $config{site_url}."/user/verify/id/".$hashObject->hash
		});

	};
	Wywrota->error("UserManager : sendNewAccountEmail", $@) if ($@);


}



sub sendSuicideEmail {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my ($hashObject);

	Wywrota->debug("sendSuicideEmail", $object->rec->{id});

	eval {
	
		
		$hashObject = Wywrota->content->createObject( {user_id => $object->rec->{id}}, 'HashConfirm' );
		Wywrota->content->persist($hashObject);
		
		Wywrota::EMail::sendEmail({
			to			=> $object,
			subject		=> "Wywrota.pl - usunięcie konta",
			style		=> 'suicide_confirm',
			hashlink	=> $config{site_url}."/user/removeAccount/id/".$hashObject->hash
		});
	
	};
	Wywrota->error("UserManager : sendSuicideEmail", $@) if ($@);


}



sub removeAccountAction {
# --------------------------------------------------------
	my ($output);
	my $id = shift;

	Wywrota::Log::log(6, $id, 8);

	Wywrota->db->execWriteQuery("UPDATE teksty SET _active=0 WHERE user_id=$id");
#	Wywrota->db->execWriteQuery("UPDATE article SET _active=0 WHERE user_id=$id");
	Wywrota->db->execWriteQuery("UPDATE image SET _active=0 WHERE user_id=$id");
	Wywrota->db->execWriteQuery("UPDATE mp3 SET _active=0 WHERE user_id=$id");
	Wywrota->db->execWriteQuery("UPDATE ludzie SET _active=0 WHERE id=$id");
	Wywrota->db->execWriteQuery("DELETE FROM session WHERE userid=$id");

}

sub verifyUserAccount {
# --------------------------------------------------------
	my $self=shift;
	my $id = shift;
	Wywrota->db->execWriteQuery("UPDATE ludzie SET verified=1 WHERE id=?", $id);
}


sub onAddToFavorites {
# --------------------------------------------------------
	my $self=shift;
	Wywrota::Notification::notifyOnAddToFriendList(shift);
}

sub onObjectDelete {
# --------------------------------------------------------
	my $self=shift;
	removeAccountAction(shift);
}


1;