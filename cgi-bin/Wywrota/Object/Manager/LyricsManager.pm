package Wywrota::Object::Manager::LyricsManager;

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
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';


sub action {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $output;
	my $action = $nut->in->{a} || $nut->in->{action};

	if    ($action eq 'ludzie')   {  return $self->ludzie();} 
	elsif ($action eq 'by_letter')  { return Wywrota->view->view->listByLetter(); } 
	elsif ($action eq 'translations')  { return Wywrota->view->view->listTranslations(); } 
	elsif ($action eq 'band_page')  { return Wywrota->view->view->bandPage($nut); } 
	
	else {	
		return Wywrota->unknownAction($action);
	}
	return $output;
}




sub initContentTemplate {
# --------------------------------------------------------
	my $self=shift;
	my $nut=shift;
	my ($bandObj, $link);

	if ($nut->in->{urlized}) {
		# this is the old-style listing
		#$nut->in->{wykonawca_urlized} = $nut->in->{urlized};
		#$nut->in->{ww} = 1; # only exact maches
		#$nut->in->{nomenu} = 'bar'; 
		#delete $nut->in->{urlized};

		$nut->in->{wykonawca_urlized} = $nut->in->{urlized};
		$nut->in->{a} = 'band_page';
		delete $nut->in->{urlized};
		
	}
	my $wykonawca_urlized = $nut->in->{wykonawca_urlized};
	my $wykonawca_id = $nut->in->{wykonawca_id};
	
	
	# listing records for wykonawca
	if ($wykonawca_urlized || $wykonawca_id ) {

		if ($wykonawca_urlized) {
			$bandObj = Wywrota->content->getObject(undef, 'Band', "wykonawca_urlized=" .Wywrota->db->quote($wykonawca_urlized) );
		} elsif (int($wykonawca_id)) {
			$bandObj = Wywrota->content->getObject($wykonawca_id, 'Band' );
		}

	# record view
	} elsif (int $nut->in->{view}) {

		($wykonawca_id) = Wywrota->db->quickArray("SELECT wykonawca_id FROM spiewnik WHERE id=?", $Wywrota::in->{view});
		$bandObj = Wywrota->content->getObject($wykonawca_id, 'Band' );
		
	}

	if ($bandObj) {
		$nut->request->{wykonawca} = $bandObj;
		$link->{text} = $bandObj->rec->{wykonawca};
		$link->{url} = $nut->request->{subdomain_url}. $bandObj->rec->{wykonawca_urlized}."/";
		push(@{$nut->request->{nav}{crumbLinks}}, $link);
	}

	$Wywrota::request->{wykonawca}=$bandObj;


}


sub onObjectAdd {
# --------------------------------------------------------
	return onObjectEdit(@_);
}



sub onObjectEdit {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $table = $object->config->{'tablename'};

	$rec->{wykonawca_urlized} = simpleAscii(trim($rec->{wykonawca}));
	my $wykonawca_id = Wywrota->db->quickOne("SELECT id FROM wykonawcy WHERE wykonawca_urlized=? AND _active=1", $rec->{wykonawca_urlized});

	$rec->{wykonawca_id} = $wykonawca_id;
	
	# update band id
	if ($wykonawca_id) {
		Wywrota->db->execWriteQuery("UPDATE $table SET wykonawca_id = $wykonawca_id WHERE id=$rec->{id}"); 
	} else {
		Wywrota->db->execWriteQuery(
			"INSERT INTO wykonawcy (user_id, wykonawca, wykonawca_urlized, informacje) VALUES (?, ?, ?, '')",
			$Wywrota::session->{user}{id}, $rec->{wykonawca}, $rec->{wykonawca_urlized}); 
			
		$wykonawca_id = Wywrota->db->quickOne("SELECT id FROM wykonawcy WHERE wykonawca_urlized=? AND _active=1", $rec->{wykonawca_urlized});
		Wywrota->db->execWriteQuery("UPDATE $table SET wykonawca_id=? WHERE id=?", $wykonawca_id, $rec->{id}); 
	}

	# update soung count and band information
	Wywrota->db->execWriteQueries( 
		Wywrota->t->process("sql/update_band.sql", {
			wykonawca_id => $wykonawca_id
		}) 
	);

	my $versions_count = Wywrota->db->quickOne(
		"SELECT COUNT(id) FROM $table WHERE wykonawca_urlized=? AND tytul_urlized=? AND _active=1", 
		$rec->{wykonawca_urlized}, 
		$rec->{tytul_urlized}
	); 


	# update main version
	Wywrota->db->execWriteQueries( 
		Wywrota->t->process("sql/update_lyrics_version.sql", {
			wykonawca_urlize    => $rec->{wykonawca_urlized},
			tytul_urlized       => $rec->{tytul_urlized}
		})
	) if ($versions_count > 1);

}


sub ludzie {
# --------------------------------------------------------

	my ($query, $sth, $i, $ilepiosenek, $czego, $output, $avatar, $personRec, $miejsce);
	$output = ""; 



	# ostatnio
	# 86400 - 1 dz, 604800 - 1 tydzien, 2592000 - 1 miesiac
	
	my $oldDate = getDate(time() - 2592000);

	$query = qq~
		SELECT ludzie.imie, ludzie.id, ludzie.wywrotid as wywrotid,  ludzie._image_filename as _ludzie_photo, 
		count(spiewnik.id) as cnt 
		FROM ludzie, spiewnik 
		WHERE spiewnik.user_id=ludzie.id 
			AND spiewnik.data_przyslania > '$oldDate' 
			AND spiewnik._active=1 
			AND ludzie._active=1 
			AND ludzie.id <> 777
		GROUP BY ludzie.id ORDER BY cnt DESC LIMIT 0,10
	~;
	$sth = Wywrota->db->execQuery($query) or return; 


	while ( $personRec = $sth->fetchrow_hashref() ) { 
		$avatar = Wywrota::Object::User->new($personRec)->recordTiny;
		$miejsce++;

		$czego = plural($personRec->{cnt}, 'piosenka');
		$output .= qq~
			<span title="$personRec->{cnt} $czego">
			$avatar
			</span>
		~;
	}
	
	$sth->finish;

	

	# w sumie
	#$ilepiosenek = Wywrota->db->selectCount("spiewnik","stan < 3");
	#$ilepiosenek = $ilepiosenek - ($ilepiosenek % 100);
	#$czego=plural($ilepiosenek, 'piosenka');
	
	#$output .= qq~
	#
	#<br class="clrl">
	#W naszej bazie znajduje się aktualnie ok. <b>$ilepiosenek</b> $czego.
	#
	#~;

	

	return Wywrota->nav->absoluteLinks($output);

}




sub landingPage {
# --------------------------------------------------------
	return Wywrota->content->includeFile("spiewnik/index.html");
}


sub getSqlAddFields {
#-----------------------------------------------------------------------
	return ", w.nazwa_pliku as band_photo ";
}

sub getSqlAddJoin {
#-----------------------------------------------------------------------
	return " LEFT JOIN wykonawcy w on rec.wykonawca_id=w.id ";
}

1;