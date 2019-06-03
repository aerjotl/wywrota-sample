package Wywrota::Object::Article;

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
use Wywrota::Utils;
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;
use Date::Parse;

use Exporter 'import';

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'auto',		'_hid',		8,			1,  '',          ''],
		tytul	=>			[1, 'alpha',	'title',	100,		1,  '',          'article_title'],
		tytul_urlized	=>	[2, 'alpha',    '_hid',		100,		0,  '',	         ''],
		tresc	=>			[3, 'alpha',	'html',		300000,		0,  '',          ''],

		autor	=>			[4, 'alpha',     '',		80,			1,  '$Wywrota::session->{user}{name}',	        ''],
		autor_urlized	=>	[5, 'alpha',     '_hid',	80,			0,  '',	        ''],
		user_id=>			[6, 'numer',     '_ao',		16,			1,  '',         'user_id'],
		data_przyslania	=>	[7, 'date',      '_hid',	60,			0,  '',			''],
		data_publikacji	=>	[8, 'date',      '_hid',	60,			0,  'Wywrota::Utils::getDate()',			''],
		lang			=>	[9, 'combo',     '_hid',	8,			1,  '1',		'language'],
		source	=>			[10, 'alpha',     '_ao',	32,			0,  '',	        'source'],

		typ	=>				[11, 'combo',    '',		60,		1,  '',          		'category'],
		category		=>	[12, 'radio',	  '',       6,		0,  '1',			'content_type'],
		recommend		=>	[13, 'radio',  '_ao',    6,		0,  '2',				'visibility'],
		show_photo_list	=>	[14, 'checkbox',  '',		6,		0,  '',				'show_photo_list'],

		stan	=>			[15, 'radio',      '_ao',       10,         1,  '1',		''],
		_comment_cnt	=>	[16, 'numer',	   '_hid',      8,          0,  '0',		''],
		_image_id		=>	[17, 'numer',      '_hid',      8,          0,  '',			''],
		_image_filename	=>	[18, 'alpha',      '_hid',      255,        0,  '',			''],
		_fav_cnt	=>		[19, 'numer',      '_hid',      8,          0,  '0', 		''],
		contest_id		=>	[20, 'combo',      '_ao_ne',	8,          1,  '0',		'contest'],
		tags	=>			[21, 'textarea',   '',	        4096, 		0,  '',         'article_tags'],
		html_snippet=>		[22, 'textarea',   '_ao',		300000,		0,  '',         'html_snippet'],
		komentarz=>			[23, 'textarea',   '_ao',		1024,		0,  '',         'introduction'],
		external_id	=>		[24, 'numer',      '_hid',		8,          0,  '',         ''],
		json		=>		[25, 'alpha',      '_hid',	    300000,		0,  '',         ''],
		subtyp		=>	    [26, 'alpha',	   '_hid',      16,			0,  '',			'content_type'],

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
	my ($output, $event);
	my $self = shift;
	my $rec = $self->rec;

	$self->SUPER::preProcess(@_);
	$self->SUPER::processTextObject();

	$rec->{tytul} = avoidUppercase($rec->{tytul});
	$rec->{data_przyslania_} = normalnaData($rec->{val}{data_przyslania},'friendly_notime');
	$rec->{data_publikacji_} = normalnaData($rec->{val}{data_publikacji},'friendly_notime');
	$rec->{data_przyslania} = normalnaData($rec->{val}{data_przyslania},0);
	$rec->{data_publikacji} = normalnaData($rec->{val}{data_publikacji},0);

	# event
	if (exists($rec->{event_id}) ) {
		if ($rec->{event_id}) {
			$event = Wywrota->content->createObject($rec, 'Event', 'event_' );
			$event->rec->{article_id} = $rec->{id};
		}
	} elsif ($rec->{id}) {
		$event = Wywrota->content->getObject(undef, 'Event', 'article_id = '.$rec->{id});
	}

	if ($event) {
		$event->preProcess;
		$rec->{event_info} = $event->rec->{event_info};
		$rec->{event_info_sm} = $event->rec->{event_info_sm};
		$rec->{auspices} = $event->rec->{val}{auspices};
		$self->{event_object} = $event;
	}

	$rec->{color} = findValueUpTree('color', Wywrota->dict->getPageId('typ', $rec->{val}{typ}, 'Article') );
	$rec->{color_name} = $config{'colorTable'}[$rec->{color}];
	$rec->{comment_str} = "<span class=\"textComments\">$rec->{_comment_cnt}&nbsp;".plural($rec->{_comment_cnt}, 'komentarz')."</span>" if ($rec->{_comment_cnt});

	#  format of the image:
	#  <img title="" class="makeBorder" src="http://wywrota.pl:81/pliki/site_images/4664db92_jpg-s1">
