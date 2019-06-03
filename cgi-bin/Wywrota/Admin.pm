package Wywrota::Admin;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict; 
use Exporter; 
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Notification;
use Wywrota::Language;
use Wywrota::Admin::Statystyki;
use Wywrota::Admin::GroupManage;
use Wywrota::Admin::Newsletter;

our @ISA = qw(Exporter);
our @EXPORT = qw(action );


sub action {
# -------------------------------------------------------------------------------------
	my $output;
	my $nut = shift;
	my $action = $nut->in->{adminAction};
	
	if (!$nut->per('admin',3)) {
		return Wywrota::User::unauthorized("Ta sekcja dostępna jest tylko dla administratorów Wywroty.");
	}

	if    ($action eq 'stats')   { $output = Wywrota::Admin::Statystyki::siteStats(); } 
	elsif ($action eq 'assignGroups') { $output = Wywrota::Admin::GroupManage::assignGroups();} 

	elsif ($action eq 'newsletter') { 

		return Wywrota::User::unauthorized("Ta sekcja dostępna jest tylko dla administratorów Wywroty.") if (!$Wywrota::session->{user}{groups}{1} && !$Wywrota::session->{user}{groups}{100});
		$output = Wywrota::Admin::Newsletter::main($nut->in);
		
	} 
	
	elsif ($action eq 'unauthorized') { $output = unauthorized();} 
		
	else { 
		return Wywrota->unknownAction($action);
	}

	
	return $output;
}
