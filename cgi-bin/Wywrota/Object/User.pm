package Wywrota::Object::User;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Captcha::reCAPTCHA;
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::UserSettings;
use Wywrota::Object::BaseObject;

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id			=> [0, 'auto',       '_hid',    16,			0,  '',          ''],
		wywrotid	=> [1, 'alpha',      '',		64,			1,  '',          ''],
		haslo		=> [2, 'alpha',      '_hid',    32,			1,  '',          ''],
		pytanie		=> [3, 'alpha',      '_hid',	128,		0,  '',          ''],
		odpowiedz	=> [4, 'alpha',      '_hid',	128,		0,  '',          ''],
		imie		=> [5, 'alpha',      '',		32,			1,  '',          ''],
		email		=> [6, 'alpha',      '',		256,		1,  '',          ''],
		adres_www	=> [7, 'alpha',      '',		256,		0,  '',          ''],
		#wiek		=> [8, 'numer',      '',		4,			0,  '',          ''],
		rok_urodzenia=> [9, 'date',      '',		40,			0,  '',		''],
		plec		=> [10, 'numer',     '',		1,			0,  '',          ''],
		adres		=> [11, 'textarea', 'txtAreaSm1',256,		0,  '',          ''],
		skad		=> [12, 'alpha',	 '',		128,		1,  '',          ''],
		wojewodztwo	=> [13, 'numer',     '',		64,			0,  '',          ''],
		adres_zastrz=> [14, 'numer',     '',		100,		0,  '',          ''],
		przeslanie	=> [15, 'textarea',  'txtAreaSm1', 10000,	0,  '',          ''],
		o_sobie		=> [16, 'textarea',  'txtAreaSm1', 10000,	0,  '',          ''],
		co_kocha	=> [17, 'textarea',  'txtAreaSm1', 10000,	0,  '',          ''],
		w_przyszlosci_bedzie => [18, 'textarea', 'txtAreaSm1',	10000,  0,  '',          ''],
		ulubiony_kolor		 => [19, 'alpha',    '',			64,		0,  '',          ''],
		muzyka				 => [20, 'alpha',    '',			512,	0,  '',          ''],
		opinia_o_stronie	 => [21, 'alpha',    '_ao',			10000,	0,  '',          ''],
		data_wpisu			 => [22, 'date',     '',			40,		0,  'Wywrota::Utils::getDate()',   ''],
		wysylac_informacje	 => [23, 'numer',    '_ao',			1024,	0,  '',          ''],
		gg					 => [24, 'numer',    '',			10,		0,  '',          ''],
		last_login			 => [25, 'date',     '',			40,		0,  'Wywrota::Utils::getDate()',   ''],
		_image_filename		 => [26, 'alpha',	 '_hid',		128,	0,  '',          ''],
		_image_id			 => [24, 'numer',    '_hid',		10,		0,  '',          ''],
		_is_premium			 => [25, 'numer',    '_hid',		10,		0,  '0',          ''],
		notka				 => [26, 'alpha',    '_hid',		2000,	0,  '',          ''],
		real_name			 => [27, 'alpha',    '_hid',		128,	0,  '',          ''],
		function			 => [28, 'alpha',    '_hid',		128,	0,  '',          ''],
		facebook_id			 => [29, 'numer',    '_hid',		20,		0,  '',          '']	
	 };

# --------------------------------------------------------



sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	Wywrota->trace("new user");
	$rec->{wywrotid} = lc($rec->{wywrotid});
	return $self;
}



