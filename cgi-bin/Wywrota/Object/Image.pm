package Wywrota::Object::Image;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

#use strict;
use Data::Dumper;
use Wywrota::Log;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'numer',     '_hid',		8,		1,  '',          ''],
		plik	=>			[1, 'image',	 '',			256,	1,  '',          ''],
		podpis	=>			[2, 'alpha',	 'inputWide',	64,		1,  '',          ''],
		podpis_urlized	=>	[3, 'alpha',    '_hid',			64,		0,  '',	        ''],

		komentarz=>			[4, 'textarea',	 'txtAreaSm1',	256,	0,  '',          ''],
		typ			=>		[5, 'combo',     '',			1,		1,  '1', ''],
		temat		=>		[6, 'radio',     '',			3,		1,  '1', ''],
		wyroznienie	=>		[7, 'radio',    '_hid',			10,		1,  '0',  ''],

		user_id=>			[8, 'numer',     '_hid',		16,		1,  '0',         '', ''],
		data_przyslania	=>	[9, 'date',      '_ao_ne',		60,		0,  '',   '', ''],
		data_publikacji	=>	[10, 'date',      '_ao_ne',		60,		0,  'Wywrota::Utils::getDate()',   '', ''],

		can_comment	=>		[11, 'checkbox',	'',			1,		0,  '1',				'can_comment'],
		can_vote	=>		[12, 'checkbox',	'',			1,		0,  '1',				'can_vote'],
		
		_vote_cnt	=>		[14, 'numer',    '_hid',		8,		0,  '0', ''],
		_vote_ratings	=>	[15, 'numer',    '_hid',		8,		0,  '0', ''],
		_vote_func		=>	[16, 'numer',    '_hid',		8,		0,  '0', ''],
		_comment_cnt=>		[17, 'numer',    '_hid',		8,		0,  '0', ''],
		_fav_cnt=>			[18, 'numer',    '_hid',		8,		0,  '0', ''],
		img_width	=>		[19, 'numer',    '_hid',		8,		0,  '0', ''],
		img_height	=>		[20, 'numer',    '_hid',		8,		0,  '0', ''],
		contest_id		=>	[21, 'combo',    '_ao_ne',		8,		1,  '0', 'contest']
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
	my ($hdiff , $wdiff , $newH, $newW, $aspect);
	my $self = shift;
	my $rec = $self->rec;

	$self->SUPER::preProcess(@_);
	Wywrota->error($@) if ($@);

	$rec->{suffix} = $Wywrota::in->{suffix} || $Wywrota::in->{postfix} || "sm";

	$rec->{data_przyslania} = Wywrota::Utils::normalnaData($rec->{data_przyslania}, 1);
	$rec->{data_publikacji} = Wywrota::Utils::normalnaData($rec->{data_publikacji}, 1);

	$rec->{thumbnail} = $rec->{plik} ."-$rec->{suffix}";
	$rec->{podpis} = dehtml($rec->{podpis});
	$rec->{podpis} = "Bez Tytułu" if (!$rec->{podpis});
	$rec->{komentarz} = smartContent($rec->{komentarz});

	$rec->{url_thumbnail} = "$config{'file_server'}/pliki/image/$rec->{thumbnail}";
	$rec->{url_image} = "$config{'file_server'}/pliki/image/$rec->{plik}-lg";
	$rec->{url_image_s1} = "$config{'file_server'}/pliki/image/$rec->{plik}-s1";

	return $self;
}




sub record {
# --------------------------------------------------------

	my ($output, $stan, $star);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	$rec->{'podpis'} = cutTextTo($rec->{'podpis'}, 17);
	$output = qq~
		<div class="photo photo_$rec->{suffix}" id="$rec->{uid}">

			<a href="$rec->{uri}" title="$rec->{podpis}">
				<img src="$rec->{url_thumbnail}">
				<span class="podpis">
					<span class="title">$rec->{podpis}</span><br>
					$star $rec->{autor}
				</span>

			</a>
			
			
		</div>
	~;


	return $output;
}


sub  recordSmall  {
# --------------------------------------------------------

	my $output;
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	$output .= qq~
		<div class="photo photo_$rec->{suffix}" id="$rec->{uid}">
			<a href="$rec->{uri}" title="$rec->{podpis}"><img src="$rec->{url_thumbnail}"></a>
		</div>
	~;

	return $output;
}


sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return $rec->{ludzie_imie} ." ".$rec->{podpis};
}



1;
