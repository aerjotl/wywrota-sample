package Wywrota::Object::Manager::LiteratureManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Object::BaseObject;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';



sub action {
# -------------------------------------------------------------------------------------
	my $output;
	my $self = shift;
	my $nut = shift;
	my $action = $nut->in->{a} || $nut->in->{action};

	if    ($action eq 'lodowka')   { 
		$output = Wywrota->view->view->lodowka();
		return $output;
	} else {	
		$output = Wywrota->unknownAction($action);
	}
	return $output;
}



sub landingPage {
# --------------------------------------------------------
	my $output = Wywrota->content->includeFile("literatura/index.html");
	if ($Wywrota::request->{urlPrefix}) {
		$output = Wywrota->nav->absoluteLinks($output);
	}
	return $output ;
}



sub initContentTemplate {
# --------------------------------------------------------

	my $self=shift;
	my $nut=shift;
	my ($obj, $link, $rec, $urlized, $bandObj);

	if ($nut->in->{urlized}) {
		$nut->in->{autor_urlized} = $nut->in->{urlized};
		$nut->in->{ww} = 1; # only exact maches
		delete $nut->in->{urlized};
	}

	if ($nut->in->{autor_urlized}) {

		$urlized = $nut->in->{autor_urlized};

		$rec = Wywrota->db->quickHashRef("SELECT id, autor, typ FROM teksty WHERE _active=1 AND autor_urlized = "
			. Wywrota->db->quote($nut->in->{autor_urlized}). " limit 1");

		$nut->request->{autor} = $rec->{autor};
		$nut->request->{typ} = $rec->{typ};

		if ($rec->{typ} == 5) {
			# build crumbtrail link
			$link = {};
			$link->{text} = "wiersze klasyków";
			$link->{url} = $nut->request->{subdomain_url}. "poezja_klasyka.html";
			push(@{$nut->request->{nav}{crumbLinks}}, $link);
		}

		# build crumbtrail link
		$link = {};
		$link->{text} = $rec->{autor}." wiersze";
		$link->{url} = $nut->request->{subdomain_url}. $nut->in->{autor_urlized}."/";
		push(@{$nut->request->{nav}{crumbLinks}}, $link);

	} elsif (int $nut->in->{view}) {
		$obj = Wywrota->content->getObject($nut->in->{view});
		
		if ($obj) {
			$urlized = $obj->rec->{autor_urlized};
		}
		
		if ($obj && $obj->rec->{typ} == 5) {
			
			# build crumbtrail link
			$link = {};
			$link->{text} = "wiersze klasyków";
			$link->{url} = $nut->request->{subdomain_url}. "poezja_klasyka.html";
			push(@{$nut->request->{nav}{crumbLinks}}, $link);
			
			# build crumbtrail link
			$link = {};
			$link->{text} = $obj->rec->{autor} ." wiersze";
			$link->{url} = $nut->request->{subdomain_url}. $obj->rec->{autor_urlized}."/";
			push(@{$nut->request->{nav}{crumbLinks}}, $link);
			
		}
		
	};

	# get the author object
	$bandObj = Wywrota->content->getObject(undef, 'Band', "wykonawca_urlized=" .Wywrota->db->quote($urlized) );
	$bandObj->preProcess('sq2') if $bandObj;
	$nut->request->{wykonawca} = $bandObj;


}

1;