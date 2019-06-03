package Wywrota::Engine::ContentListingEngine;

#-----------------------------------------------------------------------
# Pan Wywrotek
# Content Listing Manager 
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------


use strict;
use Class::Singleton;
use base 'Class::Singleton';

use Wywrota;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Engine::ContentEngine;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::DAO::ContentListingDAO;


sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;

	$self->{dao} = Wywrota::DAO::ContentListingDAO->instance();

	return $self;
}

sub action {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $in = $nut->in;
	my $output;
	my $action = $in->{ca} || $in->{contentAction};

	if    ($action eq 'top')   {  return $self->top();} 
	elsif ($action eq 'topRecords')   {  return $self->topRecords();} 
	elsif ($action eq 'byTag')   {  return $self->byTag();} 
	elsif ($action eq 'listByAuthor')   {  return $self->listByAuthor();} 
	elsif ($action eq 'countTypes')   {  return $self->countTypes($in->{column}, $in->{typ}, 'typ');} 	

	else {	
		return Wywrota->unknownAction($action);
	}
	return $output;
}



sub countTypes {
# --------------------------------------------------------
	my $self = shift;
	my $column = shift;
	my $typ = shift || 1;
	my $fieldname = shift || 'typ';

	return "<h1>seee</h1> $typ || !$column); " if (!$typ || !$column);

	my ($query, $rec, $records, $output, $label );
	my $tablename =  $Wywrota::request->{content}{current}{tablename};
	my $url = $Wywrota::request->{content}{current}{url};

	$query = qq~
		SELECT $column as col, count($column) as cnt FROM $tablename 
		WHERE $fieldname=$typ
			AND _active = 1
		GROUP BY $column
 		ORDER BY cnt DESC
		
	~;
	$records = Wywrota->db->buildHashRefArrayRef($query); 

	foreach $rec (@$records) {
		$label = Wywrota->dict->getLabel($column, $rec->{col});
		$output .=  qq~
		<li><a href="/db/$url/$column/$rec->{col}/typ/$typ">$label</a></li>
		~ if ($label);
	}
	# &nbsp;<span class="cnt">($rec->{cnt})</span>

	$output =  qq~
		<ul class="typeList">
			$output
		</ul>
	~;

	return $output;
}


sub top {
# --------------------------------------------------------
	my $self = shift;
	my ($query, $class, $object, $rec, @records, $str,$place  );
	my ($output );
	my $content_id = shift || $Wywrota::request->{content}{current}{id};
	my $tablename =  shift || $Wywrota::request->{content}{current}{tablename};
	my $limit = $Wywrota::in->{mh} || 20;


	$Wywrota::in->{sb}='tv.count';
	$Wywrota::in->{so}='desc';

	my $queryRes = Wywrota->cListEngine->query($Wywrota::in, "top");
	
	foreach (@{$queryRes->{hits}}) {
		$place++;
		$object = Wywrota->content->createObject( $_, $queryRes->{contentDef}->{package} )->preProcess();

		$rec = $object->rec;

		if ($rec->{up_down} > 0) {
			$class = 'Up';
		} elsif ($rec->{up_down} < 0) {
			$class = 'Down';
		} else {
			$class = 'Same';
		};

		$str = $object->toHtmlString || $object->toString;
		$output .=  qq~
		<li class="change$class place$place"><a href="$rec->{uri}">$str</a></li>
		~;
	}

	$output =  qq~
		<ol class="topList">
			$output
		</ol>
	~;

	return Wywrota->t->wrapHeaderFooter({ 
		title=> msg('top_records'),
		output=> $output,
	});

}




sub byTag {
# --------------------------------------------------------
	my $self = shift;
	my ($query, $class, $object, $rec, @records );
	my ($output);

	$Wywrota::in->{sb}='tag.date_added';
	$Wywrota::in->{so}='desc';

	my $queryRes = Wywrota->cListEngine->query($Wywrota::in, "tag");

	#Wywrota->debug($queryRes);

	if ($queryRes->status eq "ok") {
		$output = Wywrota->cListView->includeQueryResults($queryRes, $Wywrota::in->{tag}, $Wywrota::in->{generate});
	}

	return Wywrota->t->wrapHeaderFooter({ 
		title=> $Wywrota::in->{tag},
		output=> $output
	});
}




