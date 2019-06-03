package Wywrota::MemCache;

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

use Cache::Memcached;
use Data::Dumper;
use Wywrota;

use Wywrota::Config;
use Wywrota::Utils;




sub _new_instance {
# --------------------------------------------------------
	my $class = shift;

	my $self  = bless { 
		mem=>{} ,
		client=>  Cache::Memcached->new ({
			servers => ["$config{memcache}{host}:$config{memcache}{port}"],
			compress_threshold => 10_000
		})
		}, $class;
	return $self;
}



sub set {
# --------------------------------------------------------
	my $self = shift;
	my $key = shift;
	my $val = shift;
	my $cacheTime = timeAlias(shift);
	
	if ($self->connected) {
		return $self->client->set($key, $val, $cacheTime);
	} else {
		$self->{mem}{$key} = $val;
		return 1;
	}
}


sub get {
# --------------------------------------------------------
	my $self = shift;
	my $key = shift;
	
	if ($self->connected) {
		return $self->client->get($key);
	} else {
		return $self->{mem}{$key};
	}
}


sub incr {
# --------------------------------------------------------
	my $self = shift;
	my $key = shift;
	
	if ($self->connected) {
		return $self->client->incr($key);
	} else {
		return ++$self->{mem}{$key};
	}
}


sub decr {
# --------------------------------------------------------
	my $self = shift;
	my $key = shift;
	
	if ($self->connected) {
		return $self->client->decr($key);
	} else {
		return --$self->{mem}{$key};
	}
}


sub flush {
# --------------------------------------------------------
	my $self = shift;
	if ($self->connected) {
		$self->client->flush_all();
	} else {
		$self->{mem} = {};
	};	
}


sub connected {
# --------------------------------------------------------
	my $self = shift;
	my $cnt = 0;

	return $config{memcache}{active};


	foreach (keys %{$self->client->stats()}) {
		$cnt++;
	}


	return $cnt;
};


sub client : lvalue {	shift->{client}	}


1;