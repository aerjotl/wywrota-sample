package Wywrota::Nut::Session;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

 
use strict;
use Wywrota;
use Wywrota::Log;
use Wywrota::Config;
use Wywrota::Nut::Cookie;
use Wywrota::Language;
use Wywrota::Utils;
use XML::Simple;
use Compress::Zlib;
use MIME::Base64;
use Data::Dumper;
use JSON;

#-----------------------------------------------------------------------
# USER SESSION DATA
#
# $Wywrota::session->{user}{id}			- id z bazy
# $Wywrota::session->{user}{login}		- wywrotid
# $Wywrota::session->{user}{name}			- imie
# $Wywrota::session->{user}{email}			- email
# $Wywrota::session->{user}{groups}{$id}
# $Wywrota::session->{user}{per}{$content_id}{$per_name}
#
#  the struct is dumped, then compressed with zlib and then converted to base64
#
#-----------------------------------------------------------------------


# Wywrota->page->{|PAGE_ID|}{|LABEL|}

# $Wywrota::session->{cid}{$cid}->{..}
# ...
# $Wywrota::session->{user}{premium}
#
# ..... contentConfig.xml


sub new {
# --------------------------------------------------------
	my $class = shift;
	my $nut = shift;
	bless {_nut=>$nut}, $class;
}


sub nut {
# --------------------------------------------------------
	my $self = shift;
	return $self->{_nut};
}

sub state {
# --------------------------------------------------------
	my $self = shift;
	return $self->{_state};
}




sub openSession {
# --------------------------------------------------------
	my $self = shift;
	my (@groups, $groups, $user_id, $user_name, $user_login, $user_email,
		$query, $sessionData, $in_pw, $in_login, $is_premium, $image_filename, %cookie, $session_changed);

	Wywrota->debug("Session : openSession");
	
	
	my $ses = eval {

		%cookie = Wywrota::Nut::Cookie::getCookie(\%ENV);

		# user has a session cookie
		if ($cookie{session_id} && !$config{session_disabled}) {
			Wywrota->trace("has cookie");

			my $storedSession = Wywrota->db->quickHashRef("SELECT * FROM session WHERE id=?", $cookie{session_id});
			if ($storedSession->{id}) {
				$sessionData = decode_json($storedSession->{data});
				Wywrota->error("error evaluating", $@) if ($@);

				if ($sessionData->{session_id} eq $cookie{session_id}) {
					Wywrota->trace("GOOD session");
				} else {
					Wywrota->trace("Session expired");
					$sessionData = {};
				}

			} else {
				Wywrota->trace("Session : BAD cookie in session", $sessionData);
				$sessionData = {};
			}

		};

	
		Wywrota::Facebook::validateToken($self->nut, $cookie{facebook_token}) if ($cookie{facebook_token});
		

		if ($config{session_disabled}) {
			$session_changed = 1 if ($sessionData->{user}{id});
			$user_id = 0;
		} 

		if (!$sessionData->{user}{id}) {
			if ($Wywrota::in->{facebook_id_session}) {	
			
				# we have facebook id
				($user_id, $user_name, $user_email, $user_login, $is_premium, $image_filename) = Wywrota->db->quickArray(qq|
					SELECT id,imie,email,wywrotid,_is_premium,_image_filename 
					FROM ludzie 
					WHERE _active=1 AND facebook_id = ? 
				|, $Wywrota::in->{facebook_id_session}); 
				$session_changed = 1;
				

			} elsif ($Wywrota::in->{'login'} || $Wywrota::in->{'_registernewuser'} || ($cookie{wywrot_login} && $cookie{wywrot_pass}) ) {	
			
				# user tries to log in
				$in_login=  $Wywrota::in->{'login_wywrotid'} || $Wywrota::in->{'wywrotid'} || $cookie{wywrot_login}  ; # login_screen | cookie | register
				$in_pw=     $Wywrota::in->{'pw'} || $Wywrota::in->{'haslo'} || $cookie{wywrot_pass} ;

				($user_id, $user_name, $user_email, $user_login, $is_premium, $image_filename) = Wywrota->db->quickArray(qq|
					SELECT id,imie,email,wywrotid,_is_premium,_image_filename 
					FROM ludzie 
					WHERE _active=1 AND wywrotid=? AND haslo=?
				|, $in_login, $in_pw); 

				# not found - try login with email address
				if (!$user_id) {
					($user_id, $user_name, $user_email, $user_login, $is_premium, $image_filename) = Wywrota->db->quickArray(qq|
						SELECT id,imie,email,wywrotid,_is_premium,_image_filename 
						FROM ludzie 
						WHERE _active=1 AND  email=? AND haslo=?
					|, $in_login, $in_pw); 
				}

				$session_changed = 1;
				
			} 
		}

		if (!$sessionData->{session_id} || $session_changed) {
			$sessionData->{user}{id} = int($user_id);
			$sessionData->{user}{name} = $user_name;
			$sessionData->{user}{email} = $user_email;
			$sessionData->{user}{login} = $user_login;
			$sessionData->{user}{pass} = $in_pw;
			$sessionData->{user}{premium} = int($is_premium);
			$sessionData->{user}{image} = $image_filename;


			# get the user groups
			$groups = 0;
			$sessionData->{user}{groups}{0} = 1;

			if ($user_id) {
				$groups .= ",5";
				$sessionData->{user}{groups}{5} = 1;

				$query = "SELECT g.id FROM ugroup g, user_to_ugroup lg WHERE g.id=lg.ugroup_id AND lg.user_id=$user_id ORDER BY sortorder";
				foreach ( Wywrota->db->buildArray($query) ) {
					$sessionData->{user}{groups}{$_} = 1;
					$groups .= ",".$_;
				}

			}

			$sessionData->{user}{per} = $self->getGroupPermissions($groups);
			
			
			$self->persistSession($sessionData);
		}
		

		#%{$sessionData->{cookie}} = Wywrota::Nut::Cookie::getCookie(\%ENV);
		$self->{_state} = $sessionData;
		
		return $sessionData;
	};
	Wywrota->error("error in openSession",$@) if ($@);

	$self->{_state} = $ses;	
	
}


