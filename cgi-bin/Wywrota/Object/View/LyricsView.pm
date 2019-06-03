package Wywrota::Object::View::LyricsView;

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
use Wywrota::Chords;


sub htmlPage {
#-------------------------------#
	my ($output );
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;

	$object->preProcess(1);

	my $band = Wywrota->content->getObject( $Wywrota::request->{wykonawca}{rec}{id}, 'Band');
	$band->preProcess();

	
	# ---- generate output 
	my $output = Wywrota->t->process('object/lyrics_page.html', {
		rec				=> $rec,
		obj 			=> $object,
		actions_log		=> Wywrota::Log::getActionLog($object->id, $object->cid),
		band 			=> $band
	});
	
	
	return $self->wrapHeaderFooter({
			title =>	"$rec->{tytul} - $rec->{wykonawca} ($rec->{whatwehave})",
			meta_desc=>  $rec->{tresc},	
			meta_key=>  "$rec->{tytul}, $rec->{whatwehave}, $rec->{wykonawca}, tekst, lyrics ",
			canonical=> $rec->{url},
			nomenu=>  	"bar",
				
			image=> 	($Wywrota::request->{wykonawca}{rec}{nazwa_pliku} ? 
							sprintf("%s/pliki/site_images/%s-lg", $config{'file_server'}, $Wywrota::request->{wykonawca}{rec}{nazwa_pliku})  : undef),
			output=>  	$output,
			rec => $rec,
			obj => $object
	});
}



sub bandPage {
#-------------------------------#
	my $self = shift;
	my $nut = shift;
	
	return Wywrota->view->view('Band')->htmlPage($nut, $Wywrota::request->{wykonawca});
}





sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $output;

	my $wykonawca = $Wywrota::request->{wykonawca}{rec}{wykonawca};
	$wykonawca .= " - tłumaczenia" if ($Wywrota::in->{jezyk}==3);

	$output = qq~
		<h1>$wykonawca</h1>
	~;

	$output .= $self->SUPER::searchHeader($queryRes, $tytul);



	#$output = topLetterNav($wykonawca, $jezyk);

	return $output;

}



sub topLetterNav {
# --------------------------------------------------------
	my ($output, $i, $class_nr, $class_xyz, $lettersLabel, $link, $class);
	my $wykonawca = shift;
	my $jezyk = shift || $Wywrota::in->{jezyk};
	my $letter = (length($wykonawca)) ? (lc substr($wykonawca,0,1)) : $Wywrota::in->{letter};

	if ($jezyk == 1) {
		$link = "pl";
		$lettersLabel = "polskie";
	} else {
		$link = "zag";
		$lettersLabel = "zagraniczne";
	}

	if ($letter =~ "[0-9]") {
		$class_nr = ' class="active"';
	} elsif ($letter =~ "[xyz]") {
		$class_xyz = ' class="active"';
	}	
	
	$output = qq~
		<div class="letterLinks">
		<a href="/$link.html" style="font-size: 24px; height: 27px; ">$lettersLabel</a>
		<a href="/$link-0.html"$class_nr>#</a>~;
	for ($i="a"; $i ne "x" ;$i++) {
		$class = (lc $letter eq lc $i) ? ' active' : "";
		$output .= qq~<a href="/$link-$i.html" class="ll_$i$class">$i</a>~;
	}
	$output .= qq~<a href="/$link-x.html" $class_xyz >XYZ</a> 
		</div>
		<br class="clrl">
	~;
	return $output;
}