sub preProcess {
# --------------------------------------------------------
	my ($output, $year, $photoRec, $photoCnt, $photo_filename);
	my $self = shift; 
	my $rec = $self->rec;
	$self->SUPER::preProcess(@_);

	my $photo_suffix = shift || 'px';
	($_, $_, $_, $_, $_, $year) = localtime(time());

	$rec->{photo_suffix} = $photo_suffix;
	$rec->{rok_urodzenia} += 1900 if ($rec->{rok_urodzenia} gt 0 and $rec->{rok_urodzenia} lt 100);
	$rec->{data_wpisu} = normalnaData($rec->{data_wpisu}, 0);
	$rec->{data_wpisu} = 'zawsze' if ($rec->{id}==1);
	$rec->{last_login} = normalnaData($rec->{last_login}, 0) if ($rec->{last_login});
	
	$rec->{wiek} = 1900+$year - $rec->{rok_urodzenia} if ($rec->{'rok_urodzenia'});
	$rec->{wiek} = "$rec->{wiek} ". plural($rec->{wiek}, 'rok') if $rec->{wiek};
	$rec->{wiek} = "" if (!$rec->{wiek});

	$rec->{adres_www_link} = $rec->{adres_www};	
	$rec->{adres_www_link} = "http://$rec->{adres_www}" if ($rec->{adres_www} !~ /^http/);	

	$rec->{adres} .= "woj. $rec->{wojewodztwo}" if $rec->{wojewodztwo};
	$rec->{adres} =~ s/\n/<br>/g;

	$rec->{is_premium} =	$rec->{_is_premium}; #Wywrota->mng('PremiumAccount')->isPremium($rec->{id});
	

	if (!$rec->{imie}) {
		$rec->{imie}=$rec->{ludzie_imie};
	}

	$photo_filename = $rec->{_image_filename};
	if (defined $rec->{_ludzie_photo}) {
		$photo_filename = $rec->{_ludzie_photo};
	}
	if (!defined $rec->{user_id}) {
		$rec->{user_id} = $rec->{id};
	}

	if ($photo_filename && length($photo_filename)>3) {

		$rec->{avatar} = qq~<img src="$config{'file_server'}/pliki/site_images/$photo_filename-$photo_suffix" class="av" alt="$rec->{imie}" title="$rec->{imie}">~;

		$rec->{photo} = qq~
		<div class="photo">
			<a href="$config{'file_server'}/pliki/site_images/$photo_filename-lg" title="$rec->{imie}" class="fancy"><img src="$config{'file_server'}/pliki/site_images/$photo_filename-s1"></a>
		</div>
		~;

	} else {

		if ($rec->{user_id} eq "0") {
			$rec->{avatar} = qq~<img src="$config{'file_server'}/gfx/akta_no_photo-anonim-$photo_suffix.gif" title="anonim" class="av">~;
		} else {
			$rec->{avatar} = qq~<img src="$config{'file_server'}/gfx/akta_no_photo-$photo_suffix.gif" class="av">~;
		}

		$rec->{photo} = qq~
		<div class="photo">
			<img src="$config{'file_server'}/gfx/akta_no_photo-med.gif">
		</div>
		~;

	}

	$rec->{edit_icons_sm} = "" if ($rec->{user_id} == $Wywrota::session->{user}{id});

	$rec->{przeslanie} = dehtml($rec->{przeslanie}, 1);
	$rec->{ulubiony_kolor} = dehtml($rec->{ulubiony_kolor}, 1);
	$rec->{w_przyszlosci_bedzie} = dehtml($rec->{w_przyszlosci_bedzie}, 1);
	$rec->{co_kocha} = dehtml($rec->{co_kocha}, 1);
	$rec->{zainteresowania} = dehtml($rec->{zainteresowania}, 1);
	$rec->{o_sobie} = dehtml($rec->{o_sobie}, 1);
	$rec->{skad} = dehtml($rec->{skad}, 1);

	return $self;
}




