package Wywrota::Message;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Data::Dumper; 
use Data::Structure::Util qw(_utf8_off);

use Wywrota;
use Wywrota::Log;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Wywrota::Utils;
use Wywrota::Object::User;

use Class::Singleton;
use base 'Class::Singleton';


sub action {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $output;
	my $action = $nut->in->{message};
	
	eval{

		# send message to user
		if    ($action eq 'send')   { 
			if (!$Wywrota::session->{user}{id}) { return Wywrota::User::unauthorized("Musisz być zalogowany aby wysłać wiadomość do użytkownika");}
			$output = $self->sendForm(); 
		} 
		elsif ($action eq 'post') { 
			if (!$Wywrota::session->{user}{id}) { return Wywrota::User::unauthorized("Musisz być zalogowany aby wysłać wiadomość do użytkownika");}
			$output = $self->postMessage(); 
		} 

		# to a friend
		#elsif ($action eq 'sendLink' and $Wywrota::in->{id} and $Wywrota::in->{cid}) { 
		#	$output = $self->emailToFriend($Wywrota::in->{id}, $Wywrota::in->{cid}); 
		#} 
		#elsif ($action eq 'sendLinkPost') { 
		#	$output = $self->emailToFriendPost();
		#}
		
		# kontakt z redakcją
		elsif ($action eq 'contactForm') { 
			$output =  $self->contactForm($nut);
		} 
		elsif ($action eq 'contactFormPost') { 
			$output = $self->contactFormPost($nut);
		}
		
		
		else { 
			$output = Wywrota->unknownAction($action);
		}

	};
	$output = Wywrota->error($@) if ($@);

	
	return $output;
}






sub sendForm {
# --------------------------------------------------------
#
	my $self = shift;
	my ($output, $userObject);

	$userObject = Wywrota->content->getObject($Wywrota::in->{id}, 'User');
	$userObject->preProcess();

	$output = Wywrota->template->popUpHeader({ title => 'Wyślij wiadomość do użytkownika' });
	$output .= qq~
		
		<h3>wyślij wiadomość do $userObject->{rec}->{imie}</h3>

		<script language="JavaScript" type="text/javascript">
		<!--
			function checkForm(formObj) {
				if (!validrequired(formObj.topic,"Podaj temat wiadomości.")) return false;
				if (!validrequired(formObj.msg,"Wpisz wiadomość.")) return false;
				return true;
			}
		//-->
		</script>

		<form action="/db" method="POST" name="message" onsubmit="return checkForm(this);">
		<input type="hidden" name="message" value="post">
		<input type="hidden" name="user_id" value="$Wywrota::in->{id}">
		<input type="hidden" name="popup" value="$Wywrota::in->{popup}">

		<p><br>temat<br>
		<input type="text" name="topic" class="inputMWide">

		<p>treść<br>
		<textarea name="msg" class="txtAreaMd"></textarea><br><br>

		<div class="formButtons"><input type="submit" value="     Wyślij     " class="bold"></div>

		
		
		~;
	$output .= Wywrota->template->popUpFooter();	
	return $output;
}



sub postMessage {
# --------------------------------------------------------
#
	my $self = shift;
	my $nut = shift;

	my ($output, $recipientObj, $senderObj, $msg);


	eval {

		$senderObj = Wywrota->content->getObject($Wywrota::session->{user}{id},'User');
		$senderObj->preProcess();
		$senderObj->rec->{avatar} = Wywrota->nav->absoluteLinks($senderObj->rec->{avatar});

		$recipientObj = Wywrota->content->getObject($Wywrota::in->{user_id},'User');
		$recipientObj->preProcess();

		
		my $content = Wywrota->t->process('email/user_message.html', {
			sender		=>	$senderObj->{rec},
			body		=>	smartContent($Wywrota::in->{msg}),
			reply_url	=>	$config{'site_url'}."/message/send/id/".$senderObj->id
		});
		
		
		Wywrota::EMail::sendEmail({
			from	=> $senderObj,
			to		=> $recipientObj,
			subject	=> $Wywrota::in->{topic},
			body	=> $content,
			style	=> 'user_message',
		});

		Wywrota->db->execWriteQuery(qq~
			INSERT INTO message (`user_id_sender`, `user_id_recipient`, `topic`, `content`, `date_sent`) 
			VALUES ($Wywrota::session->{user}{id}, $Wywrota::session->{user}{id}, ~. Wywrota->db->quote($Wywrota::in->{rec}->{topic}). ",". Wywrota->db->quote($Wywrota::in->{msg}). qq~ , NOW())
			~);
			
			
		Wywrota::Log::logFile('msg',"\n\n\n\n\n---\n\n\n" 
			.$recipientObj->{rec}->{email} 
			." , " 
			.$Wywrota::in->{rec}->{topic}
			.", ". $Wywrota::in->{msg} );

	};
	Wywrota->error($@) if ($@);

	# --- ok  
	return Wywrota->t->wrapPopUpHeaderFooter({ 
		title => 'Wiadomość wysłano' }, 
		qq|
			<h2>Dziękujemy.</h2>
			Wiadomość do użytkownika została wysłana.
		|);


}



