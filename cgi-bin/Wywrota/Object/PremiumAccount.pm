package Wywrota::Object::PremiumAccount;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Wywrota::Config;
use Wywrota::Forms;
use Wywrota::Object::BaseObject;
#use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>			[0, 'auto',      '_hid',		8,		1,  '',         ''],
		notes		=>	[1, 'textarea',  '_ao',			1024,	0,  '',			''],
		valid_until	=>	[2, 'date',      '_ao',			20,		0,  'Wywrota::Utils::getDate( time() + 31532400 )',			''],
		user_id		=>	[3, 'numer',     '_ao_ne',		16,		1,  '',         ''],
		user_id_from=>	[4, 'numer',     '_ao_ne',		16,		0,  '$Wywrota::session->{user}{id}',         ''],
		credits		=>	[3, 'numer',     '_ao',			8,		1,  '1',        '']
	 };

	
# --------------------------------------------------------


sub new {
# --------------------------------------------------------
	my ($class, $rec, $contentDict) = @_;
	my $self = $class->SUPER::new($rec);
	return $self;
}

sub recordSmall {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	return Wywrota::Forms::buildHtmlRecord($rec);
}




sub record {
# --------------------------------------------------------

	my ($output, $mod);
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;

	$output .= Wywrota::Forms::buildHtmlRecord($rec);

	return $output;
}


1;