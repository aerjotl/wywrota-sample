package Wywrota::Object::View::CommentView;

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
use Wywrota::Notification;


use Captcha::reCAPTCHA;



sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;

	my $baseObject = Wywrota->content->getObject($rec->{record_id}, $rec->{content_id});

	
	my $output = "<h2>Komentarz do pracy:</h2>"
		. ($baseObject ? $baseObject->record() : "")
		. "<br class='clr'><h3>Treść komentarza:</h3>"
		. $object->record();

	return Wywrota->t->wrapHeaderFooter({ 
		title 	=> "Komentarz", 
		nomenu	=>	2, 
		nocache	=>	1,
		output	=> 	$output,
		nut		=>	$nut
		});

}



sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my ($object, $output);
	
	if ($Wywrota::in->{record_id} and $Wywrota::in->{content_id}) {
		$output .= qq~
			<h1>Komentarze</h1>
			<style type="text/css">
			#mainContent .clr {clear: none;}
			</style>
		~;

		$object = Wywrota->content->getObject($Wywrota::in->{record_id}, $Wywrota::in->{content_id});
	
		$output .= $object->record() if ($object);
		
	}

	
	$output .= "<br class='clrl'>".$self->SUPER::searchHeader($queryRes, $tytul);

	return $output;

}



sub searchHeaderGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;

	my ($output, $czego, $icon);
	my $cid = $queryRes->{contentDef}->{cid};

	if ($config{'no_of_comments'} < $queryRes->{cnt}) {
		$czego = plural($queryRes->{cnt}, 'komentarz');
		$icon = Wywrota->nav->makeSingleNav( 
			"/db/komentarze/content_id,".$queryRes->{in}{content_id}.",record_id,".$queryRes->{in}{record_id}, 
			"wszystkie komentarze", 'iconNext', 1);

		$output = qq~
			<div class="comInfo">
			Znaleziono <b>$queryRes->{cnt} $czego</b>. Poniżej ostatnie <b>$config{'no_of_comments'}</b>.
			<div align="right">$icon</div>
			</div>
		~;
	}

	# add form before all the comments
	$output = $self->_getForm($queryRes->{in})  . $output;

	$output .= $self->SUPER::searchHeaderGenerate($queryRes, $tytul);

	return '<div class="comments">'.$output;
}




sub searchFooterGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $output = "";
	
		
	$queryRes->{notify} = $queryRes->{in};

	$output .= $self->SUPER::searchFooterGenerate($queryRes, $tytul);

	$output .= '</div><!-- .comments end -->';
	

	return $output;

}



sub getComments {
# --------------------------------------------------------
# zwraca komentarze do danego rekordu
	my $self = shift;
	my $object=shift;
	my $rec = $object->rec;
	my ($output, $queryRes);

	return if (!$rec->{id});

	$queryRes = $self->mng->getComments($object);
	
	$output = Wywrota->cListView->includeQueryResults($queryRes, undef, 1, 1);

	my $deletedCount = $self->mng->getDeletedCommentsCount($object);
	if ($deletedCount) {
		my $czego = plural($deletedCount, 'komentarz');
		$output .=	qq|
			<div class="txtnews g">Usunięto $deletedCount $czego</div>
		|;	
	}


	return Wywrota->nav->absoluteLinks($output);
	
}




sub _getForm {
# --------------------------------------------------------
# zwraca formularz do komentowania
	my $self = shift;
	my $rec=shift;
	my $captcha = Captcha::reCAPTCHA->new;

	return Wywrota->t->process('object/comment_form.html', {
		rec			=>	$rec,
		captcha 	=> $captcha->get_html_v2( $config{recaptcha_public_key} ),
		watching_comments 	=> isWatchingComments($rec->{record_id}, $rec->{content_id}),
		allow_anonymous		=> Wywrota->cc($rec->{content_id})->{anonymous_comment}
	});
}



1;