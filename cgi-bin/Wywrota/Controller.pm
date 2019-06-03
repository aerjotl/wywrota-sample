package Wywrota::Controller;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict;
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Language;

use Wywrota::User;
use Wywrota::Admin;
use Wywrota::Site;
use Wywrota::Favorites;
use Wywrota::Payment;
use Wywrota::Facebook;
use Clone qw(clone); 

use Time::HiRes qw(gettimeofday tv_interval);

sub main {
#-----------------------------------------------------------------------

	my ($output);
	my $nut = shift;
	my $in = $nut->in;

	Wywrota->trace("Wywrota::Controller :: main()", $in);

	Wywrota->error("ERR0", $@) if ($@);
	eval {

	Wywrota->trace("Wywrota::Controller :: main() 1", $in );
	Wywrota->mng->initContentTemplate($nut);
	Wywrota->trace("Wywrota::Controller :: main() 2", $in );


	if    ($in->{'content_include'})	{ $output = Wywrota->content->includeFile( $nut->in->{'content_include'} ); } 
	
	elsif ($in->{'keyword'})		{ $output = Wywrota->searchEngine->action($nut) }		# opensearch backwards compat
	elsif ($in->{'search'})			{ $output = Wywrota->searchEngine->action($nut) }		# Search Action 

	elsif ($in->{'a'})				{ $output = Wywrota->content->action($nut) }			# Custom Content Action 
	elsif ($in->{'action'})			{ $output = Wywrota->content->action($nut) }			# Custom Content Action 
	elsif ($in->{'ca'})				{ $output = Wywrota->cListEngine->action($nut) }		# Content List Action 

	elsif ($in->{'message'})		{ $output = Wywrota->msg->action($nut); } 		  
	elsif ($in->{'userAction'})		{ $output = Wywrota::User::action($nut); }	
	elsif ($in->{'user'})			{ $output = Wywrota::User::action($nut); }	
	elsif ($in->{'siteAction'})		{ $output = Wywrota::Site::action($nut); }	
	elsif ($in->{'site'})			{ $output = Wywrota::Site::action($nut); }	
	elsif ($in->{'adminAction'})	{ $output = Wywrota::Admin::action($nut); }	
	elsif ($in->{'smsAction'})		{ $output = Wywrota::Payment::action($nut);  }
	elsif ($in->{'payAction'})		{ $output = Wywrota::Payment::action($nut);  }
	elsif ($in->{'favorites'})		{ $output = Wywrota->fav->action($nut); } 		  
	elsif ($in->{'send_email'})		{ $output = Wywrota->msg->contactFormPost($nut);}
	elsif ($in->{'landing_page'})	{ $output = Wywrota->content->mng->landingPage($nut); }	
	elsif ($in->{'rssfeed'})		{ $output = Wywrota->mng('RSS')->getFeed($nut); }	
	elsif ($in->{'votelist'})		{ $output = Wywrota->vote->voteList($nut); }	

	elsif ($in->{'view'})			{ if ($nut->per('view')){ $output = Wywrota->content->htmlPage($nut); } 		  else { $output = Wywrota::User::unauthorized(); } } 	
	elsif ($in->{'view_search'})	{ if ($nut->per('view')){ $output = Wywrota->cListView->viewSearch($in); } 	  else { $output = Wywrota::User::unauthorized(); } }
	
	elsif ($in->{'add'})			{ if ($nut->per('add')) { $output = Wywrota->view->addForm($nut); } 		  else { $output = Wywrota::User::unauthorized(); } }
	elsif ($in->{'addrecord'})		{ if ($nut->per('add')) { $output = Wywrota->view->addObjectHtml($nut); } 		  else { $output = Wywrota::User::unauthorized(); } }
	elsif ($in->{'deleterecords'})	{ if ($nut->per('del')) { $output = Wywrota->content->deleteObject($in->{id}, $in->{cid}); } 	  else { $output = Wywrota::User::unauthorized(); } }  
	elsif ($in->{'modify'})			{ if ($nut->per('mod')) { $output = Wywrota->view->modifyForm($nut); }			else { $output = Wywrota::User::unauthorized(); } }  
	elsif ($in->{'modifyrecord'})	{ if ($nut->per('mod')) { $output = Wywrota->view->modifyObjectHtml($nut);  } 	  else {$output =  Wywrota::User::unauthorized(); } }

	elsif ($in->{'login'})			{ $output = Wywrota::User::loginAction($nut); }
	elsif ($in->{'logout'})			{ $output = Wywrota::User::logoff($nut); }
	
	
	elsif ($in->{'facebook_login'}) 	{ $output = Wywrota::Facebook::facebookLogin($nut); }
	elsif ($in->{'facebook_postback'})  { $output = Wywrota::Facebook::facebookPostback($nut);  }
	elsif ($in->{'facebook_connect_accounts'})   { $output = Wywrota::Facebook::facebookConnect($nut); }
	elsif ($in->{'facebook_new_user'})        	{ $output = Wywrota::Facebook::facebookNewUser($nut); }
	
	

	else 							{ if ($nut->per('view')) { 
											$output =  Wywrota->cListView->viewRecords($in); 
										} 	else { 
											$output = Wywrota::User::unauthorized();
										} };
	
	Wywrota->trace("Wywrota::Controller :: main() 3", $in );
	};
	Wywrota->error($@) if ($@);

	Wywrota->trace("Wywrota::Controller :: main() 3", $in );
	$output = attachTrackingParams($output, 'site', 'ucd', $in->{'track'}) 
		if ($in->{'track'});

	return $output;
}




sub includePage {
# --------------------------------------------------------

	my $url = shift;
	my $cacheTime = shift;
	my $nogenerate = shift;
	my $timer = [gettimeofday];

	my ($output, $oldIn, $oldRequest, $tempNut);

	Wywrota->trace("Controller : includePage $url $cacheTime");  

	if ($cacheTime && $config{'cache'}{'active'} && ($output = Wywrota->cache->getFromCache("g_$url", $cacheTime)) ) {
		return $output."<!-- included " . tv_interval($timer, [gettimeofday]) .  " s. -->";
	}

	$oldIn = $Wywrota::in;
	$oldRequest = $Wywrota::request;

	$Wywrota::in = undef;
	$Wywrota::request = undef;

	$tempNut = Wywrota::Nut->new($url, { 'include'=>1 }, $Wywrota::session);
	$tempNut->in->{'generate'}=1 if (!$nogenerate &&  !$tempNut->in->{'generate'});
	$tempNut->opt('include')=1;

	$output = main($tempNut);
	Wywrota->error($@) if ($@);
	
	undef $tempNut;

	Wywrota->cache->storeCache("g_$url", $output, $cacheTime);

	if ($config{'show_debug'} || ($ENV{REQUEST_URI} =~ 'show_debug')) {
		$output .= "<div class='debug'>include: ".tv_interval($timer, [gettimeofday])." s.</div>";
	}

	$Wywrota::in = $oldIn;
	$Wywrota::request = $oldRequest;

	return $output;
}




1;
