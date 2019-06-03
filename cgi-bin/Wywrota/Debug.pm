package Wywrota::Debug;



use strict;
use Data::Dumper;
use HTTP::Date;
use Time::HiRes qw(gettimeofday tv_interval);
use Wywrota::Config;
use Wywrota::Log;
use Wywrota::Nut::Cookie;
use Wywrota::Utils;


sub new {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { 
		_htmlEngineReady	=> 0,
		_headerPrinted		=> 0,
		_shell				=> ($config{'shell'} ? 1 : 0),
		_logFileName		=> ($config{'log_per_processid'} ? "$config{log_dir}/wywrotek.$$.log" : "$config{log_dir}/wywrotek.log"),
	}, $class;
		
	if ($config{'show_debug'}) {
		# turn on autoflush
		$|++;
	}
	
	$self->resetTimer();

	return $self;
}

sub checkHeader {
# --------------------------------------------------------
	my $self = shift;
	return if ($self->headerPrinted || $self->shell);

	
	
	if ($ENV{REQUEST_URI} =~ 'show_debug') {
		print setCookie("show_debug", 1, 0);
	};
	
	print "Content-type: text/html; charset=utf-8\r\n\r\n";
	print qq~<style type="text/css">
		.traceWW, .debugWW, .warnWW, .errorWW {
			font-family: Tahoma; font-size: 10px; color: gray; text-align:left; margin: 3px 20px ; padding-left: 5px
		}
		
		.traceWW  { border-left:5px solid #DDEEDD;	color: #779977;	}
		.debugWW { border-left:5px solid #AABBCC;	color: #778899;	}
		.warnWW  { border-left:5px solid #CC8822;	color: #665500;	font-size:11px;	background-color:#FFFFCC;		}
		.errorWW { border-left:5px solid #CC5544;	color: red;		font-size:11px;	background-color:#FFE4E2;	padding:8px; }
	</style>~;
	$self->headerPrinted=1;

}

sub trace {	shift->serveArray('trace', @_)	}
sub debug { shift->serveArray('debug', @_)	}
sub warn  {	shift->serveArray('warn', @_)	}
sub error {	shift->serveArray('error', @_)	}

sub serveArray {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $class = shift;
	my ($output, $object);

	my %cookie = getCookie(\%ENV);
	
	my $url_debug = ($ENV{REQUEST_URI} =~ 'show_debug') || $cookie{show_debug};
	
	$self->checkHeader if ($config{debug}{$class} || $url_debug); 

	#return if ($config{'site_config_mode'} eq 'prod' && !$url_debug && $Wywrota::session->{user}{id} ne 1);
		# TODO
		# to jest tymczasowe rozwiazanie, pokazuje debug na serwezre prod tylko dla mnie


	foreach $object (@_) {
		SWITCH: for (ref $object) {

			/^$/		&& do { 
				if    (!defined $object) { $output .= "[ undef ]"}
				elsif (!length($object)) { $output .= "[ empty string ]"}
				else { $output .= "$object"}
				last SWITCH;
				};
			/SCALAR/	&& do { $output .= 'SCALAR ' . Dumper($object); last SWITCH; };
			/ARRAY/		&& do { $output .= 'ARRAY ' . Dumper($object); last SWITCH; };
			/HASH/		&& do { $output .= 'HASH ' . Dumper($object); last SWITCH; };
			/CODE/		&& do { $output .= "function reference" . Dumper($object); last SWITCH; };

			# DEFAULT
			$output .= "<b>$_</b>".Dumper($object);
		}
		$output .= "\n";
	}
	
	if ($config{debug}{$class} || $url_debug) {
		$output = $self->runningTime . $output;
		if ($self->shell) {
			print "[$class] $output";
		} else {
			print "<pre class='$class"."WW'>$output</pre>";
		} 
	}


	if ($config{log}{$class}) {
		open (LOGFILE,">>".$self->logFileName);
		print LOGFILE getDate()." [$class] $output";
		close LOGFILE;
	}
}

sub debugInfo {
#-----------------------------------------------------------------------
	my $output;
	my $self = shift;
	my $run_time = $self->runningTime();
	my ($env_, $in_, $conf_, $sess_);

	my $url_debug = ($ENV{REQUEST_URI} =~ 'show_debug');
	
	if (($config{debug}{debug} || $url_debug) && !$Wywrota::in->{popup}) {
		foreach (keys %ENV) 			{$env_ .=  "\t$_\t=\t$ENV{$_}<br>"  };
		foreach (keys %{$Wywrota::in}) 	{
			my $val = (length($Wywrota::in->{$_}) > 60) ? "[long string]" : $Wywrota::in->{$_};
			$in_ .=  "\t$_\t=\t$val<br>" 
			};
		foreach (keys %config)		{$conf_ .=  "\t$_\t=\t".Dumper($config{$_})."<br>" unless ($_ eq 'mode')};
		$sess_ = Dumper($Wywrota::session);
		
		$output =  qq|
			<div style='text-align: left !important; margin: 30px; padding: 30px; clear: both;'>
				
				<a href="#" class="showHide">ENV</a>
				<div class="hidden">
					$env_
				</div>
				
				<a href="#" class="showHide">Wywrota::in</a>
				<div class="hidden">
					$in_
				</div>
				
				<a href="#" class="showHide">session</a>
				<div class="hidden">
					<pre>$sess_</pre>
				</div>
				
				<br><br>generated. czas skryptu: $run_time
			</div><br><br>
		|;
	} else {
		foreach (keys %{$Wywrota::in}) 	{
			my $val = (length($Wywrota::in->{$_}) > 60) ? "[long string]" : $Wywrota::in->{$_};
			$in_ .=  "\t$_\t=\t$val\n" 
		};
		
		$output .=   qq|\n\n<!-- generated: $run_time -->\n\n|;
		$output .=   qq|<!-- \tWYWROTA::IN ................................ \n\n$in_\n\n\n -->\n\n\n\n\n| if ($config{mode} ne 'prod');
	}
	return $output;
}



sub errorMsg {
# -------------------------------------------------------------------------------------
	my $output;
	my $self = shift;
	my $title = shift;
	my $msg = shift;

	$output .=qq~
		<div class="div_warning">
			<h2>$title</h2>
			$msg
			<p>W razie pytań lub wątpliwości prosimy o <a href="http://www.wywrota.pl/kontakt.html" class="u">kontakt</a>.
		</div>
	~;
	
	return $output;
}

sub errorPage {
# -------------------------------------------------------------------------------------
	my $output;
	my $self = shift;
	my $title = shift;
	my $msg = shift;
	my $content = shift;
	
	Wywrota::Log::logFile("error", $title);

	return $self->wrapHeaderFooter({ 
		title => $title,	
		nomenu=>  'bar',	
		nocache=>  1,
		output	=> $self->errorMsg($title, $msg) . $content
	}) ;
	
	
}


sub unknownAction {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $action = shift;

	return $self->errorPage('błąd systemu', "nieznana akcja: '$action'") ;
}



sub dbException {
# ---------------------------------------------------
# Error prompt.
	my $self=shift;
    my $error = shift;
    my ($message, $show);

	Wywrota::Log::logFile("sql_error", ($error,@_) );

	if ($self->shell) {
		print "\n\n\n$config{generator}\n---------------------------------\nSQL ERROR:\n$error";

	} else {
		
		if ($config{'site_config_mode'} ne 'prod') {
			$show = $error;
		} else {
			$show = qq~DB Exception. W razie problemów prosimy o <a href="/kontakt.html">kontakt z administratorem serwisu</a>.~;
		}

		Wywrota->error($show);

		#die;
	}
}


sub wrapHeaderFooter {
# ---------------------------------------------------
	my $self=shift;
	
	if ($self->htmlEngineReady) {
		return Wywrota->t->wrapHeaderFooter(@_);
	} 
}

sub reset {
# --------------------------------------------------------
	my $self = shift;
	$self->htmlEngineReady 	= 0;
	$self->headerPrinted 	= 0;
}

sub resetTimer {
# --------------------------------------------------------
	my $self = shift;
	$self->timer 	= gettimeofday;
}

sub runningTime {
# --------------------------------------------------------
	my $self = shift;
	return sprintf (" [%.3f s.] ", tv_interval([$self->timer], [gettimeofday]));
}

sub timer : lvalue	{ shift->{_timer};}
sub htmlEngineReady : lvalue	{ shift->{_htmlEngineReady};}
sub headerPrinted : lvalue		{ shift->{_headerPrinted};}
sub shell : lvalue				{ shift->{_shell};}
sub logFileName : lvalue		{ shift->{_logFileName};}


sub DESTROY {
# --------------------------------------------------------
	my $self = shift;
	undef $self;
}

1;