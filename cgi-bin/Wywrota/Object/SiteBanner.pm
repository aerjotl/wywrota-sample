package Wywrota::Object::SiteBanner;

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
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);


# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>			[0, 'auto',    '_hid',		8,		1,  '',          ''],
		title		=>	[1, 'alpha',	'',			128,	1,  '',   'title'],
		link		=>	[2, 'alpha',	'',			128,	1,  '',   'target_address_url'], 
		image_file	=>	[3, 'file',		'',			128,	0,  '',   'image_file_120'], 
		user_id		=>	[4, 'numer',    '_hid',		16,		1,  '',         ''],
		sortorder	=>	[5, 'numer',    'inputSm',	6,		1,  '1',         ''],
		on_home		=>	[6, 'checkbox', '',			10,		0,  1,           ''],
		on_literature=>	[7, 'checkbox', '',			10,		0,  0,           ''],
		on_music	=>	[8, 'checkbox', '',			10,		0,  0,           ''],
		on_culture	=>	[9, 'checkbox', '',		10,		0,  0,           ''],
		on_art		=>	[10, 'checkbox', '',		10,		0,  0,           ''],
		on_home2	=>	[11, 'checkbox', '',			10,		0,  0,           'banner Biura Literackiego']
	 };


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

	$rec->{image_file} = $config{'file_server'}.'/pliki/banner/'.$rec->{image_file} if ($rec->{image_file} !~ "\/");

	$rec->{on} = "home " if ($rec->{on_home});
	$rec->{on} .= "literature " if ($rec->{on_literature});
	$rec->{on} .= "music " if ($rec->{on_music});
	$rec->{on} .= "culture " if ($rec->{on_culture});
	$rec->{on} .= "art " if ($rec->{on_art});



	$self->SUPER::preProcess(@_);

}

sub recordSmall {
# --------------------------------------------------------

	my ($output);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	$output = qq~
		<div class="banner" id="$rec->{uid}"> 
			<a href="$rec->{link}" target="_blank"><img src="$rec->{image_file}" title="$rec->{title}" alt="$rec->{title}"></a>
			$rec->{edit_icons_sm}
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
		<div class="bannerFull" id="$rec->{uid}">
			<a href="$rec->{link}" target="_blank"><img src="$rec->{image_file}" title="$rec->{title}" alt="$rec->{title}"></a>
			<h4>$rec->{title}</h4> 
			<span class="txtsm1">
				$rec->{edit_icons_sm}<br>
				$rec->{on},  order: $rec->{sortorder}
			</span>
		</div> 
	~;

	return $output;
}

1;