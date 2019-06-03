package Wywrota::Object::RSS;

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
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>			[0, 'auto',     '_hid',			8,		1,  '',          ''],
		title	=>		[1, 'alpha',	'title',		128,	1,  '',          ''],
		name	=>		[2, 'alpha',	"inputWide",	24,		1,  '',          ''],
		wywrotek=>		[3, 'alpha',	"inputWide",	256,	1,  '',          '']
	 };

# --------------------------------------------------------



sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	return $self;
}




sub record {
# --------------------------------------------------------
	my $output;
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	$output .= qq~
		<div class="rss3d" >
		<a href="/rss/$rec->{name}.xml">$rec->{title}</a><br>
		$config{site_url}/rss/$rec->{name}.xml
		$rec->{edit_icons_sm}		
		</div> 
	~;

	return $output;
}



1;