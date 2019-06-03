package Wywrota::Nut;

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
#
#
#	$nut->in->{action}
#	$nut->user->{id}
#	$nut->per('view')
#
 
use strict; 

use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Request;
use Wywrota::Nut::Session;
use Wywrota::Nut::Security;
use Wywrota::Nut::SysMessage;

use Facebook::Graph;



sub new {
# --------------------------------------------------------
	my $class = shift;
	my $cgiRequest = shift;
	my $options = shift;
	my $sessionToKeep = shift;
	
	my $self = {   };
	bless $self , $class;
	
	eval {

	$Wywrota::in=undef;
	$Wywrota::request=undef;
	

	if ($options) {
		$self->{_opt} = $options;		
	}

	if ($cgiRequest) {
		$self->request($cgiRequest);
		$Wywrota::in = $self->request->in();
		$Wywrota::request = $self->request();
	};
	
	if (!$sessionToKeep) {
		$Wywrota::session=undef;
		$self->session->openSession();
		$Wywrota::session = $self->session->state();
	}
	
	$Wywrota::session->{'googlebot'}=1 if ($ENV{'HTTP_USER_AGENT'}=~"google");

	};
	
	Wywrota->error($@) if ($@);
	
	return $self;
}



sub security {
# --------------------------------------------------------
	my $self = shift;
	unless (exists $self->{_security}) {
		$self->{_security} = Wywrota::Nut::Security->new($self);
	}
	return $self->{_security};
}

sub cookie {
# --------------------------------------------------------
	my $self = shift;
	unless (exists $self->{_cookie}) {
		$self->{_cookie} = Wywrota::Nut::Cookie->new($self);
	}
	return $self->{_cookie};
}

sub session : lvalue {
# --------------------------------------------------------
	my $self = shift;
	unless (exists $self->{_session}) {
		$self->{_session} = Wywrota::Nut::Session->new($self);
	}
	$self->{_session};
}

sub request : lvalue {
# --------------------------------------------------------
	my $self = shift;
	my $request = shift;
	unless (exists $self->{_request}) {
		$self->{_request} = Wywrota::Nut::Request->new($self, $request);
	}
	$self->{_request};
}

sub sysMessage {
# --------------------------------------------------------
	my $self = shift;
	unless (exists $self->{_sysMessage}) {
		$self->{_sysMessage} = Wywrota::Nut::SysMessage->new($self);
	}
	return $self->{_sysMessage};
}



sub crush {
# --------------------------------------------------------
	my $self = shift;

	delete $self->{_request};
	delete $self->{_session};
	
	foreach (keys %{$self} ) {
		delete $self->{$_};
	}

}


sub DESTROY {
	my $self = shift;
#	print "  Nut::DESTROY\n";
	$self->crush;
}



sub in {	return shift->request()->in(@_);	}
sub per {	return shift->security()->per(@_);	}
sub perRecord {	return shift->security()->perRecord(@_);	}


sub opt : lvalue {
# --------------------------------------------------------
	my $self = shift;
	my $variable = shift;
	unless (exists $self->{_opt}) {
		$self->{_opt} = {};
	}
	#Wywrota->warn($self->{_opt}, $variable);
	$self->{_opt}{$variable};		# if ($variable);
	#$self->{_opt};
}




sub fb {
# --------------------------------------------------------
	my $self = shift;
	unless (defined $self->{_fb}) {
		my $uri = URI->new("http://".$Wywrota::request->{urlPrefix} . "." . $Wywrota::request->{urlSufix}.'/db');
		$uri->query_param('facebook_postback' => 1);
		$uri->query_param('back' => $Wywrota::in->{back}) if ($Wywrota::in->{back});
	
		$self->{_fb} = Facebook::Graph->new( 
		   app_id          => $config{facebook_app_id}, 
		   secret          => $config{facebook_app_secret}, 
		   postback        => $uri->as_string 
		); 
	}
	return $self->{_fb};
};



sub getFacebookUser {
# --------------------------------------------------------
	my $self=shift;
	my $user=undef;
	eval {
		$user = $self->fb->fetch('me');
		if($user and $user->{id}){
			$user->{facebook_picture_url}=$self->fb->picture($user->{id})->uri_as_string . "?type=normal";
			$user->{facebook_picture_big_url}=$self->fb->picture($user->{id})->uri_as_string . "?width=6000&height=8000";
			$user->{facebook_token}=$self->fb->access_token;
			$user->{name_urlized}=simpleAscii($user->{name});
			$user->{name_urlized}=~ s/\-/./g;
		};
		
	};
	Wywrota->error("getFacebookUser error $@") if ($@);
	return $user;
}








1;
