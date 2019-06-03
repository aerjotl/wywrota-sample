package Wywrota::Object::View::BandView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Language;




sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	
	unless ($object) {
		my $band_deleted = Wywrota->content->getObject( undef, 'Band', "wykonawca_urlized=" .Wywrota->db->quote($nut->in->{wykonawca_urlized}), 1 );
		if ($band_deleted && $band_deleted->{rec}{new_id}) {
			my $new_band = Wywrota->content->getObject( $band_deleted->{rec}{new_id}, 'Band')->preProcess;
			$nut->request->hardredirect = $new_band->url;
			return;
		}
		
		return Wywrota->errorPage("Nie znaleziono wykonawcy.") ;
	}
	
	
	my $rec = $object->rec;
	$object->preProcess('lg', 1);
	Wywrota->debug('in htmlPage Band');

	my ($output, $queryRes );
	my $wykonawca_id = $rec->{id};
	my $forumKatId=5;

	Wywrota->debug('in htmlPage Band');




	# ----------------  forum topics
	$queryRes = Wywrota->cListEngine->query({
			kat_id=>$forumKatId, 
			topic=>1, 
			sb=>'lc_time', 
			so=>'descend', 
			small=>'1', 
			wykonawca_id=>$wykonawca_id 
		}, "view", Wywrota->app->{ccByName}{"ForumPost"} 
	);

	
	# ---- generate output 
	my $output = Wywrota->t->process('object/band_page.html', {
		obj				=>	$object,
		rec				=>	$rec,
		members			=>	$self->fanList($wykonawca_id),
		topics			=>	Wywrota->cListView->includeQueryResults($queryRes, $rec->{tytul}, 0, 1),
	});
	
	
	return Wywrota->t->wrapHeaderFooter({
		title =>  "$rec->{wykonawca} - ".$Wywrota::request->{content}{current}{title},	
		meta_desc=> "fan klub wykonawcy: $rec->{wykonawca} - zdjęcia, teksty piosenek, teledyski",	
		meta_key=> $rec->{wykonawca},
		canonical=> $rec->{old_style_url},
		image => ($rec->{nazwa_pliku} ? sprintf("%s/pliki/site_images/%s-lg", $config{'file_server'}, $rec->{nazwa_pliku})  : undef),
		nomenu			=> 'bar',
		output	=> $output
	});
}





sub fanList {
# --------------------------------------------------------
	my $self = shift;
	my $wykonawca_id = shift;
	my ($record, $found, $queryRes);
	my $output = '';

	my $is_fav = Wywrota->fav->isInFavorites($wykonawca_id, 15);
	my $user_id = $Wywrota::session->{user}{id}; 
	
	if (!$is_fav) {
		$output = Wywrota->cache->getFromCache("fan_list_$wykonawca_id", "1d");
		return $output if ($output);
	}

	$queryRes = Wywrota->fav->listUsersForItem(
		$wykonawca_id, 0, 15, {
		mh=>10
	});


	foreach $record ( @{$queryRes->{hits}} ) {
		if ($record->{id} == $user_id) {
			$found = 1;
		}
	}
	if ($is_fav && !$found) {
		$output .=  Wywrota->content->getObject($user_id, 'User')->recordTiny;
		pop @{$queryRes->{hits}};
	}
	foreach $record ( @{$queryRes->{hits}} ) {
		$output .=  Wywrota::Object::User->new($record)->recordTiny;
	}
	
	
	if (!$is_fav) {
		Wywrota->cache->storeCache("fan_list_$wykonawca_id", $output, 1);
	}
	
	return $output;
}




sub showRanking {
# -------------------------------------------------------------------------------------
# shows ranking table with a count for given elements
#  - $recordsRef   - records table refference. 
#                    required fields for each record: 'name', 'id', 'cnt'
#  - $linkTemplate - ie. "/spiewnik/{id}_{urlized}.html"

	my ($output, $href, $rec);

	my $recordsRef = shift;
	my $linkTemplate = shift;

	$output = qq~<table class="ranking">~;
	foreach $rec (@$recordsRef) {
		$href = $linkTemplate;
		$href =~ s/\{([^\}]+)\}/$rec->{$1}/g;
		$output .= qq~
			<tr>
				<td><a href="$href">$rec->{name}</a></td>
				<td>$rec->{cnt}</td>
			</tr>
			~;
	}
	$output .= qq~</table>~;

	return $output;

}



1;