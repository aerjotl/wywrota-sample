package Wywrota::DAO::GeneralDBUtils;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2010 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# This package provides handy methods for fetching/storing data 
# from/to MySQL database.
#
# Usage:
#
#	$sth 	= Wywrota->db->execQuery( $sql )
#	$ok 	= Wywrota->db->execWriteQuery( $sql )
#	$ok		= Wywrota->db->execWriteQueries( $sql )
#		
#	$count = Wywrota->db->selectCount('teksty', 'stan=1');
#			selectSum
#			selectMax
#
#
#   returns one value
#	$val	= Wywrota->db->quickOne( $sql )
#
#   returns first row as a hash - good for taking one row from the table
#	%hash	= Wywrota->db->quickHash( $sql )				
#	$x		= Wywrota->db->quickHashRef( $sql )				
#
#   returns first row as an array
#	@array	= Wywrota->db->quickArray( $sql )
#
#   build hash basing on 2 columns
#	%hash	= Wywrota->db->buildHash( "SELECT id, nazwa FROM ugroup" )
#	$x		= Wywrota->db->buildHashRef( $sql )				
#
#   builds array from values of single column query
#	@array	= Wywrota->db->buildArray( "SELECT id FROM premium_account" )
#	$x		= Wywrota->db->buildArrayRef( $sql )
#
#	builds array of hash references (for example object records)
#	$x		= Wywrota->db->buildHashRefArrayRef( $sql )
#	@array	= Wywrota->db->buildHashRefArray( $sql )
#   
#-----------------------------------------------------------------------





use strict;
use Class::Singleton;
use base 'Class::Singleton';

use DBI;
use Tie::IxHash;
use POSIX qw(ceil floor);
use Data::Structure::Util qw(utf8_off);



sub connectDB {
# ---------------------------------------------------
#	db->connectDB({
#		host		=> '',
#		database	=> '',
#		login		=> '',
#		pass		=> ''
#	});
	
	my $self=shift;
	my $dbconfig = shift;
	$self->{conf} = $dbconfig if ($dbconfig);
	$dbconfig = $self->{conf} unless ($dbconfig);
	
	$self->{dbh} = $self->makeConnection(
		$dbconfig->{database}, 
		$dbconfig->{host}, 
		$dbconfig->{login}, 
		$dbconfig->{pass}
	) unless ($self->{dbh});
	
	$self->dbException("Error conecting to database") if (!$self->{dbh});
	return $self->{dbh};
}


sub makeConnection {
# ---------------------------------------------------
	my $self=shift;
	my ($database, $host, $login, $passwd) = @_;
	my $handler;

	if ($passwd eq "_") {
	$handler = DBI->connect("DBI:mysql:database=$database;host=$host", $login)
		or $self->dbException("Database connection not made ($database at $host, using login: $login", $DBI::errstr);

	} else {
	$handler = DBI->connect("DBI:mysql:database=$database;host=$host",$login, $passwd)
		or $self->dbException("Database connection not made ($database at $host, using login: $login", $DBI::errstr);
	}

	$handler->do("SET character set utf8");
	return $handler;
}


sub disconnectDB {
# ---------------------------------------------------
	my $self=shift;
	$self->{dbh}->disconnect();
}


sub execQuery {
# ---------------------------------------------------
	my $self=shift;
    my $query = utf8_off(shift);
	my $handle = shift;
	my @binds = @_;
    my ($sth, $i, $tmpbind);
    my $params_str = '';
	$query =~ s/\\r//g;

	# no db-handle passed
	
	if (not defined $handle) {
		$handle = $self->connectDB();
		
	} elsif (defined $handle and ref $handle ne 'DBI::db') {
		unshift (@binds, $handle);
		$handle = $self->connectDB();
		
	} else {
		Wywrota->trace("passed handle for query:",  $query );
	}

	
	$sth = $handle->prepare($query) or $self->dbException("PREPARE: $DBI::errstr. \nSQL: $query");

	for ($i=0; $i<=$#binds; $i++) {
		$tmpbind = ($binds[$i] eq '0') ? ('0') : utf8_off($binds[$i]);
		$sth->bind_param($i+1, $tmpbind);
		$params_str .= $tmpbind . " ,";
	}

	if (!$sth->execute()) {
		$self->dbException("execQuery - error executing","$DBI::errstr. \n$query [$params_str]");
		return undef;
	}
	

    return $sth;
}



sub execWriteQuery {
# ---------------------------------------------------
	my $self=shift;
	my ($sth, $rows);
	$sth = $self->execQuery(@_);

	if ($sth) {
		$rows = $sth->rows;
		$sth->finish; 
		return $rows;
	} else {
		return undef;
	}
}


