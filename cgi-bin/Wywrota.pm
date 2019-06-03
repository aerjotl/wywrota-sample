package Wywrota;

#-----------------------------------------------------------------------
#   ___            __      __                   _       _   
#  | _ \__ _ _ _   \ \    / /  ___ __ ___ _ ___| |_ ___| |__
#  |  _/ _` | ' \   \ \/\/ / || \ V  V / '_/ _ \  _/ -_) / /
#  |_| \__,_|_||_|   \_/\_/ \_, |\_/\_/|_| \___/\__\___|_\_\
#                           |__/                            
#
#-----------------------------------------------------------------------
# Copyright (c) 1998-2011 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

 
use strict; 
use Class::Singleton;
our @ISA = qw(Exporter Class::Singleton);

use Data::Dumper;
use Data::Structure::Util qw(_utf8_off _utf8_on has_utf8 utf8_off utf8_on);

use Wywrota::Nut;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Log;
use Wywrota::File;
use Wywrota::Engine::ContentListingEngine;
use Wywrota::Nut::Session;
use Wywrota::Application;
use Wywrota::Controller;
use Wywrota::QueryRes;

use Wywrota::DAO::DBUtils;
use Wywrota::Nut::Security;
use Wywrota::MemCache;
use Wywrota::Cache;
use Wywrota::Debug;
use Wywrota::View::Template;
use Wywrota::View::ContentListingView;
use Wywrota::Engine::ContentEngine;
use Wywrota::Engine::VoteEngine;
use Wywrota::Engine::SearchEngine;
use Wywrota::View::Navigation;
use Wywrota::Message;
use Wywrota::Nut::SysMessage;
use Wywrota::LastFM;
use Wywrota::SpamFilter;

my $instance;
my $session;
my $request;
my $in;


sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { db=>{}, app=>{} }, $class;
	my $cgi_dir = shift;
	my $env = shift;
	$instance = $self;

	Wywrota::Config::loadConfig($cgi_dir, $env);
	Wywrota->trace("Wywrota_new_instance");

	eval {
		$self->{db} = Wywrota::DAO::DBUtils->instance();
		$self->{app} = Wywrota::Application->instance();
		$self->{content} = Wywrota::Engine::ContentEngine->instance( $self->{app} );
		$self->{contentView} = Wywrota::View::ContentView->instance( $self->{app}, $self->{content} );
		$self->{cListEngine} = Wywrota::Engine::ContentListingEngine->instance();
		$self->{cListView} = Wywrota::View::ContentListingView->instance( $self->{cListEngine} );
		$self->{security} = Wywrota::Nut::Security->new();
		$self->{fav} = Wywrota::Favorites->instance();
		$self->{nav} = Wywrota::View::Navigation->instance();
		$self->{vote} = Wywrota::Engine::VoteEngine->instance();
		$self->{msg} = Wywrota::Message->instance();
		$self->{sysMsg} = Wywrota::Nut::SysMessage->new();
	
	};

	Wywrota->error("Wywrota : Error initialising application.", $@) if ($@);

	$self->dbug->htmlEngineReady = 1;

	return $self;
}



sub processRequestNut {
#-----------------------------------------------------------------------

	my $nut = shift;
	my ($output);

	$output = $instance->overloadProtect();
	return $output if ($output);

	$output = $instance->ipBlock();
	return $output if ($output);

	eval {
		
		#  --- log record views -------------------------
		if (int($Wywrota::in->{view})) {
			Wywrota::Log::log( $Wywrota::request->{content}{current}{id}, $Wywrota::in->{view}, 1);
		}
		if (int($Wywrota::in->{parent_id}) && $Wywrota::in->{db} eq 'forum') {
			Wywrota::Log::log( $Wywrota::request->{content}{current}{id}, $Wywrota::in->{parent_id}, 1);
		}

		unless ($output = $instance->cache->getFromCache("$ENV{QUERY_STRING}.$ENV{HTTP_HOST}")) {

			# -------------------------
			# main function
			# -------------------------
			$output= Wywrota::Controller::main($nut);
			$instance->cache->storeCache("$ENV{QUERY_STRING}.$ENV{HTTP_HOST}", $output) unless ($Wywrota::request->{nocache});
			
		}

		$output .= $instance->dbug->debugInfo();

		$instance->onRequestEnd();
		
	};

	Wywrota->error("Wywrota : Error in processRequestNut.",$@) if ($@);


	utf8_off($output);
	
	return fixBrokenUTF8Chars($output);

}


sub ipBlock {
#-----------------------------------------------------------------------
	foreach (keys %{$config{'blocked_ip'}})	{
		if ($_ eq $ENV{REMOTE_ADDR}) {
			return Wywrota->template->ipBlocked();
		}
	}
	return;
}



