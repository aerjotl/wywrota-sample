#!/usr/bin/perl -X


#-----------------------------------------------------------------------
#   ___            __      __                   _       _   
#  | _ \__ _ _ _   \ \    / /  ___ __ ___ _ ___| |_ ___| |__
#  |  _/ _` | ' \   \ \/\/ / || \ V  V / '_/ _ \  _/ -_) / /
#  |_| \__,_|_||_|   \_/\_/ \_, |\_/\_/|_| \___/\__\___|_\_\
#                           |__/                            
#
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use CGI::Fast;
use Wywrota;
use Wywrota::Nut;
use Data::Dumper;

my ($req, $requestsServed);
our $Wywrota;

#print "Content-type: text/html; charset=utf-8\r\n\r\n";

$req = new CGI::Fast;	# needed to init %ENV
$Wywrota = Wywrota->instance(".", \%ENV);


print normalRequest($req);
exit(0) if ($ENV{WYWROTEK_NO_FCGI});	# -- no FastCGI 


# -- CGI::Fast request processing 
while ($req = new CGI::Fast) {
	print normalRequest($req);
	
	$requestsServed++;	
	exit(0) if ($requestsServed > 100);
}




sub normalRequest {
# --------------------------------------------------------

	Wywrota->dbug->resetTimer();

	my $req = shift;
	my $nut = Wywrota::Nut->new($req);
	my $output;
	
	if ($nut->request->hardredirect) {
		$output = "Status: 301 Moved Permanently\n"
				. "Location: ". $nut->request->hardredirect ."\n\n";
		
	} elsif ($nut->request->redirect) {
		$output = "Status: 302 Found\n"
		        . "Location: ". $nut->request->redirect ."\n\n";
		
	} else {
		$output = Wywrota::processRequestNut($nut) ;
	}

	# check once again for redirection after content action

	if ($nut->request->hardredirect) {
		$output = "Status: 301 Moved Permanently\n"
				. "Location: ". $nut->request->hardredirect ."\n\n";
		
	} elsif ($nut->request->redirect) {
		$output = "Status: 302 Found\n"
		        . "Location: ". $nut->request->redirect ."\n\n";
		
	}



	undef $nut;
	
	return $output;
}

sub serverOff {
# --------------------------------------------------------
	my $req = shift;
#	return "Status: 503 Service Temporarily Unavailable\n" .	"Content-Type: text/html; charset=UTF-8;\n" ."Retry-After: 3600\r\n\r\n" . "<h2>Wywrota</h2> przepraszamy za usterki";

	return Wywrota::View::Template::serverOff();

}