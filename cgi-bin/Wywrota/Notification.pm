package Wywrota::Notification;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

# notification for given entries
#
# [notification_record]
# content_id | record_id | user_id | status (0/1) | date_updated

# general notification settings
#
# [notification_type]
# id | name | default
#
# [notification]
# notification_id | user_id | status (0/1) | date_updated

#-----------------------------------------------------------------------

use strict;
use Data::Dumper; 
use Exporter; 
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::EMail;
use Wywrota::Utils;
use Wywrota::Language;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	storeForNotification notifyNewCommment notifyNewForumPost notifyOnAuthorize
	storeNotificationData readNotificationData showForm isWatchingPost isWatchingComments
	);


sub storeForNotification {
#-----------------------------------------------------------------------
# stores a record id in the temporary table to be processed by cron script
# storeForNotification(
#	subscription_id, subscription_cid	- record for which users has subscription (text, forum group, band, ...)
#	notification_type_id				- type of notification 
#	user_id								- user_id - user performing an action
#	notifyrecord_id, notify_cid			- record which was added (if different than id+cid)
#  )

	my ($query, $notif_type_id, $author_user_id, $status, @user_ids);
	my $subscription_id = shift;
	my $subscription_cid = shift;
	my $notification_type_id = shift || (100+int($subscription_cid));
	my $user_id = shift || $Wywrota::session->{user}{id};
	my $notifyrecord_id = shift || $subscription_id;
	my $notify_cid = shift || $subscription_cid;


	return if (!$subscription_id);


	# send message to record author (except forum and forum category)
	if ($notification_type_id != 300 and $notification_type_id != 310) {
		$notif_type_id = 100+int($subscription_cid);
		($author_user_id) = Wywrota->db->quickArray("SELECT user_id FROM ".Wywrota->cc->{$subscription_cid}{tablename}." WHERE id=$subscription_id");

		($status) = Wywrota->db->quickArray("SELECT DISTINCT status FROM notification WHERE user_id=? AND notification_type_id=? ", $author_user_id, $notif_type_id); 

		push(@user_ids, $author_user_id) if ($status);

	}


	# people that requested notification on this particular record
	$query = qq~
		SELECT DISTINCT nr.user_id
		FROM 
			notification_record nr
			RIGHT JOIN notification n on nr.user_id=n.user_id 
			RIGHT JOIN ludzie l on nr.user_id=l.id
		WHERE 
			nr.record_id = $subscription_id 
			AND nr.content_id=$subscription_cid
			AND nr.status=1 
			AND n.notification_type_id=$notification_type_id 
			AND n.status=1 
			AND l._active = 1
	~; 
	$query .= qq~AND nr.user_id<>$author_user_id~ if ($notification_type_id != 300 and $notification_type_id != 310);

	push(@user_ids, Wywrota->db->buildArray($query) ); 


	# we have the list of users so put it into the table

	my $insertCount = 0;
	if ($#user_ids>-1) {
		$query = qq~INSERT INTO `notification_send` (record_id, content_id, user_id, notify_user_id) VALUES ~;
		foreach (@user_ids) {
			next if ($_ eq $Wywrota::session->{user}{id});		# do not send notification about my own comments
			$query .= "($notifyrecord_id, $notify_cid, $user_id, $_),";
			$insertCount ++;
		}
		chop($query);
		Wywrota->db->execWriteQuery($query)if ($insertCount);
	}
	
}


