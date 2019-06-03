no warnings 'redefine';
package Wywrota::Object::Manager::BaseManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Class::Singleton';

use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::DAO::ContentDAO;


sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $config = shift;
	my $self  = bless { config=>$config }, $class;

	$self->{dao} = Wywrota::DAO::ContentDAO->instance();

	return $self;
}



sub landingPage {
# --------------------------------------------------------
	return Wywrota->cListView->viewSearch();
}

sub initContentTemplate {
# --------------------------------------------------------
}



sub action {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $output;
	my $action = $nut->in->{a} || $nut->in->{action};

	$output = Wywrota->unknownAction($action);
	$output .= "<h1>Base".$nut->request->{content}{current}{title}."</h1>";
	$output .= Wywrota::Log::debugObject($self);

	return $output;
}

sub config {
#-----------------------------------------------------------------------
	my $self=shift;
	return $self->{config};
}


sub getTextRecord {
#-----------------------------------------------------------------------
	my $self=shift;
	$self->{dao}->getTextRecord(@_);
}


sub onObjectAdd {
#-----------------------------------------------------------------------
	my $self=shift;
	return;
}

sub onObjectEdit {
#-----------------------------------------------------------------------
	my $self=shift;
	return;
}

sub onObjectDelete {
#-----------------------------------------------------------------------
	my $self=shift;
	return "";
}

sub onAddToFavorites {
#-----------------------------------------------------------------------
	return;
}

sub onRemoveFromFavorites {
#-----------------------------------------------------------------------
	my $self=shift;
	return;
}

sub getSqlAddFields {
#-----------------------------------------------------------------------
	my $self=shift;
	return "";
}

sub getSqlAddJoin {
#-----------------------------------------------------------------------
	my $self=shift;
	return "";
}

sub customQuery {
#-----------------------------------------------------------------------
	my $self=shift;
	return "";
}

sub getSqlAddConditions {
#-----------------------------------------------------------------------
	my $self = shift;
	my $mode = shift;
	my $getDeleted = shift;

	return "" if ($getDeleted);
	return  " AND rec._active=1 ";
}


1;