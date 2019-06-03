package Wywrota::Object::Manager::PremiumAccountManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::EMail;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';


sub hasCredits {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift || $Wywrota::session->{user}{id};
	my ($credits);

	return 0 if (!$user_id);

	($credits) = Wywrota->db->buildArray("SELECT credits FROM premium_account WHERE user_id=$user_id AND (valid_until>now() OR valid_until is null) "); 

	return $credits;
}


sub isPremium {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift || $Wywrota::session->{user}{id};
	my ($valid);

	return 0 if (!$user_id);

	($valid) = Wywrota->db->buildArray("SELECT id FROM premium_account WHERE _active=1 AND user_id=$user_id AND (valid_until>now() OR valid_until is null) "); 

	return $valid;
}

sub validUntil {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift || $Wywrota::session->{user}{id};
	my ($valid);

	return 0 if (!$user_id);

	($valid) = Wywrota->db->buildArray("SELECT valid_until FROM premium_account WHERE _active=1 AND user_id=$user_id AND (valid_until>now() OR valid_until is null) "); 

	return $valid;
}

sub takeCredit {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift || $Wywrota::session->{user}{id};
	my ($credits);

	return 0 if (!$user_id);
	return 0 if (!hasCredits($user_id));

	Wywrota->db->execWriteQuery("UPDATE premium_account SET credits = credits-1 WHERE user_id=$user_id AND (valid_until>now() OR valid_until is null) "); 

	return 1;
}


sub addSmsAccount {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift || $Wywrota::session->{user}{id};
	my $code = shift;
	return 0 if (!$user_id);

	my $date = Wywrota::Utils::getDate( time() + 31532400 );

	Wywrota->db->buildArray(qq~
		INSERT INTO premium_account (user_id, valid_until, notes, user_id_from, credits) 
		VALUES ($user_id, '$date', 'kupione przez SMS $code', $user_id, 2) ~); 

	Wywrota->db->execWriteQuery("UPDATE ludzie SET _is_premium=1 WHERE id=?", $user_id); 

	$Wywrota::session->{user}{premium} = 1;
	#Wywrota->session->persistSession($Wywrota::session);
	
}



sub onObjectAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;

	my $userObj = Wywrota->content->getObject($rec->{'user_id'}, 'User');
	my $userFromRec = Wywrota->content->getObject($rec->{'user_id_from'}, 'User');

	my $msgBody = qq~
			<p>Cześć $userObj->{imie}!<br><br>
			Użytkownik $userFromRec->{imie} przyznał Ci konto Wywrota premium.<br>
			Aby dowiedzieć się jakie przywileje daje to konto kliknij <a href="http://www.wywrota.pl/premium.html">tutaj</a>.
	~;

	Wywrota->db->execWriteQuery("UPDATE ludzie SET _is_premium=1 WHERE id=?", $rec->{'user_id'}); 

	Wywrota::EMail::sendEmail({
		to		=> $userObj,
		subject	=> "Powiadomienie: konto Wywrota premium",
		body	=> $msgBody
	});
	
	$self->takeCredit();


}



1;