sub getGroupPermissions {
# --------------------------------------------------------
# setting the permission variables $Wywrota::session->{per}{*}

	my $self = shift;
	my $groups = shift;
	my ($per, $groupPermissions, $sth, $content_id, $per_nazwa);
	
	
	$groupPermissions = Wywrota->memCache->get("group_permissions_".$groups); 
	if ( !$groupPermissions ) {

		$sth = Wywrota->db->execQuery("SELECT content_id,nazwa FROM uprawnienia WHERE ugroup_id IN ($groups) AND wartosc>0"); 
		while (($content_id, $per_nazwa) = $sth->fetchrow_array()) {
			$groupPermissions->{$content_id}{$per_nazwa} = 1;
			if ($per_nazwa eq 'admin') {
				$groupPermissions->{$content_id}{add} = 1;
				$groupPermissions->{$content_id}{mod} = 1;
				$groupPermissions->{$content_id}{del} = 1;
				$groupPermissions->{$content_id}{view} = 1;
			}
		}
		$sth->finish;	
		
		Wywrota->memCache->set("group_permissions_".$groups, $groupPermissions);
		
	};
	return $groupPermissions;
}



sub getUser {
# --------------------------------------------------------
	my $self = shift;
	my ($query);
	Wywrota->trace("Getting user");


}

sub persistSession {
# --------------------------------------------------------
	my $self = shift;
	my $sessionData = shift;
	my $new_session;

	#Wywrota->trace($sessionData);

	# we do not have session id so let's create one
	if (!$sessionData->{session_id}) {
		srand( time() ^ ($$ + ($$ << 15)) );
		$sessionData->{session_id} = (time() % 56251) . (int(rand(10000)) + 1);
		$sessionData->{opened} = time();
		$sessionData->{ip} = $ENV{REMOTE_ADDR};
		$new_session = 1;
	} else {
		Wywrota->db->execWriteQuery("DELETE FROM session WHERE id = ?", $sessionData->{session_id} ); 
	};

	if ($sessionData->{user}{id}) {
		Wywrota->db->execWriteQuery("DELETE FROM session WHERE userid = ?", int($sessionData->{user}{id}) ); 
		Wywrota->db->execWriteQuery("UPDATE ludzie SET last_login = CURRENT_TIMESTAMP WHERE id = ? ",  $sessionData->{user}{id} ); 
	};


	Wywrota->db->execWriteQuery(
		"INSERT INTO session ( `id`, `userid`, `ip`, `data`, `time` ) VALUES ( ?, ?, ?, ?, NOW() ) ", 
		$sessionData->{session_id}, 
		int($sessionData->{user}{id}), 
		$sessionData->{ip}, 
		encode_json($sessionData) 
	); 

	print setCookie("session_id", $sessionData->{session_id});
	print setCookie("wywrot_login", $sessionData->{user}{login}, 1) if ($sessionData->{user}{login});
	print setCookie("wywrot_pass", $sessionData->{user}{pass}, 1) if ($Wywrota::in->{'remember'});
	print setCookie("wywrot_id", $sessionData->{user}{id}, 0) if ($sessionData->{user}{id});
	print setCookie("last_wywrot_id", $sessionData->{user}{id}, 1) if ($sessionData->{user}{id});
	print setCookie("facebook_token", $Wywrota::in->{'facebook_token'}, 1) if $Wywrota::in->{'facebook_token'};
}



sub DESTROY {
# --------------------------------------------------------
	my $self = shift;
	foreach (keys %{$self} ) {
		delete $self->{$_};
	}
	undef $self;
}

1;
