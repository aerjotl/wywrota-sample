package Wywrota::Engine::ContentEngine;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Class::Singleton';

use Time::Local;
use HTTP::Date;
use Data::Dumper;
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Wywrota::Forms;
use Wywrota::Engine::ContentListingEngine;
use Wywrota::Log;
use Wywrota::DAO::ContentDAO;
use Wywrota::View::ContentView;
use Wywrota::Object::Manager::BaseManager;

sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;
	my $app = shift;
	my ($id, $contentInfo);

	$self->{dao} =		Wywrota::DAO::ContentDAO->instance();
	$self->{listDao} =  Wywrota::DAO::ContentListingDAO->instance();
	
	foreach $id (keys %{$app->{cc}}) {
		$contentInfo = $app->{cc}{$id};
		eval "use Wywrota::Object::$contentInfo->{package};";
		eval "use Wywrota::Object::Manager::$contentInfo->{package}Manager;";
		$self->{mng}{$id} = eval "Wywrota::Object::Manager::$contentInfo->{package}Manager->instance(\$contentInfo)";
		$self->{mng}{ $contentInfo->{'package'} } = $self->{mng}{$id};
		Wywrota->error("ContentManager : Error initialising $contentInfo->{package}Manager ".$@) if ($@);
	}

	return $self;

}


sub mng { 
# --------------------------------------------------------
	my $self = shift;
	my $cid = shift || $Wywrota::request->{content}{current}{id};

	if (defined $self->{mng}->{ $cid }) {
		return $self->{mng}->{ $cid };

	} else {
		Wywrota->error("Shit manager: [$cid]");
		return $self->{mng}->{1};
	}
}




sub action {
# --------------------------------------------------------
	my $output;
	my $self = shift;
	eval {
	$output = $self->mng->action(@_); 
	};
	$output = Wywrota->error($@) if ($@);
	return $output;
}


sub createObject {
# --------------------------------------------------------

	my $self = shift;
	my $rec = shift;
	my $objectClass = shift || $Wywrota::request->{content}{current}{'package'};
	
	Wywrota->error("Error creating object - no objectClass defined.") if (!length($objectClass));
	my $object = eval "Wywrota::Object::".$objectClass.'->new($rec, @_)';
	Wywrota->error("Error creating object class: $objectClass<br>".$@) if ($@);

	return $object;
}


sub createDefaultObject {
# --------------------------------------------------------
# Creates an object with default fields pre-filled
# and then fills it with $rec data that was passed

	my $self = shift;
	my $rec = shift;
	my $objectClass = shift || $Wywrota::request->{content}{current}{'package'};

	Wywrota->error("Error creating default object - no objectClass defined.") if (!length($objectClass));
	my $object = eval "Wywrota::Object::".$objectClass.'->new()';
	$object->getDefaults();
	foreach (keys %{$rec}) {$object->rec->{$_} = $rec->{$_} };
	Wywrota->error($@) if ($@);

	return $object;
}


sub persist { 
# --------------------------------------------------------
	my $self=shift;
	my $obj = shift;
	my $skipFileUpload = shift;

	if ($obj->id) {
		return $self->modifyObject($obj, $skipFileUpload);	
	} else {
		return $self->addObject($obj, $skipFileUpload); 	
	}
}



sub addObject {
# --------------------------------------------------------

	my $self = shift;
	my $object = shift;
	my $skipFileUpload = shift;
	my ($status);

	Wywrota->debug("CONTENTENGINE : ADDOBJECT ", $object);

	eval {
		
		$status = $object->validate("add");
		Wywrota->debug("addObject validated");
		
		if ($status eq "ok") {
			
			unless ($skipFileUpload) {
				$status = Wywrota->file->uploadFormFiles($object);
			};

			if ($status eq "ok") {
			
				if ($self->dao->addObject($object) ) {
					Wywrota->trace("ContentManager onObjectAdd - added object");
				} else {
					Wywrota->warn("ContentManager onObjectAdd - not added!", $object);
					$status = msg('sql_error');
					return;	# returns the eval
				}
				
				# perform other custom actions after adding
				$self->mng($object->cid)->onObjectAdd($object);
				Wywrota->trace("ContentManager onObjectAdd -ed");

				# get object after all the changes
				$object = $self->getObject($object->id, $object->getClass);

				# log successfull action
				Wywrota::Log::log($object->cid, $object->id, 2);
			
			} else {
				push(@{$object->{errors}}, "<b>plik</b> - $status");
				
			}
		} else {
			Wywrota->warn("ContentEngine : addObject, validation status: '$status' !");
		}
		
	};
	Wywrota->error("ContentEngine : addObject", $@) if ($@);


	return ($status, $object);
}



sub modifyObject {
# --------------------------------------------------------

	my $self = shift;
	my $object = shift;
	my $skipFileUpload = shift;
	my ($status);

	Wywrota->debug("CONTENTENGINE : modifyObject", $object);
	
	eval {

		$status = $object->validate("mod");
		Wywrota->debug("modifyObject validated");

		if ($status eq "ok") {


			# upload site_images
			unless ($skipFileUpload) {
				$status = Wywrota->file->uploadFormFiles($object);
			};

			if ($status eq "ok") {

				if ($self->dao->modifyObject($object)) {
					Wywrota->trace("ContentManager modifyObject - modified object");
				} else {
					Wywrota->warn("ContentManager modifyObject - not modified!", $object);
					$status = msg('sql_error');
					return; #returns the eval
				};

				# perform other custom actions after modifying
				$self->mng($object->cid)->onObjectEdit($object);

				# get object after all the changes
				$object = $self->getObject($object->id, $object->getClass);

				# log successfull action
				Wywrota::Log::log($object->cid, $object->id, 3);

			} else {
				push(@{$object->{errors}}, "<b>plik</b> - $status");
				
			}


			return ('ok', $object);
		}
	};

	Wywrota->error("ContentEngine : addObject", $@) if ($@);
	return ($status, $object);

}


