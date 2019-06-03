package Wywrota::Application;

#-----------------------------------------------------------------------
#
#  Application.pm - holds references to all major utility classes
#
#-----------------------------------------------------------------------
# Pan Wywrotek
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict; 
use XML::Simple;
use Data::Dumper;

use Class::Singleton;
use base 'Class::Singleton';

use Wywrota::Config;
use Wywrota::Dictionary;
use Data::Structure::Util qw(_utf8_off);



sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { 
		page=>{}, 
		cc=>{}, 
		ccByName=>{},
		dict=>{}
		}, $class;

	Wywrota->trace("Application : _new_instance");


	# --- load dictionaries
	$self->{dict} = Wywrota::Dictionary->instance();
	Wywrota->trace("Application : dictionaries loaded");

	# --- load config content
	my ($byId, $byName) = $self->readContentConfig();
	$self->{cc} = $byId;
	$self->{ccByName} = $byName;
	Wywrota->trace("Application : readContentConfig done");

	# --- load pages
	$self->{page} = $self->readPages();
	Wywrota->trace("Application : pages loaded");


	# --- load user groups
	$self->{userGroup} = $self->readUserGroups();
	Wywrota->trace("Application : user groups loaded");

	
	# ...

	#Wywrota->trace("Application initialised");


	return $self;
}


sub readContentConfig {
# --------------------------------------------------------
	my $self = shift;
	my ($id, $package, $byName, $VAR1, $key);
	my $xml = new XML::Simple;
	my $data = $xml->XMLin($config{'config_dir'}."/contentConfig.xml");

	_utf8_off($data);

	foreach $id (keys %{$data->{item}}) {

		$data->{item}{$id}{cid} = $id;
		$data->{item}{$id}{id} = $id;
		$package = $data->{item}{$id}{'package'};

		eval "use Wywrota::Object::$package";
		Wywrota->error("Wywrota : Error including $package ".$@) if ($@);
		$data->{item}{$id}{cfg} = eval "\$Wywrota::Object::".$package."::cc";
		Wywrota->error("Wywrota : Error including $package ".$@) if ($@);

		$byName->{ $data->{item}{$id}{'package'} } = $data->{item}{$id};
	}

	Wywrota->trace("Application : readContentConfig - finished");

	return ($data->{item}, $byName);

}


sub readPages {
# --------------------------------------------------------
	my $self = shift;
	my ($page, $pageStruct);

	my $query = "SELECT * FROM page WHERE _active=1"; #lang=$Wywrota::session->{language}{id} AND 
	my $pages = Wywrota->db->buildHashRefArrayRef($query); 

	foreach $page (@$pages) {
		$pageStruct->{$page->{id}}=$page;
	}

	return $pageStruct;
}

sub readUserGroups {
# --------------------------------------------------------
	my $self = shift;
	my ($ugroup, $ugroupStruct);

	my $query = "SELECT * FROM ugroup WHERE _active=1"; 
	my $ugroups = Wywrota->db->buildHashRefArrayRef($query); 

	foreach $ugroup (@$ugroups) {
		$ugroupStruct->{$ugroup->{id}}=$ugroup;
	}

	return $ugroupStruct;
}


sub cc : lvalue { 
# --------------------------------------------------------
	my $self = shift;
	my $cid = shift;
	
	if ($cid =~ /^\d+$/) {
		return $self->{cc}{$cid};
		
	} elsif (defined $cid) {
	
		Wywrota->error("ContentConfig : unknown content :", $cid) unless (defined $self->{ccByName}{$cid});
		return $self->{ccByName}{$cid};
		
	} else {
		#Wywrota->warn("ContentConfig : unknown content :", $cid);
		
		return $self->{cc};
	}
	
}  

1;