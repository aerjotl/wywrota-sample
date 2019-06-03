package Wywrota::Facebook;

#-----------------------------------------------------------------------
#   ___            __      __                   _       _   
#  | _ \__ _ _ _   \ \    / /  ___ __ ___ _ ___| |_ ___| |__
#  |  _/ _` | ' \   \ \/\/ / || \ V  V / '_/ _ \  _/ -_) / /
#  |_| \__,_|_||_|   \_/\_/ \_, |\_/\_/|_| \___/\__\___|_\_\
#                           |__/                            
#
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict; 
use Data::Dumper;

use URI;
use URI::QueryParam;
use Wywrota;
use Wywrota::Config;
use Wywrota::Log;
use Wywrota::Utils;
use Wywrota::Object::SiteImages;

use Data::Structure::Util qw(_utf8_off utf8_off utf8_on _utf8_on); 

use LWP::Simple;  
use LWP::UserAgent;
use Mozilla::CA; # "Can't verify SSL peers without knowing which Certificate Authorities to trust" https://community.servicenow.com/thread/158584

use Facebook::Graph;

my $fb;

sub facebookLogin {
# --------------------------------------------------------
# 	the first entry point

	my $nut = shift;

	my $uri = $nut->fb->authorize
	   ->extend_permissions(qw(email user_birthday user_hometown))
	   ->uri_as_string;
	return "Status: 302 Found\n". "Location: ". $uri ."\n\n" ;	
	
}



sub facebookPostback {
# --------------------------------------------------------
#	the second stop - after facebook confirmed permissions

	my $nut = shift;
	my $fbuser;
	
	Wywrota->trace("in facebook_postback");
	eval {
		$nut->fb->request_access_token($nut->in->{'code'});
		$fbuser=$nut->getFacebookUser;
		if($fbuser and $fbuser->{id}){
			$nut->in->{facebook_id_session}=$fbuser->{id};
			$nut->in->{facebook_token}=$fbuser->{facebook_token};
		}
	};
	
	if ($@) {
		if ($config{site_config_mode} eq 'prod') {
			return Wywrota->errorPage("Wystąpił błąd podczas logowania przez Facebook", $@);
		} else {
			Wywrota->error("facebook error: $@");
			$fbuser = _dummyUser();
			if($fbuser and $fbuser->{id}){
				$nut->in->{facebook_id_session}=$fbuser->{id};
				$nut->in->{facebook_token}=$fbuser->{facebook_token};
			}
		}
	}

	if($fbuser){
		Wywrota->trace("GOT facebook user");
		$nut->session->openSession();
		$Wywrota::session = $nut->session->state();

		if ($Wywrota::session->{user}{id}) {
			# found user by facebook_id
			return Wywrota::User::loginAction($nut);

			
		} else {
		
			# try to find user by email address
			my $uid = mergeByEmail($fbuser);
			
			if ($uid>0) {
				$nut->in->{facebook_id_session}=$fbuser->{id};
				$nut->in->{facebook_token}=$fbuser->{facebook_token};
				$nut->session->openSession();
				$Wywrota::session = $nut->session->state();
				return Wywrota::User::loginAction($nut, "Twoje konto zostało połączone z kontem Facebook");

			}
		
			return firstLoginScreen($fbuser);
		} 

	}
}


sub firstLoginScreen {
# --------------------------------------------------------
	my $fbuser = shift;

	Wywrota->trace("First facebook login");
	my $output=Wywrota->t->process('form/facebook_first_login.html',$fbuser);
	
	return Wywrota->view->wrapHeaderFooter({
		output=>$output, 
		nomenu=>'bar',
		nobillboard=>1});

}


sub mergeByEmail {
# --------------------------------------------------------
# cheks if user exists

	my $fbuser = shift;
	my ($id ) = Wywrota->db->quickArray(qq|SELECT id FROM ludzie WHERE email=? AND _active=1 AND facebook_id IS NULL ORDER BY last_login DESC|, $fbuser->{email} );
	Wywrota->trace("mergeByEmail", $id);
	
	# we have found the user in our database
	if ($id > 0) {
		Wywrota->db->execWriteQuery("update ludzie set facebook_id =? where id = ?", $fbuser->{id}, $id);
		importImage($fbuser, $id);
	};
	
	
	return $id;
}



sub facebookNewUser {
# --------------------------------------------------------
# quick registration - import data from facebook

	Wywrota->trace( "In facebookNewUser\n" );
	my $nut = shift;
	my $in=$nut->in;
	
	
	my $fbuser;
	eval {
		$nut->fb->access_token($nut->in->{facebook_token});
		$fbuser=$nut->getFacebookUser($nut->in->{facebook_token});
	};
	
	if ($@ || !$fbuser) {
		if ($config{site_config_mode} eq 'prod') {
			return Wywrota->errorPage("Wystąpił błąd podczas logowania przez Facebook", $@);
		} else {
			Wywrota->error("facebook error: $@");
			$fbuser = _dummyUser();
		}
	}
	
    my $rok =substr($fbuser->{birthday},-4);
	my $user={
		wywrotid=>$in->{wywrotid},
		imie=>$fbuser->{name},
		email=>$fbuser->{email},
		plec=>(
			$fbuser->{gender} eq 'male' ? 
			2 : 
			(	$fbuser->{gender} eq 'female' ?  
				1 : 
				0) 
			),
		skad => $fbuser->{hometown}{name} || 'nieznane',
		rok_urodzenia => $rok,
        facebook_id=>$fbuser->{id},
		data_wpisu=>Wywrota::Utils::getDate()
		
     };

	my $wywuser;
	my ($status, $object);
	eval {
		$wywuser=Wywrota::Object::User->new($user);
		$nut->in->{url}=$config{'robot_protection'} ;
		($status, $object) = Wywrota->content->persist($wywuser);
	};
	Wywrota->errorPage("Wystąpił błąd", $@) if ($@);

	if ($status eq 'ok') {
	
		importImage($fbuser, $object->id);
	
		#login new user
		$nut->in->{facebook_id_session}=$fbuser->{id} ;
		$nut->in->{facebook_token}=$fbuser->{facebook_token};
		$nut->session->openSession();
		$Wywrota::session = $nut->session->state();
		return Wywrota::User::loginAction($nut);
			
	}else{
	
		$fbuser->{errors} =  $object->getErrors();
		return firstLoginScreen($fbuser);
		
	}
	
}



