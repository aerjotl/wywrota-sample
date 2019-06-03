package Wywrota::SpamFilter;

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
use Class::Singleton;
use base 'Class::Singleton';
use Data::Dumper;
use Net::Akismet;

use Wywrota::Config;
use Wywrota::Log;
use Wywrota::Utils;
use Data::Structure::Util qw(_utf8_off utf8_off utf8_on _utf8_on); 


sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless {}, $class;

	return $self if ($config{site_config_mode} ne 'prod');
	
	$self->{_akismet} = Net::Akismet->new(
		KEY => $config{akismet_api_key},
		URL => $config{site_url},
	) or Wywrota->error('Akismet: Key verification failure!');
	
	return $self;
}


sub check {
#-----------------------------------------------------------------------
	my $self = shift;
	my $message = shift;

	return 0 if ($config{site_config_mode} ne 'prod');
	
	my $verdict = $self->{_akismet}->check(
		USER_IP                 => $ENV{'REMOTE_ADDR'},
		COMMENT_USER_AGENT      => $ENV{'HTTP_USER_AGENT'},
		REFERRER                => $ENV{'HTTP_REFERER'},
		COMMENT_CONTENT         => $message->{content},
		COMMENT_AUTHOR          => $message->{author},
		COMMENT_AUTHOR_EMAIL    => $message->{email},
		COMMENT_TYPE			=> $message->{type},
	) or Wywrota->error('Akismet: Key verification failure!');
	
	# true means spam
	return ('true' eq $verdict);

	
}



1;