package Wywrota::Nut::Cookie;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict;
use Exporter; 
use Wywrota::Config;

our @ISA = qw(Exporter);
our @EXPORT = qw(getCookie setCookie);


sub getCookie {
# --------------------------------------------------------
# getCookie - Gets all the cookies and returns them in a hash
# Usage: my %cookie = &getCookie;

  my $env = shift;
  my ($cookie, $value, $char, %cookie);

  my @Cdec = ('\+', '\%3A\%3A', '\%3D', '\%2C', '\%25', '\%2B', '\%26','\%3B');
  my %Cdec = ('\+',' ','\%3A\%3A','::','\%3D','=','\%2C',',','\%25','%','\%2B','+','\%26','&','\%3B',';');

  if ($env->{'HTTP_COOKIE'}) {
    foreach (split(/; /,$env->{'HTTP_COOKIE'})) {
    ($cookie,$value) = split(/=/);
      foreach $char (@Cdec) {
        $cookie =~ s/$char/$Cdec{$char}/g;
        $value =~ s/$char/$Cdec{$char}/g;
      }
      $cookie{$cookie} = $value;
    }
  }
  return %cookie;
}

sub setCookie {
# --------------------------------------------------------
# setCookie - Sets a cookie.
# Usage : setCookie('Name',"Value",?) ? = 0 or 1. 0 = temp, 1 = permanent

  my @cookie = @_;
  my ($cookie, $value, $type, $char, $output, $domain, @d);
  my @Cenc = ('\;','\&','\+','\%','\,','\=','\:\:','\s');
  my %Cenc = ('\;','%3B','\&','%26','\+','%2B','\%','%25','\,','%2C','\=','%3D','\:\:','%3A%3A','\s','+');

  my $header = '';
  ($domain) = split(":", $Wywrota::request->{urlSufix});

  for (my $i = 0; $i <= $#cookie; $i = $i + 3) {
    ($cookie, $value, $type) = @cookie[$i .. $i+2];
    foreach $char (@Cenc) {
      $cookie =~ s/$char/$Cenc{$char}/g;
      $value =~ s/$char/$Cenc{$char}/g;
    }
    $header = 'Set-Cookie: ' . $cookie . '=' . $value . ';';
		$header .= " domain=.$domain; path=/;"; 

    if ($type == 1) {
      $header .= ' expires=' . $config{'cookie_expiration'} . ';'
    }
    $output .= "$header\n";
  }

  return $output;

}


1;
