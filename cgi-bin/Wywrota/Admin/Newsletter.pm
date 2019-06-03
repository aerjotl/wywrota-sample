package Wywrota::Admin::Newsletter;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use CGI;
use Data::Dumper;
use Clone qw(clone);
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Forms;
use Wywrota::EMail;
use HTML::Entities;
use XML::Simple;


our @ISA = qw(Exporter);
our @EXPORT = qw(main);


my @age_ranges = (0, 15, 20, 25, 35, 45, 100);


sub _process {
# -----------------------------------------------------------------------------
	my $in = shift;

	if (!$in->{topic}) {
		$in->{topic} = "Newsletter z Wywroty, ".normalnaData(getDate(),'notime');
		$in->{headers} = 1;

		($in->{mail_template}) = Wywrota->db->quickArray("SELECT body FROM email_template WHERE id=1");
	}

	$in->{counter} = getCurrentCounter();
	
	$in->{headers} = 0 unless $in->{headers};

	$in->{age_ranges} = getAgeRangesLabels();	
	
	$in->{processed} = Wywrota->t->process(\$in->{mail_template}, {});
	$in->{processed} = Wywrota->nav->absoluteLinks($in->{processed});
	$in->{processed} = qq~
		<div style="font-family:arial,helvetica; font-size: 18px;	margin-bottom: 22px; font-weight: bold; margin-top: 24px;">$in->{topic}</div>
		$in->{processed}
	~  if ($in->{headers});

}


sub getAgeRangesLabels {
# -----------------------------------------------------------------------------

	my (@ranges, $count);
	my ($sec, $min, $hour, $day, $mon, $year, $dweek, $dyear, $daylight) = localtime(time());
	$year += 1900;
	
	for ($i=0; $i<$#age_ranges; $i++) {
		
		($count) = Wywrota->db->quickArray(qq|
			SELECT COUNT(*) as cnt FROM ludzie 
			WHERE _active=1  AND email_broken=0
			AND (rok_urodzenia BETWEEN ? AND ?)	
			|, $year-$age_ranges[$i+1], $year-$age_ranges[$i]);
		
		
		push(@ranges, {
			id=>$i, 
			label=>sprintf ("%d-%d", $age_ranges[$i], $age_ranges[$i+1]),
			count=>$count
		});
	}
	
	($count) = Wywrota->db->quickArray(qq|
		SELECT COUNT(*) as cnt FROM ludzie 
		WHERE _active=1  AND email_broken=0
		AND ( (rok_urodzenia IS NULL)	OR (rok_urodzenia BETWEEN ? AND 10000) OR (rok_urodzenia BETWEEN 0 AND 1900))
		|, $year);

	push(@ranges, {
		id=>"undefined", 
		label=>"brak danych",
		count=>$count
	});
	return \@ranges;
	
}



sub getAgeCriteriaSQL {
# -----------------------------------------------------------------------------
	my $in = shift;
	my ($sec, $min, $hour, $day, $mon, $year, $dweek, $dyear, $daylight) = localtime(time());
	$year += 1900;
	my (@options);
	my $age_criteria_deselected = 0;
	
	# age criteria
	for ($i=0; $i<$#age_ranges; $i++) {
		if ($in->{'age'.$i}) {
			push (@options, sprintf(" (rok_urodzenia BETWEEN %d AND %d)	", $year-$age_ranges[$i+1], $year-$age_ranges[$i]));
		} else {
			$age_criteria_deselected = 1;
		}
	};
	
	if ($in->{'ageundefined'}) {
		push (@options, "(rok_urodzenia IS NULL)");
		push (@options, "(rok_urodzenia BETWEEN 0 AND 1900)");
		push (@options, "(rok_urodzenia BETWEEN $year AND 10000)");
		
	} else {
		$age_criteria_deselected = 1;
	}
	
	
	
	if ($age_criteria_deselected) {
		return " AND (" . join(" OR ", @options) . ")";
	} else {
		return "";
	}	

}



sub _action {
# -----------------------------------------------------------------------------
	my $in = shift;

	if ($in->{send_test}) {

		foreach (split(",", $in->{test_email}) ) {
			
			Wywrota::EMail::sendEmail({
				from	=> $in->{from},
				to		=> trim($_),
				subject	=> $in->{topic},
				body	=> $in->{processed},
				style	=> ($in->{headers} ? '' : 'noHeaders'),
			});
	
			Wywrota->sysMsg->push("wysłałem maila testowego na adres ".trim($_), "ok");

		}
		
	} elsif ($in->{save_template}) {

		my $save = clone($in);
		delete $save->{processed};
		
		my $xml = XMLout($save, NoAttr => 1);
		
		return "Content-Disposition: attachment; filename=\"newsletter.xml\"\n".
			"Content-type: text/xml; charset=utf-8\r\n\r\n".$xml;
		
	}  elsif ($in->{load_template}) {
		
		Wywrota->sysMsg->push(Dumper($in->{template_to_load}), "ok");
		
		 
		return;

	} elsif ($in->{send_full}) {

		_saveTemplateToDB($in);
		return _sendFullMailing($in);
		
	}
}


