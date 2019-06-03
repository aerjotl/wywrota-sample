package Wywrota::Object::Manager::RSSManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use XML::RSS;
use XML::RSS::PicLens;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';




sub landingPage {
# --------------------------------------------------------
	return Wywrota->cListView->viewRecords({'id-gt'=>0});

}


sub getFeed {
# --------------------------------------------------------
	my $self=shift;
	my $nut = shift;
	my ($rec, $rss, $output, $object);
	my $queryRes = Wywrota->cListEngine->query($nut->in);

	
	if ($queryRes->{status} eq "ok") {
		$rss = XML::RSS->new( version => '2.0', encoding	 => "utf-8", encode_output=>0 );
		$rss->add_module(
				prefix=>'jwplayer', 
				uri=>'http://developer.longtailvideo.com/trac/wiki/FlashFormats'
		);
		$rss->add_module(
			prefix => 'media',
	        uri    => 'http://search.yahoo.com/mrss'
	    );

		# Prep the RSS.

		$rss->channel(
			title        => $nut->request->{content}{current}{title}." - $config{'site_name'}",
			link         => "http://www.Wywrota.pl/$Wywrota::request->{content}{current}{url}/",
			description  => $nut->request->{content}{current}{title}." - $config{'site_name'}", #"$Wywrota::request->{content}{current}{description}",
			language     => 'pl',
			copyright      => 'Copyright by Wywrota.pl - komuna internetowa');

		 $rss->image(
		   title  => $nut->request->{content}{current}{title}." - $config{'site_name'}",
		   url    => "$config{'site_url'}/gfx/logo/wywrota-komuna.png",
		   link   => $config{'site_url'}
		 );

		for (0 .. $#{$queryRes->{hits}}) {
#			if ($Wywrota::request->{content}{current}{id}==3) {
				$object = Wywrota->content->getObject($queryRes->{hits}[$_]->{id});
#			}
			$object->preProcess();
			$rec = $object->rec;

			$rec->{komentarz} = qq~
				<a href="$rec->{url}"><img src="$config{'site_url'}/pliki/$Wywrota::request->{content}{current}{url}/$rec->{nazwa_pliku}-s1" align="left" hspace="10" border="1"></a>
				$rec->{komentarz}
				~ if ($rec->{nazwa_pliku} );

			$rec->{komentarz} = qq~
				<a href="$rec->{url}"><img src="$config{'site_url'}/pliki/$Wywrota::request->{content}{current}{url}/$rec->{plik}-s1" align="left" hspace="10" border="1"></a>
				$rec->{komentarz}
				~ if ($rec->{plik} );

			$rec->{komentarz} = qq~
				<img src="$config{'site_url'}/pliki/site_images/$rec->{_image_filename}-sm" align="left" hspace="10" border="1">
				$rec->{komentarz}
				~ if ($rec->{_image_filename} );

			if ($Wywrota::request->{content}{current}{id}==3) {
				$rec->{komentarz} = cutTextTo( $rec->{komentarz} . " " . dehtml($rec->{tresc}), 350 );
			} else {
				$rec->{komentarz} .= " ". $rec->{autor};
			}


			if ($rec->{url_image}) {
				$rss->add_item( 
					title => "<![CDATA[" .  dehtml( ($rec->{tytul} || $rec->{podpis}) ." - ".$rec->{ludzie_imie} ) . "]]>", 
					description => "<![CDATA[" . $rec->{komentarz} .  "]]>", 
					author => "<![CDATA[\"" .$rec->{ludzie_imie}. "\" ]]>",
					category => $rec->{typ},
					thumbnail => $rec->{url_thumbnail},

					media => {
						(
							defined $rec->{url_thumbnail}
							? ( thumbnail => { url => $rec->{url_thumbnail}."/get.jpg" } )
							: ()
						),
						( defined $rec->{url_image} ? ( content => { url => $rec->{url_image}."/get.jpg" } ) : () ),
					},

					jwplayer => {
						provider => 'http',
					},

					);

			} else {

				$rss->add_item( 
					title => "<![CDATA[" .  dehtml($rec->{tytul}) . "]]>", 
					description => "<![CDATA[" . $rec->{komentarz} .  "]]>", 
					author => "<![CDATA[\"" .$rec->{autor}. "\" ]]>", ,
					category => $rec->{typ},
					link => $rec->{url},
					#guid => $rec->{url}
					);
			}
		}

		$output = $rss->as_string;
		$output = "Content-type: application/rss+xml; charset=utf-8\r\n\r\n".$output ;

		#	. qq~<!--  $ENV{QUERY_STRING}   $ENV{QUERY_STRING} -->~	
		#;
		return  $output;

	}
	else {
		#return Wywrota->cListView->viewFailure($nut->in, $queryRes->{msg});
	}
}



1;