sub recordSmall {
# --------------------------------------------------------
# maly rekord

	my ($output, $moderator, $premium);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	
	my @groups = split(/,/, $rec->{_user_to_ugroup});

	if (grep(/^1$/, @groups)) {
		$moderator = qq~<img src="/gfx/px.gif" class="userRole userRoleAdmin" title="kierowca"><br>~;
	} elsif (grep(/^4$/, @groups) and $Wywrota::request->{content}{current}{id}==1) {
		$moderator = qq~<img src="/gfx/px.gif" class="userRole userRoleOpLit" title="opiekun literatury"><br>~;
	} elsif (grep(/^8$/, @groups) and $Wywrota::request->{content}{current}{id}==16) {
		$moderator = qq~<img src="/gfx/px.gif" class="userRole userRoleOpGal" title="opiekun galerii"><br>~;
	} else {
		$moderator = qq~~;
	}

	$premium = qq~<div class="premiumPx" title="premium"></div>~ if ($rec->{_is_premium});

	if ($rec->{id}) {
		$output = qq~ 
		<div class="avatar">
			$premium
			<a href="$rec->{'uri'}" class="user-hover" rel="$rec->{hover_url}">$rec->{avatar}</a>
		</div>~;
	} else {
		$output = qq~ 
		<div class="avatar">
			$rec->{avatar}<div class="name">$rec->{'imie'}</div>
		</div>~;
	}

	return $output;
}



sub recordTiny {
# --------------------------------------------------------
# bardzo maly rekord

	my ($output, $premium);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	$premium = qq~<div class="premiumPx" title="premium"></div>~ if ($rec->{_is_premium});

	if ($rec->{id}) {
		$output = qq~ 
		<div class="avatarTiny">
			$premium
			<a href="$rec->{'uri'}" class="user-hover" rel="$rec->{hover_url}">$rec->{avatar}</a>
		</div>~;
	} else {
		$output = qq~ 
		<div class="avatarTiny">
			$rec->{avatar}
		</div>~;
	}

	return $output;
}




sub record {
# --------------------------------------------------------
# duzy rekord

	my ($output, $photo, $dataOutput, $premium );
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

#	$dataOutput .= qq~ $rec->{notka}~ if ($rec->{notka});
#	$dataOutput .= qq~ $rec->{o_sobie}~ if ($rec->{o_sobie});
#	$dataOutput = cutTextTo($dataOutput, 120);

	$premium = qq~<div class="premiumPx" title="premium"></div>~ if ($rec->{_is_premium});

	$output = qq~
		<div class="person" id="$rec->{uid}">
			<div class="avatar">$premium<a href="$rec->{uri}">$rec->{avatar}</a></div>
			<a href="$rec->{uri}" class="imie">$rec->{imie}</a><br>
			<b>$rec->{wiek} $rec->{skad}</b>
		</div>
	~;

	return $output;
}


sub recordBig {
	return shift->recordLead(@_);
}


sub recordLead {
# --------------------------------------------------------
# rekord do leadu

	my ($output, $photo, $dataOutput, $groups, $notkaRed, $czego, $counted );
	my $self = shift;
	my $rec = $self->rec;
	my $suffix = $Wywrota::in->{suffix} || 'sq2';
	$self->preProcess($suffix);

	$dataOutput = qq~$rec->{notka} $rec->{o_sobie}~;
	$dataOutput = cutTextTo($dataOutput, 260);

	# include user groups
	$groups = Wywrota->mng('UserGroup')->readUserGroups($rec->{id});
	if (keys %{$groups} ) {
		foreach (sort ({$groups->{sortorder} <=> $groups->{sortorder}} keys %{$groups})) {
			next if ($_ == 100);	# skip SuperAdmin group
			$notkaRed .= qq~<div class="ugroup_px ugroup_px_$_">$groups->{$_}{nazwa}</div>~;
		}

	}


	if ($rec->{_is_premium}) {
		$rec->{premium_html} = qq~
			<a href="/premium.html" class="starIcon" title="konto Wywrota premium">premium</a>
		~;
	}

	if ($rec->{_active} eq '0') {
		$rec->{active_html} = qq~
			<div><strong class="r">konto nieaktywne</strong></div>
		~;
		
	}
	
	my @visit = (3, 1, 16, 10, 8, 13, 7);
	my $contentCount = Wywrota->content->getCountForUser($rec->{id}, \@visit);

	foreach (@visit) {
		if ($contentCount->{$_}) {
			$czego=Wywrota::Language::plural($contentCount->{$_}, Wywrota->cc->{$_}{keyword});
			$counted .= qq~
				<span class="contentCount$_">
					<strong>$contentCount->{$_}</strong> $czego 
				</span>
			~;
		} 
	}
	

	$output = qq~
		<div class="userLead">
			<div class="photo photo_$suffix"><a href="$rec->{uri}">$rec->{avatar}</a></div>
			<h2><a href="$rec->{uri}">$rec->{real_name} $rec->{imie} $rec->{premium_html}</a></h2>
			<div class="meta">
				<b>$rec->{wiek} $rec->{skad}</b>
				<div class="contentCount">$counted</div>
			</div>
			<div>$dataOutput</div>
			$notkaRed
			$rec->{active_html} 
			<br class='clrl'>
		</div>
		
	~;

	return Wywrota->nav->absoluteLinks($output);
}



