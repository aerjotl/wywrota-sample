package Wywrota::Object::Manager::RecordSetManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Object::BaseObject;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';


sub initContentTemplate {
# --------------------------------------------------------

	my $self=shift;
	my $nut=shift;
	my ($set, $link);

	if ($nut->in->{view}) {
		my $set = Wywrota->content->getObject($nut->in->{view})->preProcess();

		$nut->request->{mainObject} = $set;
		$nut->request->{content}{current}{page_id} = 
			Wywrota->cc->{ $set->{rec}{content_id} }{page_id};
		$nut->request->{nav}{crumbLinks} = 
			Wywrota->nav->crumbTrailLinks( Wywrota->cc->{ $set->{rec}{content_id} }{page_id} );
		$nut->request->{fav}{cid} = $set->{rec}{content_id};		

		$link->{text} = msg('sets');
		$link->{url} = '/db/'.Wywrota->cc->{ $set->{rec}{content_id} }{url}.'/favorites/list';
		push(@{$nut->request->{nav}{crumbLinks}}, $link);
		


	} 


}

sub getRecordSetBox {
# --------------------------------------------------------
	my $self = shift;
	my ($output, $set, $word);

	my $userSets = Wywrota->cListEngine->query({
		user_id => $Wywrota::session->{user}{id}, 
		content_id=> $Wywrota::request->{content}{current}{cid},
		sb=>'title'
	}, "view", Wywrota->app->{ccByName}{"RecordSet"} );

	$output = qq~

	<div id="recordSetBox">
	<form name="add_to_set_form" action="" method="POST">
		<input type="hidden" name="record_id" value="" >
		<input type="hidden" name="content_id" value="" >
		<div>
			<div>~. msg('add_to_set') .qq~ </div>
		<select name="set_id">
			<option value="" name="playlist_id">--- ~. msg('select') . msg('set'). qq~ ---</option>
	~;

		if ($userSets->{cnt}) {
			foreach $set (@{$userSets->{hits}}) {
				$word = Wywrota::Language::plural($set->{_record_cnt}, Wywrota->cc->{$set->{content_id}}{keyword} );
				$output .= qq~<option value="$set->{id}">$set->{title} ($set->{record_cnt} $word)</option>~;
			}
		}

	$output .= qq~
			<option value="new">[ ~. msg('new').msg('set') .qq~ ]</option>
		</select>
		<input type="button" onclick="addToRecordSet(this); return false;" value="OK">
		</div>
	</form>
	</div>
	~;
	return $output;
}


sub onObjectAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;

	if ($Wywrota::in->{content_id} and $Wywrota::in->{record_id}) {
		Wywrota->fav->add($Wywrota::in->{record_id}, $object->rec->{id}, $Wywrota::in->{content_id} );
	}
}


sub getCountForUser {
# --------------------------------------------------------
# zwraca strukturę z iloscia ulubionych dla użytkownika
	my $self = shift;
	my $user_id = shift;
	return if (!$user_id);

	my $struct = Wywrota->db->buildHashRef(qq~
		SELECT content_id, count(content_id) FROM record_set 
		WHERE user_id=$user_id AND _record_cnt>0 AND _active=1
		GROUP BY content_id
	~);

	return $struct;
}



1;