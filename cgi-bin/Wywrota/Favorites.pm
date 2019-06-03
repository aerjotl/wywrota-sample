package Wywrota::Favorites;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Data::Dumper;

use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Language;

use Class::Singleton;
use base 'Class::Singleton';


sub action {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $in = $nut->in;
	my $output;
	my $action = $in->{favorites};
	my $msg = "Zaloguj się, aby mieć możliwość edycji ulubionych.";
	

	if    ($action eq 'add')   { 
		return Wywrota::User::unauthorized($msg) if (!$Wywrota::session->{user}{id});
		$output = $self->addHtml($in->{id}, $in->{set}, $Wywrota::request->{content}{current}{id}, $Wywrota::session->{user}{id} ); 
	} 
	elsif ($action eq 'remove') { 
		return Wywrota::User::unauthorized($msg) if (!$Wywrota::session->{user}{id});
		$output = $self->removeHtml($in->{id}, $in->{set}, $Wywrota::request->{content}{current}{id}, $Wywrota::session->{user}{id} ); 
	} 
	elsif ($action eq 'list') { 
		return if (!$Wywrota::session->{user}{id} && $in->{generate});
		return Wywrota::User::unauthorized($msg) if (!$Wywrota::session->{user}{id} and !$in->{user_id});
		$output = $self->list($in);
	}
	elsif ($action eq 'fulllist') { 
		return if (!$Wywrota::session->{user}{id});
		$output = $self->fulllist($in);
	}
	elsif ($action eq 'users') { 
		return Wywrota->error("Brak wymaganych parametrów w adresie") if (!$in->{id});
		$output = $self->listUsersForItemHtml($in->{id}, $in->{cid}, $in->{set});
	}
	else { 
		return Wywrota->unknownAction($action);
	}

	
	return $output;
}


sub getCountForUser {
# --------------------------------------------------------
# counts the number of favorites per content for a user

	my $self = shift;
	my $user_id = shift;
	return if (!$user_id);

	my $struct = Wywrota->db->buildHashRef(qq~
		SELECT content_id, count(content_id) FROM favorites 
		WHERE user_id=$user_id GROUP BY content_id
	~);

	return $struct;
}


sub isInFavorites {
# --------------------------------------------------------
# checks if a record is in user's favorites

	my $self = shift;
	my $id = shift;
	my $content_id=shift || $Wywrota::request->{content}{current}{id};
	my $set_id = shift || 0;
	my $user_id=shift || $Wywrota::session->{user}{id};

	return 0 if (!$id || !$content_id || !$user_id);

	return Wywrota->db->quickOne(qq|
		SELECT record_id 
		FROM favorites 
		WHERE user_id=$user_id 
		AND record_id=$id 
		AND content_id=$content_id 
		AND set_id=$set_id
	|);

}

sub add {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = int(shift);
	my $set_id = int(shift);
	my $cid = int(shift || $Wywrota::request->{content}{current}{id});
	my $user_id= int(shift || $Wywrota::session->{user}{id});

	return msg('action_require_logged_in_msg') if (!$user_id);
	return 1 if (!$id || !$cid);

	if (!$self->isInFavorites($id, $cid, $set_id, $user_id)) {
		# add record to the table
		Wywrota->db->execWriteQuery(qq~
			INSERT INTO favorites (user_id, record_id, content_id, set_id)
			VALUES ($user_id, $id, $cid, $set_id)
		~);

		# update favorite count
		$self->_updateCnt($id, $set_id, $cid, $user_id);

		Wywrota->content->mng($cid)->onAddToFavorites($id, $cid, $set_id);
		return 0;
	} else {
		return 1;
	};

}



sub _updateCnt {
# --------------------------------------------------------
	my $self = shift;
	my $id = shift;
	my $set_id = int(shift);
	my $cid = int(shift || $Wywrota::request->{content}{current}{id});
	my $user_id= int(shift || $Wywrota::session->{user}{id});

	if ($set_id==0 and defined Wywrota->cc->{$cid}{cfg}{_fav_cnt}) {
		Wywrota->db->execWriteQuery(qq~
			UPDATE ~ . Wywrota->cc->{$cid}{'tablename'} . qq~ SET _fav_cnt = 
			(SELECT COUNT(*) FROM favorites WHERE 
			record_id=$id AND content_id=$cid AND set_id=0)
			WHERE id=$id
		~);	
	}

	if ($set_id>0) {
		Wywrota->db->execWriteQuery(qq~
			UPDATE record_set SET _record_cnt = 
			(SELECT COUNT(*) FROM favorites WHERE 
			content_id=$cid AND set_id=$set_id)
			WHERE id=$set_id
		~);	
	}
}



