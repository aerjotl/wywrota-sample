package Wywrota::Object::Manager::ForumGroupManager;

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
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';

sub landingPage {
# --------------------------------------------------------
	my $forum_id = $Wywrota::in->{'forum_id'} || 1;
	return Wywrota->content->includeFile("group/index.html");

}


sub onObjectAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;

	# subscribe ty my category
	if ($rec->{typ}==2) {
		Wywrota->fav->add($rec->{id});
	}
	$self->onObjectEdit($object);

}

sub onObjectEdit {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my ($list , @uids, $cid, $id);

	$cid = $object->cid;
	$id = $object->rec->{id};

	if ($id and $cid and $Wywrota::in->{selected_users}) {
		Wywrota->db->execWriteQuery("DELETE FROM `favorites` WHERE  content_id=$cid AND record_id=$id AND set_id=0");

		@uids = split(/,/, $Wywrota::in->{selected_users});
		foreach (@uids) { 
			Wywrota->fav->add($id, 0, $cid, $_);
		}
		chop $list;


	}

}



sub initContentTemplate {
# --------------------------------------------------------

	my $self=shift;
	my $nut=shift;
	my $link;
	eval {

	if ($Wywrota::in->{view}) {
		$nut->request->{pageCat} = Wywrota->content->getObject($Wywrota::in->{view}, 'ForumGroup');
		$nut->request->{pageCat} = $nut->request->{pageCat}->preProcess() if $nut->request->{pageCat};	
	} 
	if (!$Wywrota::in->{generate}) {
		$link->{text} = $nut->request->{pageCat}{rec}{tytul};
		$link->{url} = $nut->request->{pageCat}{rec}{url};
		push(@{$nut->request->{nav}{crumbLinks}}, $link);
	}

	if ($Wywrota::in->{kat_id}==5) {
		$nut->request->{content}{current}{page_id} = 200;
		$nut->request->{content}{current}{style} = 'spiewnik';
	}	

	};
	Wywrota->error("initContentTemplate".$@) if ($@);


	#$self->addSubCats($max_page_id, $pageCat);

}


sub addSubCats {
# --------------------------------------------------------
	my $self=shift;
	my $max_page_id = shift;
	my $pageCat = shift;
	my ($cats, $parent, $key, $forum_id);

	$forum_id = $Wywrota::in->{'forum_id'} || 1;
	$cats = Wywrota->db->buildHashRef("SELECT id, tytul FROM forum_kategorie WHERE parent_id=0 AND stan=1 AND forum_id=$forum_id AND typ=1 ORDER BY pozycja");

	$parent = $Wywrota::request->{content}{current}{page_id};
	foreach $key (keys %{$cats}) {
		$max_page_id++;

		Wywrota->page->{$max_page_id}{parent_id}=$parent;
		Wywrota->page->{$max_page_id}{id}=$max_page_id;
		Wywrota->page->{$max_page_id}{url}="/group/$key.html";
		Wywrota->page->{$max_page_id}{title}=$cats->{$key};
		Wywrota->page->{$max_page_id}{short_title}=$cats->{$key};

		if ($pageCat && $pageCat->rec->{id} == $key) {
			$Wywrota::request->{content}{current}{page_id}=$max_page_id;
			$Wywrota::request->{content}{current}{page}=Wywrota->page->{$max_page_id};
		}

	}

	# for societies

	if ($pageCat && $pageCat->rec->{typ}==2) {
		$max_page_id++;

		Wywrota->page->{$max_page_id}{parent_id}=$parent;
		Wywrota->page->{$max_page_id}{id}=$max_page_id;
		Wywrota->page->{$max_page_id}{url}= "/group/$pageCat->{rec}->{id}.html";
		Wywrota->page->{$max_page_id}{title}= $pageCat->rec->{tytul};
		Wywrota->page->{$max_page_id}{short_title}= $pageCat->rec->{tytul};
		Wywrota->page->{$max_page_id}{sortorder}= 1;

		#if ($pageCat{id} == $key) {
			$Wywrota::request->{content}{current}{page_id}=$max_page_id;
			$Wywrota::request->{content}{current}{page}=Wywrota->page->{$max_page_id};
		#}
	}



}



sub onAddToFavorites {
# --------------------------------------------------------
	my $self = shift;
	my $id = shift;
	Wywrota->db->execWriteQuery(qq~
		INSERT INTO notification_record (content_id, record_id, user_id, status) 
		VALUES (12, $id, $Wywrota::session->{user}{id}, 1)
	~);
}

sub onRemoveFromFavorites  {
# --------------------------------------------------------
	my $self = shift;
	my $id = shift;
	Wywrota->db->execWriteQuery(qq~
		DELETE FROM notification_record WHERE 
		content_id=12 AND record_id=$id AND user_id= $Wywrota::session->{user}{id}
	~);
}



sub getSqlAddFields {
#-----------------------------------------------------------------------
	return ", fp2.time as lc_time, l2.imie  as lc_author,  fp2.parent_id as lc_parent_id,  fp2.child_count as lc_child_count, fp2.temat as lc_temat";
}

sub getSqlAddJoin {
#-----------------------------------------------------------------------
	return " LEFT JOIN forum_posty fp2 on rec.last_child_id=fp2.id LEFT JOIN ludzie l2 on fp2.user_id = l2.id";
}


1;