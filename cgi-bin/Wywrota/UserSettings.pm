package Wywrota::UserSettings;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------



# --------------------------------------------------------

use strict;
use Data::Dumper; 
use Exporter; 
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::User;
use Wywrota::EMail;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Notification;

our @ISA = qw(Exporter);
our @EXPORT = qw(
	settingsPage settingsSave
	readSettings storeSettings
);






sub settingsPage {
# --------------------------------------------------------
# Show configuration
	my ($output, $settings, $check, $checked, %sett);
	my $in = shift;
	my $czlowiekRec = Wywrota->content->getObject($Wywrota::session->{user}{id}, 'User')->rec;

	$checked = ' checked="checked"';
	$settings = Wywrota::UserSettings::readSettings($Wywrota::session->{user}{id});
	%sett = %{$settings};


	# ---
	
	$output = qq~
		<form action="/user/settingsSave" method="POST" name="settingForm"> 
		<input type="hidden" name="userAction" value="settingsSave">


		~ . Wywrota::Notification::showForm() . qq~

		<br class="clrl">

		<input type="submit" name="save" value="zapisz ustawienia" class="bold">
		</form>		
	~;

	return Wywrota->view->wrapHeaderFooter({ 
		output => $output,
		title => 'Ustawienia',	
		nomenu=>  'bar',	
		nocache=>  1,
		styl_local => 'moja.css'
	});


	# ----------------------------------------------- UNUSED 

	$output .= qq~
		<h3>Powiadamiaj mnie poprzez: </h3>
		<input type="hidden" value="1" name="user_settings_ids">

	~;

	if (length($czlowiekRec->{gg})>3) {
		$output .= qq~
			<div class="notifyGG">
				<input type="radio" name="sett_1" value="2" id="byGG" ~.(  $sett{1}==2 ? $checked : ""  ).qq~>
				<label for="byGG">Gadu-Gadu</label>
			</div>
		~;
	} else {
		$sett{1} = 1;
		$output .= qq~
			<div class="notifyGG">
				<input type="radio" disabled="true" id="byGG">
				<label for="byGG">Gadu-Gadu</label>
				<div class="txtsm1"><a href="/db/ludzie/modify/$Wywrota::session->{user}{id}"> podaj swój nr Gadu-Gadu<br>aby włączyć powiadomienia</a></div>
			</div>
		~;
	}


	$output .= qq~
		<div class="notifyEmail">
			<input type="radio" name="sett_1" value="1" id="byEmail" ~.(  $sett{1}==1 ? $checked : ""  ).qq~> 
			<label for="byEmail">E-Mail </label>				
		</div>
	~;


	my $unused_settings = qq~
		
		<h3>Pokaż okienko odpowiedzi:</h3>
			<input type="radio" name="sett_3" value="0" id="replyUnder"  ~.(  $sett{3}==0 ? $checked : ""  ).qq~>
			<label for="replyUnder">pod komentarzami</label><br>

			<input type="radio" name="sett_3" value="1" id="replyOver"  ~.(  $sett{3}==1 ? $checked : ""  ).qq~> 
			<label for="replyOver">nad komentarzami</label>

	~;

}




sub settingsSave {
# --------------------------------------------------------
# Show configuration
	my ($output, $msg);
	my $in = shift;

	$msg = Wywrota::Notification::storeNotificationData($Wywrota::session->{user}{id});
	$msg = storeSettings($Wywrota::session->{user}{id});
	Wywrota->sysMsg->push($msg, 'ok');

	return settingsPage();
}








# --------------------------------------------------------
# Database Access Layer
# --------------------------------------------------------






sub readSettings {
# --------------------------------------------------------
	my $user_id = shift || $Wywrota::session->{user}{id};
	my ($data, %userData);
	if ($user_id > 0) {
		$data = Wywrota->db->buildHashRef("SELECT id, `default` FROM user_settings_type");
		%userData = Wywrota->db->buildHash("SELECT id, value FROM user_settings WHERE user_id=$user_id");
		foreach (keys %userData) {			$data->{$_} = $userData{$_};		}
	}

	return $data;
}




sub storeSettings {
# --------------------------------------------------------
	my $user_id = shift || $Wywrota::session->{user}{id};
	my ($id, $value);

	return -1 if (!$user_id);

	foreach $id ( split(",", $Wywrota::in->{user_settings_ids}) ) {
		$value = ($Wywrota::in->{"sett_".$id}) ? ($Wywrota::in->{"sett_".$id}) : (0);
		Wywrota->db->execWriteQuery("DELETE FROM user_settings WHERE user_id=$user_id AND id=$id"); 
		Wywrota->db->execWriteQuery("INSERT INTO user_settings (id, value, user_id) VALUES ($id, $value, $user_id)"); 
	}

	return "Zapisano ustawienia.";
}