package Wywrota::Object::View::UserView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Cookie;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Favorites;
use Wywrota::Language;

use Captcha::reCAPTCHA;



sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;

	$object->preProcess(1);

	my ($output,  $tego_autora, $include, $mainContent, $fanKluby, $socialLinks, $record, $bands, $icons, $id, $groups, $notkaRed, $editicons, $icons);

	return Wywrota->errorPage("Nie znaleziono użytkownika w bazie.") if (!$object || !$rec->{id});

	
	
	# message if no active photo 
	if (!length($rec->{_image_filename}) && $object->id == $Wywrota::session->{user}{id}) {
		my $sex = ($rec->{val}{plec} == 1) ? ('aś') : ('eś');
		Wywrota->sysMsg->push("Nie przesłał$sex jeszcze zdjęcia do swojego profilu. <a href='/db/site_images/add=1,typ=1'>Zrób to teraz!</a>", 'tip');
	}

	$rec->{premium_until} = Wywrota->mng('PremiumAccount')->validUntil($rec->{id});
	$rec->{premium_until} = normalnaData($rec->{premium_until}, 0, 1) if ($rec->{premium_until});
	$rec->{premium_until} = "końca świata" if ($rec->{_is_premium} && !$rec->{premium_until});


	$rec->{imie} .= " - " if ($rec->{real_name} );

	if (Wywrota->per('admin')) {
		$rec->{comments} =    Wywrota->db->selectCount('komentarze', "user_id=$rec->{id} AND _active=1");
		$rec->{comments_1M} = Wywrota->db->selectCount('komentarze', "user_id=$rec->{id} AND _active=1 AND data "
			. " BETWEEN " . Wywrota->db->quote( getDate(time() - 2592000) ) 
			. " AND " . Wywrota->db->quote( getDate(time()) ) );
	};

	$tego_autora = ($rec->{val}{plec} == 1) ? ("autorki") : ("autora");
	my $_a = ($rec->{val}{plec}==1) ? "a" : "y";


	# ----------------------------------------------------------
	# social links - fan kluby, wspolnoty, znajomi


		$fanKluby = Wywrota::Object::Band::getBands($rec->{id}) if ($rec->{id});

		$socialLinks = Wywrota::Controller::includePage("db=ludzie&favorites=list&user_id=$rec->{'id'}&count=1&small=1&mh=8&quiet=1", "12h");

		$socialLinks .= qq~<div class="fanKlubyDiv">~;
		if ($#$fanKluby >= 0) {
			foreach $record ( @$fanKluby ) {
				$bands .=  qq~ <a href="/wykonawcy/$record->{wykonawca_urlized}.htm" class="band">$record->{wykonawca}</a>,~;
			}
			chop($bands);
			$socialLinks .= qq~<h2 class="yellow">fan-kluby:</h2> $bands~;
		} else {
			$socialLinks .= qq~<div class="div_msg_tip_sm">Nie jest członkiem żadnego fan-klubu.</div>~;
		}

		# wspolnoty
		$socialLinks .= Wywrota::Controller::includePage("db=group&favorites=list&count=1&small=1&mh=20&user_id=$rec->{'id'}&quiet=1", "12h");

		$socialLinks .= qq~</div>~;



	# ----------------------------------------------------------
	# ikonki

		my $photoCnt = Wywrota->db->selectCount('site_images', "user_id=$rec->{id} AND typ=1 AND _active=1");

		$icons = qq~
			<a href="/ludzie/$rec->{'wywrotid'}/photos" class="photosPage">zdjęcia</a>
		~;

		if ($Wywrota::session->{user}{id} == $rec->{id} ) {
			
			$icons .= qq|<a href="/db/ludzie/modify/$rec->{'id'}" class="editProfile">edytuj swój profil</a>|;
			
		} elsif ($Wywrota::session->{user}{id}) {
			$icons .= qq~
				<a href="/message/send/id/$rec->{id}" class=" sendmsg fancyIframe">wyślij wiadomość</a>
			~;

			if ( Wywrota->fav->isInFavorites($rec->{id} ) ) {
				$icons .= qq~
					<a href="/db/$Wywrota::request->{content}{current}{url}/favorites/remove/id/$rec->{id}" class="invite isFriend">zerwij znajomość</a>~;
			} elsif ($rec->{id}  ) {
				$icons .= qq~
					<a href="/db/$Wywrota::request->{content}{current}{url}/favorites/add/id/$rec->{id}" class="invite">dodaj do listy znajomych</a>~;
			} 

			$icons .= qq~<a href="/db/premium/add/1/user_id/$rec->{id}" class="premium">przydziel konto premium</a>~ 
				if (!$rec->{_is_premium} && ( Wywrota->per('admin') || Wywrota->mng('PremiumAccount')->hasCredits() ) );
		} else {
			$icons .= qq~
				<a href="#" class=" sendmsg inact">wyślij wiadomość</a>
				<a href="#" class="invite inact">dodaj do listy znajomych</a>
				~;
		}

		$icons = qq~
			<div id="icons">$icons</div>		
			~;
		$icons = '' if ($Wywrota::session->{'googlebot'});

		$editicons .= qq~<a href="/db/ludzie/modify/$rec->{'id'}" class="arMod">edycja danych</a>~ 
			if ( ($Wywrota::session->{user}{id} eq $rec->{user_id} && $rec->{stan} == 1) ||  Wywrota->per('admin') );

		if ($Wywrota::session->{user}{id} == $rec->{id} ) {
			$editicons .= qq~
				<a class="arDel" href="javascript: if (confirm('Ta operacja jest nieodwracalna!\\nCzy jestes pewien, że chcesz skasować swoje konto?')) window.location='/user/suicide' " rel="nofollow">usuń moje konto</a>
			~;
		} elsif ( Wywrota->per('admin') ) {
			$editicons .= qq~
				<a href="javascript: if (confirm('Na pewno chcesz usunąć konto tego użytkownika?')) window.location='/db/ludzie/deleterecords=1,id=$rec->{'id'}';" class="arDel">usuń konto</a>
				~;
		}
			
		$editicons .= qq~
			<a href="/admin/assignGroups/$rec->{'id'}" class="arLudki">grupy użytkownika</a>
		~ if ( Wywrota->per('admin') );
		
		$editicons = qq~
			<div class="editNavSm">$editicons</div>
			~ if ($editicons);
		$editicons  = '' if ($Wywrota::session->{'googlebot'});


	# ----------------------------------------------------------
	# grupy uzytkownikow i notka redakcyjna

		$groups = Wywrota->mng('UserGroup')->readUserGroups($rec->{id});
		if (keys %{$groups} ) {
			$notkaRed .= qq~<br><br>~ if (length($rec->{notka}));
			foreach (sort ({$groups->{$a}{sortorder} <=> $groups->{$b}{sortorder}} keys %{$groups})) {
				next if ( $_ == 100 && !Wywrota->per('admin'));	# super admin
				$notkaRed .= qq~<div class="ugroup ugroup_$_">$groups->{$_}{nazwa}</div>~;
				
			}

			$notkaRed .= qq~<br class="clr">~;
		}

		if ($rec->{_is_premium}) {
			$notkaRed .= qq~
				<div class="premiumAccount">
					<a href="/premium.html">konto Wywrota premium</a><br>
			~;
			$notkaRed .= qq~aktywne do $rec->{premium_until}~;
			$notkaRed .= qq~
				</div>
				<br class="clr">
			~ ;
		}


		$notkaRed = $rec->{notka}.$notkaRed;
		if (length($notkaRed)) {
			$notkaRed = qq~<div class="notka">$notkaRed</div>~;
		}




	# ----------------------------------------------------------
	# main content


		$include = Wywrota::Controller::includePage("db=image&mh=9&sb=data_przyslania&so=descend&user_id=$rec->{'id'}&count=1", "2h");
		if (length(trim($include)) > 20) {
			$mainContent .= "<h2 class='blue'>Prace w galerii</h2>" . $include . "<br class='clr'>";
		}

		$include = Wywrota::Controller::includePage("db=literatura&mh=5&sb=data_przyslania&so=descend&user_id=$rec->{'id'}&typ-not=5&count=1", "2h");
		if (length(trim($include)) > 20) {
			$mainContent .= "<h2 class='orange'>Teksty $tego_autora</h2>". $include . "<br>";
		}

		$include = Wywrota::Controller::includePage("db=artykuly&mh=5&sb=data_przyslania&so=descend&user_id=$rec->{'id'}&count=1&stan=2&category-gt=1", "2h");
		if (length(trim($include)) > 20) {
			$mainContent .= "<h2 class='red'>Artykuły</h2><div class='padded'>" . $include . "</div><br>";
		}

		$include = Wywrota::Controller::includePage("db=artykuly&mh=10&sb=data_przyslania&so=descend&user_id=$rec->{'id'}&stan=2&category=1&small=1", "2h");
		if (length(trim($include)) > 20) {
			$mainContent .= "<h2 class='red'>Newsy</h2><div class='padded'>" . $include . "</div><br>";
		}

		$include = Wywrota::Controller::includePage("db=mp3&mh=5&sb=data_przyslania&so=descend&user_id=$rec->{'id'}&small=1&count=1", "2h");
		if (length(trim($include)) > 20) {
			$mainContent .= "<h2 class='yellow'>Nagrania MP3</h2>" . $include . "<br>";
		}

		$include = Wywrota::Controller::includePage("db=spiewnik&mh=5&sb=data_przyslania&so=descend&user_id=$rec->{'id'}&count=1", "2h");
		if (length(trim($include)) > 20) {
			$mainContent .= "<h2 class='yellow'>Teksty przysłane do śpiewnika</h2>" . $include . "<br>";
		}


		if (!$mainContent) {
			$mainContent = $socialLinks;
			$socialLinks = "";
		}



	# ----------------------------------------------------------
	# generowanie strony

	
	$output .= qq~

			<div id="profileTop">

				<div class="floatLeft">
					$rec->{photo}
					<div class="clr"></div>
					$icons
				</div>
				

				<div class="nameDiv">$rec->{'imie'} $rec->{real_name} </div>
				<div class="function">$rec->{'function'} </div>

				<table>
					~; 
					$output .= qq~<tr><td class="cou">user.id.............</td><td class="cou">$rec->{'id'}</td></tr>~ if Wywrota->per('admin');
					$output .= qq~<tr><td class="cou">wiek................</td><td class="cou">$rec->{'wiek'}</td></tr>~ if $rec->{'wiek'};
					$output .= qq~<tr><td class="cou">skąd................</td><td class="cou">$rec->{'skad'}</td></tr>~ if ($rec->{'skad'});
					$output .= qq~<tr><td class="cou">na Wywrocie od......</td><td class="cou">$rec->{data_wpisu}</td></tr>~ if $rec->{data_wpisu};
					$output .= qq~<tr><td class="cou">ostatnio widzian$_a...</td><td class="cou">$rec->{last_login}</td></tr>~ if ($rec->{last_login} && $rec->{'id'}>1);
					$output .= qq~<tr><td class="cou">komentarze..........</td><td class="cou">
									<a href="http://www.wywrota.pl/db/komentarze/sb/id/so/descend/user_id/$rec->{id}">wszystkich (<b>$rec->{comments}</b>)</a>
									<a href="http://www.wywrota.pl/db/komentarze/sb/id/so/descend/data/1M/user_id/$rec->{id}">w tym miesiącu (<b>$rec->{comments_1M})</b></a>
								</td></tr>~ if ($rec->{comments});

					$output .= qq~
					<tr><td class="groups" colspan="2">
						$notkaRed					
					</td>
				</table>


			</div>

			<div class="clr"></div>
			
			<div id="profileData">
			
				
				~;
				

				$output .= qq~		
						<div class="hd">przesłanie dla świata</div>
						<div>$rec->{przeslanie}</div>~ if $rec->{przeslanie};

				$output .= qq~		
						<div class="hd">zainteresowania</div>
						<div>$rec->{zainteresowania}</div>~ if $rec->{zainteresowania};

				$output .= qq~		
						<div class="hd">co kocha, co&nbsp;jest najważniejsze</div>
						<div>$rec->{co_kocha}</div>~ if $rec->{co_kocha};

				$output .= qq~		
						<div class="hd">ulubiony kolor</div>
						<div>$rec->{ulubiony_kolor}</div>~ if $rec->{ulubiony_kolor};

				$output .= qq~		
						<div class="hd">w przyszłości będzie</div>
						<div>$rec->{w_przyszlosci_bedzie}</div>~ if $rec->{w_przyszlosci_bedzie};

				$output .= qq~		<div class="hd">kilka słów o&nbsp;sobie</div>
						<div>$rec->{o_sobie}</div>~ if $rec->{o_sobie};

				$output .= $socialLinks;

				$output .= Wywrota->fav->favListTable($rec->{id});

			$output .= qq~		</div>~;
					


	$output .= qq~
		<div id="profileLinks">
			$mainContent
		</div>

		$editicons
		
	~;

	$output .= _administrationBar($object);
		
	return Wywrota->t->wrapHeaderFooter({
			title => "$rec->{'imie'}  $rec->{real_name} [$rec->{'wywrotid'}] – akta wywroty",	
			nomenu=>  3,	
			meta_desc=> "$rec->{'imie'}  $rec->{real_name}",	
			meta_key=> "$rec->{'imie'}, $rec->{'wywrotid'}",
			canonical=> $rec->{url},
			nobillboard => 1,
			output		=>	"<div id='centerDiv' class='userPageDiv'> $output </div>"
	});


}




