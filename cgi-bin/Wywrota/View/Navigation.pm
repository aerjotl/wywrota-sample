package Wywrota::View::Navigation;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Exporter;
use Data::Dumper;

use Class::Singleton;
#use base 'Class::Singleton';

use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Favorites;
use Wywrota::Log;
use URI::Escape;

our @ISA = qw(Exporter Class::Singleton);
our @EXPORT = qw(
	absoluteLinks param  
	makeSingleNav 
	crumbTrail bigLinks  
	makePagination 
	);



sub getNavLinks {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec if ($object);
	my ($nav, $url, $cid, $uid, $keyword, $question);

	$keyword = plural(1, $object->config->{keyword});
	$question = "Czy na pewno chcesz skasować $keyword?";
	$question .= "\\n".HTML::Entities::encode($object->rec->{tytul}, '<>&"\'') if ($object->rec->{tytul});

	$url = $object->config->{url};
	$cid = $object->cid;
	$uid = $object->uid;

	$nav->{info} = qq~/ludzie/$rec->{'wywrotid'}~ if $rec->{'wywrotid'};
	
	$nav->{inne} = qq~http://literatura.$Wywrota::request->{urlSufix}/$rec->{'autor_urlized'}/~ if ($rec->{user_id}>0 && $Wywrota::request->{content}{current}{url} eq 'literatura');
	$nav->{inne} = qq~http://spiewnik.$Wywrota::request->{urlSufix}/$rec->{'wykonawca_urlized'}/~ if ($rec->{user_id}>0 && $Wywrota::request->{content}{current}{url} eq 'spiewnik');
	$nav->{link} = qq~/message/sendLink/id/$rec->{id}/cid/$Wywrota::request->{content}{current}{cid}~;

	if ($Wywrota::session->{user}{id}) {
		$nav->{fav} = "javascript:myAjax('addFav', ['id=$rec->{id}', 'cid=" . $Wywrota::request->{content}{current}{id} . "'], 'sNavfav')";
	} else {
		$nav->{fav} = qq~javascript:alert('Zaloguj się aby dodać do ulubionych.')~;
	}

	

	# prepare delete urls
	if (Wywrota->perRecord($object, 'del') || Wywrota->per('admin')) {

		$nav->{del} =	qq~deleteRec('$question', '$url', '$rec->{id}');~ ;
		$nav->{del_sm} = '#';

	}

	# prepare edit urls
	if (Wywrota->perRecord($object, 'mod') || Wywrota->per('admin')) {

		# non-admin users can change only unpublished content  if (Wywrota->per('admin') || (exists($rec->{val}{stan}) and $rec->{val}{stan} == 1)) 
		$nav->{mod} =  qq~/db/$url/modify/$rec->{'id'}~; 

	}


	# prepare favorite urls
	$nav->{addFav} = '#' 
		if ($object->config->{favorites} && !($Wywrota::in->{favorites} && !$Wywrota::in->{user_id}));

	$nav->{removeFav} = '#' 
		if ($object->config->{favorites} && $Wywrota::in->{favorites} && $Wywrota::in->{favorites} ne 'users' && !$Wywrota::in->{user_id}  && $object->config->{package} ne "RecordSet" && !$Wywrota::in->{set});

	$nav->{addSet} = '#' 
		if ($object->config->{sets} && !($Wywrota::in->{favorites} && !$Wywrota::in->{user_id}));

	$nav->{removeSet} = '#' 
		if ($object->config->{sets} && ($Wywrota::request->{content}{current}{package} eq "RecordSet" || $Wywrota::in->{set}) 
			&& defined($Wywrota::request->{mainObject}) && $Wywrota::request->{mainObject}->per('mod') );

	$nav->{flag} = '#flagReport'
		if ($object->config->{flags});

	return $nav;
}



