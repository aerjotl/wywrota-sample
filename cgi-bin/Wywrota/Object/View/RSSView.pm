package Wywrota::Object::View::RSSView;

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


sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;


	my $output = qq~
		<div style="width: 296px; float: right; margin-left: 20px">
		<p><a href="http://cafenews.pl"><img src="/gfx/bannery/cn_big.png" width="296" height="96" border="0" alt="Cafe News" style="margin-bottom: 12px;"></a>
		<p class="txtnews"><b>Wywrota.pl</b> jest Partnerem Cafe News. <br>Korzystający z Cafe News otrzymują  błyskawicznie  na swój komputer wszystkie interesujące i określone przez nich news-y na wybrane zagadnienia i tematy. Taka funkcjonalność Cafe News znacznie oszczędzą czas.<br><br>
		<p class="txtnews">Posegregowane tematycznie kanały sprawiają, że dostęp do informacji jest łatwy, szybki i przyjazny. Cafe News to coś więcej niż czytnik RSS- to innowacyjne narzędzie monitorujące i udostępniające aktualności. <br><br>
		 
		<p class="txtnews">Jeśli posiadają  już Państwo zainstalowaną aplikację Cafe News, kliknięcie na ikonkę <img src="/gfx/add_to_cn.png" width="78" height="12" border="0" alt=""> spowoduje aktywowanie naszego kanału.<br>
		<!-- p class="txtnews content">Cafe News można używać bezpłatnie. (<a href="http://cafenews.pl">pobierz plik</a>) -->
		<p class="txtnews content">Zachęcamy do skorzystania z wersji on-line Cafe News, dostępnej na stronie <a href="http://www.cafenews.pl">http://cafenews.pl</a>. System zapamiętuje wszelkie ustawienia. <!-- Wystarczy się zalogować, by wejść na zaprojektowaną przez siebie stronę. -->
		</div>
	~;

	$output .= $self->SUPER::searchHeader($queryRes, $tytul);

	return $output;

}



sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;

	if ($Wywrota::in->{view}) {
		$rec = Wywrota->db->quickHashRef("SELECT * FROM $Wywrota::request->{content}{current}{'tablename'} WHERE name=".Wywrota->db->quote($Wywrota::in->{name}));
	} 

	return Wywrota::Controller::includePage($rec->{wywrotek}."&rssfeed=1", "15m");
}


1;