sub deleteObject {
# --------------------------------------------------------

	my $self = shift;
	my $id = shift;
	my $cid = shift || $Wywrota::request->{content}{current}{id};

	Wywrota->debug("($id, $cid);");

	return Wywrota->contentView->deleteFailure("no records specified.") if (!$id);

	$self->dao->deleteObject($id, $cid);

	Wywrota->content->mng($cid)->onObjectDelete($id);
	Wywrota->contentView->deleteSuccess($id);

}	


sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my ($output, $object);

	if ((int($Wywrota::in->{view}) && $Wywrota::in->{view} ne 'on') || $Wywrota::in->{print} || $Wywrota::in->{id}) {
		$object = $self->getObject( $Wywrota::in->{view} || $Wywrota::in->{print} || $Wywrota::in->{id} );
	} else {
		my $queryRes = Wywrota->cListEngine->query($Wywrota::in);
		if ($queryRes->status eq "ok") {
			$object = $self->createObject(@{$queryRes->hits}[0]);
		}
	}

	if ($object) {
		$output = Wywrota->contentView->htmlPage($nut, $object);
		$output = Wywrota->error($@) if ($@);
	} else {
		$output = $self->recordNotFound($nut);
	}


	return $output;
}

sub recordNotFound {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $searchString;
	
	my $object = $self->getObject( $Wywrota::in->{view} || $Wywrota::in->{id}, undef, undef, 1 );
	
	if ($object && $object->rec->{tytul}) {
		$searchString = $object->rec->{tytul};
	} else {
		$searchString = $ENV{REDIRECT_URL};
		$searchString =~ s/.*\/\d*//g;
		$searchString =~ s/\.htm.?$//g;
		$searchString =~ s/[_-]/ /g;
	};
	
	#my $suggest = Wywrota->searchEngine->quickSearch($searchString);
	
	Wywrota->errorPage(msg('record_not_found'));
}


sub includeFile {
# --------------------------------------------------------
	my $self = shift;
	my $file = shift;

	my $output;

	Wywrota->trace("includeFile $file");

	if ($Wywrota::request->{urlPrefix} and -e $config{'template_dir'}."/page/$Wywrota::request->{urlPrefix}/$file") {
		$file = "page/$Wywrota::request->{urlPrefix}/$file";
	} elsif (-e $config{'template_dir'}."/page/$file") {
		$file = "page/$file";
	} elsif (-e $config{'template_dir'}."/$file") {
		$file = $file;
	} else {
		Wywrota->error("Could not find template $file");
	}

	
	# get file and process Template 
	$output = Wywrota->t->process($file, {});
	

	return Wywrota->contentView->wrapHeaderFooter({
		nobillboard=>  $Wywrota::in->{'nobillboard'} || $Wywrota::request->{content}{current}{page}->{nobillboard},
		nomenu=>  $Wywrota::in->{'nomenu'} || $Wywrota::request->{content}{current}{page}->{nomenu},
		output  => $output
	});
}



sub quickModerate {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $state = shift;
	my $recommend = shift;
	my ($rec, $table);

	if ( $object && $object->rec && Wywrota->per('admin', $object->cid) ) {

		$rec = $object->rec;
		$table = $object->config->{tablename};
		Wywrota->db->execWriteQuery("UPDATE $table SET stan = ? WHERE id = ?", $state, $rec->{id});

		if (defined($recommend)) {
			Wywrota->db->execWriteQuery("UPDATE $table SET recommend = ? WHERE id = ?", $recommend, $rec->{id});
		}

		if (defined($rec->{'data_publikacji'})) {
			Wywrota->db->execWriteQuery("UPDATE $table SET data_publikacji = ? WHERE id = ?", Wywrota::Utils::getDate(), $rec->{id});
		}

		Wywrota::Log::log( $object->cid, $rec->{id}, 7);
		Wywrota::Notification::notifyOnAuthorize( $rec->{user_id}, "1", $state, $rec);

		return msg("moderate_state_$state");

	} 
}


sub quickDistinction {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $state = shift;
	my ($rec, $table);

	if ( $object && $object->rec && Wywrota->per('admin', $object->cid) ) {

		$rec = $object->rec;
		$table = $object->config->{tablename};
		Wywrota->db->execWriteQuery("UPDATE $table SET wyroznienie = $state WHERE id = $rec->{id}");

		Wywrota::Log::log( $object->cid, $rec->{id}, (20+$state) );
		Wywrota::Notification::notifyOnDistinction( $object, $state);

		return msg("distinction_confirm_$state");

	} 
}




sub getCountForUser {
# --------------------------------------------------------
# for user_id returns a structure with the amount of element for each content

	my $self = shift;
	my $user_id = shift;
	my $idList = shift;
	my ($struct, $cnt, $table);
	
	my @ids = (defined $idList) ? @{$idList} : keys %{ Wywrota->app->{cc} };

	return unless ($user_id);

	foreach (@ids) {
		$table = Wywrota->cc->{$_}{tablename};

		next if (!$table ||	!Wywrota->cc->{$_}{cfg}{'user_id'} );

		($cnt) = Wywrota->db->quickArray(qq~
			SELECT count(id) FROM $table
			WHERE user_id=$user_id AND _active=1
		~);
		$struct->{ $_ } = $cnt;
	}

	return $struct;
}



sub getObject { shift->{dao}->getObject(@_) }
sub dao		{ shift->{dao} }
sub listDao { shift->{listDao} }
sub view	{ shift->{view} }

1;