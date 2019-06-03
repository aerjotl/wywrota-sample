package Wywrota::Object::View::ArticleView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Data::Dumper;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Language;
use Data::Structure::Util qw(_utf8_off utf8_off utf8_on _utf8_on);


sub searchHeaderGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $output = $self->SUPER::searchHeaderGenerate(@_);

	$output = $output . '<ul class="arrows">' if ($Wywrota::in->{small});

	return $output;
}

sub searchFooterGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $output  = $self->SUPER::searchFooterGenerate(@_);
	
	$output  = "</ul>" . $output  if ($Wywrota::in->{small});
	$output  = "<br>" . $output  if (!$Wywrota::in->{small} && !$Wywrota::in->{template});

	return $output  ;
}


sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $output;

	if ($Wywrota::in->{typ} && !$tytul) {
		$tytul = Wywrota->dict->getLabel('typ', $Wywrota::in->{typ});
	};

	my $baseHeader = $self->SUPER::searchHeader($queryRes, $tytul, @_);


	if ($Wywrota::in->{user_id}) {
		my $userObj = Wywrota->content->getObject($Wywrota::in->{user_id}, 'User');
		$output = $userObj->recordLead();
	}
	$output = qq~
		$output 		
		$baseHeader
	~;
	return $output;
}


sub recordForm {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $tableDef = shift;
	my $prefix = shift;
	my $replaceDict = shift;
	my $mode = shift;
	my $rec = $object->rec if ($object);

	my ($output, $event, $eventForm);

	return if (!$object);

	$output = Wywrota::Forms::buildHtmlRecordForm($object,  $tableDef, $prefix, $replaceDict, $mode) ;

	if ($mode ne 'search') {

		$rec->{event_user_id} = $rec->{user_id};
		$event = Wywrota::Object::Event->new( $rec, 'event_' );
		$eventForm = Wywrota::Forms::buildHtmlRecordForm($event, undef, 'event_');

		$output = Wywrota->t->process('form/article_event_form_wrap.html', {
			event_form	=>	$eventForm,
			rec			=>	$rec
		}) . $output;	
		
	}

	return $output;

	
}


sub recordFormAdd {
# --------------------------------------------------------
	my $output = "";
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;

	# if the user is in "Komitet Centralny" or "Ministerstwo Propagandy" - set author as redakcja
	if ($Wywrota::session->{user}{groups}{1} || $Wywrota::session->{user}{groups}{10}) {
		$rec->{user_id}=777;
		$rec->{autor}="Redakcja";
		$rec->{stan}=2;
	}



	$output .= qq~
		<div class="div_msg_tip">
			Dodajesz artykuł anonimowo. Zaloguj się do serwisu aby powiązać go z Twoim kontem, 
			otrzymywać powiadomienia o komentarzach i mieć możliwość edycji.
		</div>
	~ if (!$Wywrota::session->{user}{id});

	$output .= qq~
	<h2>Opublikuj artykuł lub newsa</h2>
	~;



	$output .= $self->recordForm($object, undef, undef, undef, 'add');

	
	$output .= qq~
		<div class="div_msg_tip_sm">
			Po przesłaniu twój artykuł będzie zweryfikowany przez redakcję. Zastrzegamy sobie prawo do korekty treści. <br>
			Teksty o charakterze reklamowym będą odrzucane.  Jeśli jesteś zainteresowany publikacją artykuły sponsorowanego <a href="/kontakt.html">skontaktuj się z nami</a>.
		</div>
	~ if (!Wywrota->per('admin'));
	
	return $output;

}


sub htmlPage {
# --------------------------------------------------------
#
	my ($output);
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $userObj;

	$object->preProcess(1);

	if ($rec->{val}{stan} != 2) {
		$Wywrota::request->{nocache} = 1;
	}

	$userObj = Wywrota->content->getObject($rec->{user_id}, 'User');
	if (!$userObj) {
		$userObj = Wywrota->content->createObject({ imie=>$rec->{autor} }, 'User');
	}

	# atach default image if not present in the content
	if ($rec->{_image_filename} && ($rec->{_image_filename} ne $config{megafon}{default_photo_filename}) && ($rec->{tresc} !~ /$rec->{_image_filename}/)) {
		$rec->{tresc} = qq|
			<a href="$config{'file_server'}/pliki/site_images/$rec->{_image_filename}-lg" class="makeBorder"><img src="$config{'file_server'}/pliki/site_images/$rec->{_image_filename}-s1" title="" /></a>
		|.$rec->{tresc};
	}
	

	#fixes
	$rec->{tresc} =~ s/text-align:\s*justify;*//g;
	$rec->{tresc} =~ s/font-family:\s*Verdana[,sans-serif];*//g;

	# ---- generate output 
	my $output = Wywrota->t->process('object/article_page.html', {
		rec				=>	$rec,
		obj 			=>  $object,
		user_lead		=>	$userObj->recordLead(),
		actions_log		=>	Wywrota::Log::getActionLog($object->id, $object->cid )
	});
	
	return Wywrota->t->wrapHeaderFooter({
		title => $rec->{tytul},
		meta_desc=> $rec->{komentarz} . " " . utf8_off($rec->{tresc}),
		meta_key=> $rec->{tags}.",".$rec->{typ}.",".$rec->{tytul},
		canonical=> $rec->{url},
		image=> ($rec->{_image_filename} ? $config{'file_server'} . "/pliki/site_images/" . $rec->{_image_filename} . "-lg" : undef ),
		output	=>	$output,
		nomenu => 'bar',
		styl_local => 'article-page.css',
		nocache	=> ($rec->{val}{stan} == 2 || $rec->{val}{stan} == 5) ? 0 : 1,
		rec => $rec,
		obj => $object
	});
	
}


sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	
	
	# ---- track event
	my $track = Wywrota->t->process('inc/google.analytics.event.inc', {
		category 	=> 'Article', 
		action  	=> 'Add', 
		opt_label 	=> $object->rec->{tytul},  
		opt_value  	=> ''
	});
		
	
	Wywrota->sysMsg->push('Twój artykuł został zapisany.'.$track, 'ok');
	$self->htmlPage($nut, $object, @_);
}

1;