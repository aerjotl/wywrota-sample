package Wywrota::Object::View::SiteImagesView;

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
	$param->{nomenu} = 'bar';

	my $output;

	$output = $self->SUPER::header($param);
	$output .= qq~<div id="mainContent">~ if (!$Wywrota::in->{popup});

	return $output;

}


sub footer {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $output;
	$output = qq~</div>~ if (!$Wywrota::in->{popup});
	$output .= $self->SUPER::footer();
	return $output;
}


sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my ($url, $output);


	$output .= qq~
		<h1>Zdjęcia</h1>
			<style type="text/css">
			.article h3 {display: none}
			</style>
	~;

	if ($Wywrota::in->{article_id}) {
		$output .= Wywrota::Controller::includePage("db=artykuly&generate=1&id=$Wywrota::in->{article_id}&nomore=1&suffix=sq", "7d");
		$output .= qq~
			<style type="text/css">
			.article h3 {display: none}
			</style>
		~;

	}

	if ($Wywrota::in->{wykonawca_id}) {
		$output .= Wywrota::Controller::includePage("db=wykonawcy&generate=1&id=$Wywrota::in->{wykonawca_id}&nomore=1&suffix=sq", "7d");
		$output .= qq~<link rel="stylesheet" href="/css/fanklub.css" type="text/css">~;

	}
	
	$output .= $self->SUPER::searchHeader($queryRes, $tytul);
	if (Wywrota->per('add')) {
		my $add_photo_url = "/db/site_images/add/1";
		$add_photo_url .= "/typ/2/wykonawca_id/".$Wywrota::in->{wykonawca_id} if ($Wywrota::in->{wykonawca_id});

		$output .= qq|
			<p><a href="$add_photo_url" class="addIcon"><b>prześlij zdjęcie</b></a><p><br><br>
		|;
	}


	return $output;

}


sub searchFooter {
# --------------------------------------------------------
	my $self = shift;
	my $output;
	$output .= qq~
		<br class="clr">	
	~;
	$output .= $self->SUPER::searchFooter(@_);

	return $output;

}



sub addSuccess {
# --------------------------------------------------------
	my $self=shift;
	my $nut = shift;
	my $object=shift;
	my $rec = $object->rec if ($object);
	my ($output);

	if ($Wywrota::in->{popup}) {

		# dialog window - close
		$output =  $self->header({title => "Zdjęcie zostało zapisane",	nomenu=>  1 });
		$output .=  qq~
			<div class="div_msg_ok">Dziękujemy. Twoje zdjęcie zostało zapisane</div>

			<script language="JavaScript">
				setTimeout("fancyClose();",1000);
			</script>
		~;
		$output .=  "</body></html>";
		return $output;

	} elsif($Wywrota::in->{typ}==1) {

		# zdjęcie użytkownika
		Wywrota->sysMsg->push("Twoje zdjęcie zostało zapisane", 'ok');
		my $userObj = Wywrota->content->getObject($rec->{'user_id'}, 'User');
		return Wywrota->view->view('User')->viewPhotos($userObj);
	
	} else {
		return $self->SUPER::addSuccess($nut, $object, @_);
	}
}




1;