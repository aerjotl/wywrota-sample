package Wywrota::Object::Lyrics;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Object::Band;
use Wywrota::Log;
use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);


# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id					=> [0,  'auto',	'_hid',			8,   1,  '',          ''],
		tytul				=> [1,  'alpha',	'title',		255, 1,  '',          'lyrics_title'],
		tytul_urlized		=> [2, 'alpha',    '_hid',		    255, 0,  '',	        ''],
		wykonawca			=> [3,  'alpha',    'title',		255, 1,  '',	        ''],
		wykonawca_urlized	=> [4,  'alpha', 	'_hid',			255, 0,  '',	        ''],
		tresc				=> [5,  'textarea',	'html_simple',	,    0,  '',  			''],
#		jezyk				=> [6,  'combo',    '',				8,   1,  '1',          'language'],
		user_id				=> [7,  'numer',    '_hid',			255, 0,  '',  			''],
		data_przyslania		=> [8,  'date',     '_hid',	   		255, 0,  'Wywrota::Utils::getDate()',  	''],
		slowa				=> [9,  'alpha',    'inputWide',	255, 0,  '',	        'lyrics_author'],
		muzyka				=> [10, 'alpha',    'inputWide',	255, 0,  '',	        'music_author'],
		plyta				=> [11, 'alpha',    'inputWide',	255, 0,  '',          'album'],
		youtube				=> [12, 'alpha',    'inputWide',	255, 0,  '',          'youtube'],
		rok					=> [12, 'alpha',    '',		        64,  0,  '',          'year'],
		tlumaczenie			=> [14, 'numer',    '_hid',			10,  0,  0,           '0'],
		czy_slowa			=> [15, 'checkbox', '',				10,  0,  1,           'song_lyrics'],
		czy_chwyty			=> [16, 'checkbox', '',				10,  0,  0,           'guitar_chords'],
		czy_tabulatura		=> [17, 'checkbox', '',				10,  0,  0,           'tabulature'],
		wykonawca_id		=> [18, 'numer',    '_hid',			10,  0,  0,           ''],
		chords				=> [19, 'alpha',    '_ao',			255, 0,  '',		  'chords_separated'],
		_comment_cnt		=> [20, 'numer',    '_hid',			8,	 0,  '0',		  ''],
		_vote_cnt			=> [21, 'numer',   '_hid',			8,		0,  '0',			''],
		_vote_ratings		=> [22, 'numer',   '_hid',			8,		0,  '0',			''],
		_vote_func			=> [23, 'numer',   '_hid',			8,		0,  '0',			''],
		_fav_cnt			=> [24, 'numer',    '_hid',			8,		0,  '0',            ''],
		_main_version       => [25, 'numer',    '_hid',			8,		0,  '1',            '']
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
	my ($output);
	my $self = shift;
	my $rec = $self->rec;

	$self->SUPER::preProcess(@_);

	$rec->{data_przyslania_} = normalnaData($rec->{'data_przyslania'},1);
	$rec->{data_publikacji_} = normalnaData($rec->{'data_publikacji'},1);
	$rec->{data_przyslania} = normalnaData($rec->{'data_przyslania'},0);
	$rec->{data_publikacji} = normalnaData($rec->{'data_publikacji'},0);

	$rec->{tytul} = dehtml($rec->{tytul});
	$rec->{wykonawca} = dehtml($rec->{wykonawca});
	
	$rec->{photo} = Wywrota->t->getPhotoCode({
		id => $rec->{band_photo}, 
		width => $Wywrota::in->{img_width}, 
		height => $Wywrota::in->{img_height},
		suffix => $Wywrota::in->{suffix} || "px",
		lazy_load => 0
	});

	$rec->{wykonawca_uri} = "http://teksty.$Wywrota::request->{urlSufix}/".$rec->{wykonawca_urlized}."/";
	$rec->{comment_str} = "<span class=\"textComments\">$rec->{_comment_cnt}&nbsp;".plural($rec->{_comment_cnt}, 'komentarz')."</span>" if ($rec->{_comment_cnt});
	
	$rec->{songDetails} = qq~<b>płyta:</b> $rec->{plyta}<br>~ if $rec->{plyta};
	$rec->{songDetails} .= qq~<b>słowa:</b> $rec->{slowa}<br>~ if $rec->{slowa};
	$rec->{songDetails} .= qq~<b>muzyka:</b> $rec->{muzyka}<br>~ if $rec->{muzyka};

	if ($rec->{youtube} =~ /youtu.be/) {
		$rec->{youtube} =~ s/^.*youtu.be\/([^&]*)$/$1/g;
	} else {
		$rec->{youtube} =~ s/^.*[\?&]v=([^&]*)&{0,1}.*$/$1/g;
	}

	return $self;
}



sub prepareSeo {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$rec->{whatwehave} = ($rec->{czy_chwyty} ?	msg('chords').", " : "")
		. ($rec->{czy_tabulatura} ? msg('tabulature').", " : "")
		. ($rec->{czy_slowa} ? msg('lyrics').", ":"");
	chop($rec->{whatwehave});
	chop($rec->{whatwehave});


	$rec->{whatwehave} = msg('song_lyrics') unless ($rec->{whatwehave});
		
	$rec->{whatwehave_seo} = ($rec->{czy_slowa} ? msg('lyrics')." ":"")
		. ($rec->{czy_chwyty} ?		msg('chords')." " : "")
		. ($rec->{czy_tabulatura} ? msg('tabulature')." " : "");
	chop($rec->{whatwehave_seo});
	$rec->{whatwehave_seo} = msg('lyrics') unless ($rec->{whatwehave_seo});
		
	
}


sub recordSmall {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	my $output = qq|
		<div class="lyricsSmall rec">
			<a href="$rec->{uri}">|. $self->toHtmlString .qq|</a>
		</div>
	|;

	return $output;
}



sub record {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	return Wywrota->t->process(
		$Wywrota::in->{template} ? "object/lyrics_record_$Wywrota::in->{template}.html" : 'object/lyrics_record.html' , {
		rec		=>	$rec,
		obj		=>	$self
	});

}


sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return $rec->{tytul} ." – ". $rec->{wykonawca};
}


sub toHtmlString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return '<span class="lineLyrics">'.$rec->{photo}. '<strong class="title">' . $rec->{tytul} . "</strong> <span class='band'>". $rec->{wykonawca} ."</span></span> ";
}