sub header {
# -------------------------------------------------------------------------------------

	my ($output);
	my ($recordSetsHTML, $queryRes);
	my $self = shift; 
	my $param=shift;
	
	if (!$param->{canonical} and !$Wywrota::in->{content_include} and !$Wywrota::in->{a}) {
	    $param->{title} = "Teksty piosenek, chwyty na gitarę, akordy i tabulatury";
		if ($Wywrota::request->{wykonawca}) {
			$param->{title} = $Wywrota::request->{wykonawca}{rec}{wykonawca}." - ".$param->{title} ;
			$param->{meta_key} = $Wywrota::request->{wykonawca}{rec}{wykonawca};
			$param->{meta_desc} = "Teksty " . $Wywrota::request->{wykonawca}{rec}{wykonawca}. " – słowa i chwyty na gitarę. Wszystkie teksty piosenek ". $Wywrota::request->{wykonawca}{rec}{wykonawca} . "";
			$param->{image} = ($Wywrota::request->{wykonawca}{rec}{nazwa_pliku} ? 
							sprintf("%s/pliki/site_images/%s-lg", $config{'file_server'}, $Wywrota::request->{wykonawca}{rec}{nazwa_pliku})  : undef),
		}
	};

	if ($Wywrota::request->{wykonawca}{rec}{id} && ($param->{nomenu} ne 'bar')) {
		$param->{nomenu}='left';
	}

	if (!$param->{nomenu}) {
		$param->{nomenu}='left';
	}



	return $self->SUPER::header($param);

}



sub listByLetter {
# --------------------------------------------------------
# generuje autorow poukladanych alfabetycznie

	my $self = shift;

	my $output;
	my ($where, $last_letter, $czego, $output_full, $query, 
		$class, $link, $current_letter,
		$meta_title, $meta_desc, $meta_key, $rec);
	my $wszystkie=0;
	my $letter = $Wywrota::in->{letter};

	my $kolumna = "wykonawca";

	if ($Wywrota::in->{jezyk} == 1) {
		$link = "pl";
	} elsif ($Wywrota::in->{jezyk} == 2) {
		$link = "zag";
	} 

	if ($letter =~ "[0-9]") {
		$where .= "  ($kolumna LIKE '0%' OR $kolumna LIKE '1%' OR $kolumna LIKE '2%' OR $kolumna LIKE '3%' OR $kolumna LIKE '4%' OR $kolumna LIKE '5%' OR $kolumna LIKE '6%' OR $kolumna LIKE '7%' OR $kolumna LIKE '8%' OR $kolumna LIKE '9%')";
	} elsif ($letter =~ "[xyz]") {
		$where .= "  ($kolumna LIKE 'x%' OR $kolumna LIKE 'y%' OR $kolumna LIKE 'z%')";
	} elsif ($letter eq '') {
		# main page
		$where = ' 1=1 '
	} else {
		$where .= "  $kolumna LIKE '$letter%' ";
	}

	$query = qq|SELECT id, wykonawca, _song_count AS cnt, wykonawca_urlized
				FROM wykonawcy
				WHERE $where 
					AND lang=?
					AND _active=1
					AND _song_count > 0
				ORDER BY wykonawca_urlized|;

	my $records = Wywrota->db->buildHashRefArrayRef($query, $Wywrota::in->{jezyk}) or return; 



	# obliczanie headera, keywordsow itp.
	if (length($letter)) {
		$meta_title = "Wykonawcy na literę '".uc($letter)."' - ";
	}
	if ($Wywrota::in->{jezyk} == 1) {
		$meta_title .= qq~Polskie piosenki~;
	} else {
		$meta_title .= qq~Pagraniczne piosenki~;
	}

	
	foreach $rec ( @$records ) { 
		$current_letter = lc substr($rec->{wykonawca_urlized},0,1);
		$current_letter = '#' if ($current_letter =~ /[0-9]/);
		$current_letter = 'xyz' if ($current_letter =~ /[xyz]/);

		next if (!$rec->{wykonawca_urlized} || $current_letter eq '-');

		$czego=Wywrota::Language::plural($rec->{cnt}, $Wywrota::request->{content}{current}{keyword}, 1);
		$wszystkie += $rec->{cnt};

		$class = "countA" if ($rec->{cnt}<20);
		$class = "countB" if ($rec->{cnt}>=30);
		$class = "countC" if ($rec->{cnt}>=40);
		$class = "countD" if ($rec->{cnt}>=50);
		$class = "countE" if ($rec->{cnt}>=60);
		$class = "countF" if ($rec->{cnt}>=70);
		$class = "countG" if ($rec->{cnt}>=80);


		if (!length($letter) && ($last_letter ne $current_letter) ) {
			if ($last_letter) {
				if ($last_letter eq '#') {
					$output .= qq|
						<a href="$link-0.html" class="moreThisLetter">więcej wykonawców <span style="color:red">1-9</span></a>
					|;
				} else {
					$output .= qq|
						<a href="$link-$last_letter.html" class="moreThisLetter">więcej na literę <span style="color:red">$last_letter</span></a>
					|;

				}
			}

			$output .= qq|
				</div><a href="$link-$current_letter.html" class='letter'>|. (uc $current_letter) .qq|</a><div class="byLetter">
			| if ($current_letter ne '_');
		}

		$output .= qq~ <a href="/$rec->{wykonawca_urlized}/" class="$class">$rec->{wykonawca}</a> ~ if ($rec->{cnt}>20);

		$output_full .= qq| 
			<a href="/$rec->{wykonawca_urlized}/">$rec->{wykonawca}</a> 
			&middot; $rec->{cnt} $czego
			| . (Wywrota->per('admin') ? " &middot; id: " . $rec->{id} : "" )  .qq|
			<br>
		|;
		$meta_key .= "$rec->{wykonawca} " if (!length($letter) ? ($rec->{cnt}>20) : ($rec->{cnt}>5) );

		$last_letter = $current_letter;

	}



	# gorna nawigacja z literkami
	if (length($letter)) {
		$output = topLetterNav() 

		.qq|
			<h1>Wykonawcy na literę <span class="letter">$letter</span></h1>

			<div class="byLetterAll">
				$output_full
			</div>
		|;
	} else {
		if ($Wywrota::in->{jezyk} == 1) {
			$output = qq~<h1>Polscy wykonawcy</h1>~.$output;
		} elsif ($Wywrota::in->{jezyk} == 2) {
			$output = qq~<h1>Wykonawcy zagraniczni</h1>~.$output;
		} 

		$output = qq~
			<div class="byLetter">
				$output
			</div>
		~;
	}


	$output if (length($letter));

	return $self->wrapHeaderFooter({
		title => $meta_title,	
		nomenu=>  2,	
		meta_desc=>  $meta_key,	
		meta_key=>  $meta_key,
		output => $output
	});
	
}


