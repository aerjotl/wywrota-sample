#!/usr/bin/perl

use CGI;

my $cgi				= CGI->new;
my $filename		= $cgi->param('f') || '';
my $files_location	= '../../files/pliki';
my $mimetype		= 'application/octet-stream';


error ("Security error") if ($filename =~ /\.\./);


my $sendfilename = $filename;

$sendfilename =~ s/(.*\/)*(.*)_(jpg|mp3)_?(.*)$/$2.$3/g;

$mimetype = 'application/pdf'	if ($sendfilename =~ /\.pdf$/);
$mimetype = 'application/zip'	if ($sendfilename =~ /\.zip$/);
$mimetype = 'application/x-tar'	if ($sendfilename =~ /\.tar$/);
$mimetype = 'application/x-compressed'	if ($sendfilename =~ /\.tgz$/);
$mimetype = 'audio/mpeg'		if ($sendfilename =~ /\.mp3$/);
$mimetype = 'image/jpeg'		if ($sendfilename =~ /\.jpg$/);
$mimetype = 'image/jpeg'		if ($sendfilename =~ /\.jpeg$/);


# send the file to the browser
open(DLFILE, "<$files_location/$filename") || error("Error opening file ". $filename); 
my @fileholder = <DLFILE>;   
close (DLFILE);   

print $cgi->header( -type => $mimetype, -attachment => $sendfilename );
print @fileholder;



sub error {
	print $cgi->header(  );
	print shift;
	exit;
}
