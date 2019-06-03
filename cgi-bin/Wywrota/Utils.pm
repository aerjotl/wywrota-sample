package Wywrota::Utils;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Astro::MoonPhase;
use Time::Local;
use Time::HiRes qw(gettimeofday tv_interval);
use Date::Parse;
use POSIX qw(ceil floor);
use Wywrota::Config;
use Encode qw/encode decode/;
use Data::Structure::Util qw(_utf8_off utf8_off utf8_on _utf8_on);
use Text::Unidecode;
 
our @ISA = qw(Exporter);
our @EXPORT = qw(
	normalnaData timeAlias getTime getDate formatTime formatBytes 
	date_to_unix  
	urlencode  
	dehtml dehtml_space smartContent
	simpleAscii trim cutTextTo 
	encodeMime
	findValueUpTree  
	moonPhase mergeHashRef flatButton
	attachTrackingParams
	fixBrokenUTF8Chars
	avoidUppercase
	);



sub getTime {
# --------------------------------------------------------
# Returns the time in the format "hh-mm-ss".
#
	my ($sec, $min, $hour, $day, $mon, $year, $dweek, $dyear, $daylight) = localtime(time());
	$sec = sprintf("%02d",$sec);
	$min = sprintf("%02d",$min);
	$hour = sprintf("%02d",$hour);
	
	return "$hour:$min:$sec";
}


sub getDate {
# --------------------------------------------------------
# Returns the date in the format "dd-mm-yy hh:mm:ss".

	my $time = shift || time();

    my ($sec, $min, $hour, $day, $mon, $year, $dweek, $dyear, $daylight) = localtime($time);
	$sec = sprintf("%02d",$sec);
	$min = sprintf("%02d",$min);
	$hour = sprintf("%02d",$hour);
	$day = sprintf("%02d",$day);
	$year = $year + 1900;
    $mon++;
	$mon = sprintf("%02d",$mon);
    return "$year-$mon-$day $hour:$min:$sec";
}

sub date_to_unix {
# --------------------------------------------------------
# This routine must take your date format and return the time a la UNIX time().
# Some things to be careful about.. 
#     int your values just in case to remove spaces, etc.
#     catch the fatal error timelocal will generate if you have a bad date..
#     don't forget that the month is indexed from 0!
#
    my ($date, $time) = split(/\s/, $_[0]);
    my ($year, $mon, $day) = split(/-/, $date);
    my ($hour, $min, $sec) = split(/:/, $time);
    unless ($day and $mon and $year)  { return undef; }
	
    eval {		
		$day = int($day); $year = int($year) - 1900;
		if ($year== -1900) {
			($_,$_,$_,$_,$_,$year) = localtime(time);
			if ( timelocal($sec, $min, $hour, $day, $mon, $year) < timelocal(localtime(time())) ) {$year++}
			$time=timelocal($sec, $min, $hour, $day, $mon, $year);
		}
		elsif ($year < 70) {
			my $oneyear=31532400;
			my $minusyears = 70 - $year;
			$time = timelocal($sec, $min, $hour, $day, $mon, 70);
			$time = $time - ($minusyears * $oneyear);
		}
		else {$time = timelocal($sec, $min, $hour, $day, $mon, $year)}
    };
    if ($@) { return undef; } # Could return 0 if you want.
    return ($time); 
}



sub urlencode {
# --------------------------------------------------------
# Escapes a string to make it suitable for printing as a URL.
#
    my ($toencode) = shift;
    $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    $toencode =~ s/\%2F/\//g;
    return $toencode;
}