sub appendEditIcons {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($cid, $msg,  $keyword, $question);
	my $uid = $Wywrota::session->{user}{id};
	my $nav = $self->getNavLinks($object);

	$rec->{nav} = $nav;
	
	$rec->{edit_icons} = '';
	$rec->{edit_icons_sm} = '';

	$keyword = plural(1, $object->config->{keyword});
	$question = "Czy na pewno chcesz skasować $keyword?";
	$question .= "\\n".HTML::Entities::encode($object->rec->{tytul}, '<>&"\'') if ($object->rec->{tytul});

	$cid = $object->config->{cid};

	$rec->{uid} = $object->uid;

	my $msg = {
		'add_to_favorites' => 		msg('add_to_favorites', $cid),
		'add_to_set' => 			msg('add_to_set', $cid),
		'remove_from_favorites' => 	msg('remove_from_favorites', $cid),
		'remove_from_this_set' => 	msg('remove_from_this_set', $cid),
		'remove' => 				msg('remove', $cid),
		'modify' => 				msg('modify', $cid),
		
		'other_items' => 			msg('other_items', $cid),
		'send_link' => 				msg('send_link', $cid),
		'flag' => 					msg('flag', $cid),
		'save_paper' => 			msg('save_paper', $cid),
		'send_to_group'=> 			msg('send_to_group', $cid),
		'remove_from_community'=> 	msg('remove_from_community', $cid),
		
	};
	

	# record edit icons
	if ($nav->{mod} && !$Wywrota::session->{'googlebot'}) {
		$rec->{edit_icons} = qq~ <div class="editNav"> ~;
		$rec->{edit_icons} .= qq~	<a rel="nofollow" href="$nav->{mod}" class="btn"><span class="arMod"> $msg->{'modify'} $keyword</span></a>~ if ($nav->{mod}); #rel="$object->{uid}"
		$rec->{edit_icons} .= qq~ 	<a rel="nofollow" href="#" onclick="$nav->{del}" class="btn"><span class="arDel"> $msg->{'remove'} $keyword</span></a>~ if ($nav->{del}); 
		$rec->{edit_icons} .= qq~ </div>~;
	}


	#  small icons
	if ($nav->{removeFav}) {
		$rec->{edit_icons_sm} .= qq~ <a href="#" rel="$object->{uid}" class="arRemoveFav ajaxRemoveFav" title="$msg->{'remove_from_favorites'}">&nbsp;<span>$msg->{'remove_from_favorites'}</span></a>~;
	} elsif ($nav->{removeSet}) {
		$rec->{edit_icons_sm} .= qq~ <a href="$nav->{removeSet}" rel="$object->{uid}x$Wywrota::in->{view}" class="arRemoveSet ajaxRemoveSet" title="$msg->{'remove_from_this_set'}">&nbsp;<span>$msg->{'remove_from_this_set'}</span></a>~;
	} else {
		$rec->{edit_icons_sm} .= qq~  <a href="$nav->{flag}" name="$object->{uid}" class="arFlag fancySmall" title="$msg->{'flag'}" onclick="flagId='$object->{uid}';">&nbsp;<span>$msg->{'flag'}</span></a>~ if ($nav->{flag}); 
		$rec->{edit_icons_sm} .= qq~  <a href="$nav->{addFav}" rel="$object->{uid}" class="arAddFav ajaxAddFav" title="$msg->{'add_to_favorites'}">&nbsp;<span>$msg->{'add_to_favorites'}</span></a>~ if ($uid && $nav->{addFav});
		$rec->{edit_icons_sm} .= qq~  <a href="$nav->{addSet}" rel="$object->{uid}" class="arAddSet ajaxAddSet" title="$msg->{'add_to_set'}">&nbsp;<span>$msg->{'add_to_set'}</span></a>~ if ($uid && $nav->{addSet});
		$rec->{edit_icons_sm} .= qq~  <a href="$nav->{mod}" class="arMod" title="$msg->{'modify'}">&nbsp;<span>$msg->{'modify'}</span></a>~ if ($nav->{mod});
		$rec->{edit_icons_sm} .= qq~  <a href="$nav->{del_sm}" data-question="$question" rel="$object->{uid}" class="arDel ajaxDel" title="$msg->{'remove'}">&nbsp;<span>$msg->{'remove'}</span></a>~ if ($nav->{del_sm}); 
	}
	
	$rec->{edit_icons_sm}  = '<div class="editNavSm">'. $rec->{edit_icons_sm} . '</div>' if ($rec->{edit_icons_sm});
	
	$rec->{edit_icons_sm}  = '' if ($Wywrota::session->{'googlebot'});



	if ($Wywrota::request->{urlPrefix}) {
		$rec->{edit_icons} = $self->absoluteLinks($rec->{edit_icons});
		$rec->{edit_icons_sm} = $self->absoluteLinks($rec->{edit_icons_sm});
	}

}



