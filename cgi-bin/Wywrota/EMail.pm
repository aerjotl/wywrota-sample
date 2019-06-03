package Wywrota::EMail;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2010 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------



use utf8;
use Exporter;
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use MIME::Lite;


our @ISA = qw(Exporter);
our @EXPORT = qw(checkEmail sendEmail mail_link sub_mail_link make_mailing main_mail);


sub checkEmail {
#-----------------------------------------------------------------------
# sprawdza poprawnosc emaila
    my $email = $_[0];
    if ($email =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||
        $email !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,3}|[0-9]{1,3})(\]?)$/) {
        return 0;
    }
    else {
        return 1;
    }
}




sub sendEmail {
#-----------------------------------------------------------------------
#  sends an email
#	Wywrota::EMail::sendEmail({
#		from	=>,
#		to		=>,
#		subject	=>,
#		body	=>,
#		style	=>,
#		cc		=>
#	});
#-----------------------------------------------------------------------

	my $p = shift;
	
	
	if (ref $p->{to} eq 'Wywrota::Object::User') {
		$p->{address_to} = sprintf("%s <%s>", encodeMime($p->{to}->val('imie')), $p->{to}->val('email') );
	} else {
		$p->{address_to} = $p->{to};
	}
#	$p->{address_to} =~ s/\@wywrota.pl/\@subverse.eu/g;


	
	if (ref $p->{from} eq 'Wywrota::Object::User') {
		$p->{address_from}     = sprintf("%s <%s>", encodeMime($p->{from}->val('imie')." | Wywrota.pl"), $config{noreply_email} );
		$p->{address_reply_to} = $p->{from}->val('email');
	} elsif ($p->{from}) {
		$p->{address_from} = $p->{from};
		$p->{address_reply_to} = $p->{from};
	} else {
		$p->{address_from} = "Wywrota.pl <$config{system_email}>";
		$p->{address_reply_to} = $config{system_email};
	}
	
	
	
	if (!$p->{body} && $p->{style}) {
		$p->{body} = Wywrota->t->process("email/". $p->{style} .".html", $p);
	}
	

	
	my $html = Wywrota->t->process("email/email_wrapper.html", $p);

	#attachTrackingParams($html, 'mail', 'mailing') 
	


	# create and send message
	my $msg = MIME::Lite->new(
		 'Reply-To' => $p->{address_reply_to},
		 'From'     => $p->{address_from},
		 'To'       => $p->{address_to},
		 'X-Mailer' => $config{'generator'},
		 'Subject'  => encodeMime($p->{subject}),
		 'Type'     => 'multipart/related'
		 );
	$msg->attach(
		Type     => 'text/html; charset=utf-8',
		Data     => $html
	);
#	$msg->attach(
#		Type     =>'text/plain; charset=utf-8',
#		Data     => dehtml_space($html)
#	);
	$msg->attr('content-type.charset' => 'UTF8');
	
	
	
	if ($config{site_config_mode} ne 'prod') {
		$p->{address_from} =~ s/</&lt;/g;
		$p->{address_to} =~ s/</&lt;/g;
		Wywrota->sysMsg->push( qq|
				<h1>$config{site_config_mode} email</h1>
				from: $p->{address_from}, to: $p->{address_to}<br> subject: $p->{subject} <br>
				<div style="padding: 20px; border: solid gray 1px; background: white; margin: 10px 0;">$html</div>			
			|, 'tip_sm' );
			
		open (MSGFILE,">$config{'log_dir'}/" . time() . "_" . simpleAscii($p->{subject}) . "_" . simpleAscii($p->{address_to}) . ".eml");
		print MSGFILE $msg->as_string;
		close MSGFILE;
		
		return 0;

	} else {
	
		eval {
			$msg->send();
		};
	}
	
	
	

	if ($config->{log}{all}) {
		Wywrota::Log::logFile('mail',"\n\n\n\n\n\n\n\n*****************************\n\n\n\n\n$p->{subject} from:<$p->{address_from}> to:<$p->{address_to}>\n".dehtml($html));
	} else {
		Wywrota::Log::logFile('mailsent',"<$p->{address_to}>    from:<$p->{address_from}>  $p->{subject}");		
	}

	Wywrota->sysMsg->push( "Wystąpł błąd podczas wysyłania wiadomości.", 'err' ) if (!$msg->last_send_successful());

	return 1-$msg->last_send_successful() ;

}





1;
