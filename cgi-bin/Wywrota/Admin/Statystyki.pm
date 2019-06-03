package Wywrota::Admin::Statystyki;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Time::HiRes qw(gettimeofday tv_interval);

our @ISA = qw(Exporter);
our @EXPORT = qw(siteStats);

my $chart_id = 0;
my @totals;


sub siteStats {
# -----------------------------------------------------------------------------
	my ($output, $days, $day, $days_radios);
	my $start = gettimeofday;

	return Wywrota::User::unauthorized() if (!Wywrota->per('admin',3) );
	
	$days = $Wywrota::in->{days} || 1;
	$days = 3 if ($days >3);

	foreach $day (qw|1 2 3|) {
		my $checked = ' checked' if $day eq $days;
		$days_radios .=  qq~<input type="Radio" name="days" value="$day" $checked id="days$day"><label for="days$day">$day &nbsp;</label>~;
	}
	


	my $stats = printStat ('Artykuły',			3, 20, $days, 1, 'AND category=2')
			. printStat ('Newsy',	 			3, 20, $days, 1, 'AND category IN (1, 3)')
			. printStat ('Klasyka Poezji', 		1, 20, $days, 0, 'AND typ=5')
			. printStat ('Literatura', 			1, 20, $days, 0, 'AND typ<>5')
			. printStat ('Śpiewnik', 			7, 30, $days, 0)
			. printStat ('Prace', 				16, 0, $days, 0)
			. printStat ('Podcasty',			10, 0, $days, 0)
			. printStat ('Forum', 				13, 0, $days, 0);
	

	$output =  Wywrota->t->process('inc/google.chart.init.inc')	. qq~
	
		<style type="text/css">
			.cnt {width: 20px; display: inline; float: left; text-align: center; font-size: 10px; }
			.theContent {padding: 0 50px;}
		</style>
	
		<h1>Statystyki </h1>
		<div class='txtcore'>
			od: <b>~
			 . normalnaData(getDate(time() - ($days*24*60*60)),1,1)
			 .qq~</b> do: <b>~
			 .normalnaData(getDate(time()),1,1)
			 .qq~</b> ($days ~.Wywrota::Language::plural($days, 'dzień').qq~)<br>
		</div>

		
		<form action="/db" method="GET">
			<input type="hidden" name="adminAction" value="stats">
			<div class="txtnews">
				<b>ile dni:</b>
				$days_radios
				<input type="submit" value="pokaż" class="bold"> 
			</div>
		</form>	

	~

		. printTotals()
	
		. $stats
		. "<br>Generowanie statystyk: <b> " 
		.  sprintf (" %.3f s. ", tv_interval([$start], [gettimeofday]))
		. "</b>.<br><br>";
	
	return Wywrota->t->wrapHeaderFooter({ 
		title => 'Statystyki Wywroty',	
		nomenu=>  'bar',
		nocache => 1,
		output => $output
		});


}

sub printTotals {
	return Wywrota->t->process('inc/google.chart.inc', {
		data		=>	\@totals,
		chart_id	=>	"totals",
		keys_label 	=> 	"typ treści",
		values_label => "wyświetleń"  		
	})
}

sub printChart {
# -----------------------------------------------------------------------------
	my $cid = shift;
	my $days = shift;
	my $add_custom_sql = shift;
	
	my $date_range = "time BETWEEN " . Wywrota->db->quote(getDate(time() - ($days *24*60*60))) . " AND " . Wywrota->db->quote( getDate(time()) );
	my $package = Wywrota->cc->{$cid}{package};
	my $table = Wywrota->cc->{$cid}{tablename};


	my $data = Wywrota->db->buildHashRefArrayRef(qq|
	SELECT d.label, count(typ) AS cnt
		FROM wywrota_log.log l
			INNER JOIN `$config{db}{database}`.$table a ON l.record_id = a.id
			INNER JOIN `$config{db}{database}`.dict_entry d ON typ=value and package='$package' and `key`='typ' and active=1
		WHERE l.content_id = $cid
			AND l.$date_range
			AND l.is_bot = 0
			$add_custom_sql 
		GROUP BY typ
		ORDER BY cnt DESC
	|);
	
	return Wywrota->t->process('inc/google.chart.inc', {
		data		=>	$data,
		chart_id	=>	"pie_".$chart_id++
	});

	
}
	
	
	
