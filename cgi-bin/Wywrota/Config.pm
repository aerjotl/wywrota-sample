package Wywrota::Config;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;

use Data::Dumper;
use XML::Simple;
use Data::Structure::Util qw(_utf8_off utf8_off);

our @ISA = qw(Exporter);
our @EXPORT = qw(%config loadConfig);
our %config = (); 


my @debug_levels = ('all', 'trace', 'debug', 'warn', 'error', 'none');


#sub new {
# --------------------------------------------------------
# NOT implemented

	#my $class = shift;
	#my $mode = shift || "prod";
	#my $self = { _configPath=>$configPath, _mode=>$mode };
	#bless $self , $class;


	#if ($ENV{WYWROTEK_MODE}) {
	#	$self->mode = $ENV{WYWROTEK_MODE}
	#}

	#$self->loadConfig();

#}






sub loadConfig {
	my $cgi_dir = shift || ".";
	my $env = shift || \%ENV;
	my ($mode, $cfg);
	
	$config{'env'} = $env;


	$config{'config_dir'} = "$cgi_dir/config";

	$config{'linux'}=1 if !$env->{'WINDIR'} && !$env->{'SYSTEMROOT'};
	$config{'shell'}=1 if !$env->{'SERVER_NAME'};

	if ($env->{WYWROTEK_SITE_CONFIG}) {
		$mode = $env->{WYWROTEK_SITE_CONFIG};
	} else {
		$mode = 'prod';
	}
	$config{'site_config_mode'} = $mode;
	$config{'production'} = ($mode eq 'prod' ? 1 : 0);

	# -- read the XML
	eval {
		my $xml = new XML::Simple;
		$cfg = $xml->XMLin( $config{'config_dir'}."/config.xml" );
		_utf8_off($cfg);
	};
	if ($@) {
		print "FATAL ERROR! Can't open config file $config{'config_dir'}/config.xml !";
		exit;
	}




	foreach (keys %{$cfg}) {
		next if (/^mode$/);
		$config{$_} = $cfg->{$_};
	}

	foreach (keys %{$cfg->{mode}{$mode}}) {
		$config{$_} = $cfg->{mode}{$mode}{$_};
	}
	
	setDebugLevel ($config{debug_level});
	setLogLevel($config{log_level});
	$config{show_debug} = $config{debug}{debug};
	$config{show_errors} = $config{debug}{error};


	$config{'dbname'} = $cfg->{mode}{$mode}{db}{database};
	$config{'dblogin'} = $cfg->{mode}{$mode}{db}{login};
	$config{'dbpasswd'} = $cfg->{mode}{$mode}{db}{pass};
	$config{'dbhost'} = $cfg->{mode}{$mode}{db}{host};	


	loadConst();
	loadRevision();
	$config{'blocked_ip'}	=	loadBlockedIP();

}

sub loadRevision {
# --------------------------------------------------------
	eval{
		open FILE, $config{'config_dir'}."/../../.git/refs/heads/master";
		while (<FILE>) {
			s/[\n\r]//g;
			$config{git}{revision} = $_;
		}
		close FILE;
	
	};
}



sub loadBlockedIP {
# --------------------------------------------------------
	my $ip;
	eval {
		open (FILE, $config{'config_dir'}."/blocked_ip.txt");
		while (<FILE>) {
			s/^\s+|\s+$//g;
			$ip->{$_} = 1;
		}
		close FILE;
	};
	return $ip;	
}





sub loadConst {
# --------------------------------------------------------


	$config{'full_months'} = ['', 'styczeń', 'luty', 'marzec', 'kwiecień', 'maj', 'czerwiec', 'lipiec', 'sierpień', 'wrzesień', 'październik', 'listopad', 'grudzień'];
	$config{'colorTable'} = ['', 'orange','yellow','green','blue','red','gray','cyan','yellow2'];

	$config{'PDFlib_license'} = 'X600605-009100-44E24F-536C04';


	# url'e i sciezki do katalogow
	$config{'db_dir_url'}     = "/cgi-bin";
	$config{'db_script_url'}  = "/db"; 
	$config{'ajax_script_uri'} = '/cgi-bin/ajax.fcgi';
	$config{'static_file_server'}     = $config{'linux'} ? $config{'file_server'} : "";


	#inne zmienne

	$config{'perf_cache_req_actions'} = { 
		'content_include' 	=> "10m",
		'ca' 				=> "2h",
		'landing_page' 		=> "1h",
		'wykonawca_urlized' => "24h",
		'view' 				=> "6h"
	  };
	
	$config{'no_of_comments'} = 25;
	$config{'embedded_logo_path'} = "$config{'www_dir'}/gfx/star_watermark.gif";

	$config{'vote_uservotes_for_star'} = 5;
	$config{'vote_func_val_for_star'} = 8.75;



	# contests
	$config{'contests'} = {
			1 => 'Pierwszy Konkurs Literacki Wywroty 2000',
			10 => '10-lecie Wywroty - proza',
			11 => '10-lecie Wywroty - poezja',
			12 => '10-lecie Wywroty - malarstwo i techniki tradycyjne',
			13 => '10-lecie Wywroty - grafika komputerowa ',
			14 => '10-lecie Wywroty - fotografia',
			15 => '10-lecie Wywroty - utwór muzyczny',
			16 => '10-lecie Wywroty - podcast literacki ',
			17 => '10-lecie Wywroty - film krótkometrażowy ',
			18 => '10-lecie Wywroty - inne formy twórczości',
			19 => '10-lecie Wywroty - artykuł, esej',
		  };
		  
		  
	# actions
	$config{'actions'} =  {
		1 => 'wyświetlił',
		2 => 'przysłał',
		3 => 'edytował',
		4 => 'usunął',
		5 => 'zalogował się',
		6 => 'wydrukował',
		7 => 'autoryzował',
		8 => 'usunął konto',
		21 => 'polecił',
		22 => 'wyróżnił',
		23 => 'wyróżnił jako pracę miesiąca',
		31 => 'dodał akordy',
		32 => 'dodał video',
	};

	

	$config{'subdomains'} = {
	#	name			  cid | page_id 
		'www'			=> [3,  1],
		'literatura'	=> [1,  2],
#		'spiewnik'		=> [7,  13],
		'teksty'		=> [7,  13],
		'forum'			=> [13,  100],
		'konkursy'		=> [20, 1]
	};

	foreach (keys %{$config{'subdomains'}}) {
		$config{'subdomains_cid'}{ $config{'subdomains'}{$_}[0] } = $_;
	};

}



sub setDebugLevel {
# --------------------------------------------------------
	my $level = shift;
	$config{debug} = {};

	for (my $i=$#debug_levels; $i>=0; $i--) {
		$config{debug}{$debug_levels[$i]} = 1 ;
		last if ($debug_levels[$i] eq $level);
	}
}

sub setLogLevel {
# --------------------------------------------------------
	my $level = shift;
	for (my $i=$#debug_levels; $i>=0; $i--) {
		$config{log}{$debug_levels[$i]} = 1 ;
		last if ($debug_levels[$i] eq $level);
	}
}





sub configPath {
# --------------------------------------------------------
	my $self = shift;
	return $self->{_configPath};
}

sub mode {
# --------------------------------------------------------
	my $self = shift;
	return $self->{_mode};
}



1;
