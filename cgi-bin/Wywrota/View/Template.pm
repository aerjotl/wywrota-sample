package Wywrota::View::Template;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict;
use Data::Dumper;
use Exporter;
use CGI::Ajax;
use HTTP::Date;
use HTML::Entities;

use Template;
use Template::Plugin::Number::Format;

use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Wywrota::Chords;

use Wywrota::Nut;


use Class::Singleton;
use base 'Class::Singleton';


sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;

	my $cfg = {
        INCLUDE_PATH => $config{'template_dir'},	# or list ref
        POST_CHOMP   => 1,							# cleanup whitespace 
        EVAL_PERL    => 1,							# evaluate Perl code blocks
    };

	# create Template object
    $self->{template} = Template->new($cfg);

	return $self;
}



sub HTTPheader {
# --------------------------------------------------------
# Print out the http headers 
#
	my $self = shift;
	my $nocache=shift;	
	my $ajax = shift;
	my $output;


	Wywrota->trace("Template : in HTTPheader");  

	$nocache = $nocache || $Wywrota::session->{user}{id};

	if ($nocache) {
		$output .= "Pragma: no-cache\n";
		#$output .= "Cache-Control: no-cache\n";
		$output .= "Cache-Control: store, no-cache, must-revalidate, post-check=0, pre-check=0\n";

		$output .= "Expires: ".time2str(time())."\n"; #
		#$output .= "Etag: ". Digest::MD5::md5_hex("$ENV{QUERY_STRING}.$ENV{HTTP_HOST}_$nocache") . "\n"; 
	} else {

		# 60 - 1 min, 600 - 10min, 3600 - 1 hours
		$output .= "Expires: ".time2str(time() + 600)."\n"; #
		#$output .= "Etag: ". Digest::MD5::md5_hex("$ENV{QUERY_STRING}.$ENV{HTTP_HOST}_static") . "\n"; 
	}
	
	#if ($ajax) {
	#	$output .= "Access-Control-Allow-Origin: http://literatura.wywrota.local\n";
		#foreach (keys %{$config{'subdomains'}}) {
		#	$output .= "Access-Control-Allow-Origin: http://$_.wywrota.local\n";
		#};
	#}
	
	$output .= "Content-type: text/html; charset=utf-8\r\n\r\n";
	
	return $output;
}




sub HTMLheader {
# --------------------------------------------------------
	my $self = shift;
	my $param = shift;
	my $output = "";

	Wywrota->trace("Template : in HTMLheader");  
	eval {
	

	$param->{color}		=	findValueUpTree('color'); # Wywrota->page->upTheTree('color', $NUT->config->page_id);
	$param->{meta_desc} =	dehtml($param->{meta_desc}) || findValueUpTree('description'); #|| Wywrota->page->upTheTree('description', $NUT->config->page_id);
	$param->{meta_key} =	dehtml($param->{meta_key});
	$param->{title} =		dehtml( $param->{title} || $Wywrota::request->{content}{current}{page}{title} );
	$param->{big_title} =	dehtml($param->{big_title});

	$param->{rss} = 		findValueUpTree('rss', $Wywrota::request->{content}{current}{page_id}); #Wywrota->page->upTheTree('rss', $NUT->config->page_id);
	$param->{rss_title} = 	findValueUpTree('rss_title', $Wywrota::request->{content}{current}{page_id}); #Wywrota->page->upTheTree('rss_title', $NUT->config->page_id);

	$param->{styl_local} =  $param->{styl_local} || $Wywrota::request->{content}{current}{style};
	$param->{styl_local} =  'home.css' if ($Wywrota::request->{content}{current}{is_home});

	$param->{meta_key} = $param->{meta_key} . ",". findValueUpTree('keywords'); #Wywrota->page->upTheTree('keywords', $NUT->config->page_id);
	$param->{meta_key} =~ s/[\n\r\t]+/ /g;
	$param->{meta_key} =~ s/\"//g;
	$param->{meta_key} =~ s/\s\S{1,2}\s/ /g;	
	$param->{meta_key} = cutTextTo($param->{meta_key}, 1000);

	if (!$param->{meta_desc}) {$param->{meta_desc} = $param->{meta_key};}
	$param->{meta_desc} =~ s/[�\n\r\t]+/ /g;
	$param->{meta_desc} =~ s/\"//g;
	$param->{meta_desc} = cutTextTo($param->{meta_desc}, 480);

	$param->{robots} = ($param->{nocache}) ?  ('noindex,nofollow') : ('index,follow');

	$param->{og_type}  = 'article' if (!$param->{og_type});
	$param->{language} = 'pl' if (!$param->{language});
	
	$param->{image} = $config{file_server} . "/pliki/wywrota-logo-2010.png" if (!$param->{image});	


	
	$param->{audio_player} = 1 if ($param->{color} == 2);

	$param->{wrap} = 'start';


	$output = $self->process('page_wrap_html.html', $param);

	};
	
	Wywrota->error($@) if ($@);

	return $self->HTTPheader($param->{nocache}). $output ;

}



