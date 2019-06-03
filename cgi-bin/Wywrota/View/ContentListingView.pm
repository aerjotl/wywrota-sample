package Wywrota::View::ContentListingView;

#-----------------------------------------------------------------------
# Pan Wywrotek
# Content Listing Manager 
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

 
use Class::Singleton;
use base 'Class::Singleton';

use strict;
use Wywrota;
use Data::Dumper;
use HTTP::Date;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;




sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $mng = shift;
	my $self  = bless { mng=> $mng}, $class;

	return $self;
}




sub searchOptions {
# --------------------------------------------------------
# Search options to be displayed at the bottom of search forms.
	my $self = shift;
	my ($output, $field);
	my $tableDef = $Wywrota::request->{content}{current}{cfg};

	$output = qq~
	<table width="100%" class="searchRow1"><tr>
	<td class="small">
		<input type="checkbox" name="ma"> sprawdzaj każde pole<br>
		<input type="checkbox" name="cs"> sprawdzaj wielkość liter
	</td>

	<td class="small">
		<input type="checkbox" name="ww"> tylko całe słowa<br>
		<input type="checkbox" name="re"> wyrażenia regularne
	</td>
	</tr></table>

	<table class="searchRow1" width="100%"><tr><td class="txtnews">
		<b>sortuj wg:</b>~;
		foreach (sort ({$tableDef->{$a}[0] <=> $tableDef->{$b}[0]} keys %{$tableDef})) { 
			$field = msg($tableDef->{$_}[6]) || $_; 
			$output .= qq~<nobr><input type="radio" name="sb" value="$_">$field</nobr>\n~ 
				if ($tableDef->{$_}[2] !~ /_hid|_ao|_ao_ne/ ); 
		} 
		$output .= qq~
		</td>
	<td align="right" nowrap="nowrap" class="small">
		<b>
		<input type="radio" name="so" value="ascend" checked>rosnąco
		<input type="radio" name="so" value="descend">malejąco
		</b>
	</td>
	</tr></table>
	~;
}



sub viewSearch {
# --------------------------------------------------------
# This page is displayed when a user requests to search the 
# database for viewing. 
#
	my $self = shift;
	my $in = shift;
	my $czego=Wywrota::Language::plural(0, $Wywrota::request->{content}{current}{keyword});
	my ( $output, $obj);



	eval {
		$obj = Wywrota->content->createObject();
		$output = Wywrota->view->recordForm($obj, undef, undef, undef, 'search'); 
	};
	Wywrota->error("viewSearch : Error.\n ".$@) if ($@);

	$output = qq~
		
		<h1>Szukaj $czego</h1>
		
		<form action="/db" method="GET" name="record_form">
			<input type="hidden" name="db" value="$Wywrota::request->{content}{current}{url}">
		
			$output
		
			<div class="formButtons">
				<input type="submit" name="viewrecords" value="     SZUKAJ     " class="bold">
			</div>
		
			~ . $self->searchOptions() . qq~
	
		</form>
	~;
	

	return Wywrota->view->wrapHeaderFooter({
		title => "szukaj $czego",
		nomenu => "left",
		nocache => 1,
		output  => $output,		
	});
}



sub viewRecords {
# --------------------------------------------------------
# This is called when a user is searching the database for 
# viewing. All the work is done in query() and the routines just
# checks to see if the search was successful or not and returns
# the user to the appropriate page.

	my $self = shift;
	my $in = shift;

	Wywrota->trace("in viewRecords() ", $in);

	my $queryRes = $self->{mng}->query($in);
	

	if ($queryRes->{status} eq "ok") {
	
		return Wywrota->view->wrapHeaderFooter({
			title => $Wywrota::request->{content}{current}{page}{title}." - ".$Wywrota::request->{content}{current}{title},	
			nomenu=>  $Wywrota::in->{nomenu},
			output=> $self->includeQueryResults($queryRes, undef, $queryRes->{in}{generate}),
			nocache=> $Wywrota::in->{nh} > 10
		});
	
	} else {
	
		if ($in->{generate}) {
			return "";
		} else {
			Wywrota->sysMsg->push( msg('not_found_any') ." " .Wywrota::Language::plural(0, $Wywrota::request->{content}{current}{keyword}) , 'err');
			return $self->viewSearch($in);
		}

	}

}





sub includeQueryResults {
# --------------------------------------------------------
# usage:
# 	$output .= Wywrota->cListView->includeQueryResults($queryRes, $title, 1);

	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $generate = shift;
	my $forceHeaders = shift;
	my ($output, $object, $cnt);


	if ($forceHeaders || ($queryRes->{status} eq "ok" and $queryRes->{cnt}>=0)) {

		foreach (@{$queryRes->{hits}}) {
			$cnt++;
			$object =  Wywrota->content->createObject( $_, $queryRes->{contentDef}->{package} )  ;
			$object->listIndex = $cnt;
			
			if ($generate eq 'newsletter') {
				$output .= $object->recordNewsletter()
			} elsif ($queryRes->{in}->{small}) {
				$output .= $object->recordSmall();
			} elsif ($queryRes->{in}->{medium}) {
				$output .= $object->recordMedium();
			} else {
				$output .= $object->record() 
			}
				
			undef $object;
		}

		#$output = msg($queryRes->{msg}) if (!$queryRes->{cnt});

		if ($generate) {
			$output = Wywrota->view->view( $queryRes->{contentDef}{cid} )->searchHeaderGenerate($queryRes, $tytul)
			. ( $queryRes->{in}->{mh}==1  ?  $output : '<div class="recordList">' . $output . '</div>')
			. Wywrota->view->view( $queryRes->{contentDef}{cid} )->searchFooterGenerate($queryRes, $tytul);
		} else {
			$output = Wywrota->view->view( $queryRes->{contentDef}{cid} )->searchHeader($queryRes, $tytul)
			. $output 
			. Wywrota->view->view( $queryRes->{contentDef}{cid} )->searchFooter($queryRes, $tytul);
		}
	
	} else {
		return ;#msg($queryRes->{msg});
	}
	return $output;
}



sub mng {shift->{mng}}

1;