sub remove {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = shift;
	my $set_id = shift || 0;
	my $cid = shift || $Wywrota::request->{content}{current}{id};
	my $user_id=shift || $Wywrota::session->{user}{id};

	return msg('action_require_logged_in_msg') if (!$user_id);
	return 1 if (!$id || !$cid);

	Wywrota->db->execWriteQuery(qq~
		DELETE FROM favorites WHERE 
		user_id=$user_id AND record_id=$id AND content_id=$cid AND set_id=$set_id
	~);

	# update favorite count
	$self->_updateCnt($id, $set_id, $cid, $user_id);


	Wywrota->content->mng( $cid )->onRemoveFromFavorites($id, $cid);

	return 0;

}



sub addHtml {
# --------------------------------------------------------
# 
	my $self = shift;
	my ($output);
	my $id = shift;
	my $set_id = shift || 0;
	my $cid = shift || $Wywrota::request->{content}{current}{id};
	my $user_id=shift || $Wywrota::session->{user}{id};

	return Wywrota->error("No ID specified.") if (!$id);

	if ($self->add($id, $set_id, $cid, $user_id)) {
		Wywrota->sysMsg->push( msg('already_in_favorites', $cid), 'tip');
	} else {
		Wywrota->sysMsg->push( msg('added_to_favorites', $cid), 'ok');
	};

	$output = $self->listFavorites();

	return Wywrota->view->wrapHeaderFooter({
			title => msg('favorites_list'),
			nomenu=>  2,
			nocache=>  1,
			output => $output,
			nobillboard => 1
	});

}



sub removeHtml {
# --------------------------------------------------------
# 
	my $self = shift;
	my ($output);
	my $id = shift;
	my $set_id = shift || 0;
	my $cid = shift || $Wywrota::request->{content}{current}{id};
	my $user_id=shift || $Wywrota::session->{user}{id};

	return Wywrota->error("No ID specified.") if (!$id);

	if (!$self->remove($id, $set_id, $cid, $user_id)) {
		Wywrota->sysMsg->push( msg('removed_from_favorites'), 'ok');
	} ;

	$output = $self->listFavorites();

	return Wywrota->view->wrapHeaderFooter({
			title => msg('favorites_list'),
			nomenu=>  2,
			nocache=>  1,
			output => $output,
			nobillboard => 1
	});

}


sub fulllist {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	my ($output);



	$output = "";
	$output .= $self->listFavorites({db=>'artykuly', generate=>1, quiet=>1}, 	Wywrota->cc->{3});
	$output .= $self->listFavorites({db=>'literatura', generate=>1, quiet=>1}, 	Wywrota->cc->{1});
	$output .= $self->listFavorites({db=>'mp3', generate=>1, quiet=>1}, 		Wywrota->cc->{10});
	$output .= $self->listFavorites({db=>'image', generate=>1, quiet=>1}, 		Wywrota->cc->{16});
	$output .= $self->listFavorites({db=>'teksty', generate=>1, quiet=>1}, 		Wywrota->cc->{7});


	return Wywrota->view->wrapHeaderFooter({
		title => msg('favorites'),	
		nomenu=>  2,
		output => $output,
		nocache => 1
		});
}




sub list {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	my ($output, $setObject );


	if ($Wywrota::request->{content}{current}{sets}) {

		if ($in->{set}) {
			$setObject = Wywrota->content->getObject($in->{set}, 'RecordSet');			
			$Wywrota::request->{mainObject} = $setObject;
			$output = $setObject->record;
		} else {

			# -- get a list of RECORD SETS
			my $queryRes = Wywrota->cListEngine->query( {
					user_id=> ($in->{user_id} || $Wywrota::session->{user}{id}), 
					content_id=>$Wywrota::request->{content}{current}{id}, 
					small=>1  
				}, 
				"view", Wywrota->app->{ccByName}{"RecordSet"} );

			$output = Wywrota->cListView->includeQueryResults($queryRes, undef, undef, 1);
			$output .= "<p>Nie masz jeszcze żadnych ".plural(0, msg('set') ) . "." if (!$queryRes->{cnt});

		}
	}

	$output .= $self->listFavorites($in);

	if (!$in->{generate}) {
		return Wywrota->view->wrapHeaderFooter({
			title => msg('favorites_list'),	
			nomenu=>  2,
			output => $output,
			nocache => 1
		});
	}
	return $output;	
}




