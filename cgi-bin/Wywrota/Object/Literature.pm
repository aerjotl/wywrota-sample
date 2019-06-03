package Wywrota::Object::Literature;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Date::Parse;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Object::BaseObject;
use Wywrota::Object::User;
use Wywrota::Language;
use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);


# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'auto',    '_hid',			8,		1,  '',          ''],
		tytul	=>			[1, 'alpha',	'title',		72,		1,  '',          'title'],
		tytul_urlized	=>	[2, 'alpha',    '_hid',			128,	0,  '',	        ''],

		tresc	=>			[3, 'alpha',	'html',			300000,	0,  '',          'content'],

		autor	=>			[4, 'alpha',     '',		64,		1,  '$Wywrota::session->{user}{name}',	        'author', 'publication_details'],
		autor_urlized	=>	[5, 'alpha',     '_hid',	64,		0,  '',	        '',			'publication_details'],
		user_id=>			[6, 'numer',     '_ao',		16,		1,  '',         '',			'publication_details'],
		data_przyslania	=>	[7, 'date',      '_ao_ne',	60,		0,  '',			'',			'publication_details'],
		data_publikacji	=>	[8, 'date',      '_ao_ne',	60,		0,  'Wywrota::Utils::getDate()',			'',			'publication_details'],
		lang			=>	[9, 'combo',     '_hid',	8,		1,  '1',		'language', 'publication_details'],

		komentarz=>			[13, 'textarea','_hid',		256,	0,  '',       'introduction'],
		typ	=>				[14, 'radio',   '',			    60,		1,  '',          'content_type'],
		wyroznienie	=>		[15, 'radio',	'_hid',			6,		0,  '',				''],
		
		can_comment	=>		[16, 'checkbox',	'',			1,		0,  '1',				'can_comment'],
		can_vote	=>		[17, 'checkbox',	'',			1,		0,  '1',				'can_vote'],
		
		_vote_cnt	=>		[18, 'numer',   '_hid',			8,		0,  '0',			''],
		_vote_ratings	=>	[19, 'numer',   '_hid',			8,		0,  '0',			''],
		_vote_func		=>	[20, 'numer',   '_hid',			8,		0,  '0',			''],
		_comment_cnt	=>	[21, 'numer',   '_hid',			8,		0,  '0',			''],
		_fav_cnt=>			[22, 'numer',    '_hid',		8,		0,  '0', ''],
		contest_id		=>	[23, 'combo',   '_ao_ne',		8,		1,  '0',          'contest']
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
	$self->SUPER::processTextObject();

	$rec->{data_przyslania_} = normalnaData($rec->{val}{'data_przyslania'},'friendly_notime');
	$rec->{data_publikacji_} = normalnaData($rec->{val}{'data_publikacji'},'friendly_notime');
	$rec->{data_przyslania} = normalnaData($rec->{val}{'data_przyslania'},0);
	$rec->{data_publikacji} = normalnaData($rec->{val}{'data_publikacji'},0);
	
	$rec->{textRatingFlat} = qq~
		<div class="ratingFlat">
			~ . (($rec->{rating}) ? "$rec->{rating}" : "") . qq~
			$rec->{vote_count}
			~ . (($rec->{_comment_cnt}) ? "<span class=\"textComments\">$rec->{comment_count}</span>" : "") . qq~
		</div>
	~;
	
	return $self;
}



sub record {
# --------------------------------------------------------
# Prezentacja pojedynczego rekordu
	my ($output, $photo);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();
	
	return $self->recordMini() if ($Wywrota::in->{mini});

	$output = qq~
		<div class="textItem $rec->{distinctions}" id="$rec->{uid}">
			<h2><a href="$rec->{uri}">$rec->{'tytul'}</a></h2>
			<span class="textAuthor">$rec->{'autor'},</span>
			<span class="textDate">$rec->{typ}, $rec->{data_publikacji_}</span>
			$rec->{textRatingFlat}
			$rec->{distinction_html}
		</div>

	~;
	return $output;
}



sub recordSmall {
# --------------------	------------------------------------
# Prezentacja pojedynczego rekordu
	my ($output);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	return $self->recordMini() if ($Wywrota::in->{mini});

	$output = qq~
		<div class="textItemSm $rec->{distinctions}" id="$rec->{uid}">
			<h3><a href="$rec->{uri}">$rec->{tytul}</a></h3>
			<span class="textAuthor">$rec->{autor},</span> 
			<span class="textDate">$rec->{typ}</span>
		</div>
	~;
	return $output;
}



sub recordMini {
# --------------------------------------------------------
# Prezentacja pojedynczego rekordu
	my ($output);
	my $self = shift;
	my $rec = $self->rec;

	$rec->{tresc} = dehtml_space($rec->{tresc});
	$rec->{tresc} = smartContent($rec->{tresc});

	$output = qq~
		<div class="textItem textItemMini $rec->{distinctions}" id="$rec->{uid}">
	
			<h3><a href="$rec->{uri}">$rec->{'tytul'}</a></h3>
			<div class="textAuthor">$rec->{'autor'}</div>
			<div class="content">$rec->{tresc}</div>
			$rec->{textRatingFlat}
		</div>

	~;
	return $output;
}





sub recordNewsletter {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();
	my ($output, $photo, $photoSuffix);

	my $img = 'sheet-48.gif';
	$img = 'sheet-48-b.gif'	 if ( $rec->{icon} eq 'bluestar');
	$img = 'sheet-48-r.gif'	 if ( $rec->{icon} eq 'redstar');
	$img = 'sheet-48-rb.gif' if ( $rec->{icon} eq 'redstarbluestar');

	$output = qq~
		<table><tr><td valign="top">
		<img src='$config{'file_server'}/gfx/$img'></td>
		<td width="100%">
		<div style="padding: 0px 5px 12px 0; font-size: 11px;">
			
			
			<h3><a href="$rec->{url}" style="font: bold 15px 'Tahoma', arial, helvetica;width: auto;display: block;text-decoration: none;color: black;">$rec->{'tytul'}</a></h3>
			<div class="textAuthor">$rec->{'autor'}</div>
			<div style="display: inline;font-size: 11px;padding: 1px 0 1px 20px;color: #666;">$rec->{data_publikacji_}</div>
			<div style="font-size: 11px;">$rec->{'komentarz'}</div>
		</div>
		</td>
		</tr>
		</table>	
	~;

	return $output;
}



sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return $rec->{tytul} ." – ". $rec->{autor};
}


sub toHtmlString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return $rec->{tytul} ." – ". "<span class='autor'>". $rec->{autor} ."</span> ";
}