sub _saveTemplateToDB {
# -----------------------------------------------------------------------------
	my $in = shift;
	Wywrota->db->writeQuery("INSERT INTO email_template (title, body, user_id) VALUES (?,?,?)", $in->{topic}, $in->{mail_template}, $Wywrota::session->{user}{id});
}


sub _sendFullMailing {
# -----------------------------------------------------------------------------
	my $in = shift;
	my ($i, $query);
	
	$| =1;
	print "Content-type: text/html; charset=utf-8\r\n\r\n";
	print "<h1>wysyłka rozpoczęta</h1>\n\n";
	print "wysyłka może trwać bardzo długo. <br>możesz zamknąć tą stronę, o zakończeniu wysyłki zostaniesz powiadomiony mailem";
	
	
	
	if (int($in->{plec})) {
		$query = " AND plec = ". int($in->{plec});
	};
	
	$query .= getAgeCriteriaSQL($in);
	
	print "<div style='color: gray; padding: 10px; margin: 10px; border: dotted gray 2px;'>dodatkowe kryteria: $query</div>" if ($query);
	
	if ($config{site_config_mode} ne 'prod') {
		sleep(1); print "<br>test wysyłki - wysłano 100";
		sleep(1); print "<br>test wysyłki - wysłano 200";
		sleep(1); print "<br>test wysyłki - wysłano 300";
			
		
	} else {
		

		
		$i = int($in->{start_from});	
		my $sth = Wywrota->db->execQuery("SELECT DISTINCT id, email FROM ludzie WHERE _active=1 AND email_broken=0 $query LIMIT $i, 1000000");  #00000


		while ( my $rec = $sth->fetchrow_hashref() ) {
			$i++;
			if ($i%100 == 0) {
				print "wysłano $i<br>";
				sleep(1);
			}

			Wywrota::EMail::sendEmail({
				from	=> $in->{from},
				to		=> $rec->{email},
				subject	=> $in->{topic},
				body	=> $in->{processed},
				style	=> ($in->{headers} ? '' : 'noHeaders'),
			});

			setCurrentCounter($i);
		};

		$sth->finish;

		
		setCurrentCounter(0);
		
		sendConfirmationEmail($Wywrota::session->{user}{email}, $i);
		sendConfirmationEmail("aerjotl\@gmail.com", $i);
		
		
	};
	
	return "<br>wysyłka zakończona";
}



sub sendConfirmationEmail {
# -----------------------------------------------------------------------------
	my $email = shift;
	my $count = shift;
	Wywrota::EMail::sendEmail({
		to		=> $email,
		subject	=> "Newsletter wysłany",
		body	=> "<h1>Zakończyłem wysyłanie newslettera</h1>Wysłałem <b>$count</b> maili.<br>"
	});
}


sub setCurrentCounter {
# -----------------------------------------------------------------------------
	my $cnt = shift;
	open (COUNTER, ">$config{tmp_dir}/newsletter_counter.txt");
	print COUNTER $cnt;
	close COUNTER;
}



sub getCurrentCounter {
# -----------------------------------------------------------------------------
	my $cnt;
	open (COUNTER, "$config{tmp_dir}/newsletter_counter.txt"); 
	$cnt = int(<COUNTER>);
	close COUNTER;
	return $cnt;
}



sub main {
# -----------------------------------------------------------------------------

	my ($output );
	my $in = shift;

	_process($in);
	
	if ($in->{counter} > 0) {
		
		$output = qq|
			<h1>Newsletter jest w trakcie wysyłki</h1>
			<h2>Aktualnie wysłano $in->{counter} maili</h2>
			<br>Zostaniesz powiadomiony emailem o zakończeniu wysyłki.
			|;
		
	} else {
		
		$output = _action($in);
		return $output if ($output);

		$in->{from_encoded} = HTML::Entities::encode($in->{from}, '<>&"');
		$output = Wywrota->t->process('admin/newsletter_form.html', $in);
	}

	return Wywrota->t->wrapHeaderFooter({
		title  => 'Wysyłanie newslettera',	
		nomenu =>  'bar',
		output => $output
	});

}


1;

