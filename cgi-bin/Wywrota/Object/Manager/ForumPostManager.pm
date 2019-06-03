package Wywrota::Object::Manager::ForumPostManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

#use strict;
use Data::Dumper;
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';
	

sub action {
# -------------------------------------------------------------------------------------
	my $output;
	my $self = shift;
	my $nut = shift;
	my $action = $nut->in->{a} || $nut->in->{action};
	
	if    ($action eq 'recentTopics')   { 
		$output = Wywrota->view->view->getRecentTopicsHtml($Wywrota::in->{kat_id}, $Wywrota::in->{wykonawca_id}, $Wywrota::in->{limit});
	}		
	elsif    ($action eq 'recentTopicList')   { 
		$output = Wywrota->view->view->getRecentTopicListHtml($Wywrota::in->{kat_id}, $Wywrota::in->{wykonawca_id}, $Wywrota::in->{limit});
	}		
	
	else { 
		$output = Wywrota->unknownAction($action);
	}

	
	return $output;
}


sub getRecentTopics {
# --------------------------------------------------------
	my $self = shift;
	my ($topics, $query);
	my $kat_id = shift;
	my $wykonawca_id = shift;
	my $limit = shift || 5;


#		~. $self->getSqlAddFields() . qq~
#		~. $self->getSqlAddJoin() . qq~

	eval {
	$query = qq~
		SELECT rec.id, rec.child_count, rec.temat 
			, fp2.time as lc_time, l2.imie as lc_author, l2.wywrotid as lc_wywrotid
		FROM forum_posty rec	
			LEFT JOIN forum_posty fp2 on rec.last_child_id=fp2.id LEFT JOIN ludzie l2 on fp2.user_id = l2.id	
		WHERE rec.topic=1 
	~ ;
	$query .= qq~ AND rec.kat_id=$kat_id ~ if ($kat_id);
	$query .= qq~ AND rec.wykonawca_id=$wykonawca_id ~ if ($wykonawca_id);
	$query .= qq~ ORDER BY lc_time DESC		LIMIT $limit ~;

	$topics = Wywrota->db->buildHashRefArrayRef($query); 
	};
	Wywrota->error($@) if ($@);
	return $topics;

}



sub landingPage {
# --------------------------------------------------------
	my $forum_id = $Wywrota::in->{'forum_id'} || 1;
	return Wywrota::Controller::includePage("db=group&stan=1&typ=1&sb=pozycja&forum_id=$forum_id");
}



sub onObjectAdd {
# --------------------------------------------------------
	my ($count, $recParent);
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $table = $object->config->{tablename};

	# update category child count
	if ($rec->{kat_id}) {
		Wywrota->db->execWriteQuery("UPDATE forum_kategorie SET last_child_id = $rec->{id}, child_count = (SELECT COUNT(id) FROM $table WHERE kat_id=$rec->{kat_id}) WHERE id=$rec->{kat_id}"); 
	}

	# update parent post last child id and child count
	if ($rec->{parent_id}) {
		$count = Wywrota->db->selectCount($table, "parent_id=$rec->{parent_id}");
		Wywrota->db->execWriteQuery("UPDATE $table SET last_child_id = $rec->{id}, child_count = $count WHERE id=$rec->{parent_id} OR parent_id=$rec->{parent_id}"); 
	} else {
		$rec->{parent_id} = $rec->{id};
		Wywrota->db->execWriteQuery("UPDATE $table SET last_child_id = $rec->{id}, parent_id=$rec->{id} WHERE id=$rec->{id}"); 
	}


	# store user's notification settings
	Wywrota::Notification::storeRecordNotificationData(
		$rec->{parent_id}, 
		$Wywrota::request->{content}{current}{id}, 
		$Wywrota::session->{user}{id}, 
		1
	)  if ($Wywrota::in->{notifyFlag});;

	
	# notify users that requested topic notification
	# subscribed to parent_id on content forum (13) (notification_type_id =300)
	Wywrota::Notification::storeForNotification($Wywrota::in->{parent_id}, 13, 300);


	#  a new thread is started...
	if ($rec->{parent_id} == $rec->{id}) {
		# notify users subscribed to CATEGORY (12)
		# that requested forum notification (notification_type_id =310)
		Wywrota::Notification::storeForNotification($rec->{kat_id}, 12, 310, undef, $rec->{id}, 13);

		# notify users subscribed to WYKONAWCA (15)
		# that requested forum notification (notification_type_id =310)
		Wywrota::Notification::storeForNotification($rec->{wykonawca_id}, 15, 310, undef, $rec->{id}, 13) if ($rec->{wykonawca_id} );
	}

}



sub initContentTemplate {
# --------------------------------------------------------
	my $self = shift;
	my $nut=shift;
	my ($cats, $forum_id, $catLink);

	#return if (!$pageCat);

	Wywrota->debug("ForumPostManager : initContentTemplate");
	eval {

		if ($Wywrota::in->{kat_id}) {
			$nut->request->{pageCat} = Wywrota->content->getObject($Wywrota::in->{kat_id}, 'ForumGroup')->preProcess();
		} 
		if ($Wywrota::in->{parent_id}) {
			$nut->request->{pageTopicPost} = Wywrota->content->getObject($Wywrota::in->{parent_id})->preProcess();
			$nut->request->{pageCat} = Wywrota->content->getObject($nut->request->{pageTopicPost}{rec}{kat_id}, 'ForumGroup')->preProcess();
		}

		if (!$Wywrota::in->{generate}) {
			$catLink->{text} = $nut->request->{pageCat}{rec}{tytul};
			$catLink->{url} = $nut->request->{pageCat}{rec}{url};
			push(@{$nut->request->{nav}{crumbLinks}}, $catLink);
		}

	};
	
	Wywrota->error("error in ForumPostManager : initContentTemplate") if ($@);
		
	return;

	if ($pageCat->rec->{id}==5) {
		$nut->request->{content}{current}{page_id} = 200;
		$nut->request->{content}{current}{style} = "fanklub.css";
	} else {
		Wywrota::Object::Manager::ForumGroupManager->addSubCats($max_page_id, $pageCat);
	}

}


sub getSqlAddFields {
#-----------------------------------------------------------------------
	return ", fp2.time as lc_time, l2.imie as lc_author, l2.wywrotid as lc_wywrotid";
}

sub getSqlAddJoin {
#-----------------------------------------------------------------------
	return " LEFT JOIN forum_posty fp2 on rec.last_child_id=fp2.id LEFT JOIN ludzie l2 on fp2.user_id = l2.id";
}



1;