package Wywrota::Nut::Security;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Wywrota::Config;

sub new {
# --------------------------------------------------------
	my $class = shift;
	my $nut = shift;
	bless {_nut=>$nut}, $class;
}

sub DESTROY {
# --------------------------------------------------------
	my $self = shift;
	undef $self;
}

sub nut {
# --------------------------------------------------------
	my $self = shift;
	return $self->{_nut};
}

sub per {
# --------------------------------------------------------
	my $self = shift;
	my $perName = shift;
	my $contentId = shift || $Wywrota::request->{content}{current}{id};
	
	
	#Wywrota->trace("PER", $perName, $contentId, $Wywrota::session->{user}{per}{$contentId}{$perName});
	#Wywrota->debug("PER", $perName, $contentId, $Wywrota::session->{user}{per}{$contentId}{$perName}, $Wywrota::session->{user}{per});
	return 0 if ($Wywrota::session->{'googlebot'} && ($perName eq 'admin'));
	
	return $Wywrota::session->{user}{per}{$contentId}{$perName};
}

sub perRecord {
# --------------------------------------------------------
# Usage:
#  Wywrota->perRecord($object);
#
#  $rec: closed, user_id

	my $self = shift;
	my $object = shift;
	my $method = shift;

	return 0 if (!$object);
	return 0 if (!int($Wywrota::session->{user}{id}));

	# this is for closed societies in forum
	if ( $object->getClass eq 'ForumGroup') {
			if ($object->{rec}{val}{closed} && !Wywrota->fav->isInFavorites($object->id, $object->cid) ) {
				return 0; 
			} else {
				return 1; 
			}
	};

	# author is allowed to edit/delete his own stuff
	return 1 if ($object->{rec}{val}{user_id} == $Wywrota::session->{user}{id});

	# WIP: users can edit comments on their own texts
	if ( $object->getClass eq 'Comment' and $method eq 'del') {
		return 1 if ($Wywrota::request->{commentedObject}{rec}{user_id} == $Wywrota::session->{user}{id});	
	}

	return 0;

}

sub isInGroup {
# --------------------------------------------------------
	my $self = shift;
	my $gid = shift;
	return  $Wywrota::session->{user}{groups}{$gid};
}

1;