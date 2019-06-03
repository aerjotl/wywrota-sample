package Wywrota::Object::View::RecordSetView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Class::Singleton;
use base 'Wywrota::Object::View::BaseView';

use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Data::Dumper;


sub htmlPage {
# --------------------------------------------------------
	my $self = shift;
	my $nut = shift;
	my $object = shift;
	my $rec = $object->rec if ($object);
	my ($queryRes, $output);
	my $favCid = $Wywrota::request->{fav}{cid} || $Wywrota::request->{content}{current}{cid};

	$object->preProcess(1);

	$output = 	qq~
		$rec->{edit_icons}
		<div class="setDesc">
		<h1>$rec->{title}</h1>
		<div>$rec->{description}</div>

		<div>
			<span class="privacy$rec->{val}->{privacy}">zestaw $rec->{privacy}</span>
			<span class="author">$rec->{ludzie_imie}</span> 
		</div>
		</div>
	~;

	# -- get a list of entries
	$queryRes = Wywrota->cListEngine->query(	{ set=>$rec->{id} }, "fav", Wywrota->cc->{$rec->{content_id}} );
	$output .= Wywrota->cListView->includeQueryResults(	$queryRes );
	
	$output = Wywrota->template->header({
			title => $rec->{title} . " - ". $Wywrota::request->{content}{current}{title},
			nocache => 1
	})
		. $output
		. Wywrota->template->footer();

	return $output;
}



sub recordFormAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $output;
	my $cid=$Wywrota::in->{content_id};

	return Wywrota->errorMsg("Nie wiem jakiego rodzaju zestaw utworzyć") if (!$cid);

	$output = "<h1>" . msg('create_new').msg('set', $cid). "</h1>";
	
	$output .= $self->SUPER::recordForm($object);
	$output .= qq~
		<input type="hidden" name="record_id" value="$Wywrota::in->{record_id}">
	~;
	return $output;

}



sub addSuccess {
# --------------------------------------------------------
	my $self = shift;
	Wywrota->sysMsg->push('Twój nowy zestaw został utworzony pomyślnie.', 'ok');
	$self->htmlPage(@_);
}



sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my ($output);
	my $queryRes = shift;
	my $tytul = shift;

	$output = "<h1 style='text-transform:capitalize;'>". msg('sets') ."</h1>";
	#$output .= $self->SUPER::searchHeader($queryRes, $tytul);
	
	return $output;
}


sub searchFooterGenerate {
# --------------------------------------------------------
	my $self = shift;
	my ($output);
	my $queryRes = shift;
	my $tytul = shift;

	$output = $self->SUPER::searchFooterGenerate($queryRes, $tytul);
	$output .= qq~
		<div><a href="/db/set/add/1/content_id/$queryRes->{in}{content_id}" class="arPlus">~. msg('new') . msg('set') .qq~</a></div>
	~;
	
	return $output;
}


sub recordSetsBox {
# --------------------------------------------------------
# get a list of RECORD SETS
	my ($queryRes, $msgSets);
	my $output = "";
	
	return "" unless ($Wywrota::session->{user}{id});
	
	if ($Wywrota::request->{content}{current}{sets}) {
		$msgSets = msg('sets');
		$queryRes = Wywrota->cListEngine->query({
				user_id=>$Wywrota::session->{user}{id}, 
				content_id=>$Wywrota::request->{content}{current}{id}, 
				small=>1,
				mh => 3
			}, 
			"view", Wywrota->app->{ccByName}{"RecordSet"} );

		$output = Wywrota->cListView->includeQueryResults($queryRes, undef, 1, 1);
		$output = qq~
			<div class="recordSetsBox">
				<h4>$msgSets</h4>
				$output
			</div>
		~;
	}
	return $output;
}


1;
