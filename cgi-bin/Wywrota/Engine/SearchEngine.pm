package Wywrota::Engine::SearchEngine;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Class::Singleton;
use base 'Class::Singleton';

use Time::Local;
use Data::Dumper;
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Log;
use Data::Structure::Util qw(_utf8_off);

use HTTP::Request::Common;
use LWP::UserAgent;
use URI::Escape;

		
sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;

	return $self;

}

sub action {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $params = $ENV{'REQUEST_URI'};
	my ($ua, $res);
	my ($key, $value, $p);
	
	$params =~ s/^\/search\/[\?]//g;
	$params =~ s/^\/db[\?]//g;		# opensearch backwards compat
	$params =~ s/keyword=/q=/g;		# opensearch backwards compat
	
	
	foreach (split(/\&/,$params)) {
		($key, $value) = split(/=/,$_);
		$value=~ tr/+/ /;
		$p->{$key}=uri_unescape($value);
	}


	return "Status: 302 Found\n"
			. "Location: ". $config{site_url}."/googlesearch.html?q=" . $p->{'q'} ."\n\n" ;	
	
	
	eval {
		$ua = LWP::UserAgent->new(timeout=>10);
		$res = $ua->request(GET $config{solr_url} . "browse?v.layout=layout_include&" . $params);
		
		Wywrota::Log::logSearch(
			$p->{'q'}, 
			0, 
			0,
			$p->{'utm_content'},
			$p->{'fq'}
		);		

	};
	
	if ($res->is_error || $@) {
		return Wywrota->errorPage("Przepraszamy", "Wyszukiwarka jest chwilowo niedostępna");
	}


	return Wywrota->t->wrapHeaderFooter({
		title => "wyniki wyszukiwania",	
		nomenu=>  'bar', 
		nocache=> 1,
		styl_local => 'search.css',
		output =>  $res->content 
	});

}

sub quickSearch {
# --------------------------------------------------------
	my $self = shift;
	my $keyword = shift;
	my ($ua, $res);	
	
	eval {
		$ua = LWP::UserAgent->new(timeout=>10);
		$res = $ua->request(GET $config{solr_url} . "browse?v.layout=layout_basic&q=" . $keyword);
		
		Wywrota::Log::logSearch(
			$keyword, 
			0, 
			0,
			"quick_search",
			$p->{'fq'}
		);		

	};
	
	if ($res->is_error || $@) {
		return "Wyszukiwarka jest chwilowo niedostępna";
	}
	
	
	
	return $res->content ;
	
}



1;