sub normalnaData {
# --------------------------------------------------------
# Zamienia date z formatu sql na czytelna dla czlowieka
#
# normalnaData( $time, $format)
#
#	'normal'			12 stycznia 2009, 4:33
#	'short' 			12-sty-09, 4:33
#	'short_notime' 		12-sty-09
#	'friendly' 			wczoraj	| <normal>
#	'notime' 			12 stycznia 2009
#	'friendly_notime'	wczoraj | <notime>
#	'friendly_short_notime'	wczoraj | <short_notime>


	my $friendlyDay = 0;
	my @months = ("stycznia","lutego","marca","kwietnia","maja","czerwca","lipca","sierpnia","września","pazdziernika","listopada","grudnia");
	my ($day);

	my $datetime = shift;
	my $format = shift;		
	
	my ($s,$min,$h,$d,$m,$y,$zone) = ($datetime=~/^\d+$/) ? localtime($datetime) : strptime($datetime);
	my ($_sec, $_min, $_hour, $_day, $_mon, $_year) = localtime(time());

	return "" if ($y<=0 || $m<0 || $d<=0);	
	
	my $age = time() - str2time($datetime);
	my $dayage = timelocal(0,0,0,$_day, $_mon, $_year) - timelocal(0, 0, 0, $d, $m, $y);


	if ($format =~ /friendly/) {
		if ($age < 120) {
			return "minutę&nbsp;temu";
		} elsif ($age < 300+300) {
			return "5&nbsp;min.&nbsp;temu"; # <10
		} elsif ($age < 600+300) {
			return "10&nbsp;min.&nbsp;temu"; # <15
		} elsif ($age < 900+300) {
			return "15&nbsp;min.&nbsp;temu"; # <20
		} elsif ($age < 1200+300) {
			return "20&nbsp;min.&nbsp;temu"; # <25
		} elsif ($age < 1800+900) {
			return "30&nbsp;min.&nbsp;temu"; # <45
		} elsif ($age < 3600+1800) {		 
			return "godzinę&nbsp;temu";		 # <1.5
		} 

		if ( $dayage == 0 ) {
			$friendlyDay = "dzisiaj";
		} elsif ( $dayage == 86400 ) {
			$friendlyDay = "wczoraj";
		} elsif ( $dayage == 172800 ) {
			$friendlyDay = "przedwczoraj";
		}
	}
	$y=1900+$y;
	
	$day = $friendlyDay ||  int($d)."-" . substr($months[$m],0,3). "-" . $y ;

	if ($format =~ /short/ && $format !~ /notime/ && ($h || $min )) {
		return $day." $h:$min";

	} elsif ($format =~ /short/) {
		return $day;

	} elsif ($format !~ /notime/ and (int($h) || int($min))) {
		$day = $friendlyDay || int($d)."&nbsp;$months[$m] $y";
		return $day.", $h:$min";

	} elsif (int($d) && int($y)) {
		$day = $friendlyDay || int($d)."&nbsp;$months[$m] $y";
	    return $day;

	} else {
	    return "";
	}

}


sub dehtml {
# --------------------------------------------------------
	my $str = shift;

	
	$str =~ s/<style[^<]*<\/style>//gs;
	$str =~ s/\&oacute;/ó/gs;
	$str =~ s/<[^>]*>//gs;
	$str =~ s/&[^\;]*;/ /g;
	$str =~ s/[\s\t]+/ /g;
	return $str;
}

sub dehtml_space {
# --------------------------------------------------------
	my $str = shift;
	$str =~ s/<!(?:--(?:[^-]*|-[^-]+)*--\s*)>//gs;
	$str =~ s/<[^>]*>/ /gs;
	$str =~ s/&nbsp;/ /gs;
	return $str;
}


sub formatTime {
# --------------------------------------------------------
	my $seconds = shift;
	my $output = "";

	if ($seconds>3600) {
		$output .= floor($seconds/3600) .":";
		$seconds = $seconds - floor($seconds/3600)*3600;
	}
	if ($seconds>60 || $output ne "") {
		if ($output ne "") {
			$output .= sprintf("%02d", floor($seconds/60)) .":";
		} else {
			$output .= floor($seconds/60) .":";
		}
		$seconds = $seconds - floor($seconds/60)*60;
	} 

	if ($output ne "") {
		$output .= sprintf("%02d", $seconds);
	} else {
		$output .= "0:".sprintf("%02d", $seconds);
	}
	return $output;
}