sub popUpHeader {
# -------------------------------------------------------------------------------------

	my $self = shift;
	my $param = shift;
	my $output = '';

	$param->{wrap} = 'start';

	$output = $self->process('pop_up.html', $param);

	return $self->HTTPheader($param->{nocache}) . $output;
}


sub popUpFooter {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $param = shift;
	$param->{wrap} = 'end';
	
	return $self->process('pop_up.html', $param);
	
}



sub header {
# -------------------------------------------------------------------------------------
# dolacza naglowek z tytulem strony
# title - tytul strony
# nomenu -  jesli 1 - istnieje, to nie drukuje reszty kody tylko <head></head>
#			jesli 2 - 'nomenu' - nie drukuje prawej kolumny
#			jesli 3 - 'bar' - drukuje tylko gorny pasek
# meta_desc - meta description
# meta_key - meta keywords
# nocache - no http cache (default 0 - cache enabled)
# nobillboard - no billboard (default 0 - billboard showed)

	my $self = shift;
	my $param = shift;
	my ($output);

	Wywrota->trace("in Template : _header");  
	
	return if ($Wywrota::in->{generate});
	return $self->HTMLheader($param) if ($param->{nomenu} == 1);
	return $self->HTTPheader(1, 'ajax') if ($Wywrota::in->{popup} eq 'ajax');
	return $self->popUpHeader($param) if ($Wywrota::in->{popup});

	$param->{nomenu}=2 if (!defined($param->{nomenu})); 	# only left column by default
	$param->{nomenu}=2 if ($param->{nomenu} eq 'nomenu');
	$param->{nomenu}=2 if ($param->{nomenu} eq 'left');
	$param->{nomenu}=3 if ($param->{nomenu} eq 'bar');
	$Wywrota::request->{nomenu} = $param->{nomenu};
	

	$output = $self->HTMLheader($param);

	# -------------------------------------------------------------------------
	eval {
	
		$output .= $self->process('layout.html', {
			wrap				=>	'start',
			param 				=>	$param,
			adminLinks			=>	Wywrota->nav->adminLinks()
		});	

		Wywrota->sysMsg->push($Wywrota::in->{sysMsg}) if ($Wywrota::in->{sysMsg});
		$output .= Wywrota->sysMsg->getAll();
		
		$output = Wywrota->nav->absoluteLinks($output) if ($Wywrota::request->{urlPrefix});

	};

	$output .= Wywrota->error($@) if ($@);
	return $output;
}




