package Wywrota::View::ContentView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Class::Singleton;
use base 'Class::Singleton';

use strict;
use Wywrota;
use Wywrota::Config;
use Wywrota::Language;
use Wywrota::Nut::Session;
use Wywrota::User;



sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;
	my $app = shift;
	my $mng = shift;
	my ($id, $contentInfo);

	foreach $id (keys %{$app->{cc}}) {
		$contentInfo = $app->{cc}{$id};
		eval "use Wywrota::Object::View::$contentInfo->{package}View;";
		Wywrota->error("ContentView : Error parsing $contentInfo->{package}View ".$@) if ($@);
		$self->{view}{$id} = eval 'Wywrota::Object::View::'.$contentInfo->{package}.'View->instance( $mng->mng('.$id.') )';
		$self->{view}{ $contentInfo->{'package'} } = $self->{view}{$id};
		Wywrota->error("ContentView : Error initialising $contentInfo->{package}View ".$@) if ($@);
	}

	return $self;
}


sub view { 
# --------------------------------------------------------
	my $self = shift;
	my $vid = shift || $Wywrota::request->{content}{current}{id};
	Wywrota->trace("in ContentView view $vid");

	if (defined $self->{view}->{ $vid }) {
		return $self->{view}->{ $vid };
	} else {
		Wywrota->error("Shit view [$vid]");
		return $self->{view}->{0};
	}
}



##########################################################
##						Adding  						##
##########################################################


sub addObjectHtml {
# --------------------------------------------------------

	my $self = shift;
	my $nut = shift;
	my ($status, $object, $objectClass);

	$objectClass = $Wywrota::request->{content}{current}{'package'};
	$object = Wywrota->content->createObject($nut->in, $objectClass);

	# save the object
	($status, $object) = Wywrota->content->addObject($object);

	Wywrota->debug("addObjectHtml: status $status");
	
	if ($status eq "ok") {
		return $self->addSuccess($nut, $object);
	}
	else {
		return $self->addForm($nut, $object);
	}
}



sub addForm {
# --------------------------------------------------------
	my $output;
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	
	$object = Wywrota->content->createDefaultObject($Wywrota::in) unless ($object);
	
	my $form = $self->view->recordFormAdd($object); 
	my $package = $object->getClass();

	$output = $object->getErrors();
	
	$form = qq~

		<form enctype="multipart/form-data" action="/db" method="POST" name="record_form" onsubmit="return checkForm$package(this);">
		<input type=hidden name="db" value="$Wywrota::request->{content}{current}{url}">
		$form 
	~ if ($form !~ /<form/);

	$form = qq~
		$form
		<div class="formButtons"><input type="submit" name="addrecord" value="    wyślij    " class="bold"> </div>
		</form>
	~ if ($form !~ /<\/form>/);	# used in MP3


	return $self->view->wrapHeaderFooter({
		title 	=> $Wywrota::request->{content}{current}{title} . " - dodawanie",	
		nomenu	=>  'bar',
		output	=>  $output . $form ,
		nocache	=>	1,
		nobillboard	=>	1
	});
	
}


sub addSuccessBasic {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my ($output, $new_link);

	Wywrota->trace("ContentView - addSuccess");
	Wywrota->sysMsg->push( msg('record_added', $object->cid), 'ok');

	$output = $object->record();

	$output .= qq~<p><a href="javascript:history.go(-2)" class="arLeft">powrót</a>~;

	$new_link = "$config{'db_script_url'}/$Wywrota::request->{content}{current}{url}/add=1";
	$new_link .= ",wykonawca=$Wywrota::in->{wykonawca}" if $Wywrota::in->{wykonawca};
	$new_link .= ",wykonawca_id=$Wywrota::in->{wykonawca_id}" if $Wywrota::in->{wykonawca_id};
	$new_link .= ",seria=$Wywrota::in->{seria}" if $Wywrota::in->{seria};
	$new_link .= ",jezyk=$Wywrota::in->{jezyk}" if $Wywrota::in->{jezyk};
	$new_link .= ",typ=$Wywrota::in->{typ}" if $Wywrota::in->{typ};
	$output .= qq~<br><a href="$new_link" class="arRight">dodaj kolejny</a>~;

	return 	$self->view->wrapHeaderFooter({
		title => $Wywrota::request->{content}{current}{title}." - wstawiono pozycję",	
		nomenu=>  'nomenu',	
		nocache=>  1,
		output => $output,
		nobillboard	=>	1
	});

}




sub deleteSuccess {
# --------------------------------------------------------
# This page let's the user know that the records were successfully
# deleted.
	my $self = shift;
	my $message = shift;
	my $output;

	$output .=  $self->view->header({
		title => $Wywrota::request->{content}{current}{title}.": pozycje skasowane",	
		nomenu=>  'nomenu',	 
		nocache=>  1,
		nobillboard	=>	1
	});
	$output .=  qq~
		<div class="div_msg_ok">Skasowano wpis $message</div>
	~;
	$output .=  $self->view->footer();
	return $output;
}




