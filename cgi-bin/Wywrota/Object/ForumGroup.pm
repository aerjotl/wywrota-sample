package Wywrota::Object::ForumGroup;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

#use strict;
use POSIX qw(ceil floor);
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;


our @ISA = qw(Wywrota::Object::BaseObject);


# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'auto',		'_hid',		8,		1,  '',          ''],
		tytul	=>			[1, 'alpha',	'title',	255,	1,  '',          'name'],
		komentarz=>			[2, 'textarea', 'txtAreaSm',800,	1,  '',          'description'],
		user_id=>			[3, 'numer',	'_hid',		16,		1,  '',         ''],
		typ	=>				[4, 'radio',	'_ao',		60,		1,  '2',          ''],
		child_count =>		[5, 'numer',	'_hid',		10,		1,  '0',  ''],
		last_child_id =>	[6, 'numer',	'_hid',		10,		0,  '0',  ''],
		tematyka	 =>		[7, 'radio',   '',			10,		1,  '1',  ''],
		grafika		=>		[8, 'image',	'',			128,	0,  '',    ''],
		forum_id	 =>		[9, 'radio',	'_hid',		10,		1,  '1',  ''],
		parent_id	 =>		[10, 'numer',	'_hid',		10,		1,  '0',  ''],
		_fav_cnt	 =>		[11, 'numer',	'_hid',		10,		1,  '0',  ''],
		data_utworzenia	=>	[12, 'date',    '_hid',		60,		1,  'Wywrota::Utils::getDate()',   ''],
		pozycja =>			[13, 'numer',	'_ao',		10,		1,  '1',  ''],
#		stan	=>			[14, 'radio',	'_ao',		10,		1,  '1',  ''],
		closed  	 =>		[15, 'checkbox','_ao',		10,		0,  '',   'privacy']
	 };

# --------------------------------------------------------





sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	return $self;
}



sub preProcess {
# --------------------------------------------------------
	my ($output, $year);
	my $self = shift;
	my $rec = $self->rec;

	$self->SUPER::preProcess(@_);

	$rec->{'lc_time'} = normalnaData($rec->{'lc_time'},'short');


	#if ($rec->{'lc_child_count'}-1 > 20) {
	#	$_ = floor(($rec->{'lc_child_count'}-1) / 20);
	#	$rec->{'topic_uri'} = "/db/forum/sb=time,parent_id=$rec->{'lc_parent_id'},nh=" . ($_+1) ."#" . ($rec->{'lc_child_count'} -1 - $_*20);
	#} else {
	#	$rec->{'topic_uri'} = "/forum/topic/$rec->{'lc_parent_id'}#".($rec->{'lc_child_count'}-1);
	#}
	
	my $lastPost = Wywrota->content->createObject({
		parent_id => $rec->{'lc_parent_id'},
		time => $rec->{'lc_time'},
		child_count => $rec->{'lc_child_count'},
		temat => $rec->{'lc_temat'},
	}, "ForumPost"); 
	
	$rec->{'topic_uri'} = $lastPost->url;

	$rec->{'czego'} = Wywrota::Language::plural($rec->{child_count}, 'wpis');
	$rec->{'members'} = Wywrota::Language::plural($rec->{'_fav_cnt'}, 'członek') if ($rec->{val}{typ}==2);
	$rec->{'count'} = ($rec->{val}{typ}==2) ?
		"<b>" .$rec->{'_fav_cnt'} . "</b>&nbsp;" . $rec->{'members'} : 
		"<b>" .$rec->{'child_count'} . "</b>&nbsp;" . $rec->{'czego'} 	;

	$rec->{img_sq} = qq~<img src="/pliki/group/$rec->{grafika}-sq" class="floatLeft">~ if ($rec->{grafika});
	$rec->{img_px} = qq~<img src="/pliki/group/$rec->{grafika}-px" class="floatLeft">~ if ($rec->{grafika});
	$rec->{img_med} = qq~<img src="/pliki/group/$rec->{grafika}-med" class="mainImg">~ if ($rec->{grafika});

	$rec->{closed} = qq~<br><span class="lock">$rec->{closed}</span>~ if ($rec->{val}{closed});

	$rec->{class} = ($rec->{'val'}{'typ'}==1) ? "forumCat forumCat" : "forumCat forumSoc";
	$rec->{class} .= "Closed" if ($rec->{val}{closed});

	return $self;
}