sub makeSingleNav {
# --------------------------------------------------------
# pojedyncza ikonka nawigacja
	my $self = shift;
	my ($href, $alt, $pic_name, $include_txt) = @_;
	my $text = $alt." " if ($include_txt);


	if ($href) {
		return qq~<div class="sNav"><a href="$href" class="$pic_name"><span>$text</span></a></div>~;
	} else {
		if (($pic_name eq ('next') ||$pic_name eq ('fav') || ($pic_name eq 'prev') || ($pic_name eq 'info')) && ($text !~ "inne teksty") && ($text !~ "rozkład")) {
			$pic_name .= "_off";
			return qq~<div class="sNav $pic_name">$text</div>~;
		}
	}
}

sub makePagination {
# --------------------------------------------------------
	my $self = shift;
	my ($link, $divideTo) = @_;
	my $pagination;
	$pagination = '<div class="pagination">';
	$pagination .= $self->makeSingleNav( ($Wywrota::in->{page} >0) ? $link.",".($Wywrota::in->{page}-1) : ""  , "poprzednia strona", 'iconPrev');
	for (my $i=0; $i<$divideTo; $i++) {
		$pagination .= ($i == $Wywrota::in->{page}) ?
			'<span class="active">'.($i+1).'</span>' :
			"<a href=\"$link,$i\">".($i+1)."</a>";
	}
	$pagination .= $self->makeSingleNav( ($Wywrota::in->{page} <$divideTo-1) ? $link.",".($Wywrota::in->{page}+1) : ""  , "następna strona", 'iconNext');
	$pagination .= '</div>';
	return $pagination;
}




sub crumbTrail {
# --------------------------------------------------------
	my $self = shift;
	my $links = shift || $Wywrota::request->{nav}{crumbLinks};
	my ($output, $printedfirst, $class);
	
	foreach  (@{$links}) {
		next unless ($_->{text});
		
		if (!$printedfirst) {
			$class = "crumb_first";
			$printedfirst=1;
		} else {
			$class = "crumb_next";
		}
		
		$output .= qq|
			<li class="$class" itemscope itemtype="http://data-vocabulary.org/Breadcrumb">
				<a href="$_->{url}" itemprop="url">
					<span itemprop="title">$_->{text}</span>
				</a>
			</li>
		|;
	}

	$output = qq|
		<ul class="crumbs">$output</ul>
	|;

	$output = $self->absoluteLinks($output);
	return $output;
}



sub crumbTrailLinks {
# --------------------------------------------------------
	my $self = shift;
	my $page_id = shift;
	my ($link, @links, $page);


	while ($page_id > 1 && ($page = Wywrota->page->{$page_id}) ) {
		$link = undef;
		$link->{url} = $page->{url};
		$link->{text} = $page->{short_title};
		$page_id=$page->{parent_id};
		unshift(@links, $link);
	}

	return \@links;
}



sub bigLinks {
# --------------------------------------------------------
	my $self = shift;
	my ($page, $output, $page_id, $subpages, $class, @pages);
	my $start_page = shift || $Wywrota::request->{content}{current}{page_id};
	my $highlight = shift;
	$subpages = 0;

	# podstrony
	foreach $page_id (sort {Wywrota->page->{$a}->{sortorder} <=> Wywrota->page->{$b}->{sortorder}} keys %{Wywrota->page}) {
		if (Wywrota->page->{$page_id}->{parent_id} == $start_page) {
			$page = Wywrota->page->{$page_id};
			$class = ($page_id == $highlight) ? 'active' : '';
			$subpages++;

			$output .= qq~<li class="$class n$subpages"><a href="$page->{url}">$page->{short_title}</a></li>~;
		} 
	}


	if ($subpages>1) {
		$output = '<li class="n0"><a href="' .Wywrota->page->{$start_page}->{url} .'">'
			. Wywrota->page->{$start_page}->{short_title}. "</a></li>	$output	" if ($start_page!=1);
	} else {
		return $self->bigLinks(Wywrota->page->{$start_page}->{parent_id}, $start_page) if (Wywrota->page->{$start_page}->{parent_id});
	}

	$output = '<ul class="mainNav">'.$output.'</ul><!-- afterNav -->';

	return $output;


}






