package Wywrota::Object::Manager::AwardManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';

sub landingPage {
# --------------------------------------------------------
	my ($queryRes, $output);

	# -- get a list of forum topics
	$queryRes = Wywrota->cListEngine->query( {"content_id-gt"=>'0', mh => 24 });

	$output = qq~
	<div style="width: 300px; float: right; text-align: center;">
		<img src="/gfx/bannery/star-book.png" border="0" alt="" vspace="3" width="240" height="100"></a><br>
		<strong style="color: red;">WYRÓŻNIENIE REDAKCJI </strong> <br>= <strong style="color: navy;">NAGRODA RZECZOWA</strong>
	</div>

	<h1>Nagrody dla autorów najlepszych prac</h1> 
		

		<p>&nbsp;</p> 
		<p>Od początku 2009 roku autorzy prac (wierszy, opowiadań, zdjęć, prac graficznych, nagrań muzycznych itp), które zostały wyróżnione przez opiekunów, otrzymują od redakcji Wywroty nagrody rzeczowe. 
		Nagrodami są książki, płyty muzyczne lub innych atrakcje ufundowane przez współpracujące z nami wydawnictwa.</p> 
		<br><br>
			

		
		<br class="clr">
	~ . Wywrota->cListView->includeQueryResults($queryRes)

	;

	return Wywrota->view->wrapHeaderFooter({
			title => "Awards",
			nomenu=>  2,
			nocache=>  1,
			output => $output,
			nobillboard => 1
	});

}



1;