package Wywrota::Object::View::BaseView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Class::Singleton;
use base 'Class::Singleton';

use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Log;
use Wywrota::Language;
use Wywrota::View::Navigation;




sub _new_instance {
# --------------------------------------------------------
	my $class = shift;
	my $self  = bless { }, $class;

	$self->{mng} = shift;

	return $self;
}


sub recordForm {
# --------------------------------------------------------
	my $self = shift;
	return  Wywrota::Forms::buildHtmlRecordForm(@_);
}


sub recordFormAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;

	my $co = Wywrota::Language::plural(1, $Wywrota::request->{content}{current}{keyword});
	my $output = qq~<h3>Prześlij $co</h3>~;
	$output .= $self->recordForm($object, @_);
	return $output;
}


sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $output;

	$object->preProcess(1);

	$output = Wywrota->template->header({
			title => "$rec->{tytul} $rec->{autor} ". $Wywrota::request->{content}{current}{title}
	});
	$output .= 	Wywrota::Forms::buildHtmlRecord($object);
	$output .= Wywrota->template->footer();

	return $output;
}


sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	Wywrota->contentView->addSuccessBasic(@_);
}



sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $output = "";
	my ($menu);
	my $queryRes = shift;
	my $tytul = shift;
	my $description = shift;

	my $czego = Wywrota::Language::plural($queryRes->{cnt}, $queryRes->{contentDef}{keyword})
			    || Wywrota::Language::plural($queryRes->{cnt}, 'pozycja') ;

	$menu = generateSortByMenu( $queryRes );

	if ($Wywrota::in->{rss}) {
		$output .= qq~
			<div class="floatRight">
			<a href="/rss/$Wywrota::in->{rss}.xml" class="rss3d" title="subskrybuj">Subskrybuj</a>
			</div>
			~;
	}
	
	$output .= qq~<h1>$tytul</h1>~ if $tytul;
	$output .= qq~<div class="txtnews">$description</div>~ if $description;

	if ($Wywrota::in->{count} && $queryRes->{cnt}) {
		$czego = Wywrota::Language::plural($queryRes->{cnt}, $Wywrota::request->{content}{current}{keyword});
		$czego = $Wywrota::request->{content}{current}{keyword} if ($queryRes->{cnt} == 1); # - mianownik
		$output.= qq~<div class="txtnews"><b>$queryRes->{cnt}</b> $czego</div>~;
	} 
	elsif ($queryRes->{cnt}) {

		#my $count_results = msg('found') . " <b>$queryRes->{cnt}</b> $czego <br>";		

		if ($menu) {
			$output .= qq~
				<table class="listHdTable">
				<tr>
					<td valign="top" nowrap="true"> 
						<div class="listPagination">
						$queryRes->{pagination}
						</div>
					</td>
					<td align="right" valign="bottom" class="txtcore" nowrap="true">$menu</td>
				</tr>
				</table>
			~;
		} else {
			$output .= qq~
				<div class="listPagination">
					$queryRes->{pagination}
				</div>
			~;
		}

	}
	return $output;
}



sub searchFooter {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	
	my $output = "";
	my ($href, $rssFeed, $czego, $co, $tmp_wiecej, $notify);

	my $maxhits = ($queryRes->{in}{'mh'}) ? ($queryRes->{in}{'mh'}) : ($queryRes->{contentDef}{records_per_page});

	return if ( $queryRes->{in}{nomore} );

	# link do więcej czego -->
	if ($queryRes->{in}{generate} && !$queryRes->{in}{pagination}) {
		my $href = $queryRes->param();

		$rssFeed = "$href,rssfeed,1";
		if ($queryRes->{in}{mh}>=$queryRes->{contentDef}{records_per_page} || !$queryRes->{in}{mh}) {
			$href .= ",nh,2";
		} else {
			#$href .= "#".($queryRes->{in}{mh}-1);
		}
		
		$czego = Wywrota::Language::plural(0,$queryRes->{contentDef}{keyword});
		$co = Wywrota::Language::plural(2,  $queryRes->{contentDef}->{keyword});
		$co .= " ".msg('of_this_author') if ($queryRes->{in}{user_id});
		
		# link do więcej czego -->
		if ($maxhits<$queryRes->{cnt}) {
			$tmp_wiecej = qq~<a href="$href">więcej&nbsp;$czego&nbsp;&raquo;</a>~;
		} 
		
		if ($queryRes->{in}{rss}) {
			$rssFeed = qq~/rss/$queryRes->{in}{rss}.xml~;
		} 
		
		

		# add notification tracking for registered users
		$notify =  Wywrota::Notification::getSubscribeButton($queryRes->{notify}{record_id}, $queryRes->{notify}{content_id}) 
			if (defined $queryRes->{notify});

		$output = qq~
			<table class="moreTable">
			<tr>
				<td><a href="$rssFeed" class="rss" title="subskrybuj $co"><span>rss</span></a> $notify </td>
				<td align="right">$tmp_wiecej</td>
			</tr>
			</table>
			
		~ if ($queryRes->{cnt});
		
	}

	if (!$queryRes->{in}{generate} || $queryRes->{in}{pagination}) {
		$output = qq~<br><br><br><div class="listPagination">$queryRes->{pagination}</div>~ if ($queryRes->{pagination});
		#my $url = $config{site_url}. "/db/" .$queryRes->{contentDef}{url} . "/find";
		#$output .= qq~<p class="advSearch"><a href="$url" class="findIcon">zaawansowane szukanie</a>~;
	}	
	
	
	return $output;
}