sub recordFull {
# --------------------------------------------------------
	my ($output, $flag);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();


	$output .= qq~
		<div class="catinfo">
		$rec->{img_med}
	~;
	
	# linki do komuny
	if ($rec->{val}{typ}==2) {

		$flag = Wywrota->fav->isInFavorites($rec->{id}, 12);

		$output .= qq~
			<div class="floatRight">
				<a class="btn ~. ($flag ? 'leave' : 'join').qq~ ajaxJoin" rel="$rec->{uid}x$flag" 
					href="#"><span>~. ($flag ? msg('leave') : msg('join')) .qq~</span></a>
			</div>
		~;

		if ($Wywrota::in->{favorites}) {
		 $output .= qq~
			<div class="floatRight">
				<a class="btn forum" href="$rec->{uri}"><span>forum wspólnoty</span></a>
			</div>
		~;
		} else {
		 $output .= qq~
			<div class="floatRight">
				<a class="btn users" href="/db/group/favorites/users/id/$rec->{id}"><span>członkowie ($rec->{'_fav_cnt'})</span></a>
			</div>
		~;
		}
	}
	
	
	$output .= qq~
		<h1>$rec->{tytul}</h1>
		<div class="g">
			kategoria: <a href="/db/group/tematyka/$rec->{val}{tematyka}" class="pxCat">$rec->{tematyka}</a><br>
			założyciel: <a href="/ludzie/$rec->{wywrotid}" class="ludek">$rec->{ludzie_imie}</a>
		</div>
		$rec->{plik_img}
		$rec->{komentarz}
		$rec->{closed}

		$rec->{edit_icons}

	~;

#	$output .= qq~ <div><br><a class="arMod" href="/db/group/modify/$rec->{id}">zmień opis / grafikę</a></div>~ if Wywrota->per('mod');

	$output .= qq~
		</div>
	~;
	return $output;
}



sub record {
# --------------------------------------------------------
	my ($output, $children, $childrenHtml, $child );
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	if ($rec->{'val'}{'typ'}==1) {
		$children = Wywrota->db->buildHashRefArrayRef("SELECT * FROM forum_kategorie WHERE parent_id = $rec->{id} and _active=1");
		foreach $child (@$children) {
			$child = Wywrota::Object::ForumGroup->new($child);
			$child->preProcess();
			$childrenHtml .= qq~ &middot; <a href="$child->{rec}->{uri}">$child->{rec}->{tytul}</a> ~;
		}
	}

	$output = qq~
		<tr>

			<td class="$rec->{class}">
				<h3><a href="$rec->{uri}">$rec->{tytul}</a></h3>
				<div class="komentarz">$rec->{komentarz} </div>
				<div class="children">$childrenHtml</div>
			</td>
			
			<td class="children" align="center">
				$rec->{count}
			</td>
			
			<td class="children">
					<a href="$rec->{'topic_uri'}" class="latestPost"><span>go</span></a>					
					<a href="$rec->{'topic_uri'}">
						<b>$rec->{'lc_temat'}  </b>
					</a><br>
					$rec->{'lc_author'} $rec->{'lc_time'} 
			</td>

		</tr>
	~;
		

	return  $output;
}



sub recordSmall {
# --------------------------------------------------------
	my ($output);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	my $countHtml = qq~<br>$rec->{'count'}~ if (!$Wywrota::in->{favorites});

	$rec->{class} = ($rec->{'val'}{'typ'}==1) ? "forumCatSm forumCatSm" : "forumCatSm forumSocSm";
	$rec->{class} .= "Closed" if ($rec->{val}{closed});

	$output = qq~
		<div class="$rec->{class}" id="$rec->{uid}"><a href="$rec->{uri}" class="cat">$rec->{tytul} </a>		$countHtml</div>
	~;
		

	return  $output;
}




1;
