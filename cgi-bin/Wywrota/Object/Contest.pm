package Wywrota::Object::Contest;

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
		id	=>			[0, 'numer',     -1,    8,		1,  '',          ''],
		#tresc		=>	[1, 'alpha',   '50x6',	60000,		1,  '',   ''],
		#autor		=>	[2, 'alpha',      40,	200,		1,  '',   ''],
		#user_id		=>	[3, 'numer',     -3,	16,		1,  '',         ''],
		#size		=>	[4, 'radio',     40,	16,		0,  '1',         '']
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
	my $object = shift;
	my $rec = $object->rec;
	return Wywrota::Forms::buildHtmlRecord($rec);
}




sub record {
# --------------------------------------------------------

my ($output);
my $self = shift;
my $object = shift;
my $rec = $object->rec;

if (Wywrota->per('mod') ) {
	$mod = qq~ 
		<a class="arDel" href="javascript: if (confirm('Na pewno chcesz skasować ten cytat?')) openPopup('$config{'db_script_url'}/cytaty/deleterecords=1,id=$rec->{id}');"></a>
		<a class="arMod" a href="javascript:openPopup('/db/$Wywrota::request->{content}{current}{url}/modify/$rec->{id}/popup/1')"></a>
	~;
}

$output .= qq~
	<div class="cytat">$rec->{tresc} $mod </div> 
	<div class="cytatAutor">$rec->{autor}</div>
~;

return $output;
}




sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
}

sub landingPage {
# --------------------------------------------------------
	return Wywrota->content->includeFile("konkursy/index.html");
}

sub header {
# -------------------------------------------------------------------------------------
# TODO - check
	return Wywrota->template->header(@_);
}

1;