sub execWriteQueries {
# ---------------------------------------------------
	my $self=shift;
	my $sth;
	foreach ( split(/;/, shift) ) {
		next if (/^\s*$/);
		$sth = $self->execQuery($_, @_);
		if ($sth) {
			$sth->finish; 
		} else {
			return undef;
		}
	}
}


sub selectMax{
# ---------------------------------------------------
	my $self=shift;
    my $table_name = shift;
    my $condition = shift;
    my $field = shift;

	if (!$table_name) {
		$self->dbException("selectMax :: no table_name defined");
		return;
	}

	$condition = ' WHERE '.$condition if $condition;
	return $self->quickOne("SELECT MAX($field) FROM $table_name rec $condition"); 
}


sub selectCount{
# ---------------------------------------------------
# example:
# $count = Wywrota->db->selectCount('teksty', 'stan=1 AND _active=1');

	my $self=shift;
    my $table_name = shift;
    my $condition = shift;

	if (!$table_name) {
		$self->dbException("selectCount :: no table_name defined");
		return;
	}

	$condition = ' WHERE '.$condition if $condition;
	return $self->quickOne("SELECT COUNT(*) FROM $table_name rec $condition"); 
}


sub selectSum{
# ---------------------------------------------------
	my $self=shift;
    my $table_name = shift;
    my $condition = shift;
    my $field = shift;

	if (!$table_name) {
		$self->dbException("selectSum :: no table_name defined");
		return;
	}

	$condition = ' WHERE '.$condition if $condition;
	return $self->quickOne("SELECT SUM($field) FROM $table_name rec $condition"); 
}


sub quote {
# ---------------------------------------------------
	my $self=shift;
	my $value = $_[0]; 
	$self->connectDB();
	return $self->{dbh}->quote($value);
}

sub quickOne {
# --------------------------------------------------------
	my $self=shift;
	my @data = $self->quickArray(@_);
	if (scalar @data > 0) {
		return $data[0];
	} else {
		return undef;
	}
}

sub quickArray {
# --------------------------------------------------------
	my $self=shift;
	my ($sth, @data);
	$sth = $self->execQuery(@_);
	@data = $sth->fetchrow_array();
	$sth->finish;
	return @data;
}


sub quickHash {
# --------------------------------------------------------
	my $self=shift;
	my ($sth, $data);
	$sth = $self->execQuery(@_);
	$data = $sth->fetchrow_hashref();
	$sth->finish;
	if (defined $data) {
        	return %{$data};
	} else {
		return ();
	}
}

sub quickHashRef {
# --------------------------------------------------------
	my $self=shift;
	my ($sth, $data);
	$sth = $self->execQuery(@_);
	$data = $sth->fetchrow_hashref();
	$sth->finish;
	if (defined $data) {
		return $data;
	} else {
		return {};
	}
}


sub buildArray {
# --------------------------------------------------------
	my $self=shift;
	my ($sth, $data, @array, $i);
	$sth = $self->execQuery(@_);
	$i=0;
	while (($data) = $sth->fetchrow_array()) {
		$array[$i] = $data;
	$i++;
	}
	$sth->finish;
	return @array;
}



sub buildArrayRef {
# --------------------------------------------------------
	my $self=shift;
	my @array = $self->buildArray(@_);
	return \@array;
}

sub buildHashRefArray {
# --------------------------------------------------------
	my $self=shift;
	my ($sth, $data, @array);
	$sth = $self->execQuery(@_);
	return undef if (!$sth);
	while ($data = $sth->fetchrow_hashref()) {
		push (@array, $data);
	}
	$sth->finish;
	return @array;
}


sub buildHashRefArrayRef {
# --------------------------------------------------------
	my $self=shift;
	my @array = $self->buildHashRefArray(@_);
	return \@array;
}


sub buildHash {
# --------------------------------------------------------
	my $self=shift;
	my ($sth, %hash, @data, $value, $key);
	tie %hash, "Tie::IxHash";
	$sth = $self->execQuery(@_);
	return undef if (!$sth);
	while (@data = $sth->fetchrow_array()) {
		$value = pop @data;
		$key = join("_",@data);	
			$hash{$key} = $value;
	}
	$sth->finish;
	return %hash;
}


sub buildHashRef {
# --------------------------------------------------------
	my $self=shift;
	my ($sth, %hash);
	tie %hash, "Tie::IxHash";
	%hash = $self->buildHash(@_);
	return \%hash;
}

sub writeQuery {
# --------------------------------------------------------
	my $self=shift;
	my $sth = $self->execQuery(@_); 
	$sth->finish;
}


sub dbException {	
# ---------------------------------------------------
	print @_;
}


1;
