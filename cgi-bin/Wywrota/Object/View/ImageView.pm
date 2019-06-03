package Wywrota::Object::View::ImageView;

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
use Wywrota::View::Navigation;




sub header {
# -------------------------------------------------------------------------------------

	my $self=shift;
	my $param=shift;
	my $old_nomenu = $param->{nomenu};
	$param->{nomenu}=3;
	

	my ($output, $name);

	my $typ = Wywrota->dict->getLabel('typ', $Wywrota::in->{typ}) if ($Wywrota::in->{typ});

	$param->{title} = Wywrota->dict->getLabel('typ', $Wywrota::in->{typ}) ." ".	$param->{title}			if ($Wywrota::in->{typ});
	$param->{title} = Wywrota->dict->getLabel('temat', $Wywrota::in->{temat}) ." ". $param->{title}		if ($Wywrota::in->{temat});



	if ($Wywrota::in->{user_id}) {
		if (!$Wywrota::in->{typ}) {
			$param->{title} = "galeria prac";
		}
	}

	$output = $self->SUPER::header($param);
	return $output if ($Wywrota::in->{generate});

	
	
	$output .= qq~
		<div id="navigation">
			~. Wywrota->nav->bigLinks() .qq~
			<br class="clr">
		</div>
	~;
		
	$output .= qq~

		<div id="columnRight">

			<!-- right column  -->
			<h4><a href="/db/image/ca,topRecords,data_publikacji,1M">Popularne</a></h4>
			<div>
			~. Wywrota::Controller::includePage("db=image&ca=topRecords&mh=4&small=1&data_publikacji=1M&generate=1&suffix=px&nomore=1", "3h") . qq~<br>

			</div>		
			<h4><a href="/db/image/data_publikacji,30D,stan,2">Najnowsze prace</a></h4>
			<div>
			~. Wywrota::Controller::includePage("db=image&generate=1&random=1&mh=8&stan=2&small=1&suffix=px&data_publikacji=30D&nomore=1", "10m") . qq~
				
				
			</div>
			
			
			<br><br>
			<h4>$typ</h4>
			<div class="tagCloud" >
					~. Wywrota->cListEngine->countTypes('temat', $Wywrota::in->{typ}) . qq~
			</div><br>

		</div>	
		<div id="mainContentWide">
	~ if (!$old_nomenu);

	$Wywrota::request->{nomenu} = $old_nomenu;

	return $output;

}




sub footer {
# -------------------------------------------------------------------------------------
	my $self=shift;
	my $output;
	return "" if ($Wywrota::in->{generate});

	$output = qq~
		</div><!-- mainContentWide END -->
	~ if (!$Wywrota::request->{nomenu});

	$output .= $self->SUPER::footer();
	return $output;
}





sub searchHeader {
# --------------------------------------------------------
	my $self=shift;
	my ($output, $name, $baseHeader  );

	my $queryRes = shift;
	my $tytul = shift;

	$baseHeader = $self->SUPER::searchHeader($queryRes, $tytul );	

	if ($Wywrota::in->{user_id}) {
		my $userObj = Wywrota->content->getObject($Wywrota::in->{user_id}, 'User');
		$output = qq~<h1>$name</h1>~ . $userObj->recordLead();
	}
	$output = qq~<h1>$tytul</h1>~ if ($Wywrota::in->{favorites});

	$output = qq~
		$output
		$baseHeader
		<br class="clrl">
	~;
	return $output;
}





sub recordFormAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($output);

	$output = qq~
	<style type="text/css">
		#mainContent h1 {display: none;}
		#mainContent form h1 {display: block;}
	</style>
	<h1>Prześlij zdjęcie / pracę do galerii</h1>
	~;

	$output .= Wywrota::Forms::buildHtmlRecordForm($object, @_);
	return $output ;
}







sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;
	$object->preProcess(1);
	
	my $userObj = Wywrota->content->getObject($rec->{user_id}, 'User')->preProcess;

	# ---- generate output 
	my $output = Wywrota->t->process('object/image_page.html', {
		rec				=>	$rec,
		obj 			=>	$object,
		user_photo		=>	$userObj->record(),
		other_items		=>	Wywrota::Controller::includePage("db=image&generate=1&mh=8&random=1&user_id=$rec->{'user_id'}&id-not=$rec->{id}&small=1&suffix=px", "12h"),
		by_type_works 	=>	Wywrota::Controller::includePage("db=image&generate=1&mh=12&random=1&small=1&suffix=px&typ=$rec->{val}{typ}&temat=$rec->{val}{temat}&nomore=1", "3h"),
		actions_log		=>	Wywrota::Log::getActionLog($object->id, $object->cid)
	});
	
	
	
	return $self->wrapHeaderFooter({
		title		=> "$rec->{podpis} - $rec->{ludzie_imie}", 
		meta_desc	=> "$rec->{komentarz} $rec->{typ} pod tytułem $rec->{podpis} - $rec->{ludzie_imie}" ,	
		meta_key	=> $rec->{typ}.",".$rec->{ludzie_imie},
		canonical	=> $rec->{url},
		nomenu		=>  3,
		nobillboard => 1,
		image		=> $config{'file_server'} . "/pliki/image/" . $rec->{plik} . "-lg",
		output		=> $output
	});
}







