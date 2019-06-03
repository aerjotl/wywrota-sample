package Wywrota::Object::Manager::PageManager;

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
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';


sub action {
# -------------------------------------------------------------------------------------
	my $output;
	my $self = shift;
	my $nut = shift;
	my $action = $nut->in->{siteAction};
	
	if ($action eq 'map') { $output = siteMap();} 
	elsif ($action eq 'mapAdmin') { $output = siteMapAdmin();} 
	elsif ($action eq 'xmlMap') { $output = getXML();} 

		
	else { 
		return Wywrota->unknownAction($action);

	}

	
	return $output;
}


sub siteMap {
# -------------------------------------------------------------------------------------
	my $output;

	$output = Wywrota->template->header({ title => "mapa serwisu" });

	$output .= qq~
		<p><a href="/db/pages/add" class="addIcon"><b>dodaj nową stronę</b></a>
		<p><a href="/db/pages/id/*" class="arRight"><b>lista stron</b></a>
	~ if (Wywrota->per('admin',17));

	$output .= _traversePageTree(1,0);
	$output .= Wywrota->template->footer();

	return $output;
}




sub siteMapAdmin {
# -------------------------------------------------------------------------------------
	my $output;

	$output = Wywrota->template->header({ title => "mapa serwisu",	nomenu=>  'bar'	});

	$output .= qq~

	<link rel="stylesheet" type="text/css" href="/js/dhtmlxTree/dhtmlxTree/codebase/dhtmlxtree.css">
	<script  src="/js/dhtmlxTree/dhtmlxTree/codebase/dhtmlxcommon.js"></script>
	<script  src="/js/dhtmlxTree/dhtmlxTree/codebase/dhtmlxtree.js"></script>
	
	<table width="100%">
		<tr>
		<td style="width: 250px;">
			<p><a href="/db/pages/add" class="arPlus">dodaj nową stronę</a>
			<p><a href="/db/pages/id/*" class="arRight">lista stron</a>
			<p><a href="javascript:void(0);" onclick="tree.openAllItems(0);">otwórz wszystkie</a>
			<br><br>
			<div id="treeboxbox_tree" style="width: 250px"></div>
		</td>	
		<td><iframe id="sampleframe" name="sampleframe" style="width: 100%; height: 800px" frameborder="0" src="about:blank" style="border: 0px solid #cecece;"></iframe>
		</td>
		</tr>
	</table>
	
			
	
	<script>
			tree=new dhtmlXTreeObject("treeboxbox_tree","100%","100%",0);
			tree.setImagePath("/js/dhtmlxTree/dhtmlxTree/codebase/imgs/csh_bluebooks/");
			tree.enableDragAndDrop(true);
			tree.loadXML("/site/xmlMap.html");
			tree.setOnClickHandler(doOnClick); 
			
			function doOnClick(nodeId){ 
				var myUrl = tree.getUserData(nodeId,"myurl"); 
				//window.open(myUrl);
				frames["sampleframe"].location.href = myUrl ;
			}
	</script>
				
	~;

	$output .= Wywrota->template->footer();

	return $output;
}




sub _traversePageTree {
# -------------------------------------------------------------------------------------
	my ($query, $sth, $output, $page, $icon);
	my $pageId = shift;
	my $depth = shift;

	$query = "SELECT * FROM page WHERE _active=1 AND parent_id=".int($pageId)." ORDER BY sortorder";
	$sth = Wywrota->db->execQuery($query); 

	$output .= "<ul class='siteMap '>" if ($sth->rows);
	while ($page = $sth->fetchrow_hashref()) {
		if ($depth==0) {
			$output .= qq~<h2>$page->{title}</h2>~;
		} 
		$icon = qq~
			<span style="margin-left: 20px;">
				<a href="/db/pages/modify/$page->{id}" class="arMod">&nbsp</a> 
				<a href="/db/pages/add/1/parent_id/$page->{id}" class="arPlus">&nbsp</a> 
			</span>
		~ if (Wywrota->per('admin',17));

		$output .= qq~<li><a href="$page->{url}">$page->{short_title}</a> $icon</li>~;
		$output .= _traversePageTree($page->{id},$depth+1);
	}
	$output .= "</ul>" if ($sth->rows);
	$sth->finish;	

	return $output;

}


sub getXML {
# -------------------------------------------------------------------------------------
	my $output;
	my $struct = _buildStruct();

	$output = "Content-type: text/xml; charset=utf-8\r\n\r\n";
	$output .=qq~<?xml version='1.0' encoding='utf-8'?>
		<tree id="0">
	~;

	$output .= _traverseStruct($struct, 0);


	$output .=qq~
		</tree>
	~;
	return $output;

}


sub _traverseStruct {
# -------------------------------------------------------------------------------------
	my $struct = shift;
	my $parent = shift;
	my $output;

	foreach (keys %{$struct}) {
		if ($struct->{$_}->{parent_id} ==  $parent) {
			$output .= qq~
				<item text="$struct->{$_}->{text}" id="$_" >
					<userdata name="myurl">/db/pages/modify/$struct->{$_}->{id}/popup/1</userdata>
				~;
			$output .= _traverseStruct($struct, $_);
			$output .= qq~</item>\n~;
		}
	}
	return $output;
}



sub _buildStruct {
# -------------------------------------------------------------------------------------
	my ($sth, $page, $struct);

	$sth = Wywrota->db->execQuery("SELECT * FROM page WHERE _active=1"); 
	while ($page = $sth->fetchrow_hashref()) {
		$struct->{ $page->{id} } =  {
			'text' => $page->{short_title},
			'title' => $page->{title},
			'url' => $page->{url},
			'id' =>  $page->{id},
			'parent_id' =>  $page->{parent_id}
		}
	}
	$sth->finish;	

	return $struct;
}



1;