sub notifyOnAddToFriendList {
# --------------------------------------------------------
	my ($msgBody, $isAccepting, $settings);
	my $friend_id=shift; 


	# check if he is answering to the other's invitation. 
	# if so - do not send email to the first one
	($isAccepting) = Wywrota->db->quickArray(
		"SELECT user_id FROM favorites WHERE user_id=? AND record_id=? AND content_id=?" ,
		$friend_id, $Wywrota::session->{user}{id}, $Wywrota::request->{content}{current}{id} );
		
	if ($isAccepting) {
		return;
	}


	my $friendRec = Wywrota->content->getObject($friend_id, 'User');
	my $senderObj = Wywrota->content->getObject($Wywrota::session->{user}{id}, 'User');

	$settings = Wywrota::UserSettings::readSettings($friend_id);

	if ($settings->{1} == 2 and length($$friendRec{gg})) {

		# send gg notification 

		$msgBody = qq~Cześć $friendRec->{imie}!\n$Wywrota::session->{user}{name} ($config{'site_url'}/db/ludzie/$Wywrota::session->{user}{id}) dodał(a) Cię do listy znajomych.\nJeżeli znasz tę osobę kliknij tutaj $config{'site_url'}/db/ludzie/favorites/add/id/$Wywrota::session->{user}{id} aby pojawiła się ona również na Twojej liście znajomych.~;
		$msgBody = Wywrota->db->quote( $msgBody );

		Wywrota->db->execWriteQuery(qq~
			INSERT INTO `notification_send` (record_id, content_id, user_id, notify_user_id, custom_msg) 
			VALUES ($friend_id, ~. $Wywrota::request->{content}{current}{id} . qq~, $Wywrota::session->{user}{id}, $friend_id, $msgBody)
			~); 

	} else {

		Wywrota::EMail::sendEmail({
			from	=> $senderObj,
			to		=> $friendRec,
			subject	=> "Powiadomienie z serwisu Wywrota.pl",
			style	=> 'add_to_friendlist',
		});


	}

}



sub notifyOnDistinction {
# --------------------------------------------------------
	my $object = shift;
	my $state = shift;
	
	my $user = Wywrota->content->getObject($object->user_id, 'User');
	
	Wywrota::EMail::sendEmail({
		to		=> $user,
		subject	=> $object->toString,
		style	=> 'distinction',
		object	=> $object,
		state	=> $state
	});	
	
}



sub notifyOnAuthorize {
# --------------------------------------------------------
	my $user_id = shift;
	my $prev_state = shift;
	my $new_state = shift;
	my $rec = shift;

	my ($msgBody, $title, $setting, $your_item, $settings);

	my $recipient;

	# skip for spiewnik
	return if ( $Wywrota::request->{content}{current}{id} == 7) ;


	if ($prev_state != $new_state) {

		$setting = Wywrota->db->quickHashRef("SELECT status FROM notification WHERE user_id=$user_id AND notification_type_id=10");
		if (!$setting->{status}) {
			# does not want notification
			return;
		}

		my $recipient = Wywrota->content->getObject($user_id, 'User');

		$title = $rec->{tytul} || $rec->{title} || $rec->{podpis};
		$your_item = msg('your_item');

		if ($new_state == 2) {
			$msgBody = qq~
				<p>$your_item zatytułowany "$title" przeszedł autoryzację i został opublikowany. Gratulujemy!
			~;
		}
		if ($new_state == 3) {
			$msgBody = qq~
				<p>$your_item zatytułowany "$title" nie został wybrany do publikacji. Życzymy szczęscia następnym razem.
			~;
		}

		$settings = Wywrota::UserSettings::readSettings($user_id);

		if ($settings->{1} == 2) {

			# send gg notification 

			$msgBody = Wywrota->db->quote(dehtml($msgBody) );

			Wywrota->db->execWriteQuery(qq~
				INSERT INTO `notification_send` (record_id, content_id, user_id, notify_user_id, custom_msg) 
				VALUES ($rec->{id}, ~. $Wywrota::request->{content}{current}{id} . qq~, $Wywrota::session->{user}{id},  $user_id, $msgBody)
				~); 

		} else {

			Wywrota::EMail::sendEmail({
				to		=> $recipient,
				subject	=> "Powiadomienie o autoryzacji - Wywrota.pl",
				body	=> $msgBody,
				style	=> 'notification',
			});	

		}

	}

}