sub printStat {
# -----------------------------------------------------------------------------
	my $header = shift;
	my $cid = shift;
	my $limit = shift;
	my $days = shift;
	my $add_chart = shift;
	my $add_custom_sql = shift;
	
	my $table = Wywrota->cc->{$cid}{tablename}; 
	my $url = Wywrota->cc->{$cid}{url};
	my $add_sql = Wywrota->mng($cid)->getSqlAddConditions();

	my ($cnt, $id, $title, $author);
	my ($query, $output, $sth, $maxcnt, $width, $fields);
	my ($cntAll, $cntRegistered);
	
	my $date_range = "time BETWEEN " . Wywrota->db->quote(getDate(time() - ($days *24*60*60))) . " AND " . Wywrota->db->quote( getDate(time()) );

	if ($cid == 7) {
		$fields = "rec.tytul, rec.wykonawca as autor";
	} elsif ($cid==16) {
		$fields = "rec.podpis as tytul, '' as autor";
	} elsif ($cid==13) {
		$fields = "rec.temat as tytul, rec.user_id as autor";
	} else {
		$fields = "rec.tytul, rec.autor";
	}


	if ($add_custom_sql) {
		($cntAll) = Wywrota->db->quickArray(qq|
			SELECT COUNT(*) 
			FROM wywrota_log.log l LEFT JOIN $table rec on l.record_id = rec.id 
			WHERE 
				content_id = $cid 
				AND $date_range 
				AND l.is_bot = 0
				$add_custom_sql
			|);
		($cntRegistered) = Wywrota->db->quickArray(qq|
			SELECT COUNT(*) 
			FROM wywrota_log.log l LEFT JOIN $table rec on l.record_id = rec.id 
			WHERE 
				content_id = $cid 
				AND $date_range 
				AND l.is_bot = 0
				$add_custom_sql
				AND l.user_id>0
			|);
	} else {
		$cntAll = Wywrota->db->selectCount("wywrota_log.log", "content_id = $cid AND $date_range");
		$cntRegistered = Wywrota->db->selectCount("wywrota_log.log", "content_id = $cid and user_id>0 AND $date_range");
	}

	if ($limit > 0) {


		$query = qq~
			SELECT count(l.record_id) as cnt, l.record_id, $fields FROM wywrota_log.log l
			LEFT JOIN $table rec on l.record_id = rec.id
			WHERE 
				l.content_id = $cid
				AND l.$date_range
				AND l.is_bot = 0
				$add_custom_sql
			$add_sql
			GROUP BY l.record_id
			ORDER BY cnt DESC
			LIMIT $limit
		~;

		$sth = Wywrota->db->execQuery($query);
		while (($cnt, $id, $title, $author)= $sth->fetchrow()) {
			$maxcnt = $cnt if (!$maxcnt);
			$width = sprintf ("%.0f", 200 * ($cnt/$maxcnt) );
			$title = cutTextTo($title, 40);
			$output .= qq~
				<span class="cnt">$cnt</span><img src="/gfx/small/pic1.gif" width="$width" height="14" alt="$cnt">
				<a href="/db/$url/$id">$title, $author</a><br>
			~;
		}	
		$output .= qq~<!-- div class="txtsm1 g">$query</div -->~;
	
		
		# -- attach chart
		$output = printChart($cid, $days, $add_custom_sql) . $output if ($add_chart);

		my $procent = sprintf ("%.1f", (($cntRegistered * 100) / $cntAll)) if ($cntAll);
		$output = qq~<h2>$header</h2>
			<p class="txtnews">Wszystkich wyświetleń: $cntAll ($procent% zarejestrownych użytkowników)<br><br>
			<p>$output
			~;
		
	}


	push (@totals, {
		label => $header,
		cnt => $cntAll,
		style => $cid 
		});

	return $output;
}



1;

