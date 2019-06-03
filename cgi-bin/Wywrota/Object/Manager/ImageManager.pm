package Wywrota::Object::Manager::ImageManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use HTTP::Date;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';




sub action {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $output;
	my $action = $nut->in->{a} || $nut->in->{action};

	Wywrota->trace("in ImageManager : action");

	if    ($action eq 'zoom')   { 
		$output = $self->zoomImage();
	} 		
	elsif    ($action eq 'dzial')   { 
		$output = Wywrota->view->view->displayDzial();
	} 
	elsif    ($action eq 'hpPolecamy')   { 
		$output = $self->hpPolecamy();
	} 
	else { 
		$output = Wywrota->unknownAction($action);
	}


	return $output;
}

sub hpPolecamy {
# --------------------------------------------------------
	my $self = shift;

	my $query = Wywrota->cListEngine->buildFullQuery($Wywrota::request->{content}{current}, undef, "rec.wyroznienie>1 AND rec.stan=2") . " ORDER BY data_publikacji DESC";
	my $rec = Wywrota->db->quickHashRef($query);
	my $object = Wywrota->content->createObject($rec, "Image");

	$object->preProcess();

	$object->rec->{photo} = Wywrota::Object::User->new($object->rec)->recordSmall;

	Wywrota->view->view->hpPolecamy($object);
}


sub onObjectAdd {
# --------------------------------------------------------
	shift->onObjectEdit(@_);
}

sub onObjectEdit {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $tablename = $object->config->{'tablename'};
	my $fileName = "$config{'www_dir'}/pliki/$tablename/$rec->{'plik'}";

	eval {
		my $srcimage = GD::Image->newFromJpeg($fileName, 1);
		my ($srcW,$srcH) = $srcimage->getBounds();
		Wywrota->db->execWriteQuery(qq~UPDATE $tablename SET img_width=$srcW, img_height=$srcH WHERE id = $rec->{id}~);
	};
	if ($@) {
		return "ERROR!! $@\n";
	}

}


sub zoomImage {
# --------------------------------------------------------
	my $self = shift;
	my $object = Wywrota->content->getObject( $Wywrota::in->{view} || $Wywrota::in->{print} || $Wywrota::in->{id}, undef, "rec._active=1");

	Wywrota->view->view->zoomImage($object);
}


sub landingPage {
# --------------------------------------------------------
	return Wywrota->content->includeFile("sztuka/index.html");
}



1;