sub hpPolecamy {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;

	my ($output);

	my $url = $rec->{uri};

	$output = qq~

	<div id="hpPolecamy">

		<div style="background: url('/pliki/image/$rec->{plik}-med') no-repeat center center;" id="picSrc">
			<a href="$url" class="big"><img src="/gfx/px.gif"></a>
		</div>
		<div id="picInfoBg">
			&nbsp;
		</div>
		<div id="picInfo">
			<span class="wyroznienie">wyróżnienie redakcji</span>
			$rec->{photo}
			<h2>$rec->{podpis}</h2>
			<b>$rec->{ludzie_imie}</b> $rec->{data_przyslania}
		</div>
		
	</div>

	~;
	return $output;
}





sub displayDzial {
# --------------------------------------------------------
# generuje strone działu 
# - najnowsze prace, wyroznione prace
# - autorow poukladanych alfabetycznie
# 
	
	my $self = shift;
	my $output = "";
	my ($column,$where,$czego, $rec ,$url, $year);
	my $wszystkie=0;
	my $first=1;
	my $query;

	return if (!$Wywrota::in->{typ});

	my $includeLatest = Wywrota::Controller::includePage("db=image&generate=1&mh=12&typ=$Wywrota::in->{typ}&sb=data_przyslania&so=descend&stan=2", "1h");
	my $includePolecamy = Wywrota::Controller::includePage("db=image&generate=1&mh=1&typ=$Wywrota::in->{typ}&sb=data_przyslania&so=descend&stan=2&wyroznienie-gt=0&nomore=1&suffix=s1", "6h");
	my $includeCategories = Wywrota->cListEngine->countTypes('temat', $Wywrota::in->{typ});


	$output .= qq~

		<div id="columnLeft">

			<div style="margin-right: 30px;">
			$includePolecamy 
			</div>

			<br class="clr">

			<h3>Kategorie</h3>
			$includeCategories 
		</div>

		<div id="mainContent">

			<h3>Najnowsze prace</h3>
			$includeLatest
			<br class="clr">

		</div>	
		
	~;

	$output = $self->header({
			title =>  "",	nomenu=>  3,	meta_desc=>  "" 
	}) . $output;
	$output .= $self->footer();
	return $output;


}


sub printAutorzy {
# --------------------------------------------------------
	
	my $self = shift;
	my ($column,$where,$czego, $rec ,$url, $year);
	my $wszystkie=0;
	my $first=1;
	my $query;
	my $output;

	$output .= "<h3>Autorzy</h3>";

	# actual listing here
	foreach $column (keys %{$Wywrota::request->{content}{current}{cfg}}) {
		if ($Wywrota::in->{$column} !~ /^\s*$/) { 
			$where .= " AND " if !$first;
			$where .= " rec.$column='$Wywrota::in->{$column}' ";
			$url .= "/".$column."/".urlencode($Wywrota::in->{$column});
			$first=0;
		}
	}

	$query = qq~
	SELECT
       	sort.user_id, sort.cnt,
       	rec.plik,
       	ludzie.imie as ludzie_imie, ludzie.wywrotid as wywrotid, ludzie._grupy as _user_to_ugroup, ludzie._image_filename as _ludzie_photo,
       	ludzie.skad as _ludzie_skad, ludzie.rok_urodzenia as _ludzie_rok
       	FROM images_max sort 
		LEFT JOIN $Wywrota::request->{content}{current}{tablename} rec on sort.max_id=rec.id
       	RIGHT JOIN ludzie ON rec.user_id=ludzie.id
       	WHERE $where AND cnt >1 ORDER by ludzie.imie~;

	my $sth = Wywrota->db->execQuery($query) or return; 
	while ( $rec = $sth->fetchrow_hashref() ) { 
		$czego=Wywrota::Language::plural($rec->{cnt}, $Wywrota::request->{content}{current}{keyword});
		if ($rec->{_ludzie_rok}) {
			($_, $_, $_, $_, $_, $year) = localtime(time());
			$rec->{wiek} = 1900+$year - $rec->{_ludzie_rok};
			$rec->{wiek} = ", $rec->{wiek} ". plural($rec->{wiek}, 'rok') if $rec->{wiek};
			$rec->{wiek} = "" if (!$rec->{_ludzie_rok});
		}
		$rec->{_ludzie_skad} = cutTextTo($rec->{_ludzie_skad}, 20);
		$rec->{ludzie_imie} = cutTextTo($rec->{ludzie_imie}, 20);

		$output .= qq~ 
		<div class="authorIntro">
		<a href="/db/$Wywrota::request->{content}{current}{url}$url/user_id/$rec->{user_id}"><img src="/pliki/image/$rec->{plik}-px"></a>
		<a href="/db/$Wywrota::request->{content}{current}{url}$url/user_id/$rec->{user_id}" class="name">$rec->{ludzie_imie}</a>
		<span class="additional">$rec->{_ludzie_skad}$rec->{wiek}</span>
		<br>
		$rec->{cnt} $czego 
		</div>

		~;

	}
	$sth->finish;


}

1;