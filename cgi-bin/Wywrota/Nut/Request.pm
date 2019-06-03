package Wywrota::Nut::Request;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# $Wywrota::request->{urlPrefix}
# $Wywrota::request->{urlSufix}
# $Wywrota::request->{language}{id}
# $Wywrota::request->{language}{prefix}
# $Wywrota::request->{nav}{crumbLinks}
# $Wywrota::request->{log}{...}
#
# $Wywrota::request->{content}{current}{...} 
# $Wywrota::request->{content}{current}{url}
# $Wywrota::request->{content}{current}{name}
# $Wywrota::request->{content}{current}{page_id}
# $Wywrota::request->{content}{current}{tablename}
# $Wywrota::request->{content}{current}{sql_view}
#
#-----------------------------------------------------------------------

 
use strict;
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Clone qw(clone);


sub new {
# --------------------------------------------------------
    my $class = shift;
	my $nut = shift;
	my $cgiRequest = shift;

    my $self = bless {
		_nut=>$nut,
		_request => $cgiRequest,
		time => time()
	}, $class;

	$self = eval {
		
		$self->{_in} = $self->checkParams();


		return $self if (!$self->checkSubdomain());		# returs 0 if we're redirecting

		$self->checkContent();
		$self->checkPage();
		return $self;
	};
	Wywrota->error("error in Request:new",$@) if ($@);

	return $self;
}