sub deleteFailure {
# --------------------------------------------------------
# This page let's the user know that some/all of the records were
# not deleted (because they were not found in the database). 
# $errstr contains a list of records not deleted.
	my $self = shift;
	my ($errstr) = shift;
	my $output;

	$output .=  $self->view->header({
			title => $Wywrota::request->{content}{current}{title}.": Błąd: Pozycje nie skasowane!",	nomenu=>  'nomenu', nocache=>  1
	});
	$output .=  qq~
		<h2>~. $Wywrota::request->{content}{current}{title} .qq~: Błąd: Pozycje nie skasowane!</h2>
		Podane wpisy nie zostały znalezione w bazie: <FONT COLOR="red">'$errstr'</FONT>.
	~;
	$output .=  "</body></html>";
	return $output;
}





##########################################################
##						Modifying						##
##########################################################


sub modifyObjectHtml {
# --------------------------------------------------------

	my $self = shift;
	my $nut = shift;
	my ($status, $object, $objectClass);

	$objectClass = $Wywrota::request->{content}{current}{'package'};
	$object = Wywrota->content->createObject($nut->in, $objectClass);

	# save the object
	($status, $object) = Wywrota->content->modifyObject($object);

	Wywrota->debug("modifyObjectHtml: status $status");
	if ($status eq "ok") {
		return $self->modifySuccess($nut, $object);
	}
	else {
		return $self->modifyForm($nut, $object);
	}
}


sub modifyForm {
# --------------------------------------------------------
# The user has picked a record to modify and it should appear
# filled in here stored in $rec. If we can't find the record,
# the user is sent to modify_failure.
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my ($output, $co);

	$object = Wywrota->content->getObject($nut->in->{'modify'}) unless ($object);

	return Wywrota->errorPage("nie mogę znaleźć wpisu: $Wywrota::in->{'modify'}") unless ($object); 
	my $package = $object->getClass();
	my $rec = $object->rec;

	return Wywrota::User::unauthorized() if 
		(abs($rec->{user_id})!=$Wywrota::session->{user}{id} 
			and !$nut->per('admin') 
			and !($nut->request->{content}{current}{url} eq 'ludzie' and $rec->{id}==$Wywrota::session->{user}{id} ) ) ;

			
	$output = $object->getErrors();
			
	$co = Wywrota::Language::plural(1, $nut->request->{content}{current}{keyword});

	$output .= qq~
		<h3>Zmień $co</h3><br>
		<form enctype="multipart/form-data" action="/db" method="POST" name="record_form" onsubmit="return checkForm$package(this);">
		<input type=hidden name="db" value="~ . $nut->request->{content}{current}{url} . qq~">
	 ~;
	$output .= $self->view->recordForm($object); 

	$output .= qq~
		<div class="formButtons"><input type="submit" name="modifyrecord" value="    zapisz zmiany    " class="bold"></div>
		</form>
	~;

	
	return $self->wrapHeaderFooter({
		title => $nut->request->{content}{current}{title}.": zmiana wpisu",	
		nomenu=>  'bar',
		nocache=> 1,
		output => $output,
		nobillboard	=>	1
	});
	
	
	Wywrota->error($@) if ($@);
}



sub modifySuccess {
# --------------------------------------------------------
# The user has successfully modified a record, and this page will 
# display the modified record as a confirmation.
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $output;

	if ($nut->in->{popup}) {
		return $self->wrapHeaderFooter({
			title => "pozycja zmieniona",	
			nomenu=> 'nomenu',	
			nocache=>  1,	
			nobillboard	=>	1, 
			output => '<h2>Pozycja zmieniona</h2>'
		});

	} else {
		Wywrota->sysMsg->push($Wywrota::request->{content}{current}{title}. ': pozycja zmieniona', 'ok');
		$self->htmlPage($nut, $object);
		#$nut->session->redirect = $object->url;
		
	}

}




sub recordForm { shift->view->recordForm(@_) }
sub recordFormAdd { shift->view->recordFormAdd(@_) }
sub htmlPage { shift->view->htmlPage(@_) }
sub addSuccess { shift->view->addSuccess(@_) }

sub header { 
	return ($Wywrota::in->{generate}) ? "" : shift->view->header(@_);
}
sub footer { 
	return ($Wywrota::in->{generate}) ? "" : shift->view->footer(@_);
}
sub wrapHeaderFooter { shift->view->wrapHeaderFooter(@_) }
sub searchHeaderGenerate { shift->view->searchHeaderGenerate(@_) }
sub searchFooterGenerate { shift->view->searchFooterGenerate(@_) }
sub searchHeader { shift->view->searchHeader(@_)  } 
sub searchFooter { shift->view->searchFooter(@_)  } 

 
 

1;