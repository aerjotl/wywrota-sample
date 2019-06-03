package Wywrota::Object::MP3;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Utils;
use Wywrota::User;
use Wywrota::Object::BaseObject;
use Wywrota::Object::User;
use Wywrota::Object::Band;
use Wywrota::Language;
use Wywrota::Dictionary;


our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'auto',     '_hid',			8,		1,  '',          ''],
		tytul	=>			[1, 'alpha',	'title',		128,	1,  '',          'title'],
		tytul_urlized	=>	[2, 'alpha',    '_hid',			128,	0,  '',	        ''],

		komentarz	=>		[3, 'textarea', 'txtAreaSm1',	10000,	0,  '',          ''],
		user_id=>			[4, 'numer',     '_ao',			16,		1,  '0',         'user_id'],
		autor	=>			[5, 'alpha',     '',			128,	1,  '$Wywrota::session->{user}{name}',	        ''],
		nazwa_pliku	=>		[6, 'alpha',     '_hid',		64,		1,  '',          ''],
		czas_trwania_sec=>	[7, 'numer',     '_ao',			10,		0,  '0',          ''],
		rozmiar_pliku_byte=>[8, 'numer',     '_hid',		10,		0,  '0',          ''],
		pobrania_pliku	=>	[9, 'alpha',     '_hid',		10,		0,  '0',          ''],
		data_przyslania	=>	[10, 'date',     '_hid',		60,		1,  'Wywrota::Utils::getDate()',   ''],
		data_publikacji	=>	[11, 'date',     '_hid',			60,		0,  'Wywrota::Utils::getDate()',   ''],
		wyroznienie	=>		[12, 'radio',	 '_hid',			1,		0,  '0', ''],
		typ			=>		[13, 'radio',    '',			1,		1,  '1', ''],
		edition		=>		[14, 'numer',    '_ao',			1,		1,  '4', ''],
		can_comment	=>		[15, 'checkbox',	'',			1,		0,  '1',				'can_comment'],
		can_vote	=>		[16, 'checkbox',	'',			1,		0,  '1',				'can_vote'],
		_vote_cnt	=>		[17, 'numer',    '_hid',		8,		0,  '0', ''],
		_vote_ratings	=>	[18, 'numer',    '_hid',		8,		0,  '0', ''],
		_vote_func		=>	[19, 'numer',    '_hid',		8,		0,  '0', ''],
		_comment_cnt=>		[20, 'numer',    '_hid',		8,		0,  '0', ''],
		content_id 	=>		[21, 'numer',    '_hid',		8,		0,  '1', ''],
		record_id	=>		[22, 'numer',    '_hid',		8,		0,  '0', ''],
		wykonawca_id	=>	[23, 'numer',    '_ao',			8,		0,  '0', ''],
		contest_id		=>	[24, 'combo',     '_ao_ne',		8,		1,  '0',          'contest']
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
	my $self = shift;
	my $rec = $self->rec;
	$self->SUPER::preProcess(@_);

	$rec->{avatar} = Wywrota::Object::User->new($rec)->recordSmall;

	$rec->{data_przyslania} = normalnaData($rec->{'data_przyslania'},'friendly_notime');
	$rec->{data_publikacji} = normalnaData($rec->{'data_publikacji'},'friendly_notime');

	$rec->{length} = qq~<span class="podTime">czas:</span> ~ . formatTime($rec->{'czas_trwania_sec'}) if ($rec->{'czas_trwania_sec'});
	$rec->{size} = formatBytes($rec->{'rozmiar_pliku_byte'});

	if ($rec->{record_id}) {
		$rec->{tekstHtml} = "przeczytaj tekst:<br>";
		$rec->{tekstHtml} .= Wywrota::Controller::includePage("db=literatura&generate=1&mh=1&id=$rec->{record_id}&nomore=1", "1d");
	}

	$rec->{tytul} = dehtml($rec->{tytul});
	$rec->{autor} = dehtml($rec->{autor});
	$rec->{komentarz} = smartContent($rec->{komentarz});
	
	$rec->{comment_str} = "<span class=\"textComments\">$rec->{_comment_cnt}&nbsp;".plural($rec->{_comment_cnt}, 'komentarz')."</span>" if ($rec->{_comment_cnt});

	return $self;
}


sub recordSmall {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();
	my ($output, $class);


	$class = ' nutka' if ($rec->{val}{typ}==2);

	$output = qq~
		<div class="podcastItemSm $class" id="$rec->{uid}">$rec->{prizeHTML}
			<h3><a href="$rec->{uri}" class="podTitleSm">$rec->{tytul} - $rec->{autor}</a></h3>
			<span class="itemVotes">$rec->{rating} $rec->{vote_count}</span>
			$rec->{comment_str}  
		</div>
	~;

	return  $output;
}



sub record {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();
	my ($output, $class, $photoRec);

	$rec->{komentarz} = cutTextTo( dehtml($rec->{komentarz}), 120 );
	$rec->{avatar} =~ s/href=\"[^\"]*\"/href="$rec->{uri}"/g;
	$class = ' nutka' if ($rec->{val}{typ}==2);
	
	# promo
	if ($rec->{val}{typ}==3) {
		if ($rec->{wykonawca_id}) {
			$photoRec = Wywrota->db->quickHashRef("SELECT nazwa_pliku FROM site_images WHERE wykonawca_id = $rec->{wykonawca_id} AND stan=1  AND _active=1 ORDER BY isdefault DESC LIMIT 1");
		}

		$rec->{avatar} = qq~
			<div class="avatar">
			<a href="$rec->{uri}"><img src="$config{'file_server'}/pliki/site_images/$photoRec->{nazwa_pliku}-px"></a>
			</div>
			~ if ($photoRec->{nazwa_pliku});
		$class = ' nutka';
	}


	$output = qq~
		<div class="podcastItem" style="clear:left" id="$rec->{uid}">

		
			$rec->{prizeHTML}
			
			<h3><a href="$rec->{uri}">$rec->{tytul} - $rec->{autor}</a></h3>
				$rec->{komentarz} 
			<span class="textDate">
				$rec->{data_publikacji}
				<div class="textContests">$rec->{'contest_id'}</div>
			</span>
		</div>
	~;
	return  $output;

}



sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return $rec->{autor} . " - " .$rec->{tytul};
}


1;



