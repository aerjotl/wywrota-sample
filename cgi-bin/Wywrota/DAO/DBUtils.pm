package Wywrota::DAO::DBUtils;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2010 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# This package is a wrapper over GeneralDBUtils, which adds 
# Wywrota-specific functionality for config and logging 
#
#-----------------------------------------------------------------------


use strict;
use base 'Wywrota::DAO::GeneralDBUtils';

use DBI;
use Data::Dumper;
use Tie::IxHash;
use Wywrota;
use Wywrota::Log;
use Wywrota::Config;



sub execQuery {
# ---------------------------------------------------
	my $self=shift;
    my $query = shift;

	Wywrota->trace("execQuery -  executing $query");
	if ($config{'log_sql'}) {
		logFile("sql",$query, @_);
	}
	$self->SUPER::execQuery($query, @_);
}


sub tempDBH {
# ---------------------------------------------------
	my $self=shift;
	
	$self->{tempDBH} = $self->makeConnection(
		$config{db}{database_temp}, 
		$config{db}{host}, 
		$config{db}{login}, 
		$config{db}{pass}
	) unless ($self->{tempDBH});
	return $self->{tempDBH};
}

sub connectDB {
# ---------------------------------------------------
	my $self=shift;
	return $self->SUPER::connectDB(	$config{db} );	
}


sub dbException {	
# ---------------------------------------------------
	my $self=shift;
	Wywrota->dbException(@_);
}



1;