sub formatBytes {
# --------------------------------------------------------
	my $bytes = shift;
	my $output = "";

	if ($bytes>1000000000) {
		$output .= floor($bytes/1000000000).".";
		$bytes = $bytes - floor($bytes/1000000000)*1000000000;
		$output .= sprintf("%02d",floor($bytes/10000000)) . " GB";
	} elsif ($bytes>1000000) {
		$output .= floor($bytes/1000000).".";
		$bytes = $bytes - floor($bytes/1000000)*1000000;
		$output .= sprintf("%02d",floor($bytes/10000)) . " MB";
	} elsif ($bytes>1000) {
		$output .= floor($bytes/1000) . " kB";
	} else {
		$output .= $bytes . " bytes";
	}

	return $output;
}
 

sub simpleAscii {
# --------------------------------------------------------
# simple ASCII characters only

	my $line = shift;
	$line = _utf8_on($line);
	eval{
	unidecode($line);

	$line =~ s/[\s\-]+/-/g;
	$line =~ s/_+/_/g;
	$line =~ tr/[A-Z]/[a-z]/;
	$line =~ s/[^a-z_0-9\-]//g;
	};
	return $line;
}


sub trim {
# --------------------------------------------------------
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/^\t+//;
	$string =~ s/\s+$//;
	$string =~ s/\t+$//;
	return $string;
}

sub cutTextTo {
# --------------------------------------------------------
	my $text = shift;
	my $to = shift || 200;

	if (length($text) > $to) {
		$text = substr($text, 0, $to);
		$text =~ s/(.*)\s\S+$/$1/g;
		$text .= "&hellip;";
	}
	return $text;
}


sub cutLongText {
	my $mach = shift;
	if ($mach =~ /^(http|www)/) {return $mach};
	$mach =~ s/(.{60})(?=.)/$1 /sg;
	return $mach;
}

sub smartContent {
# --------------------------------------------------------
	my $output = shift;
	my $nofollow = shift;
	
	my $nofollow_text = " rel='nofollow'" if ($nofollow);

	$output =~ s/</&lt;/g;
	$output =~ s/(\S{60,})/cutLongText($1)/ge;
	$output =~ s/http(s)*:\/\/(\S+)/" <a href='http$1\:\/\/$2'$nofollow_text>" . cutTextTo($2, 50) . "<\/a>"/ge;
	$output =~ s/\s(www\.\S+)/" <a href='http\:\/\/$1'$nofollow_text>" . cutTextTo($1, 50) . "<\/a>"/ge;
	$output =~ s/\n/<br\/>\n/g;
	$output =~ s/^(<br\/>\s*)*//g;
	$output =~ s/(<br\/>\s*)*$//g;

	return $output;	
}




sub findValueUpTree {
# --------------------------------------------------------
	my $label = shift;
	my $page_id = shift || $Wywrota::request->{content}{current}{page_id};
	my ($val, $page);

	
	while ($page_id) {
		$page = Wywrota->page->{$page_id};
		$val = $page->{$label} if ($page->{$label});
		return $val if ($val);
		$page_id = $page->{parent_id}
	}
	return $val;
}


sub moonPhase {
# --------------------------------------------------------
	my $self = shift;
	my ($MoonPhase, $iconSize, $x, $y, @phases );
	@phases = ('nów', '', '', 'pierwsza kwadra', '', 'wkrótce pełnia', 'pełnia', '', '', 'ostatnia kwadra', '', 'wkrótce nów');

	$MoonPhase = Astro::MoonPhase::phase();
	
   
	$iconSize = 26;
	$MoonPhase = int ($MoonPhase*12.0 + 0.5);
	$MoonPhase = 11 if ($MoonPhase>11);
	
	
	$y = ($MoonPhase%2) * $iconSize;
	$x = ($MoonPhase * $iconSize - $y) /2;

	$x .= "px"; 	
	$y .= "px";
	$iconSize .= "px";

	return qq~
		<div style="background-position: -$y -$x; width: $iconSize; height: $iconSize" class="moonPhase" title="$phases[$MoonPhase]">&nbsp;</div>
	~;
	 
}

