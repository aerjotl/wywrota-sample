package Wywrota::Object::View::EventView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Language;



sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;

	my ($output);
	$output = qq~
		<h1>Promocja i reklama</h1>
	~;
	$output .= $self->SUPER::searchHeader($queryRes, $tytul);

	return $output;
}


sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
}

1;