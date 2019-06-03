package Wywrota::Object::View::LiteratureView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Data::Dumper;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Language;




sub lodowka {
# --------------------------------------------------------
	my ($output, $i, $j);
    my ($sec, $min, $hour, $day, $mon, $year, $dweek, $dyear, $daylight) = localtime(time());
	$year = $year + 1900;

	my $cnt = Wywrota->db->buildHashRef(qq~
		SELECT date_format(data_publikacji, '%Y-%m') as month, count(id) as cnt
		FROM teksty GROUP BY date_format(data_publikacji, '%Y-%m')
		~);

	for ($i=$year; $i>=2000; $i--) {
		$output .= "<h3>$i</h3><div class='months'>";
		my $endmonth = ($i==$year) ? $mon+1 : 12;
		for ($j=1; $j<=$endmonth; $j++) {
			$j = "0$j" if ($j<10);
			if ($cnt->{"$i-$j"}) {
				$output .= qq~<a href="/db/$Wywrota::request->{content}{current}{url}/data_publikacji=$i-$j">$config{full_months}[$j]</a> ~;
			} else {
				$output .= qq~<span class="g">$config{full_months}[$j]</span> ~;
			}
			$output .= " - " if ($j!=$endmonth);
		}
		$output .= "</div>";
	}
	$output .= qq~
		<h3>1998-1999</h3><div class='months'>
			<a href="/db/$Wywrota::request->{content}{current}{url}/data_publikacji=1999-09">teksty z lat 1998-1999</a>
		</div>
	~;

	return $output;
}




sub htmlPage {
# --------------------------------------------------------
#
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $image = undef;
	$object->preProcess(1);
	
	
	my $userObj = Wywrota->content->getObject($rec->{user_id}, 'User')->preProcess;


	if ($userObj->rec->{_image_filename}) {
		$image = $config{'file_server'} . "/pliki/site_images/" . $userObj->rec->{_image_filename} . "-lg";
	}

	if ($nut->request->{wykonawca} && $nut->request->{wykonawca}{rec}{nazwa_pliku}) {
		$image = $config{'file_server'} . "/pliki/site_images/" . $nut->request->{wykonawca}{rec}{nazwa_pliku} . "-lg";
	}
	

	# ---- generate output 
	my $output = Wywrota->t->process('object/literature_page.html', {
		rec				=>	$rec,
		obj 			=>  $object,
		user_lead		=>	$userObj->recordLead(),
		band			=>	$nut->request->{wykonawca},
		actions_log		=>	Wywrota::Log::getActionLog($object->id, $object->cid)
	});
	
	
	return Wywrota->t->wrapHeaderFooter({
		title => $rec->{tytul}." - ".$rec->{autor} . " ($rec->{typ})",	
		nomenu=>  			3,	
		meta_desc=>  $rec->{tytul}.", ".$rec->{typ}." na Wywrocie",	
		meta_key=>  "$rec->{tytul}, $rec->{autor}",
		canonical=> $rec->{url},
		image=> $image,
		output => $output,
		nobillboard => 1,
		styl_local => 'literatura-page.css',
		rec => $rec,
		obj => $object
	});

}


sub header { 
	my $self=shift; 
	my $param=shift;
	Wywrota->trace("in LiteratureView header");  

	$param->{title} = customTitle($Wywrota::in, $param->{title});

	Wywrota->t->header($param);	
	
}



sub customTitle {
# --------------------------------------------------------
	my $in = shift;
	my $title = shift;
	# custom title 

	if ($Wywrota::request->{autor}) {
		$title = $Wywrota::request->{autor};
		$title .= ($Wywrota::request->{typ} == 5 ? " - wiersze" : " - wiersze i opowiadania");
	} 
	
	elsif ($in->{wyroznienie}) {
		$title = ($in->{wyroznienie} == 1) ? "Czytelnia – polecane teksty" : "Czytelnia – wyróżnione teksty";
	}
	
	elsif ($in->{data_publikacji} =~ /(\d+)[DM]/) {
		if ($in->{typ} == 1) {
			$title = "Czytelnia – nowe wiersze";
		} elsif ($in->{typ} == 2) {
			$title = "Czytelnia – nowe opowiadania";
		} elsif ($in->{typ} == 3) {
			$title = "Czytelnia – nowe dramaty";
		} else {
			$title = "Czytelnia – nowe wiersze i opowiadania";
		};
	}
	elsif ($in->{data_publikacji} =~ /(\d*)\-(\d*)/) {
		$title = "Lodówka, ".$config{full_months}[$2]." $1";
	}
	return $title;
}


sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $description = shift;

	my ($imie, $user_id, $typ, $output);

	($user_id, $imie, $typ) = Wywrota->db->quickArray(
		"SELECT user_id, autor, typ FROM $Wywrota::request->{content}{current}{'tablename'} WHERE autor_urlized = ? AND _active=1 LIMIT 0,1",
		$Wywrota::in->{autor_urlized}) if ($Wywrota::in->{autor_urlized});

	$user_id = $user_id || $Wywrota::in->{user_id};
	if ($user_id and $typ != 5) {
		my $userObj = Wywrota->content->getObject($user_id, 'User');
		$output = $userObj->recordLead() if ($userObj);
	}

	$tytul = customTitle($queryRes->{in});

	if ($Wywrota::in->{autor_urlized} eq 'julian-tuwim') {
		$description = qq|Najstarszy polski serwis kulturalny Wywrota.pl pragnie przybliżyć wszystkim użytkownikom klasykę polskiej poezji. Polecamy Wam znakomite wiersze Juliana Tuwima, którego dorobek artystyczny to znacznie więcej niż tylko popularne utwory dla dzieci. Starannie wyselekcjonowany wybór wierszy Tuwima dedykujemy szczególnie tym z Was, którzy kojarzą wybitnego poetę jedynie z zapominalskim słoniem oraz lokomotywą. Poznajcie dorobek utalentowanego klasyka, jakim był Julian Tuwim – wiersze poety możecie odczytać w dowolnej chwili online, bez konieczności udawania się do biblioteki. Dzięki zbiorowi tekstów na Wywrota.pl poznacie ociekający humorem i ironią, mistrzowski warsztat literacki jednego z naszych najlepszych twórców i rozsmakujecie się w jego poezji – serdecznie zapraszamy do lektury wierszy Tuwima!|;
	}
	if ($Wywrota::in->{autor_urlized} eq 'jan-brzechwa') {
		$description  = qq|Serwis kulturalno-społecznościowy Wywrota.pl wita wszystkich w kąciku z literaturą. Przedstawiamy Wam wiersze Jana Brzechwy – utwory adresowane do dzieci są pełne humoru, jak i posiadają walory wychowawcze. Poza poezją dla najmłodszych, Jan Brzechwa pisał też utwory satyryczne oraz poezję liryczną – na Wywrocie koncentrujemy się głównie na nastrojowych lirykach, jak i humorystycznych wierszach Jana Brzechwy. Nie musicie już udawać się do biblioteki, aby wypożyczyć tomik poezji – dzięki serwisowi Wywrota.pl możecie przeglądać wybór stu kilkudziesięciu najlepszych wierszy Brzechwy, nie odrywając się od komputera. Doceńcie dorobek naszego rodzimego klasyka, na którego utworach wychowało się wiele pokoleń Polaków, poznajcie też najpiękniejsze wiersze Jana Brzechwy adresowane do nieco starszej literackiej publiczności. Zapraszamy.|;
	}

	$output .= $self->SUPER::searchHeader($queryRes, $tytul, $description);
	
	

	return $output;

}


sub searchHeaderGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my ($cnt, $i, $after_cnt_label);
	my $href = $queryRes->param();;

	return unless ($queryRes->{cnt});
	
	
	return $self->SUPER::searchHeaderGenerate($queryRes, $tytul, $after_cnt_label);

}


sub searchFooterGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my ($cnt, $i, $after_cnt_label, $output, $label);
	my $href = $queryRes->param();;

	my $czego = Wywrota::Language::plural($queryRes->{cnt}, $queryRes->{contentDef}{keyword})
			    || Wywrota::Language::plural($queryRes->{cnt}, 'pozycja') ;


	return unless ($Wywrota::in->{count} && $queryRes->{cnt});
	
	for ($i=1; $i<6; $i++) {
		$cnt->{$i} = int( Wywrota->db->selectCount($queryRes->{_sql_query_cnt_from}, $queryRes->{_sql_query_conditions}. " AND typ=".$i)  );

		next unless $cnt->{$i};
		$after_cnt_label .= "<a href='$href,typ,$i'>" . 
			"<b>" . $cnt->{$i} . "</b>&nbsp;". Wywrota::Language::plural($cnt->{$i}, Wywrota->dict->getLabel('typ', $i, 'Literature') )
		. '</a> ';
	}
	
	if ($queryRes->in->{count} && $queryRes->{cnt}) {
		$label = $Wywrota::in->{count} if ($Wywrota::in->{count} ne '1');
		$output = qq~<div class="countLabel">$label <b>$queryRes->{cnt}</b> $czego:$after_cnt_label</div>~;
	} 


	return $output.$self->SUPER::searchFooterGenerate($queryRes, $tytul);

}

sub recordFormAdd {
# --------------------------------------------------------

	my $self = shift;
	my $object=shift;
	my ($output, $replaceDict);


	$output = qq~
		<h1>Prześlij wiersz lub opowiadanie    </h1>
		
		<div id="hint02" class="uxHint hint">
			<div class="hintMessage">
				Przed przysłaniem tekstu zapoznaj się ze wskazówkami dotyczącymi publikacji.
			</div>
			<div class="hintButtons">
				<input type="button" value="Nie teraz" onclick="closeHint('hint02');" class="grayButton">
				<input type="button" value="OK" onclick="closeHint('hint02'); window.location ='http://literatura.wywrota.pl/publikacja.html'; ">
			</div>
		</div>
	~;


	$output .= $self->recordForm($object, undef, undef, $replaceDict);

	return  $output;
}


sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	
	
	# ---- track event
	my $track = Wywrota->t->process('inc/google.analytics.event.inc', {
		category 	=> 'Literature', 
		action  	=> 'Add', 
		opt_label 	=> $object->rec->{tytul},  
		opt_value  	=> ''
	});
		
	Wywrota->sysMsg->push('Twój tekst został zapisany.'.$track, 'ok');
	$self->htmlPage($nut, $object, @_);
}


1;