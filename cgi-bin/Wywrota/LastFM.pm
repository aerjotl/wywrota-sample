package Wywrota::LastFM;

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
use Net::LastFMAPI;

use Wywrota::Config;
use Wywrota::Log;
use Wywrota::Utils;
use Data::Structure::Util qw(_utf8_off utf8_off utf8_on _utf8_on); 


sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless {}, $class;

	unless (-e "$config{tmp_dir}/lastfm") {
		mkdir "$config{tmp_dir}/lastfm";
		chmod 755, "$config{tmp_dir}/lastfm";
	}

	lastfm_config(
		api_key => $config{lastfm_api_key},
		secret => $config{lastfm_secret},

		cache => 1,
		cache_dir => $config{tmp_dir}."/lastfm",	  
		sk_savefile => $config{tmp_dir}."/lastfm",
	);
	
	return $self;
}


sub ask {
#-----------------------------------------------------------------------
	my $self = shift;
	my $res;
	
	return undef if ($config{site_config_mode} ne 'prod');
	
	push(@_,
	lang  => "pl",
	autocorrect => "1");
	eval {
		$res = lastfm(@_);
	};
	_utf8_off($res);

	return $res;

	
}



1;