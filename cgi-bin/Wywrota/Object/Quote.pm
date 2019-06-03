package Wywrota::Object::Quote;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

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
		id	=>			[0, 'auto',      '_hid',		8,		1,  '',         ''],
		quote		=>	[1, 'textarea',  'txtAreaSm1',	60000,	1,  '',			''],
		autor		=>	[2, 'alpha',     '',			200,	1,  '',			''],
		user_id		=>	[3, 'numer',     '_ao_ne',		16,		1,  '',         ''],
		size		=>	[4, 'radio',     '',			16,		0,  '1',        '']
	 };



sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	return $self;
}


sub recordSmall {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return Wywrota::Forms::buildHtmlRecord($rec);
}




sub record {
# --------------------------------------------------------

	my ($output, $mod);
	my $self = shift;
	my $rec = $self->rec;

	$output .= qq~
		<div id="$rec->{uid}" class="cytat rec">
		<div>$rec->{quote} $rec->{edit_icons_sm} </div> 
		<div class="cytatAutor">$rec->{autor}</div>
		</div>
	~;

	return $output;
}




sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
}



1;