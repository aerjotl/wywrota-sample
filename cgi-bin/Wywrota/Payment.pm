package Wywrota::Payment;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use POSIX qw(ceil floor);
use Data::Dumper;

use HTTP::Request::Common;
use LWP::UserAgent;
use XML::Simple;

use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;

 
our @ISA = qw(Exporter);
our @EXPORT = qw( action validateSMSCode );


sub action {
# --------------------------------------------------------
	my $output;
	my $nut = shift;
	my $action = $nut->in->{smsAction} || $nut->in->{payAction};

	if    ($action eq 'spiewnik') { $output = smsSpiewnikOffline($nut);} 
	elsif ($action eq 'premium') { $output = smsPremiumAccount($nut);} 
	elsif ($action eq 'accessCodeForm') { $output = accessCodeForm($nut);} 
	elsif ($action eq 'registerCode') { $output = registerCode($nut);} 
		
	else { 
		return Wywrota->unknownAction($action);

	}
	
	return $output;

}

sub registerCode {
# --------------------------------------------------------
# register code recived from DotPay.pl
	my $output;
	my $nut = shift;

	my $code = $nut->in->{'kod'};
	
	$output = "Content-type: text/plain; charset=utf-8\r\n\r\n";

	if ($code) {
		Wywrota->db->execWriteQuery("INSERT INTO payment_codes (code) VALUES ('$code')");
		$output .= "ok";
	} else {
		$output .= "error";
	}

	return $output;
}




sub smsPremiumAccount {
# --------------------------------------------------------
# sprawdzanie kodu  - spiewnik offline

	my ($output);
	my $nut = shift;
	
	my $errorMsg = validateSMSCode( $nut->in->{'code'} );

	if (!$errorMsg) {

		eval {
			Wywrota->mng('PremiumAccount')->addSmsAccount($Wywrota::session->{user}{id}, $nut->in->{'code'} );
		};
		Wywrota->error("Błąd podczas dodawania konta premium", $@) if ($@);
		
		$output .= qq~
			<h1>Kod poprawny.</h1>
			Dziękujemy za zakup! <h2>Od teraz jesteś właścicielem konta Wywrota premium!</h2>
			<br><br>
			<p><a href="/ludzie/$Wywrota::session->{user}{login}" class="arRight">moja Wywrota</a>
		~;			

	} else {
		$output = $errorMsg;
	}


	#$output .= qq~
	#<script language="JavaScript">
	#pageTracker._trackPageview("/dynamic/buy/premium.html"); 
	#</script> 
	#~;

	return Wywrota->t->wrapHeaderFooter({ 
		title => "SMS Code Validation",
		output => $output
		}) ;

}


sub accessCodeForm {
# --------------------------------------------------------
	my $nut = shift;
	return Wywrota->t->process('pay_form.html');	
}





sub smsSpiewnikOffline {
# --------------------------------------------------------
# sprawdzanie kodu  - spiewnik offline

	my ($output);
	my $errorMsg = validateSMSCode( $Wywrota::in->{'code'} );

	if (!$errorMsg) {
		$output = Wywrota->t->process('spiewnik/offline_access.html');

	} else {
		$output = $errorMsg;
	}

	return Wywrota->t->wrapHeaderFooter({ 
		title => "SMS Code Validation",
		output => $output,
		nomenu => 2
		}) ;
	
	#$output .= qq~
	#<script language="JavaScript">
	#pageTracker._trackPageview("/dynamic/buy/spiewnik.html"); 
	#</script> 
	#~;


}


sub validateSMSCode {
# --------------------------------------------------------
# sprawdzanie kodu wyslanego przez SMS
# z serwisu MobilePay.pl

	my ($xml_out, $xml_in, $xml_out_ref, $output, $code, $dbCode );
	my $code = shift;


	
	# -- free access - reaktywacja
	return 0 if ($code eq $config{mobilepay}{free_access});


	# -- code found in database
	return 0 if ( Wywrota->db->selectCount("payment_codes", "code='$code' AND _active=1 "
		. "AND `time` > ". Wywrota->db->quote( getDate(time() - 86400*$config{'pay_code_active_days'}) ) ) );
	

	$xml_in =  qq~<request>
	<merchantID>$config{mobilepay}{merchant_id}</merchantID>
	<password>$config{mobilepay}{password}</password>
	<serviceID>$config{mobilepay}{service_id}</serviceID>
	<code>$code</code>
	<responseType>1</responseType>
	</request>~;
		
	my $ua = LWP::UserAgent->new(
		ssl_opts => { verify_hostname => 0 },
		timeout  => 10
		);
	
	my $res = $ua->post(
		$config{mobilepay}{url}, 
		Content => $xml_in, 
		Content_Type => 'text/xml'
	);
	 

	if ($res->is_success) {
		$xml_out_ref = XML::Simple::XMLin($res->content);
		Wywrota::Log::logFile("sms", "code: $Wywrota::in->{'code'}, response: $xml_out_ref->{value} $xml_out_ref->{reason} \n\n");

		if ( (int($xml_out_ref->{value}) == 0) ) {
			return 0;

		} elsif (int($xml_out_ref->{value}) == -1) {
			#	value = -1; reason = 'Invalid code' w przypadku negatywnego wyniku walidacji kodu
			return Wywrota->errorMsg(
				"Nieprawidłowy kod", 
				"Kod który wpisałeś \"$code\" jest nieprawidłowy.<br>Jeśli wpisałeś kod poprawnie i nadal widzisz ten komunikat skontaktuj się z działem technicznym.<br><br>");

		} else {
			#	value = -100; reason = 'Unsecured connection' w przypadku requestu po niezabezpieczonym kanale (http zamiast https)
			#	value = -200; reason = 'Bad XML' w przypadku błędnie sformatowanego XML::a requestu, lub w przypadku braku wymaganych tagów
			#	value = -300; reason = 'Execution error' w przypadku błędu wykonania procedury walidacji kodu po stronie serwera
			return Wywrota->errorMsg(
				"Wystąpił błąd walidacji", 
				$xml_out_ref->{reason} );
		}

	} else {
		return Wywrota->errorMsg(
			"Wystąpił błąd połączenia", 
			$res->status_line );
	}


}



1;