sub adminLinks {
# --------------------------------------------------------
	my $self = shift;
	my ($output, $count, $count_news, $count_events);

	return "" unless ($Wywrota::session->{user}{groups}{1} or $Wywrota::session->{user}{groups}{2} or $Wywrota::session->{user}{groups}{4} or $Wywrota::session->{user}{groups}{11}  or $Wywrota::session->{user}{groups}{100} );

	if (Wywrota->per('admin',3)) {
		$count=Wywrota->db->selectCount('article', 'stan=1 AND _active=1');
		$count_news=Wywrota->db->selectCount('article', 'stan=5 AND _active=1 AND category=1');
		$count_events=Wywrota->db->selectCount('article', 'stan=5 AND _active=1 AND category=3');

		$output .= qq~
			<li class="space">&nbsp;</li>
			<li>Na autoryzację oczekuje</li>
		~ if ($count || $count_news || $count_events);

		$output .= qq~
			<li>
				<a href="$config{'db_script_url'}/artykuly/stan/1/template/quickimport/nomenu/bar/mh/50"><strong>$count&nbsp;~.plural($count, 'artykuł').qq~</strong></a> 
			</li>
		~ if ($count);

		$output .= qq~
			<li>
				<a href="$config{'db_script_url'}/artykuly/stan/5/category/1/template/quickimport/nomenu/bar/mh/50"><strong>$count_news&nbsp;~.plural($count_news, 'news').qq~</strong></a> 
			</li>
		~ if ($count_news);


		$output .= qq~
			<li>
				<a href="$config{'db_script_url'}/artykuly/stan/5/category/3/template/quickimport/nomenu/bar/mh/50"><strong>$count_events&nbsp;~.plural($count_events, 'wydarzenie').qq~</strong></a> 
			</li>
		~ if ($count_events);		
	}


	$output .= qq~
		<li class="space">&nbsp;</li>
	~;


	$output .= qq~<li> <a class="stats" href="/admin/stats">statystyki oglądalności</a></li>~	if (Wywrota->per('admin',3) );
	$output .= qq~<li> <a class="stats" href="/db/komentarze/data/1M/sb/data/so/descend/mh/100">moderacja komentarzy</a></li>~	if (Wywrota->per('admin',3) );
	$output .= qq~<li> <a class="stats" href="/stat.html">statystyki komentarzy</a></li>~	if (Wywrota->per('admin',3) );
	$output .= qq~<li> <a class="mail" href="/admin/newsletter">newsletter</a></li>~			if ($Wywrota::session->{user}{groups}{1} || $Wywrota::session->{user}{groups}{100} );
	$output .= qq~<li> <a class="pagemng" href="/site/mapAdmin.html">edycja stron</a></li>~		if (Wywrota->per('admin',17) );
	$output .= qq~<li> <a class="grupy" href="/db/ugroup">grupy użytkowników</a></li>~		if (Wywrota->per('admin',22) );
	$output .= qq~<li> <a class="grupy" href="/db/ludzie/sb=data_wpisu,so=descend,data_wpisu=1M">nowi użytkownicy</a></li>~ if ($Wywrota::session->{user}{groups}{1}  || $Wywrota::session->{user}{groups}{100});
	$output .= qq~<li> <a class="bannermng" href="/db/banner">bannery</a></li>~		if (Wywrota->per('admin',24) );
	$output .= qq~<li> <a class="pagemanage" href="/db/cytaty">baza cytatów</a></li>~		if (Wywrota->per('admin',9) );
	$output .= qq~<li> <a class="pagemanage" href="/db/event">wydarzenia</a></li>~		if (Wywrota->per('admin',19) );


	return $output;
}




sub _favListItems {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift || $Wywrota::session->{user}{id};
	my $output;	

	return if (!$user_id); 

	my $favCount = Wywrota->fav->getCountForUser($user_id);

	foreach (sort keys %{Wywrota->app->{cc}}) { 
		$output .= "<li><a class='fav' href='/db/" 
			. Wywrota->cc->{$_}{url}."/favorites/list'>"
			. msg('favorites_list', $_) 
			. ($favCount->{$_} ? " <span class='txtnews'>&nbsp;(<b>$favCount->{$_}</b>)</span>" : "")
			. "</a></li>\n"  
		if (int(Wywrota->cc->{$_}{favorites})) and (int($_));
	}	
	return $output;
}







sub absoluteLinks {
# --------------------------------------------------------
	my $self = shift;
	my $content = shift;
	my $absolute_url = "http://www.$Wywrota::request->{urlSufix}/";

	$content =~ s/href=\"\//href=\"$absolute_url/g;
	$content =~ s/src=\"\//src=\"$absolute_url/g;
	return $content;
}



1;