#	my $title = HTML::Entities::encode($rec->{tytul}, '<>&"\'');
	$rec->{tresc} =~ s/<(img[^>]+)(class=\"makeBorder\")([^>]+src=\")([^>\"]+)(\-[^>\-\"]+\")([^>]*)>/<a href="$4-lg" $6 class="makeBorder"><$1$3$4$5$6><\/a>/g;

	$rec->{photo} = Wywrota->t->getPhotoCode({
		id => $rec->{_image_filename}, 
		width => $Wywrota::in->{img_width}, 
		height => $Wywrota::in->{img_height},
		suffix => $rec->{suffix},
		lazy_load => !$Wywrota::in->{no_lazy_load}
	});

	$rec->{image_filename} = $rec->{_image_filename};

	if (!$Wywrota::in->{nometa}) {
		$rec->{'intro'} = dehtml($rec->{'komentarz'});
		if (length($rec->{'intro'}) <200 ) {
			$rec->{'intro'} = $rec->{'intro'} . "<p>" . cutTextTo( dehtml($rec->{'tresc'}), 200) ;
		}
		
	} else {
		$rec->{'intro'} = cutTextTo( dehtml($rec->{'komentarz'}), 150);
		if (length($rec->{'intro'}) <10 ) {
			$rec->{'intro'} =  cutTextTo( dehtml($rec->{'tresc'}), 150);
		}
	}

	if ($rec->{'tresc'} =~ /youtu\.be|youtube.com|vimeo.com/) {
		$rec->{'has_video'} = 1;
	}
	
	return $self;
}



sub recordSmall {
# --------------------------------------------------------
	my $output;
	my $self = shift;
	my $rec = $self->rec;
	
	$rec->{suffix} = $Wywrota::in->{suffix} || 'sq';
	$self->preProcess();
	my $class;
	
	
	$class = 'auspices' if ($rec->{auspices});
	$class .= " listIndex".$self->listIndex;
	
	if ($self->listIndex == 1) {
		return record($self);
		$rec->{photo} = '';
	} else {
		$rec->{photo} = '';
	}
	
	$output = qq~
		<li class="$class "><a href="$rec->{uri}" class="accent">$rec->{photo}$rec->{'tytul'}</a> </li>
	~;
	return $output;
}


sub record {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$rec->{suffix} = $Wywrota::in->{suffix} || 'med';
	$self->preProcess();
	
	return Wywrota->t->process(
		$Wywrota::in->{template} ? "object/article_record_$Wywrota::in->{template}.html" : 'object/article_record.html' , {
		rec		=>	$rec,
		obj		=>	$self
	});

}




sub recordNewsletter {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$rec->{suffix} = $Wywrota::in->{suffix} || 'med';
	$self->preProcess();
	my ($output, $photo);

	$photo = qq~<a href="$rec->{uri}" style="float: left; margin-right: 12px; margin-bottom: 24px;"><img src="$config{'file_server'}/pliki/site_images/$rec->{_image_filename}-$rec->{suffix}" style="margin:2px 10px 10px 5px;	-webkit-border-radius: 5px;	-khtml-border-radius: 5px;		-moz-border-radius: 5px;	border-radius: 5px;	-moz-box-shadow: 2px 2px 2px #aaa;	-webkit-box-shadow: 2px 2px 2px #aaa;	box-shadow: 2px 2px 2px #aaa;"></a>~ if ($rec->{_image_filename});

	$rec->{autor} .= qq~<br>($rec->{data_publikacji})~ if ($Wywrota::in->{putDate});

	$output .= qq~
			$photo 
			<a href="$rec->{uri}" style="text-decoration: none; font-family: arial, helvetica; font-size: 18px; margin-top: 6px; color: red; font-weight: bold;">$rec->{'tytul'}</a><br>
			<span style="font-family: helvetica, arial;">
				<a href="$rec->{uri}" style="text-decoration: none; font-family: helvetica, arial;">
					$rec->{'komentarz'} 
					<i>- $rec->{'autor'}</i>
				</a>
				$rec->{event_info_sm}
			</span>

		<div style="margin: 10px; clear: both;">
		$output 
		</div>
	~;

	return $output;
}




sub validate {
# --------------------------------------------------------

	my $self = shift;
	my $mode = shift;
	my $rec = $self->rec;

	Wywrota->trace("Article validate");
	
	my $status = $self->SUPER::validate($mode);


	if (!$self->val('_image_id'))  {
		push(@{$self->{errors}}, "<b>Zdjęcie</b> – Dodaj przynajmniej jedno zdjęcie do tego artykułu");	
		$status = "err";
	}
	
	return $status;

}


sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return ($rec->{tytul} || "bez tytułu");
}