sub listFavorites {
# --------------------------------------------------------
# 
	my $self = shift;
	my $in = shift;
	my $cc = shift;
	my ($output, $msg, $ccid);
	my $queryRes = Wywrota->cListEngine->query($in, "fav", $cc);
	eval {
		$ccid = $cc->{id};
	};

	if ($queryRes->{status} eq "ok") {
		$output = Wywrota->cListView->includeQueryResults($queryRes, msg('favorites_list', $ccid));

	}
	else {
		if ($Wywrota::in->{user_id}) {
			$msg = msg('user_no_favorites', $ccid);
		} else {
			$msg = msg('no_favorites', $ccid);
		}

		if ($in->{generate}) {
			$output = qq~<div class="div_msg_tip_sm">$msg</div>~ unless ($in->{quiet});
		} else {
			$output .= Wywrota->view->searchHeader($queryRes, msg('favorites_list', $ccid) );
			$output .= qq~<div class="div_msg_tip_sm">$msg</div>~;
			$output .= Wywrota->view->searchFooter($queryRes, msg('favorites_list', $ccid) );
		}
	}
	return $output;
}



sub listUsersForItemHtml {
# --------------------------------------------------------
# 
	my $self = shift;
	my ($output);
	my $id = shift;
	my $set_id = shift;
	my $cid = shift;

	my $queryRes = $self->listUsersForItem($id, $set_id, $cid);
	my $object = Wywrota->content->getObject($id);

	return Wywrota->view->wrapHeaderFooter({
			title =>  msg('favorites_users'),
			nomenu => 'bar',
			output => $object->record
				. Wywrota->cListView->includeQueryResults($queryRes, msg('favorites_users'))
	});

	
}



sub listUsersForItem {
# --------------------------------------------------------
# 
	my $self = shift;
	my $id = shift || $Wywrota::in->{id};
	my $set_id = shift || 0;
	my $cid = shift || $Wywrota::in->{cid} ||  $Wywrota::request->{content}{current}{id};
	my $in = shift || $Wywrota::in;
	
	my ($query, $queryRes, $cnt);
	eval {
			
		($cnt) = Wywrota->db->quickArray(qq|
			SELECT COUNT(*) FROM favorites f 
			RIGHT OUTER JOIN ludzie ON f.user_id=ludzie.id 
			WHERE f.record_id=?
				AND f.content_id=?
				AND f.set_id=?
				AND ludzie._active=1|, $id, $cid, $set_id); 
	
		$query = qq|
			SELECT ludzie.* FROM favorites f 
			RIGHT OUTER JOIN ludzie ON f.user_id=ludzie.id 
			WHERE f.record_id=?
				AND f.content_id=?
				AND f.set_id=?
				AND ludzie._active=1
			ORDER BY _image_id DESC
			|. Wywrota->queryEngine->dao->appendLimitOrderBy($in, $cnt, Wywrota->cc('User')), ;
			
			
		#$cnt = Wywrota->db->selectCount('favorites', "record_id=$id AND content_id=$cid AND set_id=$set_id" );
		
		
		$queryRes = Wywrota::QueryRes->new({
			in			=>	$in,
			cnt			=>	$cnt,
			contentDef	=>	Wywrota->cc('User'),
			hits		=>	Wywrota->db->buildHashRefArrayRef($query, $id, $cid, $set_id),
			status		=>	'ok'
		});
		
		$queryRes->pagination();

	};
	Wywrota->error("Error in Favorites::listUsersForItem", $@) if ($@);
	return $queryRes;
}




sub favListTable {
# --------------------------------------------------------
	my $self = shift;
	my $user_id = shift || $Wywrota::session->{user}{id};
	my ($output, $url, $word);	

	return if (!$user_id); 

	my $favCount = Wywrota->fav->getCountForUser($user_id);
	my $setCount = Wywrota->mng('RecordSet')->getCountForUser($user_id);

	foreach (sort keys %{Wywrota->app->{cc}}) {
		next if (!($favCount->{$_} || $setCount->{$_}) || ($_ == 6));
		 
		$url = Wywrota->cc->{$_}{url};
		$word = Wywrota->cc->{$_}{keyword};


		$output .= qq~ <div><a href="/db/$url/favorites/list/user_id/$user_id" class="setIcon"> ~
			. msg('favorites_list', $_) . "</a> ("
			. ($favCount->{$_} ? $favCount->{$_}." ".plural($favCount->{$_}, $word) : "")
			. ($favCount->{$_} && $setCount->{$_} ? ", " : "")
			. ($setCount->{$_} ? $setCount->{$_}." ".plural($setCount->{$_}, 'zestaw') : "")
			. ")</div>\n"  
		if (int(Wywrota->cc->{$_}{favorites})) and (int($_));
	}	

	return 
		"<h1>" . msg('favorites') . qq~ i zestawy</h1>
		<div class="favListTable">$output</div>
	~ if ($output);
}



1;