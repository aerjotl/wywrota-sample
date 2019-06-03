package Wywrota::Object::View::PremiumAccountView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Wywrota::Object::View::BaseView;
use base 'Wywrota::Object::View::BaseView';

use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Language;




sub recordFormAdd {
# --------------------------------------------------------
	my ($output );
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $credits = $self->mng->hasCredits();
	my $userObj = Wywrota->content->getObject($rec->{'user_id'}, 'User');
	my $avatar = $userObj->record;

	return Wywrota->errorMsg("Brak kredytów", "Nie możesz już przydzielać innym użytkownikom konta Wywrota premium") if (!Wywrota->per('admin') && !$credits);
	
	$output = qq~
		<h3>Przydziel konto premium</h3> <br>
		$avatar <br class="clr">
		<p>Przydziel użytkownikowi <b>$userObj->{rec}->{imie}</b> konto Wywrota premium.~;

	$output .= "<p>Możesz przydzielić konto premium jeszcze <b>$credits</b> " . (($credits>1) ? ("użytkownikom.") : ("użytkownikowi.")) if ($credits);

	$output .= Wywrota::Forms::buildHtmlRecordForm($object, @_);
	return $output;
}



sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $userObj = Wywrota->content->getObject($Wywrota::in->{'user_id'}, 'User');
	my $output;

	$output .= Wywrota->template->header({
			title => $Wywrota::request->{content}{current}{title}." - wstawiono pozycję",	
			nomenu=>  'nomenu',	meta_desc=>  undef,	meta_key=>  undef,	nocache=>  1
	});
	$output .= qq~
		<h1>Konto Wywrota premium</h1>
		<div class="div_msg_ok">Użytkownikowi $userObj->{rec}->{imie} przyznano konto Wywrota premium.</div><P>
		<p><a href="/ludzie/$userObj->{rec}->{wywrotid}" class="arLeft">powrót do akt użytkownika</a>
	~;

	$output .= Wywrota->template->footer();

	return $output;
}

1;