sub facebookConnect {
# --------------------------------------------------------
	my $nut=shift;
	my $fbuser;
	my $uid;
	eval {
		$nut->fb->access_token($nut->in->{facebook_token});
		$fbuser=$nut->getFacebookUser($nut->in->{facebook_token});
		Wywrota->warn( "fbuser", $fbuser);
	};

	if ($@ || !$fbuser) {
		if ($config{site_config_mode} eq 'prod') {
			return Wywrota->errorPage("Wystąpił błąd podczas logowania przez Facebook", $@);
		} else {
			Wywrota->error("facebook error: $@");
			$fbuser = _dummyUser();
		}
	}

	
	($uid) = Wywrota->db->quickArray(qq|
				SELECT id FROM ludzie  
				WHERE wywrotid=? AND haslo =? 
				AND facebook_id IS NULL AND _active=1
			|, $Wywrota::in->{login_wywrotid}, $Wywrota::in->{pw} );
		
	# not found - try login with email address
	if (!$uid) {
		($uid) = Wywrota->db->quickArray(qq|
				SELECT id FROM ludzie  
				WHERE email=? AND haslo =? 
				AND facebook_id IS NULL AND _active=1
			|, $Wywrota::in->{login_wywrotid}, $Wywrota::in->{pw} );
	}
		
		
	if($uid >0) {
		Wywrota->db->execWriteQuery("update ludzie set facebook_id =? where id = ?", $fbuser->{id}, $uid);
		
		importImage($fbuser, $uid);
		
		$nut->in->{facebook_id_session}=$fbuser->{id};
		$nut->in->{facebook_token}=$fbuser->{facebook_token};
		$nut->session->openSession();
		$Wywrota::session = $nut->session->state();
		return Wywrota::User::loginAction($nut, "Twoje konto zostało połączone z kontem Facebook" );
			
	} else {
	
		$nut->sysMessage->push( "Niepoprawna nazwa użytkownika lub hasło", "err" );
		return firstLoginScreen($fbuser);
		
	}
}




sub importImage {
# --------------------------------------------------------
	my $fbuser = shift;
	my $uid = shift;
	my ($photo, $path, $filename, $status, $si);
	
	eval {
	
		($photo) = Wywrota->db->quickArray("SELECT _image_filename FROM ludzie WHERE id = ?", $uid);
		
		$path = $config{'file_dir'} . "/site_images";
		
		$filename = substr(Digest::MD5::md5_hex(time()), 0,8) ."_jpg";
		
		unless ($photo) {
		
			Wywrota->trace("getting image", $fbuser->{facebook_picture_big_url}, "$path/$filename");
			my $status = LWP::Simple::getstore($fbuser->{facebook_picture_big_url}, "$path/$filename");

			if ($status == 200) {
			
				$status = Wywrota::Image::createImageSet("$path/$filename", 
								Wywrota->cc('SiteImages')->{dict}{field}{'nazwa_pliku'});
								
				if ($status == 'ok') {
					$si = Wywrota::Object::SiteImages->new({
						nazwa_pliku => $filename,
						user_id => $uid,
						typ => 1,
						isdefault => 1,
						source => "facebook"
					});
					
					my ($imgstatus, $imgobject) = Wywrota->content->persist($si);
					
					Wywrota->db->execWriteQuery("update ludzie set _image_filename =?, _image_id =? where id = ?", $filename, $imgobject->id, $uid);
		
				}
						
			} else {
				Wywrota->error("error while getting image", $fbuser->{facebook_picture_big_url}, "$path/$filename", "status: $status");
			};
		
		
		}
		
	};
	Wywrota->error("error while saving image $@") if ($@);

}


sub validateToken {
# --------------------------------------------------------
	my $nut=shift;
	my $token = shift;
	my $fbuser;
	eval {
		$nut->fb->access_token($token);
		$fbuser=$nut->getFacebookUser($token);
	};

	if ($@ || !$fbuser) {
		if ($config{site_config_mode} eq 'prod') {
			return undef;
		} else {
			Wywrota->error("validateToken: facebook error: $@");
			$fbuser = _dummyUser();
		}
	}
	if ($fbuser && $fbuser->{id}) {
		$Wywrota::in->{facebook_id_session}=$fbuser->{id};
		$Wywrota::in->{facebook_token}=$fbuser->{facebook_token};
	}
}


sub _dummyUser {
	return {
		'facebook_picture_url' => 'http://graph.facebook.com/630293064/picture?type=normal',
		'facebook_picture_big_url' => 'http://graph.facebook.com/630293064/picture?width=9999&height=9999',
		'facebook_token' => '2313131231',
		'username' => 'test.user',
		'name' => 'Arek Janicki',
		'email' => 'aerjotl@gmail.acom',
		'id'	=> 123456
	};
}

1;