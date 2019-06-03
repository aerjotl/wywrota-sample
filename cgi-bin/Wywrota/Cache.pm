package Wywrota::Cache;

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
use Digest::MD5;

use Wywrota::Config;
use Wywrota::Log;
use Wywrota::Utils;



sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { 
		_config=>shift 
	}, $class;
	
	return $self;
}

sub clean {
#-----------------------------------------------------------------------
	my $self = shift;
	my $cache_id = shift;
	
	unlink ("$config{tmp_dir}/cache/".substr($cache_id, 0, 2)."/". $cache_id );
}

sub storeCache {
#-----------------------------------------------------------------------
	my $self = shift;
	my $cache_id = shift;
	my $content = shift;
	my $cacheHours = shift;
	my ($shouldstore, $prefix);
	
	my $cache_dir = "$config{tmp_dir}/cache";

	$cache_id = Digest::MD5::md5_hex($cache_id);
	$prefix = substr($cache_id, 0, 2);

	if ($cacheHours) {
		$shouldstore = 1 
	} else {
		foreach (keys %{$config{'perf_cache_req_actions'}}) {
			if (defined $Wywrota::in->{$_}) {
				$shouldstore = 1;
			}
		}
		$shouldstore = 0 if ($Wywrota::session->{user}{id} != 0);
	}
	

	# storing content
	if (length($content) > 100 && $config{'cache'}{'active'} && $shouldstore) {	

		unless (-e "$cache_dir") {
			mkdir "$cache_dir";
			chmod 755, "$cache_dir";
		}
		
		unless (-e "$cache_dir/$prefix") {
			mkdir "$cache_dir/$prefix";
			chmod 755, "$cache_dir/$prefix";
		}

		open ("FILE", ">$cache_dir/$prefix/$cache_id");
		print FILE $content; 
		close FILE;
	}
}


sub getFromCache {
#-----------------------------------------------------------------------
	my $self = shift;
	my $cache_id = shift;
	my $cacheTime = shift;
	my ($output, $fileDate, $age, $shouldInclude, $prefix);

	my $cache_dir = "$config{tmp_dir}/cache";
	
    return if (!$config{'cache'}{'active'});

	# cache only data from anonymous users
    return if ($Wywrota::session->{user}{id} != 0 && !$cacheTime);
	
	$cache_id = Digest::MD5::md5_hex($cache_id);
	$prefix = substr($cache_id, 0, 2);
	$fileDate = (stat("$cache_dir/$prefix/$cache_id"))[9];
	
	# no file found
	return if (!$fileDate);

	# included file has changed
	return if ($Wywrota::in->{content_include} && (stat($config{'www_dir'}."/content/".$Wywrota::in->{content_include}))[9] > $fileDate );

	$age = (time - $fileDate) / $config{'cache'}{'multiplier'};

	if ($cacheTime) {
		$shouldInclude = 1 if ($age < timeAlias($cacheTime));

	} else {
		foreach (keys %{$config{'perf_cache_req_actions'}}) {
			
			if (defined $Wywrota::in->{$_} and $age < timeAlias( $config{'perf_cache_req_actions'}->{$_}) ) {
			
				$shouldInclude = 1;
			}
		}
	}
	

	# the file in cache has expired
	return if (!$shouldInclude);

	open ("FILE", "$cache_dir/$prefix/$cache_id" );
	while (<FILE>) {$output .= $_;};
	close FILE;
	$output .= "\n<!-- cache: [$cache_id] $cacheTime  -->";

	return $output;
	
}

1;