sub _administrationBar {
# --------------------------------------------------------

	my $object = shift;
	my $rec = $object->rec if ($object);
	my $output;

	return if (!Wywrota->per('admin'));
	return if ($Wywrota::session->{'googlebot'});

	$rec->{action_log} = Wywrota::Log::getUserActionLogHTML($rec->{id});

	$output .= qq~

	<br class="clr">
	<h3 class="gray">administracja</h3>

	<div class="padded">

	<form action="/db" method="POST" name="record_form">
		<input type="hidden" name="db" value="ludzie">
		<input type="hidden" name="id" value="$rec->{id}">

		<label class="formLabel">Imię&nbsp;i&nbsp;nazwisko</label>
		<input name="real_name" value="$rec->{real_name}" class="inputWide">

		<label class="formLabel">Funkcja w serwisie</label>
		<input name="function" value="$rec->{function}" class="inputWide">

		<label class="formLabel">Notka redakcyjna</label>
		<textarea name="notka" class="inputXWide" rows="5">$rec->{notka}</textarea><br>
		<input type="submit" name="modifyrecord" value="zapisz" class="bold">
	</form>
	<br>

	~;


	$output .= qq~		<span class="hd r">login</span>
			<span>$rec->{wywrotid}</span>~ if $rec->{wywrotid};
	$output .= qq~		<span class="hd r">hasło</span>
			<span>$rec->{haslo}</span>~ if $rec->{haslo};
	$output .= qq~		<span class="hd r">Email</span>
			<span>$rec->{email}</span>~ if $rec->{email};

	$output .= qq~		<br><span class="hd r">pytanie</span>
			<span>$rec->{pytanie}</span>~ if $rec->{pytanie};
	$output .= qq~		<span class="hd r">odpowiedź</span>
			<span>$rec->{odpowiedz}</span>~ if $rec->{odpowiedz};		
	
	
	$output .= "<br>";

	$output .= qq~		<span class="hd r">opinia o stronie</span>
			<span>$rec->{opinia_o_stronie}</span>~ if $rec->{opinia_o_stronie};
	$output .= qq~		<span class="hd r">jak trafił</span>
			<span>$rec->{jak_trafil}</span>~ if $rec->{jak_trafil};

	$output .= qq~ <span class="hd r">adres:</span> $rec->{'adres'}~ if ($rec->{'adres'});

	
	$output .= $rec->{action_log};
	
	$output .= qq~ </div>~ ;

	return $output;


}