sub listTranslations {
# -------------------------------------------------------------------------------------
# generuje tłumaczeń poukladanych alfabetycznie
	my $self = shift;
	my ($output, $outputA, $query, $czego, $wykonawca, $wykonawca_url, $meta_key, $i);
	
	$query = qq~SELECT wykonawca, count(id) as cnt, wykonawca_urlized
		FROM $Wywrota::request->{content}{current}{tablename} 
		WHERE jezyk=3 
		GROUP BY wykonawca_urlized
		ORDER BY wykonawca_urlized
	~;

	my $wykonawcy = Wywrota->db->buildHashRefArrayRef($query); 
	foreach $wykonawca (@$wykonawcy) {
		$czego=Wywrota::Language::plural($wykonawca->{cnt}, $Wywrota::request->{content}{current}{keyword});
		$wykonawca_url = "/t/".$wykonawca->{wykonawca_urlized}.".htm";

		$output .= qq~<a href="$wykonawca_url">$wykonawca->{wykonawca}</a> $wykonawca->{cnt} $czego <br>~ if (length($wykonawca->{wykonawca_urlized}));
		$meta_key .= "$wykonawca->{wykonawca}," if ($wykonawca->{cnt}>3);

		if (++$i == int($#$wykonawcy / 2)) {
			$outputA = $output ;
			$output ="";
		}

	}

	$output = qq~
		<h1>Tłumaczenia</h1>
		<div class="translat">
		$outputA
		</div>
		<div class="translat">
		$output
		</div>
	~;

	return $self->wrapHeaderFooter({
		title => "Tłumaczenia",
		meta_desc=>  $meta_key,	
		meta_key=>  $meta_key,
		output => $output
	});
}




sub recordFormAdd {
# --------------------------------------------------------

	my $self = shift;
	my $object = shift;
	my $output;

	$output = qq~
	<h2>Prześlij tekst piosenki</h2>

	<div class="div_msg_tip">
	Przed przysłaniem tekstu sprawdź, czy nie ma go już w naszej bazie.
	</div>

	~;
	
	$output .= Wywrota::Forms::buildHtmlRecordForm($object, @_);

	return  $output;
}




1;