sub checkSubdomain {
# --------------------------------------------------------
	my $self = shift;
	my ($cid);

	$self->{language}{id} = 1;
	$self->{language}{prefix} = "";
	
	# IP request
	if ($ENV{HTTP_HOST} =~ /\d+\.\d+\.\d+\.\d+/ && $config{allow_ip_request}) {
		$self->{urlPrefix}='www';
		$self->{subdomain_url} = $ENV{HTTP_HOST};
		$self->{content}{current} = clone( Wywrota->cc->{ 3 } );
		return 1;
	}
	
	if ($ENV{HTTP_HOST} !~ "(wywrota|subverse)") {
		$self->{_redirect} = $config{site_url};
		return 0;
	}
	

	# defined content or defined subdomain
	my @token = split(/\./, $ENV{HTTP_HOST});

	if ($#token<2) {
		# we have 'localhost' or something similar
		$self->{urlSufix}=$ENV{HTTP_HOST};

	} else {

		# we have regular domain name with at least two dots
		$self->{urlSufix}=$token[$#token-1].".".$token[$#token];
		
		
		if ($token[$#token-2] eq 'spiewnik') {
		
			# SEO improvement - spiewnik = teksty		
			$self->{_hardredirect} = "http://teksty." . $self->{urlSufix} . $ENV{REQUEST_URI};
			return 0;
		
		} else {

			foreach (keys %{$config{'subdomains'}}) {
				$cid = $config{'subdomains'}{$_}[0];

				if ($_ eq $token[$#token-2]) {
					# znalezlismy cid dla subdomeny z zapytania
					$self->{urlPrefix}=$token[$#token-2];
					$self->{subdomain_url} = "http://$_." . $self->{urlSufix} ."/";
					$self->{content}{current} = clone( Wywrota->cc->{ $cid } );
				}

				
			}

		}
		

	}

	# dodaj prefix 'www'
	if ( !$self->{urlPrefix} and $token[$#token] !~ /^\d+$/ ){
		$self->{_hardredirect} = "http://www." . $self->{urlSufix} . $ENV{REQUEST_URI};
		return 0;
	}

	# wiecej niz 3 tokeny np. www2.literatura.wywrota.pl
	if ( $#token>2 and $token[$#token] !~ /^\d+$/ ){
		$self->{_hardredirect} = "http://".$self->{urlPrefix}."." . $self->{urlSufix} . $ENV{REQUEST_URI};
		return 0;
	}



	return 1;
}




sub checkContent {
# --------------------------------------------------------
	my $self = shift;
	my ($id, $VAR1, $cc, $subdomain);
	my $in_db = $self->in('db');

	Wywrota->trace("Request :: checkContent");
	
	return if ($self->{content}{current} && !$in_db);  # by default return what we have

	Wywrota->trace("Request :: checkContent 2");
	foreach $id (keys %{Wywrota->app->{cc}}) {
		if (grep(/^$in_db$/,   split(/,/, Wywrota->cc->{$id}{url})  )) {
			$cc = clone( Wywrota->app->{cc}->{$id} );
			last;
		}
	}

	if ($in_db eq 'spiewnik') {
		$cc = clone( Wywrota->app->{cc}->{7} );
	}
	

	if (!$cc) {
		Wywrota->warn("Session : not found cid for '$in_db'") if ($in_db);
		# default : artykuly
		$cc = clone(  Wywrota->app->{cc}->{3}); 
	}


	$subdomain = $config{'subdomains_cid'}{ $cc->{id} } || 'www';

	# check if we are in good subdomain
	if ( !$self->nut->opt('include') &&  ($subdomain ne  $self->{urlPrefix}) ) {

		$self->{_redirect} = "http://$subdomain." . $self->{urlSufix} . $ENV{REQUEST_URI};
		return 0;
	
	}



	$self->{content}{current} = $cc;

}



sub checkPage {
# --------------------------------------------------------
	my $self = shift;
	my $page;
	my $suffix = $self->{urlSufix};

	my $uri = $ENV{REQUEST_URI};
	$uri =~ s/\?.*$//g;
	
	Wywrota->debug("checkPage",  $uri, "http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}");

	foreach (sort {$b <=> $a} keys  %{Wywrota->page}) {
		$page = Wywrota->page->{$_};
		next if ($self->{language}{id} != $page->{lang});

		# - include_template

		$page->{url} =~ s/wywrota\.pl/$suffix/g;

		if ( $page->{url} eq $uri || 
			 $page->{url} eq $uri."index.html" ||
			 $page->{url} eq "http://$ENV{HTTP_HOST}$uri" || 
			 $page->{url} eq "http://$ENV{HTTP_HOST}/index.html" ) 
		{
			#Wywrota->debug("SESSION !!!!!!!!!");
			$self->{content}{current}{page_id} = $page->{id};
			$self->{content}{current}{page} = clone( $page );
			last;
		}
	}
	$self->{nav}{crumbLinks} = Wywrota->nav->crumbTrailLinks( $self->{content}{current}{page_id} );

	$self->{content}{current}{is_home} = (defined ($self->{content}{current}{page}{parent_id}) and !$self->{content}{current}{page}{parent_id});

}



sub checkParams {
# --------------------------------------------------------
	my $self = shift;
	my $request = $self->{_request};
	my ($in, $key, $value);


	if ((ref $request) =~ /^$/) {
		# string
		foreach (split(/\&/,$request)) {
			($key, $value) = split(/=/,$_);
			$in->{$key}=$value;
		}
	} elsif ($request->isa('HTTP::Engine::Request')) {
		# HTTP::Engine::Request
		foreach (keys %{$request->params}) {
			$in->{$_} = $request->param($_) if (length($_));
		}

	} elsif ($request->isa('CGI::Fast')) {
		# CGI::Fast
		foreach ($request->param) {
			$in->{$_} = $request->param($_) if (length($_));
		}

	} elsif ($request->isa('HTTP::Request')) {
		# HTTP::Request
		foreach (@{$request->{'.parameters'}}) {
			$in->{$_} = $request->{$_}[0] if (length($_));
		}

	} else {
		Wywrota->error("Bad request type.");
	}

	cleanCustomTags($in);

	Wywrota->debug("Nut::Request : checkParams ", $in); #, $in, $request

	return $in;
}




sub cleanCustomTags {
# --------------------------------------------------------
	my $in = shift;
	my (@pairs, $i);
	
	if ($in->{_qs}) {

		@pairs = split (/[\/,=\?]/, $in->{_qs});

		# /1222_record_name.html
		if ($in->{_qs} =~ /^(\d+)[^,]+\.html$/) {
			$in->{view} = $1;
			pop @pairs;
	
		# /register
		} elsif ($in->{_qs} =~ /^register$/) {
			$in->{add} = 1;
			$in->{db} = 'ludzie';
			pop @pairs;

		# /db/set/
		} elsif ($in->{_qs} =~ /^db\/([^\/]+)$/) {
			$in->{db} = $1;
			$in->{landing_page} = 1;
			

		# /db/set/1222_record_name.html
		} elsif ($in->{_qs} =~ /^db\/([^\/]+)\/(\d+)[^,]*(\.html)?$/) {
			$in->{view} = $2;
			$in->{db} = $1;
			pop @pairs;
						
		# /ludzie/arek
		} elsif ($in->{_qs} =~ /^ludzie\/([^\/]+)$/) {
			$in->{wywrotid} = $1;
			$in->{db} = 'ludzie';
			$in->{view} = 'on';
			$in->{ww} = 1;

		# /ludzie/arek/photos
		} elsif ($in->{_qs} =~ /^ludzie\/([^\/]+)\/([^\/]+)$/) {
			$in->{wywrotid} = $1;
			$in->{action} = $2;
			$in->{db} = 'ludzie';

		# /site/xx.html
		} elsif ($in->{_qs} =~ /^site\/([^\/]+)\.html$/) {
			$in->{siteAction} = $1;
			
		# /user/xx.html
		} elsif ($in->{_qs} =~ /^user\/([^\/]+)(\.html)?$/) {
			$in->{userAction} = $1;
			
		} elsif (!$#pairs) {

			# /historia/costam.html
			if ($in->{_qs} =~ /\.html$/) {
				$in->{content_include} = $in->{_qs};

			# /adam_mickiewicz/
			} elsif ($in->{_qs} =~ /\/$/) {
				$in->{urlized} = $in->{_qs};
				chop $in->{urlized};
			}

		} else {
			for ($i=0; $i<$#pairs; $i=$i+2) {
				$in->{$pairs[$i]} = $pairs[$i+1];
			}
		}
		
		$in->{$pairs[$#pairs]}=1 unless ($#pairs %2);
		delete $in->{_qs};
	}

	# process date and time fields
	foreach (keys %{$in}) {
		if (/^time_h_(.+)/) {
			$in->{$1} = $in->{"date_$1"} 
				." ". sprintf("%02d",$in->{"time_h_$1"}) 
				.":". sprintf("%02d",$in->{"time_m_$1"}) 
				.":". sprintf("%02d",$in->{"time_s_$1"}) if ($in->{"date_$1"});
			delete $in->{"date_$1"} ;
			delete $in->{"time_h_$1"} ;
			delete $in->{"time_m_$1"} ;
			delete $in->{"time_s_$1"} ;

		}
		$in->{$1} = '' if ($in->{$1} eq '0000-00-00');
		$in->{$1} = '' if ($in->{$1} eq '0000-00-00 00:00:00');
		
		## SEO optimisation - underscores to dashes
		if (/urlized/) {
			$in->{$_} =~ s/_/\-/g;
		}
	}

	return $in;
}


sub nut {
# --------------------------------------------------------
	my $self = shift;
	return $self->{_nut};
}

sub in {
# --------------------------------------------------------
	my $self = shift;
	my $variable = shift;

	return $self->{_in}{$variable} if ($variable);
	return $self->{_in};
}


sub redirect : lvalue {
# --------------------------------------------------------
	my $self = shift;
	$self->{_redirect};
}

sub hardredirect  : lvalue{
# --------------------------------------------------------
	my $self = shift;
	$self->{_hardredirect};
}


sub DESTROY {
# --------------------------------------------------------
	my $self = shift;
	foreach (keys %{$self->in} ) {
		delete $self->in->{$_};
	}
	foreach (keys %{$self} ) {
		delete $self->{$_};
	}
	
	undef $self;
}


1;