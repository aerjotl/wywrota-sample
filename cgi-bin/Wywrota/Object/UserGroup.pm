package Wywrota::Object::UserGroup;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota;
use Wywrota::Log;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;
use Wywrota::Dictionary;


our @ISA = qw(Wywrota::Object::BaseObject);


# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id			=> [0, 'auto',       '_hid',    16,			0,  '',          ''],
		nazwa		=> [1, 'alpha',      'strong',		40,			0,  '',          'name'],
		description	=> [2, 'textarea',   'txtAreaSm1',		4096,		0,  '',          'description'],
		sortorder	=> [3, 'numer',      '',		8,			1,  '1',          ''],
		visible		=> [4, 'checkbox',   '',		2,			0,  '1',          '']
	 };


# --------------------------------------------------------


sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	return $self;
}




sub record {
# --------------------------------------------------------
# duzy rekord

	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess();

	my ($output, $includeRow, $row, $cnt, $name, $widoczna);
	my $groups;
	my ($perStruct, $gid, $cid, $nazwa, $sth);

	my $groupId=$rec->{id};

	# building setting struct
	$perStruct = undef;
	$sth = Wywrota->db->execQuery("SELECT ugroup_id, content_id, nazwa FROM uprawnienia");
	while (($gid, $cid, $nazwa) = $sth->fetchrow_array()) {
		$perStruct->{$gid}{$cid}{$nazwa} = 1;
	}
	$sth->finish;

	$cnt = Wywrota->db->selectCount('user_to_ugroup', "ugroup_id = $groupId") if ($groupId );
	$widoczna = ($rec->{visible}) ? "widoczna " : "ukryta";

		$output .= qq~
			<h3 class="ugroup ugroup_sm_$groupId">$rec->{nazwa} <span class="g txtcore">&nbsp;($groupId)</span></h3>
			<p class="txtnews">$widoczna, &nbsp; &nbsp; <b>$cnt</b> użytkowników
			$rec->{edit_icons_sm}
		~;


		my $perHtml='';
		foreach $cid (keys %{Wywrota->app->{cc}}) {
			$name = Wywrota->cc->{$cid}{package};
			next if ($cid eq 'current');
			$includeRow = 0;
			$row = "";
			foreach (("view","mod","del","admin")) {

				$row .= qq~ <td align=center> ~;
				if (defined($perStruct->{$groupId}{ $cid }{$_})) {
					$row .= qq~<img src="/gfx/btn-dot.gif" width="16" height="15">~;
					$includeRow =1;
				} else {
					$row .= qq~.~;
				}
			}

			$perHtml .= qq~ <tr><td>$name $row ~ if ($includeRow );
		}

		$output .= qq~ 
			<table width="400">
			<tr style="color: #888; background: #F5F5F5;">
				<th align=center>nazwa</th>
				<th align=center>view</th>
				<th align=center>mod</th>
				<th align=center>del</th>
				<th align=center>admin</th>
			</tr>
			$perHtml
			</table>			<br><br>
		~ if ($perHtml);

	return $output;
}




1;