sub emailToFriend {
# --------------------------------------------------------
#
	my ($output);
	my $self = shift;
	my $id = shift;
	my $cid = shift;

	my $object = Wywrota->content->getObject($id,  Wywrota->cc->{$cid}{package} );	# $Wywrota::request->{content}{$cid}{'package'}
	$object->preProcess() if ($object );


	my $titleToString = ($object->rec->{autor} || $object->rec->{ludzie_imie}) . " - \"" . ($object->rec->{tytul} || $object->rec->{podpis} || $object->rec->{temat} || "bez tytułu") . "\"";

	$output = Wywrota->template->popUpHeader({ title => 'Wyślij link do znajomego' });

	$output .= qq~
		<h3>Wyślij link do znajomego</h3>

	<div align="center">

		<script language="JavaScript" type="text/javascript">
		<!--
			function checkForm(formObj) {
				if (!validrequired(formObj.emailTo,"Podaj poprawny adres e-mail.")) return false;
				if (!validEmail(formObj.emailTo,"Podaj poprawny adres e-mail.")) return false;
				if (!validrequired(formObj.name,"Nie podałeś imienia i nazwiska.")) return false;
				return true;
			}
		//-->
		</script>

		<form action="/db" method="POST" name="kontakt" onsubmit="return checkForm(this);">
		<input type="hidden" name="message" value="sendLinkPost">
		<input type="hidden" name="subject" value="Polecam: $object->{rec}->{tytul} - Wywrota.pl">
		<input type="text" name="www" value="$config{'robot_protection'}" class="robotHide">

		<table>
		<tr><td class="descr" valign="top"><p>Adresat (adres e-mail)</td><td><input type="text" name="emailTo" class="txtinput" onclick="clearmsg();" onkeypress="clearmsg();"></td></tr>
		<tr>
			<td class="descr" valign="top"><p>Nadawca</td>
			<td>
			~. (
			($Wywrota::session->{user}{id} > 0) ?
				(qq~<input type="hidden" name="name" value="$Wywrota::session->{user}{name}"> <b>$Wywrota::session->{user}{name}</b> ~) :
				(qq~<input type="text" name="name" class="txtinput" onclick="clearmsg();" onkeypress="clearmsg();">~) )
			.qq~
				
			</td>
		</tr>
		<tr><td colspan="2"><textarea name="msg" class="msg" onclick="clearmsg();" onkeypress="clearmsg();">
Cześć,

zapraszam Cię do przeczytania tekstu na Wywrocie:
$titleToString 
$object->{rec}->{url}

pozdrawiam
	</textarea></td>

	<tr><td>&nbsp;</td><td height="50">
	<input type="submit" value="     Wyślij     " class="bold">
	</td></tr>
	</table>

	</form>
	</div>

	~;

	$output .= Wywrota->template->popUpFooter();
	return $output;
	
}


sub emailToFriendPost {
# --------------------------------------------------------
#
	my $self = shift;
	my ($output, $replyTo, $senderObj, $msg);

	return $self->emailToFriendPostError("Brak adresata wiadomości")	
		if (!$Wywrota::in->{emailTo});

	return $self->emailToFriendPostError("Robot protection error")
		if ($Wywrota::in->{www} ne $config{'robot_protection'});

	return $self->emailToFriendPostError("Użyto niedozwolonych znaczników HTML w treści wiadomości") 
		if ($Wywrota::in->{msg} =~ /<a href=/);

	$msg = smartContent($Wywrota::in->{msg});
	if ($Wywrota::session->{user}{id}) {
		$senderObj= Wywrota->content->getObject($Wywrota::session->{user}{id}, 'User');
		$replyTo = $senderObj->rec->{email} if ($senderObj);
	}


	Wywrota::EMail::sendEmail({
		from	=> $senderObj,
		to		=> $Wywrota::in->{emailTo},
		subject	=> $Wywrota::in->{subject},
		body	=> $msg."<br><br>\n".$Wywrota::in->{name}
	});


		return Wywrota->t->wrapPopUpHeaderFooter({ 
		title => 'Wiadomość wysłano',
		output => qq|
					<h2>Wiadomość została wysłana</h2>
					<script language="JavaScript">
						setTimeout("fancyClose();",2000);
					</script>
					|
	});

}


