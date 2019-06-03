package Wywrota::Engine::VoteEngine;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

 
use strict;
use Wywrota;
use Wywrota::Log;
use Wywrota::Nut::Session;
use Wywrota::Config;
use Wywrota::Language;
use Wywrota::Utils;

use Class::Singleton;
use base 'Class::Singleton';

our (@oceny_zasieg, @oceny_wartosci, @oceny);

#@oceny_zasieg =   qw|1.0  3.0  5.0  7.0  8.74  10|;
#@oceny_wartosci = qw|   2    4    4     8   10   |;
#@oceny = ('słaby','przeciętny','wartościowy','bardzo dobry','wyśmienity');

@oceny_zasieg =   qw|0.0 3.0 4.4 5.4 6.4 7.4 8.7 10|;
@oceny_wartosci = qw|   2   4   5   6   7   8   10|;
@oceny = ('fatalny','słaby','przeciętny','niczego sobie','wartościowy','bardzo dobry','wyśmienity');

 
sub _rating2human {
# --------------------------------------------------------
	my $rating = shift;
	my $ocena;
	for ($a=0; $a<$#oceny_zasieg; $a++) {
		if ($rating>$oceny_zasieg[$a] && $rating<=$oceny_zasieg[$a+1]) {
			$ocena = $oceny[$a];

			my $x = ($oceny_zasieg[$a+1]-$oceny_zasieg[$a])/4;
			$ocena .= "&#150;" if ($rating < ($oceny_zasieg[$a] + $x));
			$ocena .= "+ " if ($rating > ($oceny_zasieg[$a+1] - $x) && $a+1!=$#oceny_zasieg);

			last;
		}
	}
	return $ocena;
}





sub initRatings {
# --------------------------------------------------------
# oddaje normalna wartosc oceny
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec if ($object);

	$rec->{rating} = "";
	$rec->{vote_count} = "brak ocen";
	$rec->{comment_count} = "";


	if ($rec->{_vote_ratings}) {
		$rec->{rating} = _rating2human($rec->{_vote_ratings});
		$rec->{vote_count} = $rec->{_vote_cnt}." ".Wywrota::Language::plural($rec->{_vote_cnt}, 'głos');
	} ;


	if ($rec->{_comment_cnt}>0) {
		$rec->{comment_count} = $rec->{_comment_cnt}." ".Wywrota::Language::plural($rec->{_comment_cnt}, 'komentarz');
	};


	if ($rec->{_fav_cnt}) {
		$rec->{fav_count} = '<div class="iconFavHeart txtnews">'
			. $rec->{_fav_cnt} . " " . Wywrota::Language::plural($rec->{_fav_cnt}, 'osoba')
			. " ma "
			. msg('this_item', $object->cid)." w ulubionych </div>";
	};


	$rec->{vote_css} = $self->_cssClass($rec);

	return $rec;
}



sub _cssClass {
# --------------------------------------------------------
#	returns: pusty, 0, 1, .., n-1, bluestar
	my $self = shift;
	my $rec = shift;

	my $count=$rec->{_vote_cnt};
	my $ratings = $rec->{_vote_ratings};
	my $nr;

	return 'pusty' if ($ratings==0);
	#return 'bluestar' if ($self->isBluestar($rec));

	for ($nr=0; $nr<$#oceny_zasieg; $nr++) {
		if ($ratings>$oceny_zasieg[$nr] && $ratings<=$oceny_zasieg[$nr+1]) {
			last;
		}
	}
	$nr = 6 if ($nr>6);

	return $nr;
}


sub isBluestar {
# --------------------------------------------------------
	my $self = shift;
	my $rec = shift;
	return 0 if ($rec->{'typ'} =~ 'klasyka');

	if ( ($rec->{'_vote_func'} > $config{'vote_func_val_for_star'}) && ($rec->{'_vote_cnt'} >= $config{'vote_uservotes_for_star'} )) 
	{return 1}	else {return 0}
}


sub rateIt {
# --------------------------------------------------------
#	funkcja wywoływana przez AJAX przy głosowaniu
#	sprawdza wszystkie warunki, jeśli nie wystąpią żadne problemy dodaje 
#	głos do bazy i zwraca nowy kod do div'a

	my $self = shift;
	my $in = shift;
	my ($output, $object, $sum, $rated);


	# Make sure we have a valid rating. 
    return $self->rateError("invalid_rating") if (($in->{rating} !~ /^\d\d?/) or ($in->{rating} < 1) or ($in->{rating} > 10) or !$in->{id} or !$in->{cid});

	# Let's get the link information.
	$object = Wywrota->content->getObject($in->{id}, Wywrota->cc->{ $in->{cid} }{package});

	if ($Wywrota::session->{user}{id} >0) {
		return $self->rateError("na_siebie") if ($object->{user_id} == $Wywrota::session->{user}{id});

		($rated) = Wywrota->db->quickArray("SELECT ocena FROM glosy WHERE record_id=? AND content_id=? AND user_id=?", $in->{id}, $in->{cid}, $Wywrota::session->{user}{id});
	} else {

		($rated) = Wywrota->db->quickArray("SELECT ocena FROM glosy WHERE record_id=? AND content_id=? AND ip=?" , $in->{id}, $in->{cid}, $ENV{'REMOTE_ADDR'} );
	};

	return $self->rateError("already_voted" ) if ($rated);

	# Vote is ok
	Wywrota->db->execWriteQuery("INSERT INTO glosy VALUES (?, ?, ?, NOW(), ?, ?)",
									$in->{rating}, $in->{cid}, $in->{id}, int($Wywrota::session->{user}{id}), $ENV{'REMOTE_ADDR'});
									
	$object->rec->{_vote_sum} = Wywrota->db->selectSum("glosy","record_id=$in->{id} AND content_id=$in->{cid}","ocena");
	$object->rec->{_vote_cnt} += 1;
	$object->rec->{_vote_ratings}= $object->rec->{_vote_sum} / $object->rec->{_vote_cnt}; 

	Wywrota->db->execWriteQuery(
		"UPDATE ".Wywrota->cc->{$in->{cid}}{tablename}
		. " SET _vote_cnt=_vote_cnt+1, _vote_ratings=".$object->rec->{_vote_ratings}." WHERE id=$in->{id}");
	
	$output .= $self->votePortletsDivContents($object, $in->{cid});

	return $output;
}




sub rateError {
# --------------------------------------------------------
	my $self = shift;
	my $message = shift;
	return $message;
}


sub voteStatsTable {
# --------------------------------------------------------
#	zwraca html z wykresem ocen

	my $self = shift;
	my ($max,$output, $size);
	my $id=shift;
	my $cid=shift;
	my $HEIGHT = 60;

	return if (!$id);

	my %glosy = Wywrota->db->buildHash("SELECT DISTINCT ocena, count(ocena) FROM glosy WHERE record_id=$id AND content_id=$cid GROUP BY ocena");
	$max=1;

	$output = qq~<table class="votes"><tr>~;
	foreach (keys %glosy) {$max = $glosy{$_} if ($glosy{$_}>$max);}
	for (0..$#oceny_wartosci) {
		$size = $glosy{$oceny_wartosci[$_]}*($HEIGHT/$max); 
		$size = sprintf ("%.0f", $size)+1;
		$output .= qq~
			<td>~.($glosy{$oceny_wartosci[$_]} || "<span class='zero'>0</span>").qq~<br><img src="$config{file_server}/gfx/px.gif" class="c$_" height="$size" alt="$oceny[$_]" title="$oceny[$_]"></td>
		~;
	}
	
	$output .= qq~</tr></table>~;

	return $output;
}




sub votePortletsDiv {
# --------------------------------------------------------
	my $self = shift;
	my $output = $self->votePortletsDivContents(@_);
	
	return qq~
		<!-- votes -->
		<div id="votePortlets">
			$output
		</div>
	~;
	
}


sub votePortletsDivContents {
# --------------------------------------------------------
# zwraca div'a ze wszystkimi informacjami potrzebnymi do głosowania:
# formularz, wykres ze słupkami, oraz listę głosujšcych

	my $self = shift;
	my $object = shift;
	my $cid = shift || $object->cid;
	my ($rec, $output, $voteStats, $radio, $i, $rated);

	return "no object" if (!$object);

	$self->initRatings($object);
	$rec = $object->rec;

	if ($Wywrota::session->{user}{id} > 0) {
		($rated) = Wywrota->db->quickArray("SELECT ocena FROM glosy WHERE record_id=? AND content_id=? AND user_id=?" , $rec->{id}, $cid, $Wywrota::session->{user}{id} );
	} else {
		($rated) = Wywrota->db->quickArray("SELECT ocena FROM glosy WHERE record_id=? AND content_id=? AND ip=?" , $rec->{id}, $cid, $ENV{'REMOTE_ADDR'} );
	}


	$voteStats = $self->voteStatsTable($rec->{id}, $cid) if ($rec->{_vote_ratings});


	$output = qq|
		<div class="voteUserRating">
			$voteStats 
			<b>$object->{rec}{rating}</b>
			<a href="/votelist/$cid/$rec->{id}" class="fancy" rel="nofollow" title="historia ocen">$object->{rec}{vote_count}</a>
			$rec->{fav_count}
		</div>
	| if ($rec->{_vote_cnt});

		

	if ($Wywrota::in->{rating}) {
		while ($Wywrota::in->{rating} > $oceny_wartosci[$i]) {$i++};
		$output .= qq~<div id="voteTag" class="votedInfo"><b>Dziękujemy za oddanie głosu!</b><br>Oceniłeś ~. msg('this_item') .qq~ jako $oceny[$i].</div>~;

	} elsif (abs($rec->{user_id}) == $Wywrota::session->{user}{id}) {
		$output .= qq~<div id="voteTag" class="votedInfo"><b>To jest ~. msg('your_item') .qq~.</b><br>Nie możesz na niego głosować.</div>~;

	} elsif ($rated) {

		$output .= qq~<div id="voteTag" class="votedInfo">Już oceniałeś ~. msg('this_item') .qq~. </div>~;

	}
	
	elsif (!$Wywrota::session->{user}{id} && !Wywrota->cc($cid)->{anonymous_vote}) {
		#$output .= qq~
		#	<div id="voteTag">
		#		<div class="div_msg_tip_sm clrl" id="tip_login">
		#		~. msg('log_in_to_vote') .qq~						
		#		</div>
		#	</div>
		#~;
	}
	else {

		for (0..$#oceny_wartosci) {
			$radio .= qq|<input name="rating" type="radio" class="hover-star" value="|. $oceny_wartosci[$_] . qq|" title="|. $oceny[$_] .qq|"> |;
		}

		$output .= qq|
			<div id="voteTag">
				<b>twoja ocena:</b>
				<form>
				<input type="hidden" name="id" value="$rec->{id}">
				<input type="hidden" name="cid" value="$cid">
				
				<div id="voteGadget">
					$radio
					<div id="voteLabel"></div>
				</div>
				</form>
			</div>
		|;

	}			

	$output = qq|
	<div class="votePortletsDiv">
	
		$output

	</div>
	<div class="clrl"></div>
	|;

	return $output;
}








sub voteList {
# --------------------------------------------------------
# zwraca html z listą osób, które oddały głos na ten rekord

	my $self = shift;
	my $nut = shift;
	my $in = $nut->in;
	my ($output, $votes, $rec);
	
	my $baseObject = Wywrota->content->getObject($in->{id}, $in->{cid});

	
	return unless $baseObject;
	$baseObject->preProcess;



	$votes = Wywrota->db->buildHashRefArrayRef(qq~
		SELECT ocena, data, user_id,
			ludzie.imie as ludzie_imie, ludzie.wywrotid as wywrotid
		
		FROM glosy rec
			LEFT OUTER JOIN ludzie ON rec.user_id=ludzie.id

		WHERE record_id=? AND content_id=?
		ORDER BY data 

		~, $in->{id}, $in->{cid});

	$output =  qq~
		
		<h1>Oceny ~ . $baseObject->toString . qq~  </h1>
		
		<ul class="voteList ">
			
		~;
		foreach $rec (@$votes) {
			if ($rec->{user_id}>0) {
				$output .= qq~
					<li>
					<span class="rating">~. _rating2human($rec->{ocena}) . qq~</span>
					<a href="/ludzie/$rec->{wywrotid}">	$rec->{ludzie_imie}</a>
					<span class="date">~. normalnaData($rec->{data},1,1) . qq~</span>
					</li>
				~;
			} else {
				$output .= qq~
					<li>
					<span class="rating">~. _rating2human($rec->{ocena}) . qq~</span>
					<span class="anonimUser">anonimowy użytkownik</span>
					<span class="date">~. normalnaData($rec->{data},1,1) . qq~</span>
					</li>
				~;
			}
		}
		$output .= qq~
		</ul>
		
		

	~;
	
	return Wywrota->contentView->wrapHeaderFooter({
		title => "Szczegóły ocen dla " . $baseObject->toString,
		output => $output,
		nomenu => 'bar',
		nocache=>1
	});
}




1;