sub overloadProtect {
#-----------------------------------------------------------------------
# performance - block multiple requests from one IP

	my $sleeping;
	if ($config{'block_multiple_ip'}) {
		while ((-e "$config{tmp_dir}/ip/$ENV{REMOTE_ADDR}")) {
			sleep(2); # X seconds
			$sleeping++;
			if ($sleeping>30) {
				Wywrota->db->execWriteQuery("INSERT INTO wywrota_log.overload  VALUES (?, ?, ?, NOW())", 
					int($Wywrota::session->{user}{id}),	
					$ENV{'REMOTE_ADDR'},
					"http://$ENV{HTTP_HOST}$ENV{REQUEST_URI}"
				);
				return Wywrota->template->serverOverloaded();
			}
		};

		# setting mutex
		open "FILE", ">$config{tmp_dir}/ip/$ENV{REMOTE_ADDR}";
			print(FILE time()."\n");
			print(FILE "$ENV{CONTENT_LENGTH}  $ENV{QUERY_STRING}  $ENV{HTTP_HOST} \n\n" . Dumper(\%ENV) );
		close FILE;
	}
	return;

}



sub onRequestEnd {
#-----------------------------------------------------------------------

	if ($config{'block_multiple_ip'}) {
		unlink ("$config{tmp_dir}/ip/$ENV{REMOTE_ADDR}");
	}

	foreach (keys %{$session}) { delete $session->{$_}; }
	foreach (keys %{$request}) { delete $request->{$_}; }
	foreach (keys %{$in}) { delete $in->{$_}; }
	
}



sub app { $instance->{app} }
sub db : lvalue { $instance->{db} }
sub cc { shift; $instance->{app}->cc(@_) }

sub page { $instance->{app}->{page} }
sub dict { $instance->{app}->{dict} }
sub initialised { $instance->{initialised} if ($instance) }

sub content { $instance->{content} }
sub contentView { $instance->{contentView} }

sub queryEngine { $instance->{cListEngine} }
sub cListEngine { $instance->{cListEngine} }		#deprecated

sub cListView { $instance->{cListView} }
sub mng { shift; $instance->{content}->mng(@_) }
sub widget { shift; $instance->{widget}->widget(@_) }

sub fav { $instance->{fav} }
sub nav { $instance->{nav} }
sub adv { $instance->{adv} }
sub msg { $instance->{msg} }
sub cache { Wywrota::Cache->instance( $config{cache} ); }
sub memCache { Wywrota::MemCache->instance(); }
sub file { Wywrota::File->instance() }
sub view { $instance->{contentView} }
sub vote { $instance->{vote} }
sub sysMsg { $instance->{sysMsg} }
sub per { shift; $instance->{security}->per(@_) }
sub perRecord { shift; $instance->{security}->perRecord(@_) }



sub staticMain { shift; Wywrota::Controller::main(@_) }


sub t : lvalue { shift->template }
sub template : lvalue { 
	my $self = shift;
	unless (exists $instance->{template}) {
		$instance->{template} = Wywrota::View::Template->instance();
	}
	$instance->{template};
}


sub searchEngine : lvalue { 
	my $self = shift;
	unless (exists $instance->{searchEngine}) {
		$instance->{searchEngine} = Wywrota::Engine::SearchEngine->instance();
	}
	$instance->{searchEngine};
}



sub dbug : lvalue { 
	my $self = shift;
	unless (exists $instance->{_debug}) {
		$instance->{_debug} = Wywrota::Debug->new( $config{debug_level} );
	}
	$instance->{_debug};
}



sub lastfm : lvalue { 
	my $self = shift;
	unless (exists $instance->{_lastfm}) {
		$instance->{_lastfm} = Wywrota::LastFM->instance();
	}
	$instance->{_lastfm};
}

sub spamFilter : lvalue { 
	my $self = shift;
	unless (exists $instance->{_spamFilter}) {
		$instance->{_spamFilter} = Wywrota::SpamFilter->instance();
	}
	$instance->{_spamFilter};
}




sub trace { shift; $instance->dbug->trace(@_) }
sub debug { shift; $instance->dbug->debug(@_) }
sub warn { shift; $instance->dbug->warn(@_) }
sub error { shift; $instance->dbug->error(@_) }

sub errorMsg { shift; $instance->dbug->errorMsg(@_) }
sub errorPage { shift; $instance->dbug->errorPage(@_) }
sub dbException { shift; $instance->dbug->dbException(@_) }
sub unknownAction { shift; $instance->dbug->unknownAction(@_) }




1;