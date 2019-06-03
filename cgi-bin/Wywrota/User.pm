package Wywrota::User;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Exporter; 
use Data::Dumper;

use URI;
use URI::QueryParam;
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Nut::Cookie;
use Wywrota::Notification;
use Wywrota::Favorites;
use Wywrota::Object::User;
use Wywrota::Utils;

use Wywrota::Language;

our @ISA = qw(Exporter);
our @EXPORT = qw(action loginForm loginScreen unauthorized listPhotos removeAccount loginAction);


sub action {
# -------------------------------------------------------------------------------------
	my $output;
	my $nut = shift;
	my $in = $nut->in;
	my $action = $in->{userAction} || $in->{user} ;
	
	if ($action eq 'setDefaultPhoto') { 
		$output = ($Wywrota::session->{user}{id}) ? ( setDefaultPhoto() )  : ( Wywrota::User::unauthorized() );
	} 
	elsif ($action eq 'settings') { 
		$output = ($Wywrota::session->{user}{id}) ? ( Wywrota::UserSettings::settingsPage($in) )  : ( Wywrota::User::unauthorized() );
	} 
	elsif ($action eq 'settingsSave') { 
		$output = ($Wywrota::session->{user}{id}) ? ( Wywrota::UserSettings::settingsSave($in) )  : ( Wywrota::User::unauthorized() );
	} 
	elsif ($action eq 'removeAccount') { 
		$output = ($Wywrota::session->{user}{id}) ? ( removeAccount($nut) )  : ( Wywrota::User::unauthorized() );
	} 
	elsif ($action eq 'suicide') { 
		$output = ($Wywrota::session->{user}{id}) ? ( suicide($nut) )  : ( Wywrota::User::unauthorized() );
	} 

	elsif ($action eq 'verify') { $output = verifyAccount($nut);} 
	elsif ($action eq 'loginScreen') { $output = loginScreen();} 
	elsif ($action eq 'unauthorized') { $output = unauthorized();} 
	elsif ($action eq 'lostPassword') { $output = lostPassword();} 
		
	else { 
		return Wywrota->unknownAction($action);

	}

	
	return $output;
}



sub verifyAccount {
# --------------------------------------------------------
	my $nut = shift;
	my $output;
	
	my $uid = Wywrota->mng('HashConfirm')->verify($nut->in->{id});
	
	if ($uid) {
	
		Wywrota->mng('User')->verifyUserAccount($uid);
	
	
		$output = qq|
			<h1>Dziękujemy!</h1>
			Twój adres email został zweryfikowany.<br><br>
			
			<a href="/" class="arRight">przejdź do strony głównej</a>
			|;
	} else {
		$output = Wywrota->errorMsg("Wystąpił błąd podczas weryfikacji adresu email");
	}
	
	return Wywrota->t->wrapHeaderFooter({			
			title => "Weryfikacja adresu email",
			nomenu=>  'bar',	
			nocache=>  1,
			output => $output,
			nobillboard => 1
	});
	
}



# --------------------------------------------------------
#		PHOTO MANAGEMENT
# --------------------------------------------------------




sub loginForm {
# --------------------------------------------------------
# The login form
	my $msg = shift;
	return Wywrota->t->process('form/login_form.html', {
		message		=> $msg
	});
}



sub loginScreen {
# --------------------------------------------------------
	my $msg = shift;

	if ($Wywrota::session->{user}{id} > 0) {
		return "Status: 302 Found\n"
			. "Location: /\n\n" ;

	} else {

		return Wywrota->view->wrapHeaderFooter({
			title => "Zaloguj się.",	
			nomenu=>  'bar',	
			nocache=>  1,
			output => loginForm( $msg ),
			nobillboard => 1
		});
	}


}



sub unauthorized {
# --------------------------------------------------------
# A user tried to do something he was not authorized for.
	my ($output, $errormsg);
	my $msg = shift;

	Wywrota->trace("unauthorized");

	if ($Wywrota::session->{user}{id}) {
		$errormsg = $msg || msg('no_permissions_msg');
		$output .= qq~
			<h1>~. msg('no_permissions') .qq~</h1>
			<p>~. $errormsg .qq~
		~;
	} else 	{
		$errormsg = $msg || msg('action_require_logged_in_msg');
		$output .=  loginForm( $errormsg );
	}

	return Wywrota->view->wrapHeaderFooter({
			title =>  msg('no_permissions'),	
			nomenu=>  'bar',	
			nocache=> 1,
			output => $output,
			nobillboard => 1
	});
}