sub topRecords {
# --------------------------------------------------------
	my $self = shift;
	my ($query, $class, $object, $rec, @records );
	my ($output);

	$Wywrota::in->{sb}='tv.count';
	$Wywrota::in->{so}='desc';

	my $queryRes = Wywrota->cListEngine->query($Wywrota::in, "top");

	#Wywrota->debug($queryRes);

	if ($queryRes->status eq "ok") {
		$output = Wywrota->cListView->includeQueryResults($queryRes, msg('top_records'), $Wywrota::in->{generate});
	}
	else {
		$output = msg('nothing_found');

	}

	return Wywrota->t->wrapHeaderFooter({ 
		title=> msg('top_records'),
		output=> $output
	});
}





sub listByAuthor {
# --------------------------------------------------------
# generuje autorow poukladanych alfabetycznie
# TODO - split into manager and view part

	my $self = shift;
	my $output = "<p>";
	my ($where, $last, $litera, $czego, $letter_output, $ile, $author, $author_urlized, $column, $url);
	my $wszystkie=0;
	my $first=1;
	my $query;


	my $kolumna = $Wywrota::in->{column};
	my $has_urlized = (defined($Wywrota::request->{content}{current}{cfg}{$kolumna."_urlized"})) ? (1) : (0);

	foreach $column (keys %{$Wywrota::request->{content}{current}{cfg}}) {
		if ($Wywrota::in->{$column} !~ /^\s*$/) { 
			$where .= " AND " if !$first;
			$where .= " $column='$Wywrota::in->{$column}' ";
			$url .= urlencode($Wywrota::in->{$column});
			$first=0;
		}
	}

	# wypisywanie tabelki
	$output .= qq~<table class="byAuthor">~;


	if ($has_urlized) {
		$query = qq~SELECT $kolumna, count(id), ~.$kolumna.qq~_urlized
					FROM $Wywrota::request->{content}{current}{tablename} 
					WHERE $where AND _active=1
					GROUP BY ~.$kolumna.qq~_urlized
					ORDER BY ~.$kolumna.qq~_urlized~;
	} else {
		$query = "SELECT $kolumna, count(id) FROM $Wywrota::request->{content}{current}{tablename} WHERE $where GROUP BY $kolumna ORDER BY $kolumna";
	}

	my $sth = Wywrota->db->execQuery($query) or return; 
	while ( ($author, $ile, $author_urlized) = $sth->fetchrow_array() ) { 
		$czego=Wywrota::Language::plural($ile, $Wywrota::request->{content}{current}{keyword});
		$wszystkie += $ile;

		if (!$has_urlized) {
			$author_urlized = $author;
		}

		if (($last ne lc substr($author_urlized,0,1)) && (substr($author_urlized,0,1) == 0) ) {
			$litera = uc $last;
			if ($litera >0) {
				$litera = '0-9';
			}
			$output .= qq~
				<tr>
				<td class="letter">$litera</td>
				<td>$letter_output</td>
				</tr>
			~ ;
			$letter_output='';
		}

		$letter_output .= qq~ <a href="/$author_urlized/">$author</a> $ile $czego<br>~;
		$last = lc substr($author_urlized,0,1);
	}
	$sth->finish;

	$litera = uc $last;
	$output .= qq~
		<tr>
		<td class="letter">$litera</td>
		<td>$letter_output</td>
		</tr>
	~ ;
	$output .= qq~</table>~;

	return $output;
}





sub query {
# --------------------------------------------------------
#		 $queryRes->{hits}					- array reference of hits
#		 $queryRes->{cnt}				- the total number of hits
#        $queryRes->{pagination}			- html for displaying the next set of results.
#		 $queryRes->{contentDef}

	my $self = shift;
	my $in = shift;
	my $current_operation = shift || "view";
	my $contentDef = shift || $Wywrota::request->{content}{current}; #$Wywrota::request->{content}{current};

	my $queryRes = $self->dao->query($in, $current_operation, $contentDef);

	# make pagination and store in a variable 
	$queryRes->pagination();

	return $queryRes;	
}



sub dao { shift->{dao} }
sub buildFullQuery { shift->{dao}->buildFullQuery(@_) }

1;