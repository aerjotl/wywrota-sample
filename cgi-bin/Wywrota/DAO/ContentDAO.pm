package Wywrota::DAO::ContentDAO;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# Data Access Object for CRUD operations on objects
#
#-----------------------------------------------------------------------


use Class::Singleton;
use base 'Class::Singleton';

use strict;
use Exporter; 
use DBI;
use Wywrota;
use Wywrota::Log;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Wywrota::Utils;
use Wywrota::DAO::ContentListingDAO;
use POSIX qw(ceil floor);


sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;

	#$self->{cListEngineDAO} = Wywrota::DAO::ContentListingDAO->instance();
	#$self->{view} = Wywrota->contentView;	

	return $self;
}



sub getObject {
# --------------------------------------------------------
# Given an ID as input, getObject returns a hash of the 
# requested record or undefined if not found.

	my $self = shift;
	my $id = shift;
	my $objectClass = shift || $Wywrota::request->{content}{current}{'package'};
	my $condition = shift;
	my $getDeleted = shift;
	my ($rec, $query, $query_from, $fields, $object, $cond, $count, $contentDef );

	if (int($objectClass)) {
		$contentDef = Wywrota->app->{cc}{$objectClass};
		$objectClass = $contentDef->{package};
	} else {
		$contentDef = Wywrota->app->{ccByName}{$objectClass};
	}

	if (!length($id) && !$condition) {
		Wywrota->error("ContentDAO : getObject - no parameters passed") ;
		return;
	}
	Wywrota->trace("in ContentDAO in getObject ($id, $objectClass $condition)");  

	$object = eval "Wywrota::Object::$objectClass".'->new()';
	Wywrota->error("ContentDAO : Error getting object " . $@) if ($@);

	#return undef if (!$id);


	if ($id eq "random") {
		# execute the main query
		$condition = "rec._active=1" if (!$condition);

		srand;
		$count = Wywrota->db->selectCount($contentDef->{tablename}, $condition);
		return undef if (!$count);
		$count = int (rand($count-1));
		$query = Wywrota->cListEngine->buildFullQuery($contentDef, undef, $condition, "one") . " LIMIT $count,1";
		$rec = Wywrota->db->quickHashRef($query);


	} elsif ($id eq "on") {
		my $queryRes = Wywrota->cListEngine->query($Wywrota::in, "view", $contentDef);
		$rec = $queryRes->{hits}[0];

	} else {
		$cond = " rec.id=".Wywrota->db->quote($id)." " if (int($id) || $id eq '0');
		$cond .= ' AND ' if (int($id) && $condition);
		$query = Wywrota->cListEngine->buildFullQuery($contentDef, undef, "$cond $condition", "one", undef, $getDeleted) ;
		$rec = Wywrota->db->quickHashRef($query);
	}
	
	#Wywrota->debug($rec);  

	if (defined($rec->{id})) {
		$object->{rec} = $rec;
		return $object;

	} else {
		Wywrota->warn("can not get object <b>$objectClass $id</b> ") if ($id); #\n $query
		return undef;
	}

}


sub addObject {
# --------------------------------------------------------

	my $self = shift;
	my $object = shift;
	my ($rec, $query, $keys, $values, $origField);
	my $autoinc = $object->cc->{id}[1] eq 'auto';

	eval {
	
		$rec =  $object->rec;
		
		if (!$autoinc) {
			$rec->{id} = Wywrota->db->selectMax($object->config->{tablename}, undef, 'id')+1;
		}
		

		foreach (keys %{$object->cc}) {
		
			next if ($autoinc and $_ eq 'id');

			$keys .= $_.",";

			if (/^.*_urlized/) {
				$origField = $_;
				$origField =~ s/_urlized//g;
				$rec->{$_} = simpleAscii(trim($rec->{$origField}));
				$values .= Wywrota->db->quote( trim($rec->{$_}) ).",";
			} elsif (not length($rec->{$_})) { #$Wywrota::request->{content}{current}{$_}[1] eq 'date' and 
				$values .= "NULL,";
			} else {
				$values .= Wywrota->db->quote(trim($rec->{$_})).",";
			}
		}
		chop($keys);
		chop($values);

		$query = "INSERT INTO " .$object->config->{tablename}. " ($keys) VALUES ($values)";
		Wywrota->db->execWriteQuery($query) or return undef; 

		if ($autoinc) {
			($rec->{id}) = Wywrota->db->quickArray("SELECT LAST_INSERT_ID();"); 
		}

	};
	
	Wywrota->error("ContentDAO : addObject", $@) if ($@);

	return 1;
}


sub modifyObject {
# --------------------------------------------------------

	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($found, $values, $oldState, $origField, $key);
	

	foreach $key (keys %{ $object->cc }) {

		# skip fields that were not changed and that are not checkboxes
		next if (!defined($rec->{$key}) && $object->cc->{$key}[1] ne 'checkbox'); 

		if ($key =~ /^.*_urlized/) {
			$origField = $key;
			$origField =~ s/_urlized//g;
			$rec->{$key} = simpleAscii(trim($rec->{$origField}));
			$values .= $key."=".Wywrota->db->quote( trim($rec->{$key}) ).",";
		} elsif (not length($rec->{$key})) {
			$values .= $key."=NULL,";
		} else {
			$values .= $key."=".Wywrota->db->quote( trim($rec->{$key}) ).",";
		}
	}
	chop($values);


	Wywrota->db->execWriteQuery( "UPDATE ".$object->config->{tablename}." SET $values WHERE id=".Wywrota->db->quote($rec->{'id'}) ) or return undef; 


	if (defined $rec->{'stan'}) {
		$oldState = Wywrota->db->quickOne("SELECT stan FROM ".$object->config->{tablename}." WHERE id=".$rec->{'id'});
		Wywrota::Notification::notifyOnAuthorize($rec->{'user_id'}, $oldState, $rec->{'stan'}, $rec);
	}


	return 1;	
}



sub deleteObject {
# --------------------------------------------------------

	my $self = shift;
	my $id = shift;
	my $cid = shift || $Wywrota::request->{content}{current}{id};

	Wywrota->db->execWriteQuery("UPDATE ". Wywrota->cc->{$cid}{tablename} ." SET _active=0 WHERE id=$id") or return 1;

	Wywrota::Log::log($cid, $id, 4);

}	

1;