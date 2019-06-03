package Wywrota::Log;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict;
use Exporter; 
use Wywrota::Config;
use Wywrota::Utils;
use Data::Dumper;
use HTTP::BrowserDetect;
our @ISA = qw(Exporter);
our @EXPORT = qw(log logFile logSearch getActionLog debugObject);

	

sub log {
# --------------------------------------------------------
# zapisuje do bazy logi 
	my ($content_id, $record_id, $action) = @_;
	# $action: 
	# 1. view
	# 2. add
	# 3. edit
	# 4. delete
	# 5. login
	# 6. print
	# 7. authorize
	# 8. suicide
	
	# 21. distinction - 1
	# 22. distinction - 2

	return if (!$record_id || !$content_id);

	my $table = ($action==1) ? ('wywrota_log.log') : ('log_actions');
	my $browser = new HTTP::BrowserDetect($ENV{'HTTP_USER_AGENT'});


	Wywrota->db->execWriteQuery("INSERT INTO $table (`content_id`, `record_id`, `action`, `user_id`, `ip`, `time`, `user_agent`, `is_bot`) VALUES (?, ?, ?, ?, ?, NOW(), ?, ?)", 
		$content_id, 
		$record_id, 
		$action, 
		int($Wywrota::session->{user}{id}),
		$ENV{'REMOTE_ADDR'},
		substr($ENV{'HTTP_USER_AGENT'}, 0, 128),
		($browser && $browser->robot) ? 1 : 0
	);
	
	increaseContentViews($content_id, $record_id) if ($action==1);

}


sub increaseContentViews {
# --------------------------------------------------------
	my ($content_id, $record_id) = @_;

	if (! Wywrota->db->execWriteQuery( "UPDATE _content_views SET count=count+1 WHERE  content_id=? AND record_id=? ",  $content_id, $record_id) ) {
		# query returned 0 - it means record was not found
		Wywrota->db->execWriteQuery( "INSERT INTO _content_views VALUES (?,?,?) ",  $content_id, $record_id, 1);
	};
	
}


sub logSearch {
# --------------------------------------------------------
	my ($keyword, $results, $content_id, $source, $search_options) = @_;
	return if (!$keyword);

	Wywrota->db->execWriteQuery(
		"INSERT INTO wywrota_log.log_search VALUES (?, ?, ?, ?, ?, ?, ?, NOW())",
		$keyword, 
		$results, 
		$content_id, 
		$source,
		$search_options,
		int($Wywrota::session->{user}{id}),
		$ENV{'REMOTE_ADDR'}
	);
		

}



sub logFile {
# --------------------------------------------------------
# zapisuje do pliku logi 
	my $output;
	my $log_file = shift;
	foreach (@_) {
		$output .= $_."\n";		
	}

	open (LOGFILE,">>$config{'log_dir'}/$log_file.log");
	print LOGFILE getDate()." $output	\t\t\t\tIP:$ENV{'REMOTE_ADDR'} : $ENV{'REQUEST_URI'}\n";
	close LOGFILE;

}




sub getActionLog {
# --------------------------------------------------------
	my $record_id = shift;
	my $content_id = shift;

	return unless ($record_id and $content_id);

	return Wywrota->db->buildHashRefArrayRef(qq~
		SELECT la.*, ludzie.imie FROM log_actions la
		RIGHT OUTER JOIN ludzie ON la.user_id=ludzie.id 
		WHERE content_id=? AND record_id=? ORDER BY time 
		~, $content_id, $record_id);
}



sub getCreationIP {
# --------------------------------------------------------
	my $record_id = shift;
	my $content_id = shift;

	return unless ($record_id and $content_id);

	my ($ip) = Wywrota->db->quickArray(qq~
		SELECT la.ip FROM log_actions la
		WHERE content_id=? AND record_id=? 
		AND action = 2 
		~, $content_id, $record_id);
		
	return $ip;
}

sub getLastUserByIP {
# --------------------------------------------------------
	my $ip = shift;
	
	return unless ($ip);

	return Wywrota->db->quickHashRef(qq~
		SELECT la.time, ludzie.* FROM log_actions la
		RIGHT OUTER JOIN ludzie ON la.user_id=ludzie.id 
		WHERE ip=? AND user_id>0 ORDER BY time DESC
		LIMIT 0,1
		~, $ip);
	
}

sub getUserActionLog {
# --------------------------------------------------------
	my $user_id = shift;

	return unless ($user_id);

	return Wywrota->db->buildHashRefArrayRef(qq~
		SELECT la.* FROM log_actions la
		WHERE la.user_id=? ORDER BY time DESC
		LIMIT 0,20
		~, $user_id);
}



sub getUserRegisteredLog {
# --------------------------------------------------------
	my $user_id = shift;

	return unless ($user_id);

	return Wywrota->db->buildHashRefArrayRef(qq~
		SELECT la.* FROM log_actions la
		WHERE la.content_id=6 
			AND la.action=2
			AND la.record_id=? 
		~, $user_id);
}



sub getUserActionLogHTML {
# --------------------------------------------------------
	my $user_id = shift;
	my ($action, $output);

	my $log = getUserActionLog($user_id);
	my $registered = getUserRegisteredLog($user_id);

	foreach $action (@{$log}) {
		$output .= "<tr><td>"
			. $config{'actions'}{$action->{action}} 
			. " " . Wywrota->cc($action->{content_id})->{keyword} . "  " . $action->{record_id} 
			. "</td><td> ". normalnaData($action->{time},1)  
			. "</td><td> " . $action->{ip} 
			. "</td></tr>";
	}
	
	foreach $action (@{$registered}) {
		$output .= "<tr><td>"
			. " zarejestrował się" 
			. "</td><td> ". normalnaData($action->{time},1)  
			. "</td><td> " . $action->{ip} 
			. "</td></tr>";
	}
	
	return qq~
		<h3>Ostatnia aktywność</h3>
		<table class="actionLog">
		$output
		</table>
		~;
}





sub debugObject {
# --------------------------------------------------------
	my $object = shift;
	my $output;

	$output = Wywrota->template->HTTPheader('Object debug', 'bar');
	$output .= "<h1>Object debug</h1><pre>" . Dumper($object) . "</pre>";

	return $output;

}

1;
