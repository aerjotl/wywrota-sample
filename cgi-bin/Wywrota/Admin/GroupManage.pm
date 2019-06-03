package Wywrota::Admin::GroupManage;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Exporter; 
use Data::Dumper;
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;

our @ISA = qw(Exporter);
our @EXPORT = qw(action );




sub assignGroups {
# -------------------------------------------------------------------------------------
#	przypisywanie grup użytkownikowi

	my ($output, $group, $groups, $groups_in, $settings, $ids);
	my $message = shift;

	return Wywrota->error("Brak ID użytkownika") if (!$Wywrota::in->{'id'});
	
	my $rec=Wywrota->content->getObject($Wywrota::in->{'id'}, 'User');
	my $avatar = Wywrota::Object::User::record($rec);
	my $msg = qq~<div class="div_msg_ok">~.Wywrota->mng('UserGroup')->storeUserGroups($Wywrota::in->{'id'}).qq~</div>~ if ($Wywrota::in->{group_ids});


	$groups = Wywrota->db->buildHashRef("SELECT id, nazwa FROM ugroup WHERE _active=1 ORDER BY sortorder");
	$groups_in = Wywrota->mng('UserGroup')->readUserGroups($Wywrota::in->{'id'});


	# generate output
	$output = qq~
		<link rel="stylesheet" href="/styles/moja.css" type="text/css">
		<div id="userpage">
		$avatar
		<br class="clr">
		$msg
		<h3>Przypisz użytkownika do grup</h3>
		<form action="$config{'db_script_url'}" method="POST">
		<input type="hidden" name="adminAction" value="assignGroups">
		<input type="hidden" name="id" value="$Wywrota::in->{'id'}">

	~;

	foreach $group (keys %{$groups}) {
		next if (!$group || $group==5); # skip regular users 
		$ids .= "$group,";
		$checked = ($groups_in->{$group}) ? (' checked="checked"') : ('');
		
		if ($group==100 && $groups_in->{$group}) {
			$output .= qq|
				<input type="hidden" name="group$group" value="1">
				<div class="star">$groups->{$group}</div>
			|;		
		} else {
			$output .= qq|
				<div>
					<input type="checkbox" name="group$group" id="group$group" value="1"$checked>
					<label for="group$group">$groups->{$group}</label>
				</div>
			|;
		}
	}


	$output .= qq|
		<input type="hidden" name="group_ids" value="$ids">
		<div class="formButtons"><input type="submit" name="modifyrecord" value="zapisz" class="bold"></div>
		</form>

		</div>
	|;

	return Wywrota->t->wrapHeaderFooter({			
			title => "Grupy użytkowników",
			nomenu=>  'bar',	
			nocache=>  1,
			output => $output,
			nobillboard => 1
	});
}


