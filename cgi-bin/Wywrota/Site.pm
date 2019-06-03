package Wywrota::Site;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Exporter; 
use Wywrota;
use Wywrota::Utils;
use Wywrota::Log;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Object::User;
use Wywrota::Language;
use Wywrota::Object::User;
use Wywrota::Object::Manager::PageManager;

our @ISA = qw(Exporter);
our @EXPORT = qw(action siteMap);


sub action {
# -------------------------------------------------------------------------------------
	my $output;
	my $nut = shift;
	my $action = $nut->in->{siteAction} || $nut->in->{site} ;
	
	if ($action eq 'map') { $output = Wywrota::Object::Manager::PageManager->siteMap();} 
	elsif ($action eq 'mapAdmin') { $output = Wywrota::Object::Manager::PageManager->siteMapAdmin();} 
	elsif ($action eq 'xmlMap') { $output = Wywrota::Object::Manager::PageManager->getXML();} 
	elsif ($action eq 'redakcja') { $output = editors();} 
	elsif ($action eq 'editors') { $output = editors();} 
	elsif ($action eq 'groupUserList') { $output = listUserGroupSmall($Wywrota::in->{gid});} 
	elsif ($action eq 'listUserGroup') { $output = listUserGroup($Wywrota::in->{gid});} 
	elsif ($action eq 'showGroup') { $output = showGroup($Wywrota::in->{id});} 
	elsif ($action eq 'moderateStats') { $output = moderateStats($Wywrota::in->{cid});} 
	elsif ($action eq 'commentStats') { $output = commentStats($Wywrota::in->{cid});} 	
	elsif ($action eq 'check') { $output = checkIP($Wywrota::in->{ip});} 	
	elsif ($action eq 'flushMemCache') { Wywrota->memCache->flush(); $output = Wywrota->errorPage("flushMemCache" );} 	
	elsif ($action eq 'cache') { Wywrota->cache->clean($Wywrota::in->{clean}); $output = Wywrota->errorPage("cache cleaned", $Wywrota::in->{clean} );} 	
	
	else { 
		return Wywrota->unknownAction($action);

	}

	
	return $output;
}



sub moderateStats {
	# -------------------------------------------------------------------------------------
	# statystyki moderowania

	my ($output, $query, $rec );
	my $cid = shift || 1;
	my $i=0;

	$query = qq~
		SELECT imie, wywrotid, user_id, count(la.action) as cnt FROM `log_actions` la
		LEFT JOIN ludzie ON la.user_id = ludzie.id
		WHERE content_id=$cid 
		   AND `time` > ~.  Wywrota->db->quote( getDate(time() - 2592000) ) . qq~
		   AND (`action` = 7)
		GROUP BY user_id
		ORDER BY cnt DESC
	~;



	my $hits = Wywrota->db->buildHashRefArrayRef($query);

	foreach $rec (@{$hits}) {
			$i++;
			$output .= qq~
				<tr><td>
					$i.
				</td><td class="imie">
					<a href="/ludzie/$rec->{wywrotid}">
					$rec->{imie}
					</a>
				</td><td class="cnt">
					$rec->{cnt}
				</td>
				</tr>
			~; 
	}

	$output =  qq~
		<h3>Moderacja: ~. Wywrota->app->{cc}{$cid}{package} .qq~ </h3>
		<table class="moderateStats">
		$output
		</table>
	~;

	return Wywrota->nav->absoluteLinks($output);
}



sub commentStats {
	# -------------------------------------------------------------------------------------
	# statystyki komentowania

	my ($output, $query, $rec );
	my $cid = shift || 1;
	my $i=0;

	$query = qq~
		SELECT imie, wywrotid, user_id, _grupy, count(k.id) as cnt FROM `komentarze` k
			LEFT JOIN ludzie ON k.user_id = ludzie.id
			WHERE k.content_id=$cid  AND `data` > ~.  Wywrota->db->quote( getDate(time() - 2592000) ) . qq~
			GROUP BY user_id
			ORDER BY cnt DESC
		LIMIT 0,20
	~;



	my $hits = Wywrota->db->buildHashRefArrayRef($query);

	foreach $rec (@{$hits}) {
			$i++;
			$output .= qq~
				<tr><td>
					$i.
				</td><td class="imie">
					<a href="/ludzie/$rec->{wywrotid}">
					$rec->{imie}
					</a>
				</td><td class="cnt">
					$rec->{cnt}
				</td>
				</tr>
			~; 
	}

	$output =  qq~
		<h3>Komentarze: ~. Wywrota->app->{cc}{$cid}{package} .qq~ </h3>
		<table class="moderateStats">
		$output
		</table>
	~;

	return Wywrota->nav->absoluteLinks($output);
}