sub emailToFriendPostError {
# --------------------------------------------------------
#
	my $self = shift;
	my $msg = shift;
	my ($output);

	$output = 
		Wywrota->template->popUpHeader({ title => 'Wiadomość nie została wysłana' }) .
		Wywrota->errorMsg("Wiadomość nie została wysłana", $msg) .
		#qq~
		#<script language="JavaScript">
		#	setTimeout("closeDialog()",5000);
		#</script>
		#~. 
		Wywrota->template->popUpFooter();
	return $output;
}


sub contactForm {
#-----------------------------------------------------------------------

	my $self = shift;
	my $nut = shift;
	
	my ($output);
	my $xml = new XML::Simple;
	my $data = $xml->XMLin($config{'config_dir'}."/contactFormRecip.xml");

	_utf8_off($data);
	
	$output = Wywrota->t->process('page/kontakt.html',{
		recipients	=> $data->{recipient}
	});
	
	return Wywrota->t->wrapHeaderFooter({
		output => $output,
		nomenu => 'bar'
	});
}



sub contactFormPost {
#-----------------------------------------------------------------------
#  wysyla formularz kontaktowy

	my $self = shift;
	my ($output, $result, $message, $msg, $user);
	my $date = normalnaData( getDate(), 1, 1 );
	my $xml = new XML::Simple;
	my $data = $xml->XMLin($config{'config_dir'}."/contactFormRecip.xml");

	$date =~ s/\&nbsp;/ /g;

	_utf8_off($data);

	return Wywrota->errorPage("Robot protection error") if ($Wywrota::in->{www} ne $config{'robot_protection'});
	return Wywrota->errorPage("Błąd podczas wysyłania", "No message to send") if (!$Wywrota::in->{msg});
	return Wywrota->errorPage("Błąd podczas wysyłania", "Użyto niedozwolonych znaczników HTML w treści wiadomości") 
		if (($Wywrota::in->{msg} =~ /<a href=/) || ($Wywrota::in->{msg} =~ /\[url=/));
	
	return Wywrota->errorPage("Błąd podczas wysyłania", "Spam protection error") if (Wywrota->spamFilter->check({
		content=>$Wywrota::in->{msg}, 
		email=>$Wywrota::in->{name}, 
		author=>$Wywrota::in->{email} }));

	foreach (sort keys %{$Wywrota::in}) {
		next if (/(send_email|subject|message|recipient|www|popup|submit|facebook_id_session|facebook_token)/);
		
		$msg = smartContent($Wywrota::in->{$_});

		$message .= qq~
			<p class="txtcore g"><b>$_:</b> $msg</p>
		~ if ($Wywrota::in->{$_});
	}
	
	if ($Wywrota::session->{user}{id}>0) {
		$user = qq~ <a href="http://www.wywrota.pl/ludzie/$Wywrota::session->{user}{login}">$Wywrota::session->{user}{name}</a> ~;
	} else {
		$user = qq~ Anonimowy użytkownik ~;	
	}

	$message .= qq~
		<p class="g txtnews">
		$date, &nbsp; &nbsp; 
		user: $user, &nbsp; &nbsp; 
		IP: $ENV{'REMOTE_ADDR'} $ENV{'REMOTE_HOST'} $Wywrota::session->{user}{id}
	~;

	
	my $userObj = Wywrota->content->createObject( {
		imie => $Wywrota::in->{name} || "anonimowy użytkownik",
		email => $Wywrota::in->{email}
	}, 'User' );	
	
	$result = Wywrota::EMail::sendEmail({
		from	=> $userObj,
		to		=> $data->{recipient}{ $Wywrota::in->{recipient} }{email} ||  $Wywrota::in->{to},
		subject	=> "[kontakt $date] ".$Wywrota::in->{subject},
		body	=> $message
	});


	
	if ($result) {
		$output = Wywrota->errorMsg("Wystąpił błąd podczas wysyłania wiadomości", $result);
	} else {
		$output = Wywrota->t->process('msg/contact_form_sent.html', {});
	}
	
	return Wywrota->t->wrapHeaderFooter({
		title => "Wiadomość wysłano",
		output => $output
	});
}


1;