sub validate {
# --------------------------------------------------------

	my $self = shift;
	my $mode = shift;
	my $rec = $self->rec;

	my ($status, $found, $query);	
	
	Wywrota->trace("User validate");
	
	$status = $self->SUPER::validate($mode);

	if ($mode eq "add") 	{		# check WywrotID
		
		unless ($Wywrota::in->{'facebook_token'}) {
			
			eval {
				my $captcha = Captcha::reCAPTCHA->new;
				my $result = $captcha->check_answer_v2(
					$config{recaptcha_private_key},
					$Wywrota::in->{'g-recaptcha-response'},
					$ENV{'REMOTE_ADDR'}
				);

				unless ( $result->{is_valid} ) {
					push(@{$self->{errors}}, "<b>Błędny kod zabezpieczający ".$result->{error}."</b>");
					$status = "err";
				}
			};
			if ($@) {
				Wywrota->error("User validate Captcha: ", $@);
				return "err";
			}
		
			if ($Wywrota::in->{url} ne $config{'robot_protection'}) {
				push(@{$self->{errors}}, "<b>robot intrusion detected</b>");
				$status = "err";
			};
		
		};
	
		eval {

			($found) = Wywrota->db->quickArray("SELECT id FROM `ludzie` WHERE wywrotid=?", $self->val('wywrotid') );
			if ($found) {
				push(@{$self->{errors}}, "<b>WywrotID</b> – podany login jest zajęty");	
				$status = "err";
			};
			
			if ($config{site_config_mode} eq 'prod') {
				($found) = Wywrota->db->quickArray("SELECT time FROM log_actions WHERE content_id=6 AND action=2 AND ip=? AND time BETWEEN ? AND ?", $ENV{'REMOTE_ADDR'}, getDate(time()-86400) , getDate(time()) );
				if ($found) {
					push(@{$self->{errors}}, "<b>Multiple registration</b> – z twojego adresu IP (" . $ENV{'REMOTE_ADDR'} . ") już założono konto w ciągu ostatnich 24h");	
					$status = "err";
				};
			};
		};
		if ($@) {
			Wywrota->error("User validate: ", $@);
			return "err";
		}
	}

	if ($self->val('wywrotid') !~ /^[0-9a-z\._-]*$/)  {
		push(@{$self->{errors}}, "<b>zły format WywrotID</b> <br>Tylko małe litery, bez spacji, polskich liter ani znaków specjalnych");	
		$status = "err";
	}
	
	return $status;

}



sub appendUrl {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;

	$rec->{uri} = "/".$self->config->{url}."/".$rec->{wywrotid};

	if (!defined($rec->{url})) {
		if ($rec->{uri} =~ /^http/) {
			$rec->{url} = $rec->{uri};
		} else {
			$rec->{url} = $config{'site_url'}.$rec->{uri} ;
		}
	}

	return $rec;
}


sub getIndexable {
# --------------------------------------------------------

	my $self = shift;
	my $doc = $self->SUPER::getIndexable();


	$doc->{title} 		= $self->val('uname');
	$doc->{author} 		= 'akta wywroty';
	$doc->{content}		= $self->val('introduction') . $self->val('notka') ;		
	$doc->{user_id} 	= $self->val('id');
	$doc->{keywords} 	= $self->val('real_name') . " ".$self->val('wywrotid') ;

	return $doc;
}

sub isPremium	: lvalue	{	
	my $self = shift;
	$self->{rec}->{is_premium}; 	}



1;
