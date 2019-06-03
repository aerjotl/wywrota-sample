package Wywrota::Object::View::ForumPostView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Data::Dumper;
use POSIX qw(ceil floor);
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Wywrota::Notification;
use Wywrota::Object::View::ForumGroupView;
use Data::Structure::Util qw(_utf8_off utf8_off utf8_on _utf8_on);



sub getRecentTopicListHtml {
# --------------------------------------------------------
	my $self = shift;
	my $kat_id = shift;
	my $wykonawca_id = shift;
	my $limit  = shift;
	my $forumTopics; 
	my ($output, $record);

	eval {
		$forumTopics =  $self->mng->getRecentTopics($kat_id, $wykonawca_id, $limit);
	};
	
	Wywrota->error($@) if ($@);


	if ($#{$forumTopics} gt -1) {
		$output .=  qq~ 
		<ul class="topics">
		~;
		
		foreach $record ( @{$forumTopics} ) {

			$record->{'lc_time'} = normalnaData($record->{'lc_time'},'short');
			$output .=  qq~ 
				<li><a href="/forum/topic/$record->{id}" title="$record->{lc_author} $record->{lc_time}">$record->{temat}</a></li>
				~;
		}

		$output .=  qq~ 
		</ul>
		~;

	} else {
		$output = '<div class="div_msg_tip_sm">'. msg('no_forum_topics') . '</div>';
	}

	return $output;
};


sub getRecentTopicsHtml {
# --------------------------------------------------------
	my $self = shift;
	my $kat_id = shift;
	my $wykonawca_id = shift;
	my $limit  = shift;
	my $forumTopics;
	my ($output, $record);

	eval {
		$forumTopics =  $self->mng->getRecentTopics($kat_id, $wykonawca_id, $limit);
	};
	Wywrota->error($@) if ($@);

	if ($#{$forumTopics} gt -1) {
		$output .=  qq~ 

		<table class="forumPosts">
			<tr>
				<th class="link">temat</th>
				<th class="lastEntry">ostatni wpis</th>
			</tr>
		~;
		
		foreach $record ( @{$forumTopics} ) {

			$record->{'lc_time'} = normalnaData($record->{'lc_time'},'short');
			$output .=  qq~ 
				<tr>
					<td class="link">
						<a href="/forum/topic/$record->{id}">$record->{temat}</a> 
					</td>
					<td class="lastEntry">$record->{lc_author} $record->{lc_time}</td>
				</tr>
				~;
		}

		$output .=  qq~ 
		</table>
		~;

	} else {
		#$output = qq~<div class="div_msg_tip_sm">brak wpisów na forum tego wykonawcy</div>~;
	}

	return $output;
};




sub header {
# -------------------------------------------------------------------------------------
# dolacza naglowek z tytulem strony
# 0 - tytul strony
# 1 - jesli istnieje, to nie drukuje reszty kody tylko <head></head>
#     jesli 'nomenu' - nie drukuje prawej kolumny
#     jesli 'bar' - drukuje tylko gorny pasek
# 2 - meta description
# 3 - meta keywords
# 4 - no http cache

	my $self = shift;
	my $param=shift;
	my ($output);
	
	$param->{nomenu} = 2;
	$param->{title} = (defined $Wywrota::request->{pageTopicPost}) ? 
						$Wywrota::request->{pageTopicPost}{rec}{temat} . " : " . $Wywrota::request->{pageCat}{rec}{tytul} 
						: $param->{title};
	$param->{meta_key} = $Wywrota::request->{pageTopicPost}{rec}{temat} . "," . $Wywrota::request->{pageCat}{rec}{tytul} . ",";
	$param->{meta_desc} = utf8_off($Wywrota::request->{pageTopicPost}{rec}{tresc_});
	

	$output = $self->SUPER::header($param);

	my $crumb = Wywrota->nav->crumbTrail();
	$output .= qq~
		<div class="forumCrumb">$crumb</div>
	~;

	my $afterNav = Wywrota::Object::View::ForumGroupView::forumNavigation();

	if ($Wywrota::request->{pageTopicPost}{rec}{wykonawca_id}) {
		my $bandObj = Wywrota->content->getObject($Wywrota::request->{pageTopicPost}{rec}{wykonawca_id}, 'Band');
		$afterNav = $bandObj->recordBig().$afterNav if ($bandObj);
	};
	
	$output =~ s/<!-- afterNav -->/$afterNav/g;

	return $output;

}

sub replyButtons {
# --------------------------------------------------------
	my $self = shift;
	my $in = shift;
	my $wyk_add = ",wykonawca_id=$in->{wykonawca_id}" if ($in->{wykonawca_id});
	my $output = '';
	my $cat_id;

	if ($Wywrota::request->{pageCat}) {
		$cat_id = $Wywrota::request->{pageCat}{rec}{id};
	} elsif ($in->{kat_id}) {
		$cat_id = $in->{kat_id};
	} elsif (!$in->{kat_id} && $in->{wykonawca_id}) {
		$cat_id = 5;
	} else {
		return "zonk";
	}

	my $buttClass = ($Wywrota::session->{user}{id}) ? '' : 'inact';
	my $buttTitle = ($Wywrota::session->{user}{id}) ? '' : msg('action_require_logged_in_msg');


	if ($Wywrota::request->{pageTopicPost}) {
		$output .= qq~
			<a href="/db/forum/add=1,kat_id=~. $Wywrota::request->{pageCat}{rec}{id} .qq~,parent_id=~. $Wywrota::request->{pageTopicPost}{rec}{id} .qq~" 
				class="btn reply $buttClass" title="$buttTitle">
				<span>~.msg('reply').qq~</span>
			</a>~;
	} else {
		$output .= qq~
			<a href="/db/forum/add=1,kat_id=$cat_id,topic=1$wyk_add" class="btn newPost $buttClass" title="$buttTitle">
				<span>~. msg('new_topic') .qq~</span>
			</a>~;
	}

	return $output;
		
}


sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $temat = shift;
	my $in = $queryRes->{in};

	my $output="";
	my ($cat, $title, $icons);

	if (int($in->{parent_id}) && $queryRes->{cnt}) {
		$title = $Wywrota::request->{pageTopicPost}{rec}{temat};
		$output .= qq~ <h1>$title</h1>~;
		
	}
	$icons = $self->replyButtons($in);


	# główny nagłówek
	$output .= qq~
		<div class="icons searchHeaderIcons">$icons</div>
		<div class="listPagination">$queryRes->{pagination}</div>
	~;


	if (int($in->{small})) {
		$output .= qq~
			<div class="clr"></div>
			<table class="forumPosts">
			<tr class="tableHeader">
				<th class="link">~.msg('topic').qq~</th>
				<th class="autor">~.msg('author').qq~</th>
				<th class="replies">~.msg('rep').qq~</th>
				<th class="lastEntry">~.msg('last_entry').qq~</th>
			</tr>
		~;
	} elsif ($queryRes->{cnt}) {
		$output .= qq~
			<div class="forumRead">
		~;
	}

	return $output;
}


sub searchFooter {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $temat = shift;
	my $in = $queryRes->{in};
	my $output;
	my ($kat, $icons, $cid, $recid);
	


	if ($in->{small}) {
		$output .= qq~</table>~;
		$output .=  $self->replyButtons($in);

	} elsif ($queryRes->{cnt}) {
		$output .= qq~</div>~;

		# add form after all the comments
		$output .=  $self->_getForm($in);
	}

	$output .= qq~
		<br class="clr">
		<div class="listPagination">$queryRes->{pagination}</div>
		<br><br>
	~ if ($queryRes->{pagination});


	if ($in->{kat_id} || $in->{wykonawca_id}) {
		$recid = ($in->{wykonawca_id}) ? $in->{wykonawca_id} : $in->{kat_id};
		$cid = ($in->{wykonawca_id}) ? 15 : 12;
		$output .= Wywrota::Notification::getSubscribeButton($recid, $cid);

	} elsif ($in->{parent_id}) {
		$cid = $Wywrota::request->{content}{current}{cid};
		$output .= Wywrota::Notification::getSubscribeButton($in->{parent_id}, $cid);

	}

	return $output;
}


sub searchFooterGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $output = "";

	# add form after all the comments
	$output .=  $self->_getForm($queryRes->{in});

	$output .= $self->SUPER::searchFooterGenerate($queryRes, $tytul);
	return $output;

}

sub _getForm {
# --------------------------------------------------------
# zwraca formularz do komentowania
	my $self = shift;
	my $rec=shift;

	return Wywrota->t->process('object/forum_form.html', {
		rec			=>	$Wywrota::request->{pageTopicPost}{rec},
		pageCat		=>	$Wywrota::request->{pageCat}{rec},
		watching_comments => isWatchingComments($Wywrota::request->{pageTopicPost}{rec}{id})
	});

}



sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my ($output, $return_uri, $record_html);

	$record_html = $object->record();
	$return_uri = $object->rec->{uri};


	$output = qq~
		<h1>Twój post został wysłany. Dziękujemy!</h1>
		$record_html
		<br class="clrl">
	~;
	
	if (!$object->rec->{topic}) {
	
		$output .= qq~<p><br><a href="$return_uri" class="arLeft">powrót do tematu</a></p>~ ;
	
	} elsif ($object->{rec}{wykonawca_id} ) {
		my $bandObj = Wywrota->content->getObject($object->{rec}{wykonawca_id}, 'Band')->preProcess;
		$return_uri = $bandObj->url();
		$output .= qq~<p><a href="$return_uri" class="arLeft">powrót do fan klubu</a></p>~;
		
	} else {
		
		$return_uri = $nut->request->{pageCat}{rec}{url};
		$output .= qq~<p><a href="$return_uri" class="arLeft">powrót do forum</a></p>~;
	}
	
	return $self->wrapHeaderFooter({
		title => $Wywrota::request->{content}{current}{title}." - post został wysłany",	
		nomenu=> 'nomenu',
		output=> $output
	});

}



sub recordFormAdd {
# --------------------------------------------------------

	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($output, $parentRec);

	return Wywrota->errorMsg( msg('forum_missing_arguments') ) 
		. qq~<style>.formButtons {display: none}</style>~
		if (!$Wywrota::in->{parent_id} && !$Wywrota::in->{topic});

	if ($Wywrota::in->{parent_id}) {
		$parentRec = Wywrota->content->getObject($Wywrota::in->{parent_id});
		$rec->{temat} = $parentRec->{rec}{temat};
		$output .= qq~<h1>Odpowiedz</h1>~;
	} else {
		$output .= qq~<h1>Nowa dyskusja</h1>~;
	}
	
	$output .= Wywrota::Forms::buildHtmlRecordForm($object, @_);
	
	return  $output;
}




sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $suffix = '';

	if ($rec->{'child_count'}-1 > $object->config->{'records_per_page'}) {
		$_ = floor(($rec->{'child_count'}-1) / $object->config->{'records_per_page'});
		$suffix = "&nh=" . ($_+1);
	};
	
	return Wywrota::Controller::includePage("db=forum&parent_id=$rec->{id}$suffix", undef, 1);

}

1;