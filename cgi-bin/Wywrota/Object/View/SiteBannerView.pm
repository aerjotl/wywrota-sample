package Wywrota::Object::View::SiteBannerView;

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


sub header {
# -------------------------------------------------------------------------------------
	my $self = shift; 
	my $param=shift;
	$param->{nomenu}='bar';
	return $self->SUPER::header($param, @_)
}
	

sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;

	my ($output);
	$output = qq~
		<h1>Promocja i reklama</h1>

		<div>
				<a class="addIcon" href="/db/banner/add/1">Dodaj banner</a>
		</div><br><br>
	~;
	$output .= $self->SUPER::searchHeader($queryRes, $tytul);

	return $output;
}



sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
}

1;