sub loginAction {
# --------------------------------------------------------
	my $nut = shift;
	my $msg = shift;
	my $in = $nut->in;
	
	if ($Wywrota::session->{user}{id} > 0) {

		my $uri = URI->new($in->{back} || "/");
		$uri->query_param('reload' => 'true');
		$uri->query_param('sysMsg' => $msg) if ($msg);
		
		return "Status: 302 Found\n"
		        . "Location: ". $uri->as_string ."\n\n";
		
	} else {
		return loginScreen("Niepoprawne logowanie.");
	}

}




sub logoff {
# --------------------------------------------------------
	my $nut = shift;
	my $in = $nut->in;
	my ($sth, $query);

	Wywrota->db->writeQuery("DELETE FROM session WHERE userid=".int($Wywrota::session->{user}{id}) );

	print setCookie("wywrot_id","",0);
	print setCookie("wywrot_pass","",1);
	print setCookie("session","",0);
	print setCookie("facebook_token","",1);

	if ($ENV{'HTTP_REFERER'}) {
		print "Status: 302 Found\n";
		print "Location: $ENV{'HTTP_REFERER'}\n\n";
	} else {
		print "Status: 302 Found\n";
		print "Location: /\n\n";
	}
	return "";
}




sub suicide {
# --------------------------------------------------------
	#my $self = shift;
	my $nut = shift;
	my ($output, $userObj, $groups );

	
	eval {

		$userObj = Wywrota->content->getObject( $Wywrota::session->{user}{id}, 'User');

		$groups = Wywrota->mng('UserGroup')->readUserGroups( $Wywrota::session->{user}{id} );

		if (keys %{$groups} ) {
			$output = Wywrota->errorMsg(qq~Z powodów bezpieczeństwa osoby, które pełnią odpowiedzialne funkcje w naszym serwisie nie mogą same usuwać swojego konta. Aby dokończyć procedurę skontaktuj się z Komitetem Centralnym.~);
		} else {
			Wywrota->mng('User')->sendSuicideEmail($userObj);
			$output = Wywrota->errorMsg(qq~
				Czy dobrze przemyślałeś swą decyzję?<br>
				Masz jeszcze ostatnią szansę aby się wycofać.<br>
				Na Twój adres email została wiadomość z linkiem ostatecznie wyłączającym konto.
			~);
		}
		
	};
	Wywrota->error("suicide error", $@) if ($@);

	return Wywrota->t->wrapHeaderFooter({ 
		title 	=> 	"Usunięcie konta",	 
		nocache	=>	1,
		nomenu  =>  "bar",
		output	=>	$userObj->recordLead()
					. '<h1>Usunięcie konta</h1>'
					. $output,
		nobillboard => 1
	});
		
}




sub removeAccount {
# --------------------------------------------------------
	my $nut = shift;
	my ($output);

	my $uid = Wywrota->mng('HashConfirm')->verify($nut->in->{id});
	
	if ($uid) {
		Wywrota->debug("GOT", $nut->in->{id}, $uid);
		Wywrota::Object::Manager::UserManager::removeAccountAction($Wywrota::session->{user}{id});

		return Wywrota->t->wrapHeaderFooter({ 
			title =>  msg('account_deleted'),	nomenu=>  'nomenu',
			output => "<h1>".msg('account_deleted')."</h1> Konto zostało usunięte."
			});
	} else {
		Wywrota->debug("NOT GOT", $nut->in->{id}, $uid);
		
		return Wywrota->errorPage("Nie udało się usunąć konta. Wystąpił problem.");

	}
	

}


