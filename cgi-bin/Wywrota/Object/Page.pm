package Wywrota::Object::Page;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Object::BaseObject;
use Wywrota::Dictionary;

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'numer',	'_hid',		4,		1,  '',         '', ''],
		parent_id=>			[1, 'numer',	'_hid',		4,		0,  '',         '', ''],
		original_id=>		[2, 'numer',	'_hid',		4,		0,  '0',        '', ''],
		title		=>		[3, 'alpha',	"title",	64,		1,  '',         'page_title', ''],
		short_title		=>	[4, 'alpha',	"inputWide",128,	1,  '',         'menu_title', ''],
		url			=>		[5, 'alpha',	"inputWide",128,	1,  '',         '', ''],
		keywords	=>		[6, 'textarea',	'txtAreaSm1',2000,	0,  '',         '', 'meta'],
		description	=>		[7, 'textarea',	'txtAreaSm1',10000,	0,  '',         '', 'meta'],
		lang		=>		[8, 'combo',	'',			16,		1,  '1',        'language', 'details'],
		color		=>		[9, 'combo',	'',			16,		0,  '',         'color', 'details'],
		content_id	=>		[10, 'combo',	'',			16,		0,  '0',        '', 'details'],
		nomenu		=>		[11, 'combo',	'',			16,		0,  '0',        'page_layout', 'details'],
		nobillboard	=>		[12, 'checkbox','',			6,		0,  '0',		'', 'details'],
		sortorder	=>		[13, 'numer',	"inputSm1",	4,		1,  '0',        '',	'details'],
		rss		=>			[14, 'alpha',	'',			128,	0,  '',         '',		'details'],
		rss_title	=>		[15, 'alpha',	'',			128,	0,  '',         '',		'details'],
		content		=>		[16, 'textarea','txtAreaMd',100000,	0,  '',         'page_content',		'']
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
	my $self = shift;
	my $rec = $self->rec;
	my ($output, $gray);

	#my $gray = " g" if (!$rec->{active});

	$output = qq~
	<tr class="onePage">
		<td>$rec->{id}</td>
		<td><a href="/db/$Wywrota::request->{content}{current}{url}/modify=$rec->{id}" class="arMod"><span class=" $gray">$rec->{title}</span></a></td>
		<td class="cou$gray">
			<!--, 
			$rec->{url} 
			<b>url:</b> 
			<b>id:</b> $rec->{id}	
			<b>parent_id:</b> $rec->{parent_id}, <b>color:</b> $rec->{color}, <b>active:</b> $rec->{active}<br>
			$rec->{rss}-->
		</td>
	</tr>
	~;
	return $output;

}



1;