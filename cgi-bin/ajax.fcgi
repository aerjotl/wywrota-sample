#!/usr/bin/perl -X


#-----------------------------------------------------------------------
#   ___            __      __                   _       _   
#  | _ \__ _ _ _   \ \    / /  ___ __ ___ _ ___| |_ ___| |__
#  |  _/ _` | ' \   \ \/\/ / || \ V  V / '_/ _ \  _/ -_) / /
#  |_| \__,_|_||_|   \_/\_/ \_, |\_/\_/|_| \___/\__\___|_\_\
#                           |__/                            
#
#-----------------------------------------------------------------------
# Copyright (c) 1998-2008 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict;
use CGI::Fast;
use Data::Dumper;
use Wywrota;
use Wywrota::AJAX;
use Wywrota::Nut;

my ($req);
our ($Wywrota, $AJAX);


$req = new CGI::Fast;		# needed to init %ENV
$Wywrota = Wywrota->instance(".", \%ENV);
$AJAX = Wywrota::AJAX->instance();


ajaxRequest($req);
exit(0) if ($ENV{WYWROTEK_NO_FCGI});

# -- CGI::Fast request processing
while ($req = new CGI::Fast) {
	#$Wywrota->dbug->reset();
	ajaxRequest($req);
}


sub ajaxRequest {
# --------------------------------------------------------
	my $request = shift;
	my ($out, $nut);
	$nut = Wywrota::Nut->new($req);
	
	unless ($nut->request->redirect || $nut->request->hardredirect) {
		$out = Wywrota::AJAX::processRequestNut($nut)
	}
	
	if ($nut->request->hardredirect) {
		print "Status: 301 Moved Permanently\n";
		print "Location: ". $nut->request->hardredirect ."\n\n";
		
	} elsif ($nut->request->redirect) {
		print "Status: 302 Found\n";
		print "Location: ". $nut->request->redirect ."\n\n";
		
	} else {
		print "Content-type: text/html; charset=utf-8\r\n\r\n";
		print $out;
	}		
	undef $nut;
}