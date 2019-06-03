package Wywrota::Object::View::PageView;

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


sub recordFormAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;

	Wywrota->sysMsg->push( msg('page_no_parent'), 'warn') if (!$object->{rec}{parent_id});

	return $self->SUPER::recordFormAdd($object);
}



sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $output;
	$output .= qq~<p><a href="/db/pages/add" class="arPlus"><b>dodaj nową stronę</b></a>~;
	$output .= $self->SUPER::searchHeader(@_);
	$output .= qq~
		<table>
		<tr>
			<th>id</th>
			<th>tytuł</th>
			<th></th>
		</tr>

	~;
	return $output;

}

sub searchFooter {
# --------------------------------------------------------
	my $self = shift;
	my $output;
	
	$output .= qq~
		</table>
	~;
	$output .= $self->SUPER::searchFooter(@_);
	$output .= qq~
		<p><a href="/db/pages/add" class="arPlus"><b>dodaj nową stronę</b></a>
		<p><a href="/site/map.html" class="arRight"><b>mapa strony</b></a>
	~;
	return $output;

}

1;