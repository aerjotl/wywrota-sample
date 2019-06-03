package Wywrota::Object::View::ForumGroupView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Language;



sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $output;
	my $queryRes = shift;
	my $tytul = shift;


	if (!$Wywrota::in->{parent_id} && !$Wywrota::in->{quiet}) {
		if ($Wywrota::in->{typ}==2) {
			$output = qq~<h1>Wspólnoty</h1>~;
			$output .= qq~<p><a href="/db/group/add/1/typ/2/parent_id/0/forum_id/$Wywrota::in->{forum_id}" class="arPlus"><b>załóż nową wspólnotę</b></a>~  if Wywrota->per('admin') ;
		} else {
			$output = qq~<h1>Forum Wywroty</h1>~;
			$output .= qq~<p><a href="/db/group/add/1/typ/1/parent_id/0/forum_id/$Wywrota::in->{forum_id}" class="arPlus"><b>załóż nowe forum</b></a>~  if Wywrota->per('admin') ;
		}

	}
		

	my $czego = ($Wywrota::in->{typ}==2) ? "członków" : "wpisów";
	$output .= qq~<p class="listPagination">$queryRes->{pagination}</p>~ if ($queryRes->{pagination});
	$output .= qq~
		<table class="forumCats">
			<tr>
				<th></th>
					<th>$czego:</th>
				<th>ostatni wpis:</th>
			</tr>
	~ if (!$Wywrota::in->{small});
	#$output .= $self->SUPER::searchHeader(@_);
	return $output;
}


sub searchFooter {
# --------------------------------------------------------
	my $self = shift;
	my $output;
	my $queryRes = shift;
	my $tytul = shift;

	$output = qq~
		</table>
	~if (!$Wywrota::in->{small});

	
	$output .= qq~<p class="listPagination">$queryRes->{pagination}</p>~ if ($queryRes->{pagination});
	
	return $output;
}

sub searchFooterGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $output = "";
	my $parent_id = int($queryRes->{in}{parent_id});

	if ($queryRes->{in}{typ}<2) {
		$output .= qq~<p><a href="/db/group/add/1/typ/1/parent_id/$parent_id" class="arPlus"><b>załóż nowe forum</b></a>~  if Wywrota->per('admin') ;
	}

	$output .= $self->SUPER::searchFooterGenerate($queryRes, $tytul);
	return $output;

}

sub header {
# -------------------------------------------------------------------------------------

	my $self = shift;
	my $param=shift;
	$param->{nomenu}=2;

	my $output = $self->SUPER::header($param);

	my $incBanner = forumNavigation();

	$output =~ s/<!-- afterNav -->/$incBanner/g;
	

	return $output;

}


sub forumNavigation {
# -------------------------------------------------------------------------------------

	my ($output);

	$output = qq~

		<div class="mySocieties">
			~. Wywrota::Controller::includePage("db=group&favorites=list&count=1&generate=1&small=1&mh=30&quiet=1") .qq~
		</div><br class="clrl">

		<div class="categories">
			~. Wywrota::Controller::includePage("db=group&ca=countTypes&column=tematyka&typ=2&field=typ", "1d") .qq~
		</div><br class="clrl">
	
		~;

	return $output;

}



sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;

	$object->preProcess(1);

	my $catid = $object->rec->{id};
	my $forum_id = $Wywrota::in->{'forum_id'} || 1;
	my ($queryRes, $title, $pageCat, $icons, $output);

	return Wywrota->errorPage( msg('no_permissions') , 
		msg('no_permissions_forum') .qq~ <a href="/ludzie/$rec->{wywrotid}" class="ludek">$rec->{ludzie_imie}</a>~) 
		if (!$nut->perRecord($object));


	# TODO $wyk_add

	$title = $object->rec->{tytul};
	$icons = qq~
		<a href="/db/forum/add=1,kat_id=$object->{rec}{id},topic=1" class="btn newPost"><span>~.msg('new_topic').qq~</span></a>
	~;

	# dolacz naglowek z opisem kategorii
	if ($Wywrota::in->{nh} < 2) {
		$output .= $object->recordFull . '<br class="clrl">';
		$output .= qq~<p><a href="/db/group/add/1/typ/1/parent_id/$object->{rec}{id}/forum_id/$object->{rec}{forum_id}" class="arPlus"><b>załóż nowe forum</b></a>~  
			if Wywrota->per('add') && $pageCat && $pageCat->rec->{typ}==1;

		# lista podkategorii
		$queryRes = Wywrota->cListEngine->query(
			{stan=>1, typ=>1, sb=>'pozycja', parent_id=>$catid, so=>'descend', small=>'1', nomore=>1}, 
			"view", Wywrota->app->{ccByName}{"ForumGroup"} );
		$output .= Wywrota->cListView->includeQueryResults($queryRes, undef, 1);

	} else {

		$output .= qq~
			<h1>$title</h1>
		~;
	}



	# -- get a list of forum topics
	$queryRes = Wywrota->cListEngine->query(
		{kat_id=>$catid, topic=>1, sb=>'lc_time', so=>'descend', small=>'1' }, 
		"view", Wywrota->app->{ccByName}{"ForumPost"} );


	return $self->wrapHeaderFooter({
		output => $output . Wywrota->cListView->includeQueryResults($queryRes, $rec->{tytul}, 0, 1),
		title => $rec->{tytul},	
		meta_desc=>  $rec->{komentarz},	
		meta_key=>  $rec->{tytul},
		canonical=> $rec->{url}
	});
}



sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	Wywrota->sysMsg->push('Twoja wspólnota została założona.', 'ok');
	$self->htmlPage(@_);
}


sub recordFormAdd {
# --------------------------------------------------------
	my $self = shift;
	my $output = $self->recordForm(@_);
	if ($Wywrota::in->{typ}==1) {
		$output = "<h1>Załóż nowe forum</h1>".$output ;
	} else {
		$output = "<h1>Załóż nową wspólnotę</h1>".$output ;
	}
	return $output;

}


sub recordForm {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;

	my ($output, $starter);

	$output = Wywrota::Forms::buildHtmlRecordForm($object, @_);

	return $output;
}



1;