sub footer {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $output = '';

	Wywrota->trace("in Template : _footer");  

	return if ($Wywrota::in->{generate});
	return if ($Wywrota::in->{popup} eq 'ajax');
	return $self->popUpFooter() if ($Wywrota::in->{popup});
	
	eval {
	
	
		#my $randomcytat =  Wywrota->content->getObject("random", "Quote");
		#$randomcytat->preProcess() if ($randomcytat);
		#$randomcytat = $randomcytat->record();

		$output = $self->process('layout.html', {
			wrap				=>	'end',
			nomenu				=>	$Wywrota::request->{nomenu},
			moon_phase			=>	\&Wywrota::Utils::moonPhase,
			#quote 				=>	$randomcytat,
		});	

		$output = Wywrota->nav->absoluteLinks($output);

	};

	$output = Wywrota->error($@) if ($@);
	return $output;

}





sub wrapPopUpHeaderFooter {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $param = shift;
	my $output = shift || $param->{output};

	return $self->popUpHeader($param)
		. $output
		. $self->popUpFooter($param);
}



sub wrapHeaderFooter {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $param = shift;
	my $output = shift || $param->{output};

	
	return $self->header($param)
		. $output
		. $self->footer($param);
}



sub ipBlocked {
# -------------------------------------------------------------------------------------
	my $self = shift;

	my 	$output = "Status: 503 Service Temporarily Unavailable\n";
	$output .= "Content-Type: text/html; charset=UTF-8;\n";
	$output .= "Retry-After: 3600\r\n\r\n";
	$output .= $self->process('error_ip_blocked.html');

	return $output;
}




sub serverOverloaded {
# -------------------------------------------------------------------------------------
	my $self = shift;

	my 	$output = "Status: 503 Service Temporarily Unavailable\n";
	$output .= "Content-Type: text/html; charset=UTF-8;\n";
	$output .= "Retry-After: 3600\r\n\r\n";
	$output .= $self->process('error_page_overload.html');

	return $output;
}







sub serverOff {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $output;

	$output = "Status: 503 Service Temporarily Unavailable\n";
	$output .= "Content-Type: text/html; charset=UTF-8;\n";
	$output .= "Retry-After: 3600\r\n\r\n";
	$output .= $self->process('error_page_server_off.html');

	return $output;
}




sub template : lvalue {shift->{template}};


sub process {
# -------------------------------------------------------------------------------------
	
	my $self = shift;
	my $file = shift;
	my $param = shift;
	my $output = '';

	$param = mergeHashRef($param, {
		config 		=>	\%config,
#		nut 		=> 	$Wywrota::Nut::NUT,
		env			=>	\%ENV,
		in 			=> 	$Wywrota::in,
		session		=>	$Wywrota::session,				# workaround - remove it!
		request		=>	$Wywrota::request,				# workaround - remove it!
		is_admin	=>	Wywrota->per('admin'),			# workaround - remove it!
		is_premium	=>	$Wywrota::session->{user}{premium},

		wywrotek	=>	\&Wywrota::Controller::includePage,
		msg			=>	\&Wywrota::Language::msg,
		plural		=>	\&Wywrota::Language::plural,
		normalnaData=>	\&Wywrota::Utils::normalnaData,
		
		isInFavorites=> 	sub {Wywrota->fav->isInFavorites(@_)},
		
		crumb_trail	=>		sub{ Wywrota->nav->crumbTrail },
		main_nav	=>		sub{ Wywrota->nav->bigLinks(@_) },
		recordSetsHTML	=>	sub{ Wywrota->view->view('RecordSet')->recordSetsBox() },
		errorMsg 	=>	sub { Wywrota->errorMsg(@_) },
		findChord	=>	\&Wywrota::Chords::findChord,

		#param 		=> 	$Wywrota::Nut::NUT->request->param
		});
		
	
	$self->template->process($file, $param, \$output) || $self->error();
	return $output;
};



sub error {	
# -------------------------------------------------------------------------------------
	my $self = shift;
	Wywrota->error( $self->template->error->as_string() );
};



sub getPhotoCode {
	my $self = shift;
	my $photo = shift;
	return trim($self->process('inc/photo.inc', {
		photo => $photo
	}));
}



1;