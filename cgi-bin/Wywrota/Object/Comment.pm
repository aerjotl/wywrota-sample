package Wywrota::Object::Comment;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Log;
use Wywrota::Object::BaseObject;
use Wywrota::Object::User;
use Wywrota::Dictionary;

use Data::Structure::Util qw(_utf8_off _utf8_on);

our @ISA = qw(Wywrota::Object::BaseObject);




# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>			[0, 'auto',      '_hid',		16,		1,  '',          ''],
		user_id=>		[1, 'numer',     '_hid',		16,		1,  '',         ''],
		autor	=>		[2, 'alpha',     '_hid',		255,	0,  '$Wywrota::session->{user}{name}',	        ''],
		content_id	=>	[3, 'numer',     '_hid',		6,		1,  '', ''],
		record_id	=>	[4, 'numer',     '_hid',		6,		1,  '', ''],
		komentarz	=>	[5, 'textarea',	 'txtAreaSm',	200000,	0,  '',          ''],
		data		=>	[6, 'date',      '_ao_ne',		60,		1,  'Wywrota::Utils::getDate()',   '']
	 };

# --------------------------------------------------------


sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	Wywrota->trace("new comment");
	return $self;
}


sub preProcess {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;

	$rec->{data_} = normalnaData($rec->{data},'friendly');
	$rec->{komentarz} = smartContent($rec->{komentarz}, 1);
	
	$self->SUPER::preProcess(@_);
	return $self;
}


sub recordSmall {
# --------------------------------------------------------
	return record(shift);
}

sub record {
# --------------------------------------------------------
	my ($output, $mod, $avatar, $user, $user_info);
	my $self = shift;
	my $rec = $self->rec;
	my $id = $rec->{id};

	$self->preProcess();

	if ($rec->{user_id}==0 && Wywrota->per('admin')) {
		$rec->{ip} = Wywrota::Log::getCreationIP($self->id, $self->cid);
		$rec->{lastIPUser} = qq|<a href="/site/check/ip/$rec->{ip}" target="_blank" rel="nofollow"><span class="g txtsm1">(sprawdź IP)</span></a>| if ($rec->{ip});
	}
	
	$rec->{ludzie_imie} = ($rec->{user_id}==0)? $rec->{autor} : $rec->{ludzie_imie};
	$rec->{id}=$rec->{user_id};
	$user = Wywrota::Object::User->new($rec);
	$avatar = $user->recordSmall();
	
	

	$user_info = ($rec->{user_id}==0) ? 
		qq|<b title="anonimowy użytkownik">$rec->{autor}</b>| : 
		qq|<a href="$user->{rec}{uri}">$rec->{ludzie_imie}</a>|;


	$output = qq~
		<div class="com" id="$rec->{uid}">
			$avatar
			<div class="comBody">
				<div class="meta">
					$user_info					
					$rec->{data_}
					$rec->{edit_icons_sm}
					$rec->{lastIPUser} 
				</div>
				$rec->{komentarz}
				
			</div>
		</div>
	~;
	return $output;
}


1;