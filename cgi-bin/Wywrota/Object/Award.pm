package Wywrota::Object::Award;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Wywrota::Utils;
use Data::Dumper;
use Wywrota::Object::BaseObject;
our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>			[0, 'auto',     '_hid',			8,		1,  '',          ''],
		content_id	=>	[1, 'numer',     '_hid',		6,		1,  '', ''],
		record_id	=>	[2, 'numer',     '_hid',		6,		1,  '', ''],
		award_date	=>	[3, 'date',      '_ao_ne',		60,		1,  'Wywrota::Utils::getDate()',	'award_date'],
		prize_info	=>	[4, 'textarea',	 'txtAreaSm',	200000,	0,  '',								'prize_info'],
		sent_date	=>	[5, 'date',      '',			60,		0,  '',								'sent_date'],
		user_id		=>	[6, 'numer',     '_hid',		16,		0,  '',         '']
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

	$rec->{award_date} = normalnaData($rec->{award_date}, 0);
	$rec->{sent_date} = normalnaData($rec->{sent_date}, 0);
	$rec->{object} = Wywrota->content->getObject($rec->{record_id}, $rec->{content_id}, undef, 1);
	return $self if (!$rec->{object});

	$rec->{objectHtml} = $rec->{object}->recordSmall();
	$rec->{authorObj} = Wywrota->content->getObject($rec->{object}{rec}{user_id}, 'User', undef, 1);
	return $self if (!$rec->{authorObj});


	if ($rec->{sent_date}) {
		$rec->{sent_date} = qq~<div class="txtnews">wysłano: $rec->{sent_date}</div>~;
	} else {
		$rec->{sent_date} = qq~<div class="txtnews r">nagrody jeszcze nie wysłano</div>~;
	}

	# secure personal information
	if ($self->per('admin')) {
		if ($rec->{authorObj}{rec}{adres}) {
			$rec->{safe_adres} = smartContent($rec->{authorObj}{rec}{adres});
		} else {
			$rec->{safe_adres} = qq~brak adresu <a href="/db/ludzie/popup/1/modify/$rec->{authorObj}{rec}{id}?ie=UTF-8&iframe" class="arMod txtnews fancy">uzupełnij</a>~;
		}
		$rec->{safe_adres} .= qq~<br><a href="/message/send/user/$rec->{authorObj}{rec}{id}?ie=UTF-8&iframe" class="emailLink txtnews fancy">wyślij wiadomość</a><br>~;
	} else {
		$rec->{prize_info}='';
		$rec->{sent_date} ='';
	}

	return $self;
}




sub recordSmall {
# --------------------------------------------------------
	my $output;
	my $self = shift;
	$self->preProcess();

	my $rec = $self->rec;

	$output .= qq~
		<tr>
		<td>
			$rec->{objectHtml}
			<br class="clrl">
			<div class="txtnews">nagrodzono: $rec->{award_date}</div>
		</td>
		<td>
			<a href="/ludzie/$rec->{authorObj}{rec}{wywrotid}" class="ludek"><b>$rec->{authorObj}{rec}{imie}</b></a> <br>
			$rec->{safe_adres}
		</td>
		<td>
			$rec->{edit_icons_sm}<br>
			$rec->{prize_info}<br>
			$rec->{sent_date}  $rec->{ludzie_imie}
		</td>
		</tr>

		~;

	return $output;
}



sub record {
# --------------------------------------------------------
	my $output;
	my $self = shift;
	$self->preProcess();

	my $rec = $self->rec;

	$output .= qq~
		<div class="awardSmall">
			$rec->{objectHtml}
			<br class="clrl">
			<div class="txtnews">nagrodzono: $rec->{award_date}</div>
			<a href="/ludzie/$rec->{authorObj}{rec}{wywrotid}" class="ludek"><b>$rec->{authorObj}{rec}{imie}</b></a> <br>
			$rec->{edit_icons_sm}<br>
		</div>

		~;

	return $output;
}



1;