sub lostPassword {
# --------------------------------------------------------
my ($query, $output, $form);
my ($id, $email, $imie,$pytanie, $odpowiedz,$login,$haslo);

$query = "SELECT id, email, imie,pytanie,odpowiedz,wywrotid,haslo FROM ludzie WHERE wywrotid='$Wywrota::in->{wywrotid}'" if $Wywrota::in->{wywrotid};
$query = "SELECT id, email, imie,pytanie,odpowiedz,wywrotid,haslo FROM ludzie WHERE email='$Wywrota::in->{email}'" if $Wywrota::in->{email};

if ($Wywrota::in->{wywrotid} || $Wywrota::in->{email}) {
	($id, $email, $imie, $pytanie, $odpowiedz, $login, $haslo) = Wywrota->db->quickArray($query);
}

$pytanie = "Jaki samochód jest najszybszy" if (!$pytanie);
$odpowiedz = "Wywrotka" if (!$odpowiedz);

$form = qq|
	<form action="/db" name="zapomnialem_hasla" method="POST">
	<input type="hidden" name="db" value="ludzie">
	<input type="hidden" name="userAction" value="lostPassword">
	<input type="hidden" name="wywrotid" value="$Wywrota::in->{wywrotid}">
	<input type="hidden" name="email" value="$Wywrota::in->{email}">
	
	<b>$pytanie ? </b><br>
	<input type="radio" name="odpowiedz" value="1">zielony<br>
	<input type="radio" name="odpowiedz" value="2">$odpowiedz<br>
	<input type="radio" name="odpowiedz" value="3">bez sensu<br>
	 
	<input type="submit" value="odpowiedz" class="bold"> 
	</form>
|;



if (!$Wywrota::in->{wywrotid} && !$Wywrota::in->{email}) {
	$output .=  qq~
	<h2>Zapomniałeś hasła?</h2>
	<p>Aby odzyskać utracone hasło podaj swój WywrotID lub adres e-mail.<br>
	<style type="text/css">
		.forget td {vertical-align: middle;	}
	</style>
	<table class="forget">

	<form action="/db" method="POST">
	<input type="hidden" name="db" value="ludzie">
	<input type="hidden" name="userAction" value="lostPassword">
	<tr>
		<td><b>WywrotID:</b></td>
		<td><input type="text" name="wywrotid" size="12"> </td>
		<td><input type="submit" value=" dalej " class="bold"></td>
	</tr> 
	</form>

	<form action="/db" method="POST">
	<input type="hidden" name="db" value="ludzie">
	<input type="hidden" name="userAction" value="lostPassword">
	<tr>
		<td><b>Adres e-mail:</b></td>
		<td><input type="text" name="email" size="12"></td>
		<td><input type="submit" value=" dalej " class="bold"></td>
	</tr> 
	</form>

	</table>
	~
} elsif (!$id){
	$output .=  qq~
	<div class="div_warning">
		<h2>Błąd!!!</h2>
		<p>Nie znaleziono 
	</div>
	~;
	$output .= 'WywrotID: <b>'.$Wywrota::in->{wywrotid} .'</b> w naszej bazie!' if $Wywrota::in->{wywrotid};
	$output .= 'adresu e-mail: <b>'.$Wywrota::in->{email} .'</b> w naszej bazie!' if $Wywrota::in->{email};
	$output .= '<p><a href="javascript:history.go(-1)" class="arLeft">spróbuj ponownie</a>';

} elsif (!$Wywrota::in->{odpowiedz}) {
	$output .= qq~
	<h1>$imie, zapomniałeś hasła?</h1>
	<p>Nie ma problemu - wystarczy tylko, że odpowiesz na pytanie:
	$form
	~
} else {
	if ($Wywrota::in->{odpowiedz} eq '2') {
			$output .= qq~<h1>Odpowiedziałeś prawidłowo!</h1>~;
			my $message = qq~
			Cześć $imie!<br><br>

			Tak, jak obiecaliśmy, przysyłamy ci twoje wywrotowe hasło<br>
			Nie zapominaj go więcej i pilnuj go jak oka w głowie!<br><br>

			WywrotID: $login<br>
			hasło:    $haslo<br>
			~;
			
		my $res = Wywrota::EMail::sendEmail({
			to		=> $email,
			subject	=> "Zapomniane hasło z Wywroty",
			body	=> $message
		});
			
		$output .= qq~
		Sprawdź swoją skrzynkę pocztową. <br>Email z twoim hasłem powinien już tam być. <br>W razie problemów prosimy o <a href="/kontakt.html">kontakt</a>
		~ if ($res);

	} else {
	$output .= qq~
		<h2>Zła odpowiedź!</h2>
		Spróbuj jeszcze raz:
		$form
	~;
	}
}


return Wywrota->t->wrapHeaderFooter({			
			title => "Zapomniałeś hasła?",	
			nomenu=>  'bar',	
			nocache=>  1,
			output => $output,
			nobillboard => 1
	});


}


1;