sub recordFormAdd {
# --------------------------------------------------------
	my $output;
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;

	my $captcha = Captcha::reCAPTCHA->new;
	
	return Wywrota->t->process('object/user_form_add.html', {
		recordForm =>	$self->recordForm($object),
		captcha => $captcha->get_html_v2( $config{recaptcha_public_key} )
	});
	
	
}


sub recordForm {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;

	my $rec = $object->rec;
	my ($output, $sex, $referer);


	#my $confirmation = readConfirmationData($rec->{'id'});

	$sex->{ $rec->{plec} } = ' checked="checked"';

	if (!$Wywrota::in->{_referer}) {
		$referer = $ENV{HTTP_REFERER};
	} else {
		$referer = $Wywrota::in->{_referer}
	}

$output .= qq~
<div class="registerForm">
<script type="text/javascript">
<!--
	function checkForm(formObj) {
		checkAvailability();
		if (!validrequired(formObj.imie,"Nie podałeś swojego imienia.")) return false;
		if (!validrequired(formObj.plec,"Wybierz swoją płeć.")) return false;
		if (!validrequired(formObj.rok_urodzenia,"Podaj swój rok urodzenia. (np. 1989)")) return false;
		if (!validNum(formObj.rok_urodzenia,"Zły format danych dla roku urodzenia.")) return false;
		
		if (formObj.rok_urodzenia.value <1900 ) {showpoperror( formObj.rok_urodzenia, "Niepoprawny format roku urodzenia. Wpisz pełny rok, np. 1982."); formObj.focus(); return false;}
		if (!validrequired(formObj.skad,"Napisz skąd jesteś.")) return false;
		if (!validrequired(formObj.email,"Podaj swój adres e-mail.")) return false;
		if (!validEmail(formObj.email,"Podaj poprawny adres e-mail.")) return false;
//		if (!validrequired(formObj.przeslanie,"Podaj przesłanie dla świata.")) return false;

	~; 
		if (!($Wywrota::in->{modify} || $Wywrota::in->{modifyrecord} )) { $output .= qq~

		if (!validrequired(formObj.wywrotid,"Podaj swój WywrotID.")) return false;
		if (!validAlphanumeric(formObj.wywrotid, "WywrotID nie może zawierać spacji, polskich liter ani znaków specjalnych.")) return false;
		if (!wywrotid_valid) {
			showpoperror(formObj.wywrotid, "Ten login jest już zajęty."); return false;
		}
		
		if (!validrequired(formObj.haslo,"Podaj hasło.")) return false;
//		if (!validrequired(formObj.haslo_confirm,"powtórz hasło.")) return false;
//		if (!validrequired(formObj.akceptuj,"Musisz zaakceptować regulamin aby się zarejestrować.")) return false;

//		if (formObj.haslo.value != formObj.haslo_confirm.value) {
//			showpoperror(formObj.haslo, "Wpisane hasła nie zgadzają się."); return false;
//		}

	~; } $output .= qq~
		return true;
	}

//-->
</script>

		<input type="hidden" name="contest_id" value="$Wywrota::in->{contest_id}">
		<input type="hidden" name="_referer" value="$referer">
		<input type="hidden" name="_registernewuser" value="1">
		<input type="hidden" name="id" value="$rec->{'id'}">
		<input type="hidden" name="data_wpisu" value="$rec->{'data_wpisu'}">



			<div class="formLabel required">Imię i nazwisko lub pseudonim</div>
			<div class="formInput">
				<input name="imie" value="$rec->{imie}" class="inputWide">
			</div>


			<div class="formLabel required">Płeć</div>
			<div class="formInput">
				<input type="radio" name="plec" value="1" id="1" $sex->{1}><label for="1">kobieta</label> 
				<input type="radio" name="plec" value="2" id="2" $sex->{2}><label for="2">mężczyzna</label> 
				<input type="radio" name="plec" value="3" id="3" $sex->{3}><label for="3">inne</label> 
			</div>

			<div class="formLabel required">Rok urodzenia</div>
			<div class="formInput">
				<input name="rok_urodzenia" value="$rec->{rok_urodzenia}" class="inputSm" maxlength="4"> np. 1989
			</div>


			<div class="formLabel required">Skąd jesteś</div>
			<div class="formInput">
				<input name="skad" value="$rec->{skad}" class="inputWide">
			</div>


			<div class="formLabel required">Adres e-mail</div>
			<div class="formInput">
				<input name="email" value="$rec->{email}" class="inputWide">
			</div>


			<div class="formLabel">Przesłanie dla świata</div>
			<div class="formInput">
				<textarea name="przeslanie" rows="4" class="inputWide">$rec->{przeslanie}</textarea>
			</div>

		<fieldset class="collapsible collapsed"> 
			<legend>informacje profilowe</legend> 

			<!--
			<div class="formLabel">Strona www</div>
			<div class="formInput">
				<input name="adres_www" value="$rec->{adres_www}" class="inputWide">
			</div>
			-->


			<div class="formLabel">Numer gadu-gadu</div>
			<div class="formInput">
				<input name="gg" value="$rec->{gg}" class="inputSm" maxlength="8">
			</div>



			<div class="formLabel">Ulubiony kolor</div>
			<div class="formInput">
				<input class="inputWide" name="ulubiony_kolor" value="$rec->{ulubiony_kolor}">
			</div>


			<div class="formLabel">Kim chciał(a)byś zostać w&nbsp;przyszłości?</div>
			<div class="formInput">
				<input class="inputWide" name="w_przyszlosci_bedzie" value="$rec->{w_przyszlosci_bedzie}">
			</div>


			<div class="formLabel">Kilka słów o sobie</div>
			<div class="formInput">
				<textarea name="o_sobie" rows="4" class="inputWide">$rec->{o_sobie}</textarea>
			</div>


			<div class="formLabel">Co kochasz? Co jest dla Ciebie najważniejsze?</div>
			<div class="formInput">
				<textarea name="co_kocha" rows="4" class="inputWide">$rec->{co_kocha}</textarea>
			</div>
		</fieldset>


		<fieldset class="collapsible collapsed"> 
			<legend>informacje dla redakcji</legend> 


			<div class="formLabel">Adres korespondencyjny</div>	
			<div class="formInput">
				<textarea name="adres" class="inputWide" rows="4">$rec->{adres}</textarea>
				<div class="txtnews">adres tylko do wiadomości redakcji<br>przyda się, gdy będziemy wysyłać nagrody.</div>
			</div>

		</fieldset>


	~;
		

	if (! ($Wywrota::in->{modify} || $Wywrota::in->{modifyrecord} )) {

		$output .= qq~

		<br class="clr">

		<div class="loginData">

			<div class="ld1">
				<label class="formLabel required">login</label>
				<input type="text" class="inputSm wywrotidInput" name="wywrotid" value="$rec->{wywrotid}" id="wywrotid"><em id="baduser"></em>
				<div class="tipcomment">Twój identyfikator - tylko małe litery, bez spacji, polskich liter ani znaków specjalnych.</div>
			</div>

			<div class="ld2">



				
				 <script type="text/javascript">

        function pwdBlur() {
        	var v = \$('#passwordinput').attr('value');
            \$('#passwordinputtext').attr('value', v);
            
        }
        
         function pwdTextBlur() {           
        	var v = \$('#passwordinputtext').attr('value');
            \$('#passwordinput').attr('value', v);
        }
    </script>





				<label class="formLabel required">Hasło</label>
				<input class="wywrotidInput inputSm" type="text" name="haslo" value="$rec->{haslo}" id="passwordinputtext" style="display: none" onblur="pwdTextBlur()">
				<input class="wywrotidInput inputSm" type="password" name="haslo" value="$rec->{haslo}" id="passwordinput" onblur="pwdBlur()">
				
				<br class="clr"/>
				

				

				<label class="formLabel">&nbsp;</label>
				<input type="checkbox" name="show_pass" id="show_pass"><label for="show_pass">pokaż znaki</label> 
				
				<script>
				\$("#show_pass").change(function() {
				  if (\$(this).attr("checked")) {
  					   \$("#passwordinputtext").show();
  					   \$("#passwordinput").hide();
				  }	else {
				     \$("#passwordinputtext").hide();
  					   \$("#passwordinput").show();
				  }
				});
				
				</script>

			</div>


			<div class="ld3">
				<div class="tipcomment">
					Jeśli zapomnisz hasło będziesz mógł je odzysjać podając właściwą odpowiedź na pytanie. 
				</div>

				<label class="formLabel">Pytanie</label>
				<input type="text" name="pytanie" class="inputMd" value="$rec->{pytanie}">
				<br class="clrl"/>

				<label class="formLabel">Odpowiedź</label>
				<input type="text" name="odpowiedz" class="inputMd" value="$rec->{odpowiedz}">

			</div>

		</div>
		~; 
	}
 $output .= "</div>";


	return $output;
}




