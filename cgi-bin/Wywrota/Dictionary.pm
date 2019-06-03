package Wywrota::Dictionary;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota;
use Wywrota::Config;

use Class::Singleton;
use base 'Class::Singleton';

sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $dict = readDictionaries();
	my $self  = bless { _dict=>$dict }, $class;


	return $self;
}




sub readDictionaries {
# --------------------------------------------------------
	my $self = shift;
	my ($dict, $dictStruct);


	my $query = "SELECT * FROM dict_entry"; 
	my $dicts = Wywrota->db->buildHashRefArrayRef($query); 

	Wywrota->error("Empty dict_entry table !!! ") if ($#$dicts <0);

	foreach $dict (@$dicts) {
		$dictStruct->{$dict->{'package'}}{$dict->{key}}{$dict->{value}}{label}=$dict->{label};
		$dictStruct->{$dict->{'package'}}{$dict->{key}}{$dict->{value}}{page_id}=$dict->{page_id};
		$dictStruct->{$dict->{'package'}}{$dict->{key}}{$dict->{value}}{active}=$dict->{active};
	}

	return $dictStruct;
}


sub getLabel {
# --------------------------------------------------------
	my $self = shift;
	my $field = shift;
	my $value = shift;
	my $package = shift || $Wywrota::request->{content}{current}{package};

	return eval{ $self->getRefForLabel($package, $field)->{$value}{label} };
	
}

sub getPageId {
# --------------------------------------------------------
	my $self = shift;
	my $field = shift;
	my $value = shift;
	my $package = shift || $Wywrota::request->{content}{current}{package};
	
	return eval{ $self->dict->{$package}{$field}{$value}{page_id} };
	
}


sub getRefForLabel {
# --------------------------------------------------------
	my $self = shift;
	my $package = shift;
	my $field = shift;
	my ($dic_context, $dic_label, $dictRef);

	($dic_context, $dic_label) = split(/:/, Wywrota->app->{ccByName}{$package}{dict}{field}{$field}{dict});

	if ($dic_label) {
		$dictRef = $self->dict->{$dic_context}{$dic_label};
	} elsif ($dic_context) {
		$dictRef = $self->dict->{$package}{$dic_context};
	} else {
		$dictRef = $self->dict->{$package}{$field};
	}

	return $dictRef;

}




sub dict { 
	my $self = shift;
	$self->{_dict} = $self->readDictionaries() if (!$self->{_dict});
	return $self->{_dict}; 
}



1;