sub editors {
# -------------------------------------------------------------------------------------
	my ($output, $groups, $group, $users, $sth);

	$output = Wywrota->template->header({ title => "Redakcja", nomenu => 2 });

	$output .= qq~
		<h1>Redakcja</h1>
		
		~;

	$groups = Wywrota->db->buildHashRef("SELECT id, nazwa FROM ugroup WHERE visible = 1 AND id>0 ORDER BY sortorder");

	foreach $group (keys %{$groups}) {
		$output .= qq~

			<br class="clrl">
			<div class="ugroup_sm ugroup_sm_$group">$groups->{$group}</div>
			
		~ 
		. listUserGroup($group) 
		. "<br><br>";
	}

	$output .= qq~
		<br class="clrl"> 
	
		<a href="/site/showGroup/id/7" style="font-weight: bold; font-size: 16px; margin-top: 20px; text-decoration: underline;">
			<img src="/gfx/odznaki/gwardia_sm.png" width="60" height="60" border="0" alt="" align="absmiddle" hspace="5">
			Zasłużeni dla serwisu
		</a><br>
	~;



	$output .= Wywrota->template->footer();

	return $output;
}


sub showGroup {
	# -------------------------------------------------------------------------------------
	my $group_id = shift;
	my $output;

	my $group = Wywrota->content->getObject($group_id, 'UserGroup'); 

	$output = qq~		
		<h1>Redakcja</h1>
		<a href="/site/redakcja.html" class="arLeft">powrót do stopki redakcyjnej</a>
		
		
		<br class="clrl"><br><br><br>
		<div class="ugroup ugroup_$group_id">$group->{rec}->{nazwa}</div>
			<h1>$group->{rec}->{nazwa}</h1>
			$group->{rec}->{description}
		~;

		

	$output = Wywrota->template->header({ title => $group->{nazwa}, nomenu=>2	})
			. $output 
			. listUserGroup($group_id)
			. qq~<br><br><a href="/site/redakcja.html" class="arLeft">powrót do stopki redakcyjnej</a>~
			. Wywrota->template->footer();

	return $output;
}





sub listUserGroup {
	# -------------------------------------------------------------------------------------
	# pokazuje listę użytkowników należących do danej grupy

	my $group_id = shift;
	my ($output, $user, $rec);

	my $hits = Wywrota->db->buildHashRefArrayRef(
		"SELECT l.* FROM user_to_ugroup lg LEFT JOIN ludzie l ON lg.user_id=l.id WHERE ugroup_id=$group_id AND l._active=1 ORDER BY id");

	foreach (@{$hits}) {
			$user =  Wywrota->content->createObject( $_, "User" );
			$user->preProcess('sq');
			$rec = $user->rec;
			#$rec->{wiek} = " &middot; $rec->{wiek}" if ($rec->{wiek});
			$rec->{skad} = " &middot; $rec->{skad}" if ($rec->{skad});

			$rec->{real_name} = $rec->{imie} if (!$rec->{real_name});

			$output .= qq~
				<tr><td>
					<a href="$rec->{uri}">
					$rec->{avatar}
					</a>
				</td><td width="100%" class="details">
					<h2>$rec->{real_name}  </h2>
					<h4>$rec->{wiek} $rec->{skad}</h4>
					$rec->{function}
				</td>
				</tr>
			~; #$rec->{notka}
	}

	$output = qq~
		<table class="redakcja">
		$output
		</table>
	~;


}

sub listUserGroupSmall {
	# -------------------------------------------------------------------------------------
	# pokazuje listę użytkowników należących do danej grupy $Wywrota::in->{gid}

	my ($output, $sth, $query, $rec );
	my $gid = shift || 1;

	$output .= qq~<div class="moderatorzy">~;

	$query = qq~
		SELECT l.id, l.imie, l.wywrotid, l._image_filename 
		FROM user_to_ugroup lg 
		INNER JOIN ludzie l ON lg.user_id = l.id 
		WHERE lg.ugroup_id=$gid AND l._active=1 
		ORDER BY plec, imie
	~;
	$sth = Wywrota->db->execQuery($query); 
	while ( $rec = $sth->fetchrow_hashref() ) { 
		$output .= Wywrota::Object::User->new($rec)->recordSmall;
	}
	$sth->finish;
	
	$output .= qq~</div>~;

	return Wywrota->nav->absoluteLinks($output);
}


sub checkIP {
	# -------------------------------------------------------------------------------------
	my $ip = shift;
	my $lastIPUser =  Wywrota::Log::getLastUserByIP($ip);
	
	my $user = Wywrota::Object::User->new($lastIPUser);

	return Wywrota->t->wrapHeaderFooter({
		output => ($lastIPUser->{id}) ? 
			"<h1>Ostatni użytkownik widziany z adresu $ip</h1><h3>o godzinie $lastIPUser->{time}</h3>" .$user->recordLead() 
			: "<h1>Nie znaleziono użytkownika który logował się z adresu $ip</h1>",
		nomenu => 'bar',
		nocache	=> 1
	});
	
}