sub viewPhotos {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my ($rec, $output, $back, $photos);


	return Wywrota->errorPage("Nieznany użytkownik") if (!$object);
	
	$rec = $object->rec;

	
	$output = $object->recordLead() . 
		qq~
		<h2>Galeria zdjęć</h2>
		~;

	$output .= qq~<br class="clr"><a class="addIcon" href="/db/site_images/add=1,typ=1">prześlij zdjęcie</a><br><br>~
		if ($Wywrota::session->{user}{id} eq $rec->{id} || Wywrota->per('admin'));

	$photos = Wywrota::Controller::includePage("db=site_images&user_id=$rec->{id}&icons=1&typ=1&stan=1");

	if (length($photos)>20) {
		$output .=  $photos;
	} else {
		$output .=  qq~<div class="div_msg_tip">Nie przesłałeś jeszcze żadnych zdjęć do naszego serwisu.</div>~;
	}



	return $self->wrapHeaderFooter({
			title => "zdjęcia: $rec->{'imie'} [$rec->{'wywrotid'}]",	
			nomenu=> "bar",
			output=> $output
	});
}





#####################################



sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $output;


	eval {
		$nut->session->openSession();;
		$Wywrota::session = $nut->session->state();
	};
	Wywrota->error("UserView :: addSuccess", $@) if ($@);

	#Wywrota->sysMsg->push('Dziękujemy. Twoje konto zostało utworzone.', 'ok');
	#return $self->htmlPage($nut, $object);

	$output = qq~
		<h1>Dziękujemy</h1>

		<div class="div_msg_ok">Twoje konto zostało utworzone.</div>

		<ul class="arrows">
			<li class="add"><a href="/db/site_images/add=1,typ=1">dodaj zdjęcie do swoich akt</a></li>
			<!-- <li><a href="$Wywrota::in->{_referer}">kontynuuj</a></li> 
			<li><a href="/">moja Wywrota</a></li>-->
		</ul>
		
		
				
				
		<!-- Google Code for rejestracja Conversion Page -->
		<script type="text/javascript">
		/* <![CDATA[ */
		var google_conversion_id = 1067114098;
		var google_conversion_language = "en";
		var google_conversion_format = "3";
		var google_conversion_color = "ffffff";
		var google_conversion_label = "XBXpCIalzQQQ8rzr_AM";
		var google_conversion_value = 1;
		/* ]]> */
		</script>
		<script type="text/javascript" src="//www.googleadservices.com/pagead/conversion.js">
		</script>
		<noscript>
		<div style="display:inline;">
		<img height="1" width="1" style="border-style:none;" alt="" src="//www.googleadservices.com/pagead/conversion/1067114098/?value=1&amp;label=XBXpCIalzQQQ8rzr_AM&amp;guid=ON&amp;script=0"/>
		</div>
		</noscript>		
		
		
	~;
	
	
	# ---- track event
	$output .= Wywrota->t->process('inc/google.analytics.event.inc', {
		category 	=> 'User', 
		action  	=> 'Register', 
		opt_label 	=> $object->rec->{wywrotid},  
		opt_value  	=> ''
	});
		
	

	return $self->wrapHeaderFooter({
			title => $Wywrota::request->{content}{current}{title}." - dziękujemy!",	
			nomenu=>  'nomenu',
			output => $output
	});
	
}


sub searchFooter {
# --------------------------------------------------------
	my $self=shift;
	my $output = $self->SUPER::searchFooter(@_);

	my $queryRes = shift;
	my $tytul = shift;

	
	return  qq~ 
		<br class="clr">
		$output 
	~;
	
}


sub header {
# --------------------------------------------------------
	my $self = shift;
	my ($output);
	my $param=shift;
	$param->{nomenu}='bar';
	$param->{nobillboard}='1';



	$output = $self->SUPER::header($param);

	if (!$Wywrota::in->{view} && !$Wywrota::in->{modifyrecord} && !$Wywrota::in->{add}) {
		$output .= qq~
			<link rel="stylesheet" href="/css/moja.css" type="text/css">

			<div id="userpageWide">
		~;	
	} else {
		$output .= qq~<div id="centerDiv">~;
	}

	return $output;
}

sub footer {
# --------------------------------------------------------
	my $self = shift;
	my ($output);

	$output .= qq~</div>~;
	$output .= $self->SUPER::footer();

	return $output;
}


1;