sub searchFooterGenerate {
	my $self = shift;
	my $queryRes = shift;
	$queryRes->{in}{generate}=1;
	return $self->searchFooter($queryRes,@_);
}


sub generateSortByMenu {
# --------------------------------------------------------
	my $queryRes = shift;
	my $columnData = $queryRes->{contentDef}{sort}{by};
	my ($kolumna, $wedlug, $so, $href, $key, $default, $sortcount );
	my $output = "";



	foreach (@$columnData) {
		#$href = "/";
		$default = 0;
		if (ref $_ eq 'HASH') {
			$_ = $_->{content};
			$default = 1;
		}
		$href = "/db/".$queryRes->{contentDef}{url}."/";

		($kolumna, $wedlug, $so) = split(/,/, $_);
		
		next if ($Wywrota::in->{$kolumna} || $Wywrota::in->{$kolumna."_urlized"} );
		
		if ((!$queryRes->{in}{sb} && $default ) or ($queryRes->{in}{sb} eq $kolumna) ) {
			$output .= qq~<span class="sortbySelected">$wedlug</span> ~
		} else {
			foreach $key (keys %{$Wywrota::in}) {
				next if (($queryRes->{in}{'keyword'}) && ($key ne 'keyword')); 
				next if ($key =~ /txt|tabela|kolumna|suffix|postfix|random|count|db|count|generate|mh|nh|val|sb|so/);
				$href .= "$key,$queryRes->{in}{$key}," if length($queryRes->{in}{$key});
			}

			$href .= "sb,$kolumna,";
			$href .= "so,$so";
			$output .= qq~<a href="$href" class="sortby" rel="nofollow">$wedlug</a> ~;
			
			$sortcount++;
		}
	}

	return $output if ($sortcount);
}




sub searchHeaderGenerate {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my $after_cnt_label = shift;
	my $output = "";
	my $label;

	my $czego = Wywrota::Language::plural($queryRes->{cnt}, $queryRes->{contentDef}{keyword})
			    || Wywrota::Language::plural($queryRes->{cnt}, 'pozycja') ;

	return if ( $queryRes->{in}{nomore} );

	$after_cnt_label = ": ".$after_cnt_label if ($after_cnt_label);
	
	if ($Wywrota::in->{count} && $queryRes->{cnt}) {
		$label = $Wywrota::in->{count} if ($Wywrota::in->{count} ne '1');
		$output = qq~<div class="countLabel">$label <b>$queryRes->{cnt}</b> $czego$after_cnt_label</div>~;
	} 
	
	return $output;
}






sub mng { shift->{mng} }
sub header { 
	Wywrota->trace("in BaseView header");  
	shift; 
	return ($Wywrota::in->{generate}) ? "" : Wywrota->template->header(@_);
}
sub footer { 
	Wywrota->trace("in BaseView footer");  
	shift; 
	return ($Wywrota::in->{generate}) ? "" : Wywrota->template->footer(@_);
}


sub wrapHeaderFooter {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $param = shift;
	my $output = shift || $param->{output};

	return ($Wywrota::in->{generate}) ? 
		$output : 
		$self->header($param) . $output	. $self->footer($param);
	
}


1;