sub flatButton {
# --------------------------------------------------------
	my $link = shift;
	return qq| 	
		<span class="flatButton">
			<a href="$link->{link}" class="$link->{class}" onclick="$link->{onclick}" > $link->{title}</a>
		</span>
	|;
}

sub timeAlias {
# --------------------------------------------------------
# parses such strings as '+1M', '+3w', 
# from CGI::Session

    my ($str) = @_;

    # If $str consists of just digits, return them as they are
    if ( $str =~ m/^\d+$/ ) {
        return $str;
    }

    my %time_map = (
        s           => 1,
        m           => 60,
        h           => 3600,
        d           => 86400,
        w           => 604800,
        M           => 2592000,
        y           => 31536000
    );

    my ($koef, $d) = $str =~ m/^([+-]?\d+)(\w)$/;

    if ( defined($koef) && defined($d) ) {
        return $koef * $time_map{$d};
    }
}


sub mergeHashRef {
# --------------------------------------------------------
# adds keys/vals from the second hash to the first
	my $hash1 = shift;
	my $hash2 = shift;	
	foreach (keys %{$hash2}) {
		$hash1->{$_} = $hash2->{$_};
	}
	return $hash1;
}




sub attachTrackingParams {
# ----------------------------------------------------
	my $txt = shift;
	my $utm_medium = shift || 'site';
	my $utm_campaign = shift || 'ucd';
	my $utm_content = shift;
	return $txt;

	my $suffix = "?utm_source=wywrota&utm_medium=$utm_medium&utm_campaign=$utm_campaign&utm_content=$utm_content";
	
	$txt =~ s/(href=\"[^\"]*)\"/$1$suffix"/g;
	return $txt;
}

sub fixBrokenUTF8Chars {
# ----------------------------------------------------
	my $output = shift;

	$output =~ s/Ä…/ą/g;
	$output =~ s/Ä™/ę/g;
	$output =~ s/Ã³/ó/g;
	$output =~ s/Å›/ś/g;
	$output =~ s/Å‚/ł/g;
	$output =~ s/Åº/ź/g;
	$output =~ s/Å¼/ż/g;
	$output =~ s/Ä‡/ć/g;
	$output =~ s/Å„/ń/g;
	

	$output =~ s/Ä„/Ą/g;
	$output =~ s/Ä˜/Ę/g;
	$output =~ s/Ã“/Ó/g;
	$output =~ s/Åš/Ś/g;
	$output =~ s/Å/Ł/g;
	$output =~ s/Å¹/Ź/g;
	$output =~ s/Å»/Ż/g;
	$output =~ s/Ä†/Ć/g;
	$output =~ s/Åƒ/Ń/g;

	return $output;
}


sub encodeMime {
#-------------------------------
	my $text = shift;
	$text = encode('MIME-Q', _utf8_on($text));
	return $text;
}

sub avoidUppercase {
#-------------------------------
	my $text = shift;
	if ($text =~ /^[ \p{Uppercase}ĘÓĄŚŁŻŹĆŃ\d]+$/) {
		$text = lc($text);
		$text =~ s/Ę/ę/g;
		$text =~ s/Ó/ó/g;
		$text =~ s/Ą/ą/g;
		$text =~ s/Ś/ś/g;
		$text =~ s/Ł/ł/g;
		$text =~ s/Ż/ż/g;
		$text =~ s/Ź/ź/g;
		$text =~ s/Ć/ć/g;
		$text =~ s/Ń/ń/g;
		$text = ucfirst($text);

	}
	return $text;
}


1;

