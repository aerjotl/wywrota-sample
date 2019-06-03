package Wywrota::Object::Manager::CommentManager;

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
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Object::BaseObject;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';

sub getComments {
# --------------------------------------------------------
	my $self = shift;
	my $object=shift;
	my $rec = $object->rec;
	my ($condition, $cnt, $query, $limit);
	my $queryRes = Wywrota::QueryRes->new( { 
		in			=>	{
							record_id=>$object->id, 
							content_id=>$object->cid, 
							mh=>$config{'no_of_comments'}
						},
		contentDef	=>	Wywrota->cc('Comment')
	});

	$Wywrota::request->{commentedObject}=$object;

	
	$condition = "rec._active=1 AND record_id= " .$object->id . " AND content_id=".$object->cid ;

	$cnt = Wywrota->db->selectCount("komentarze", $condition);

	if ($config{'no_of_comments'} < $cnt) {
		$limit = " LIMIT " . ($cnt-$config{'no_of_comments'}) . "," . $config{'no_of_comments'}. " ";
	}

	$query = qq~
		SELECT rec.*, ludzie.imie AS ludzie_imie, ludzie.wywrotid, ludzie._image_filename as _ludzie_photo, ludzie._grupy as _user_to_ugroup, ludzie._is_premium 
		FROM komentarze rec
		LEFT JOIN ludzie ON rec.user_id=ludzie.id 
		WHERE $condition ORDER BY rec.data 
		$limit 
		~;

	if ($cnt) {
		$queryRes->fromQuery($query, $cnt);
	}
	
	return $queryRes;

}

sub getDeletedCommentsCount {
# --------------------------------------------------------
	my $self = shift;
	my $object=shift;
	my $condition = "rec._active=0 AND record_id= " .$object->id . " AND content_id=".$object->cid ;

	return Wywrota->db->selectCount("komentarze", $condition);

}



sub addComment {
# --------------------------------------------------------
	my $self = shift;
	my $in = shift;
	my ($output, $rec, $sql, $msg, $object);

	if (!$Wywrota::session->{user}{id}){
		eval {
			my $captcha = Captcha::reCAPTCHA->new;
			my $result = $captcha->check_answer_v2(
				$config{recaptcha_private_key}, 
				$Wywrota::in->{'g-recaptcha-response'},
				$ENV{'REMOTE_ADDR'}
			);

			unless ( $result->{is_valid} ) {
				$msg = "Błędny kod zabezpieczający ".$result->{error};
			}
		};
	
	}; 
	
	if (!$in->{txt_txt}) {
		$msg = "Brak komentarza";
	};
	
	if (($in->{txt_txt} eq "" and !$in->{stan}) or $in->{txt_txt} =~ /<a/ or $in->{txt_txt} =~ /\[url/) {
		$msg = "wystąpił błąd podczas dodawania komentarza<br>użyto niedozwolonych znaczników HTML lub podano adresy stron www.<br>W razie pytań <a href='/kontakt.html'>skontaktuj się</a> z nami.";
	} 
	
	if ($in->{url} ne $config{'robot_protection'}) {
		$msg = "robot intrusion detected<br><br>w razie problemów skontaktuj się z administratorem";
	} 
	
	


	if (!$msg) {
		$object = Wywrota->content->createObject({
			content_id=>$in->{cid}, 
			komentarz=>$in->{txt_txt}, 
			record_id=>$in->{id}, 
			user_id=>$Wywrota::session->{user}{id},
			autor=>$in->{podpis}, 
			}, 'Comment');

		$object = Wywrota->content->addObject($object);

		# store user's notification settings
		Wywrota::Notification::storeRecordNotificationData(
			$in->{id},  $in->{cid},  $Wywrota::session->{user}{id},  1	) if ($in->{notifyFlag});

		# store for notification 
		Wywrota::Notification::storeForNotification($in->{id}, $in->{cid}, 200); 

		return $object->record;			
	} else {
		return qq~<div class="div_msg_err clr">$msg</div>~;
	}

}


1;