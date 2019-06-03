package Wywrota::Object::SiteImages;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Utils;
use Wywrota::Log;
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;

use HTML::Entities;

our @ISA = qw(Wywrota::Object::BaseObject);




# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'auto',      '_hid',    8,		1,  '',          ''],
		nazwa_pliku	=>		[1, 'image',	 '',		256,	1,  '',          'file'],
		opis	=>			[2, 'alpha',	 '',		256,	0,  '',          'podpis'],
		user_id=>			[4, 'numer',     '_hid',	16,		1,  '0',         ''],
		typ			=>		[5, 'radio',     '_hid',		1,		1,  '1', ''],
		data_przyslania	=>	[6, 'date',      '_hid',	60,		1,  'Wywrota::Utils::getDate()',   ''],
		wykonawca_id=>		[7, 'numer',     '_hid',	16,		0,  '',         ''],
		article_id=>		[8, 'numer',     '_hid',	16,		0,  '',         ''],
		isdefault =>		[9, 'checkbox',  '_ao',		16,		0,  '0',         ''],
		source	=>			[10, 'alpha',    '_hid',	32,		0,  '',	        'source']
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
	my $suffix = $Wywrota::in->{suffix} || $Wywrota::in->{postfix} || "sq";

	$self->SUPER::preProcess(@_);

	$rec->{suffix}  = $suffix;
	$rec->{thumbnail} = $rec->{nazwa_pliku} ."-$suffix";
	$rec->{url_thumbnail} = "$config{'file_server'}/pliki/site_images/$rec->{thumbnail}";
	$rec->{url_image} = "$config{'file_server'}/pliki/site_images/$rec->{nazwa_pliku}-lg";
	$rec->{url_image_s1} = "$config{'file_server'}/pliki/site_images/$rec->{nazwa_pliku}-s1";

	$rec->{opis} = dehtml($rec->{opis});
	#$rec->{opis} =~ s/\"//g;
	$rec->{opis} = HTML::Entities::encode($rec->{opis}, '<>&"\'');

	return $self;
}



sub record {
# --------------------------------------------------------

	my $self = shift;
	my $rec = $self->rec;
	my ($output, $mod, $default, $link, $add, $action);

	$self->preProcess();

	$link = qq~href="$rec->{url_image}" class="fancy" rel="group" title="$rec->{opis}"~;


	if (Wywrota->per('mod')) {

		if ($Wywrota::in->{article_include}) {
			$mod = qq~ <a class="arDot" href="javascript:void(0);" onclick="setMainPhoto($rec->{id}, '$rec->{nazwa_pliku}'); return false;">główne</a>~;
		
		} elsif ($rec->{val}{typ} == 1 && $rec->{val}{user_id} ==  $Wywrota::session->{user}{id}) {
			$mod = qq~ <a class="arDot " href="javascript:void(0);" onclick="myAjax('setUserPhoto', '$self->{uid}');return false;">główne</a>~;
		} 

		$rec->{edit_icons_sm} =~ s/<\/div>$/$mod<\/div>/g;
		
	}

	if ($Wywrota::in->{article_include}) {
		$link = qq|
			href="javascript:void(0);" style="cursor: alias" title="wstaw do edytora"		
			onmousedown="CKEDITOR.instances.wysywig_tresc.insertHtml(
				'<img src=\\'$config{'file_server'}/pliki/site_images/$rec->{nazwa_pliku}-s1\\' title=\\'$rec->{opis}\\'  class=\\'makeBorder\\'>' );"
		|;

	}


	# add stuff to wykonawcy
	if ($rec->{val}{typ}==2) {
		$add .= "&nbsp; przysłał: &lt;a href='/ludzie/$rec->{wywrotid}'&gt;$rec->{ludzie_imie}&lt;a&gt;"
	}

	$output .= qq~
		<div class="photo siteImg photo_$rec->{suffix}" id="$rec->{uid}">
			<a $link><img src="$rec->{url_thumbnail}" ></a>
			$rec->{edit_icons_sm}
		</div>
	~;


	return $output;
}


sub recordSmall {
# --------------------------------------------------------

	my $output;
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	$output .= qq~
		<div class="onePhoto" id="$rec->{uid}">
			<div class="photoFile">
			<a href="$rec->{url_image}" class="fancy" rel="group" title="$rec->{opis}">
				<img src="$rec->{url_thumbnail}" >
			</a>
			</div>
		</div>

	~;

	return $output;
}



1;