package Wywrota::Object::View::MP3View;

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

use MP3::Tag;



sub recordFormAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($output, $fileName, $file, $mp3);

	#my $cnt = Wywrota->db->selectCount($Wywrota::request->{content}{current}{tablename}, "user_id=$Wywrota::session->{user}{id} AND substr(data_przyslania,1,10) = substr(NOW(),1,10) AND _active=1");
	#
	#if ($cnt and !Wywrota->per('admin')) {
	#	$output .= Wywrota->errorMsg("Dzisiaj już wysłałeś jedno nagranie.");
	#	$output .= qq~<style type="text/css">.bold {display: none;}</style>~;
	#	return $output ;
	#}


	if ($Wywrota::in->{'file'}) {
		eval{

			$fileName = Wywrota->file->fileUpload($Wywrota::in->{'file'}, 'mp3');
			$rec->{nazwa_pliku} = $fileName;
			$rec->{rozmiar_pliku_byte} = $ENV{'CONTENT_LENGTH'};

			$fileName = "$config{'www_dir'}/pliki/mp3/$fileName";

			# -- get mp3 data
			$mp3 = MP3::Tag->new($fileName);
			$mp3->get_tags;
			$rec->{czas_trwania_sec} = $mp3->total_secs_int();

			if ($rec->{czas_trwania_sec}<5) {
				Wywrota->sysMsg->push( "Nieprawidłowy format pliku.", 'err');
				return $self->recordFormUpload();
			}

			if (exists $mp3->{ID3v1}) {
				$rec->{tytul} = $mp3->{ID3v1}->title if ($mp3->{ID3v1}->title);
				$rec->{autor} = $mp3->{ID3v1}->artist if ($mp3->{ID3v1}->artist);
				$rec->{komentarz} = $mp3->{ID3v1}->comment ."\n" . $mp3->{ID3v1}->album ;
			}

		};
		Wywrota->error("MP3 Tag Error ".$@) if ($@);


		# -- build output form
		$file = $Wywrota::in->{'file'};
		$file=~m/^.*(\\|\/)(.*)\.(.*)$/; 
		Wywrota->sysMsg->push( "Odebrano plik &lt;$file&gt;", 'ok');
		$output .= qq~
			<h3>Krok 2 / 2: Uzupełnij dane</h3>
		~;
		$output .= Wywrota::Forms::buildHtmlRecordForm($object, @_);


	} else {

		Wywrota->sysMsg->push( qq~
			Pamiętaj! W naszym serwisie możesz opublikować jedynie nagrania <b>własnego autorstwa</b>.
			Przed przesłaniem pracy zapoznaj się z 	<a href='/regulamin.html#muzyka'>regulaminem</a>.
		~, 'tip');

		return $self->recordFormUpload();

	}
	return  $output;

}




sub recordFormUpload {
# --------------------------------------------------------

	my $self = shift;
	my $output = qq~

	<script language="JavaScript" type="text/javascript">
	<!--
		function checkForm(formObj) {
			if (!validrequired(formObj.file,"Nie wybrałeś pliku do wysłania.")) return false;
			if (!validrequired(formObj.regulamin,"Musisz potwierdzić, że to nagranie jest Twojego autorstwa.")) return false;
			return true;
		}


		function ap_stopAll() {
		}

	//-->
	</script>


		<h2>Krok 1 / 2: Załaduj plik</h2>


		<div class="padded">
			Wybierz z dysku plik MP3 z nagraniem. Maksymalny rozmiar przesyłanego pliku to 20 MB.
			Podczas przesyłania proszę pamiętać o tym, że wysyłanie sporego pliku może potrwać <b>do kilku minut</b>, w zależności od prędkości łącza.


			<form enctype="multipart/form-data" action="$config{'db_script_url'}" method="post" onsubmit="return checkForm(this);">
				<input name="add" value="1" type="hidden">
				<input type="hidden" name="db" value="$Wywrota::request->{content}{current}{url}">
				<input type="hidden" name="wykonawca_id" value="$Wywrota::in->{wykonawca_id}">

				<h3>Wybierz plik do przesłania: </h3>
				<input type="file" name="file" onclick="clearmsg();" onkeypress="clearmsg();"><br>


				<input type="checkbox" name="regulamin" onclick="clearmsg();" onkeypress="clearmsg();"> jestem autorem tego nagrania, lub zostałem upoważniony do przesłania pliku.<br><br>
				<input type="submit" name="upload" value="    wyślij    " class="bold"></br>

			</form>

		
			
		</div>
	~;
	return $output;
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
	my $output = Wywrota->t->process('object/mp3_page.html', {
		rec				=>	$rec,
		obj 			=>	$object,
		user_lead		=>	$userObj->recordLead(),
		other_items		=>	Wywrota::Controller::includePage("db=mp3&typ=$rec->{typ}&stan=2&random=1&mh=3&sb=_vote_func&so=descend&generate=1&small=1&user_id=$rec->{user_id}&id-not=$rec->{id}", "12h"),
		actions_log		=>	Wywrota::Log::getActionLog($object->id, $object->cid)
	});
	
	
	return Wywrota->t->wrapHeaderFooter({
			title		=> "MP3 $rec->{tytul}  - $rec->{autor}",	
			meta_desc	=> "piosenka pod tytułem $rec->{tytul}, $rec->{length}",	
			meta_key	=> "mp3, piosenki do ściągnięcia, $rec->{tytul}",
			canonical	=> $rec->{url},
			nomenu		=>  'bar',
			audio_player => 1,
			image=> 	$config{'file_server'} . "/pliki/site_images/" . $userObj->rec->{_image_filename} . "-lg",
			output		=> $output

	});
}




sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $output;


	if ($Wywrota::in->{user_id}) {
		my $userObj = Wywrota->content->getObject($Wywrota::in->{user_id}, 'User');
		$output = $userObj->recordLead();
	}


	$tytul = "Promo MP3" if ($Wywrota::in->{typ}==3);
	$tytul = "Wasza muzyka MP3" if ($Wywrota::in->{typ}==2);

	$output .= $self->SUPER::searchHeader($queryRes, $tytul);

	return $output;

}

1;