sub isWatchingComments {
# --------------------------------------------------------
# is a user watching comments on this item?

	my ($query, $is);
	my $id = shift;
	my $cid = shift || $Wywrota::request->{content}{current}{id};
	my $user_id = shift || $Wywrota::session->{user}{id};

	return 0 if (!$id || !$cid || !$user_id);

	$query = qq~
		SELECT count(status)
		FROM 
			notification_record nr
		WHERE 
			record_id = $id AND status=1 AND content_id=$cid AND user_id=$user_id
		GROUP BY user_id
	~; 
	($is) = Wywrota->db->quickArray($query); 
	return ($is) ? 1 : 0;
}



sub showForm {
# --------------------------------------------------------
# Show notofication form
	my ($output, $types, $settings, $notifyBy, $checked, $type, $ids );

	$settings = readNotificationData($Wywrota::session->{user}{id});
	$types = Wywrota->db->buildHashRef("SELECT id, name FROM notification_type ORDER BY id");

	$output .= qq~
		<h3>Chcę otrzymywać powiadomienia:</h3>

		<div class="notifications">
	~;
	foreach $type (keys %{$types}) {
		$checked = ($settings->{$type}) ? (' checked="checked"') : ('');
		$ids .= "$type,";
		$output .= qq~
			<div>
				<input type="checkbox" name="type$type" id="type$type" value="1"$checked>
				<label for="type$type">$types->{$type}</label>
			</div>
		~;
	}
	chop($ids);
	$output .= qq~
		</div>
		<input type="hidden" name="notification_ids" value="$ids">
	~;

	return $output;
}




sub setDefaultNotificationData {
# --------------------------------------------------------
	my $user_id = shift;

	Wywrota->db->execWriteQuery("DELETE FROM notification WHERE user_id=$user_id"); 
	Wywrota->db->execWriteQuery("INSERT INTO notification (notification_type_id, user_id) SELECT id, $user_id FROM notification_type"); 

	return "Zapisano ustawienia powiadomień";
}



sub storeNotificationData {
# --------------------------------------------------------
	my $user_id = shift;
	my ($query, $id, $status);

	return -1 if (!$user_id);

	Wywrota->db->execWriteQuery("DELETE FROM notification WHERE user_id=$user_id"); 

	foreach $id ( split(",", $Wywrota::in->{notification_ids}) ) {
		$status = ($Wywrota::in->{"type".$id}) ? (1) : (0);

		$query = qq~INSERT INTO notification
			(notification_type_id, status, user_id) VALUES ($id, $status, $user_id);
		~;
		Wywrota->db->execWriteQuery($query); 
	}
	return "Zapisano ustawienia powiadomień";
}


sub readNotificationData {
# --------------------------------------------------------
	my $user_id = shift;
	my ($data);
	if ($user_id > 0) {
		$data = Wywrota->db->buildHashRef("SELECT notification_type_id, status FROM notification WHERE user_id=$user_id");
	}

	return $data;
}

sub storeRecordNotificationData {
# --------------------------------------------------------
	my ($notifyCond, $notifyFlag, $prevSetting);
	my $id = shift;
	my $cid = shift;
	my $uid = shift;
	my $flag = shift;

	return -1 if !($id and $cid and $uid);

	$notifyCond = "content_id = $cid AND record_id = $id AND user_id = $uid";
	$prevSetting = Wywrota->db->quickHashRef("SELECT record_id, status FROM notification_record WHERE $notifyCond");
	if (defined $prevSetting->{status}) {
		Wywrota->db->execWriteQuery("UPDATE notification_record SET status=$flag, date_updated = NOW() WHERE $notifyCond");
	} else {
		Wywrota->db->execWriteQuery("INSERT INTO notification_record VALUES ($cid, $id, $uid, $flag, NOW() )");
	}
}


sub getSubscribeButton {
# --------------------------------------------------------
	my $id = shift;
	my $cid = shift;

	return Wywrota->t->process('inc/subscribe_button.inc', {
		id				=>	$id,
		cid				=>	$cid,
		flag			=>	isWatchingComments($id, $cid)
	});

	
}