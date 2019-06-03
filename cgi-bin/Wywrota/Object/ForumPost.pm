package Wywrota::Object::ForumPost;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Data::Dumper;

use POSIX qw(ceil floor);
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Utils;
use Wywrota::Object::BaseObject;
use Wywrota::Object::ForumGroup;
use Wywrota::Notification;
use Wywrota::Language;
use Wywrota::Favorites;
use Wywrota::Dictionary;


our @ISA = qw(Wywrota::Object::BaseObject);

my $classCounter=0;
# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'auto',			'_hid',		8,		1,  '',         ''],
		parent_id	=>		[1, 'numer',		'_hid',		8,		0,  '',         ''],
		kat_id		=>		[2, 'numer',		'_hid',		8,		1,  '',         ''],
		user_id=>			[3, 'numer',		'_hid',		16,		1,  '',			''],
		temat	=>			[4, 'alpha',		'title',	255,	1,  '',         'topic'],
		time =>				[5, 'date',			'_hid',		60,		0,  '',          ''],
		tresc_ =>			[6, 'textarea',		'txtAreaMd',50000,	1,  '',          'content'],
		last_child_id	=>	[7, 'numer',		'_hid',		60,		0,  '',			''],
		child_count =>		[8, 'numer',		'_hid',		10,		0,  '1',		''],
		topic	=>			[9, 'numer',		'_hid',		10,		0,  '0',		''],
		wykonawca_id	=>  [10, 'numer',		'_hid',		10,		0,  '0',        '']
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

	$rec->{'time'} = normalnaData($rec->{'time'},1);
	$rec->{'lc_time'} = normalnaData($rec->{'lc_time'},'short');
	$rec->{temat} =~ s/</&lt;/g;
	$rec->{tresc_} = smartContent($rec->{tresc_}, 1);

	return $self;
}


sub recordSmall {
# --------------------------------------------------------
	my ($output, $czego, $one, $class );
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	if ($rec->{child_count}>1) {
		#$czego = Wywrota::Language::plural($rec->{child_count}-1, Wywrota::Language::msg('reply') );
		$czego = $rec->{'child_count'};
	} else {
		$czego = "-";
		$one = qq~ class="one"~;
	}

	if (++$classCounter%2==0) {
		$class = "odd";
	} else {
		$class = "even";
	}


	$output = qq~
		<tr class="$class">
			<td class="link"><a href="$rec->{'uri'}"$one>$rec->{temat}</a></td>
			<td class="autor"><a href="/ludzie/$rec->{wywrotid}">$rec->{ludzie_imie}</td>
			<td class="replies">$czego</td>
			<td class="lastEntry">
				<a href="/ludzie/$rec->{'lc_wywrotid'}"> $rec->{'lc_author'} </a><br>
				$rec->{'lc_time'} 
				</td>
		</tr>
	~;

	return  $output;
}



sub record {
# --------------------------------------------------------
	my ($output, $avatar, $user);
	my $self = shift;
	my $rec = $self->rec;

	$self->preProcess();

	$rec->{id}=$rec->{user_id};
	$user = Wywrota::Object::User->new($rec);
	$avatar = $user->recordSmall();

	$output = qq~
		<div class="com forumPost" id="$rec->{uid}">
			$avatar
			<div class="comBody">
				<div class="meta">
					<a href="$user->{rec}{uri}">$rec->{ludzie_imie}</a>
					$rec->{'time'}
					$rec->{edit_icons_sm}
				</div>
				$rec->{tresc_}
			</div>
		</div>
	~;

	return  $output;
}


sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return $rec->{temat};
}


1;