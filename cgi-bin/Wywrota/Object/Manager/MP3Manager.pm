package Wywrota::Object::Manager::MP3Manager;

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
use Wywrota::Log;
use Clone qw(clone);

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';


sub onObjectAdd {
# --------------------------------------------------------
	shift->onObjectEdit(@_);
}



sub initContentTemplate {
# --------------------------------------------------------
	my $self=shift;
	my $nut=shift;

	if ($nut->in->{typ}==1 ) {
		$nut->request->{content}{current}{page_id}=65;
		$nut->request->{content}{current}{page}= clone (Wywrota->page->{65});
	}
}


1;