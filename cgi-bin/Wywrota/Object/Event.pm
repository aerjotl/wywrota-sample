package Wywrota::Object::Event;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Utils;
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>			[0, 'numer',    '_hid',			8,		1,  '',          ''],
		title		=>	[1, 'alpha',	'_hid',			128,	0,  '',   'title'],
		information	=>	[2, 'alpha',	'_hid',			60000,	0,  '',   'information'],
		user_id		=>	[3, 'numer',    '_hid',			16,		1,  '',         ''],
		date_from	=>	[4, 'date',		'inputSm',		20,		0,  '', 'date_from'],
		date_to		=>	[5, 'date',		'inputSm',		20,		0,  '', 'date_to'],
		city		=>	[6, 'alpha',	'inputSm',		128,	0,  '', 'city'],
		location	=>	[7, 'textarea',	'txtAreaSm2',	255,	0,  '', 'location'],
		article_id	=>	[8, 'numer',	'_hid',			20,		0,  '', ''],
		auspices	=>	[9, 'checkbox', '_ao',			6,		0,  '', 'auspices'],
		date_added	=>	[10, 'date',	'_hid',			20,		0,  '', 'date_added']

	 };



sub new {
# --------------------------------------------------------
	my ($class, $rec, $prefix) = @_;
	
	if ($prefix) {
		my $newRec = {};
		foreach (keys %{$rec}) {
			if (/$prefix(.*)/) {
				$newRec->{$1} = $rec->{$_};
			}
		}
		$rec = $newRec;
	}

	Wywrota->debug($rec);

	my $self = $class->SUPER::new($rec);
	return $self;
}


sub preProcess {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;

	$self->SUPER::preProcess(@_);

	$rec->{title_html} = dehtml($rec->{title});

	$rec->{information} = smartContent($rec->{information} );

	# with time
	$rec->{date_from_} = normalnaData($rec->{'date_from'}, 'normal');
	$rec->{date_to_} = normalnaData($rec->{'date_to'}, 'normal');
	$rec->{date_from_} = qq~<span class="date">$rec->{date_from_}</span>~ if ($rec->{date_from_});
	$rec->{date_to_} = qq~<span class="date">$rec->{date_to_}</span>~ if ($rec->{date_to_});
	$rec->{date_from_} = "od: " . $rec->{date_from_} if ($rec->{date_from_} && $rec->{date_to_} );
	$rec->{date_to_} = "<br>do: " . $rec->{date_to_} if ($rec->{date_from_} && $rec->{date_to_} );

	# withouth time
	$rec->{date_from} = normalnaData($rec->{'date_from'}, 'notime');
	$rec->{date_to} = normalnaData($rec->{'date_to'}, 'notime');
	$rec->{css} = " auspices" if ($rec->{auspices});
 	$rec->{photo} = $rec->{photo} = Wywrota->t->getPhotoCode({
		id => $rec->{_image_filename}, 
		width => 100, 
		height => 60,
		lazy_load => 1
	});
	$rec->{photo} = qq|<img src="$config{'file_server'}/thumb/?src=/gfx/megaphone-180.png&w=100&h=60" alt="">| if (!$rec->{photo});


	$rec->{location_html} = qq~<span class="locationSm">$rec->{location}<br>$rec->{city}</span>~ if ($rec->{location} || $rec->{city});
	$rec->{location} = "<br>" . $rec->{location} if ($rec->{date_from_} && $rec->{date_to_} );
	$rec->{event_info} = qq~
		<div class="eventInfo">
			$rec->{date_from_} 
			$rec->{date_to_} 
			$rec->{location_html}
		</div>			
	~ if ($rec->{date_from} || $rec->{date_to} || $rec->{location} );


	if ($rec->{date_from_}) {
		if ($rec->{date_from} eq $rec->{date_to}) {
			$rec->{date_to} ="";
		} elsif ($rec->{date_from} and $rec->{date_to} ) {
			if ((substr($rec->{date_from}, 3) eq substr($rec->{date_to}, 3)) or
				(substr($rec->{date_from}, 2) eq substr($rec->{date_to}, 3)) ) {
				$rec->{date_from} = int(substr($rec->{date_from}, 0, 3));
			}
			$rec->{date_to} = "–".$rec->{date_to};
		}
		$rec->{event_info_sm} = qq~
			<span class="eventInfoSm">$rec->{date_from}$rec->{date_to}</span>			
		~;
	}
	$rec->{url} = "/db/artykuly/".$rec->{'article_id'};
	return $rec;
}



sub recordSmall {
# --------------------------------------------------------

	my ($output);
	my $self = shift;
	my $rec = $self->rec;
	$rec->{suffix} = $Wywrota::in->{suffix} || 'px';
	
	$self->preProcess();

	$rec->{atitle} = cutTextTo($rec->{atitle}, 40);
	
	$output = qq~
		<div class="event" id="$rec->{uid}">
			<a href="$rec->{url}">$rec->{photo}<br>$rec->{atitle}</a>
		</div> 
	~;

	return $output;
}




sub record {
# --------------------------------------------------------

	my ($output);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();


	$output = qq~
		<div class="eventFull $rec->{css}" id="$rec->{uid}">
			<a href="$rec->{url}">
				$rec->{atitle}
				$rec->{information}<br>
			</a>
			$rec->{event_info_sm}
			$rec->{location_html}

		</div> 
	~;

	return $output;
}

1;