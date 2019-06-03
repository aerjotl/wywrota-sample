package Wywrota::DAO::ContentListingDAO;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# Data Access object for listing the results of a query
#
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Class::Singleton;
use base 'Class::Singleton';

use DBI;
use Clone qw(clone);
use Wywrota;
use Wywrota::Log;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::QueryRes;
use POSIX qw(ceil floor);

my $DBH;




sub query {
# --------------------------------------------------------
# this is the main query procedure, the heart of the record listing engine.
# it's long, ugly, hard to debug, but it works fine
#
# what it does:
# - builds a query from the parameters passed by cgi variables (%in)
# - executes the query
# - creates pagination html in global variables
#
# it returns a set of records which can be put into the listing (QueryRes object)

	my $self = shift;
	my $in = clone(shift);
	my $db_operation = shift;
	my $contentDef = shift;
	my $is_first_search_field = 1;

	Wywrota->trace("ContentListingDAO : QUERY ($db_operation)", $in);

	my ($i, $column, $fieldquery, $cnt, $field, 
		@search_fields, @search_gt_fields, @search_lt_fields, @search_not_fields, 
		$hits, $tmpval, $tmpval2,
		$query, $fields, $addQuery, $query_from, $query_cnt_from, $group_by, $tag, $tags_str);

	my $queryRes = Wywrota::QueryRes->new( { 
		contentDef=>$contentDef, 
		in=>$in 
	} );
	

	# First thing we do is find out what we are searching for. We build a list of fields
	# we want to search on in @search_fields.

	if ($db_operation eq "fav") {
		my $uid = $in->{user_id} || $Wywrota::session->{user}{id};
		$in->{set} = int($in->{set});
		$query  = qq~ rec.id=f.record_id AND f.content_id=$contentDef->{id} AND f.set_id=$in->{set} ~;
		$query .= qq~  AND f.user_id=$uid ~ if (!$in->{set});

		$in->{user_id}=undef;
		$in->{id}=undef;
		$is_first_search_field = 0;

	} elsif ($db_operation eq "top") {
		$query = " tv.content_id=$contentDef->{id} AND rec.id=tv.record_id ";
		$is_first_search_field = 0;
		$in->{id}=undef;

	} elsif ($db_operation eq "tag") {
		my @tags = split(",", $in->{tag});
		foreach $tag (@tags) {
			$tag = simpleAscii(trim($tag));
			if (length($tag)) {
				$tags_str = ($tags_str) ? $tags_str .", ". Wywrota->db->quote($tag) : Wywrota->db->quote($tag);
			}
		}

		$query = " tag.content_id=$contentDef->{id} AND rec.id=tag.record_id AND tag.tag IN ($tags_str) ";
		$is_first_search_field = 0;
		$in->{id}=undef;

	} elsif ($in->{'cq'}) {	# custom query
		$query = Wywrota->content->mng( $contentDef->{cid} )->customQuery($in->{'cq'});
		$is_first_search_field = 0;
		$in->{id}=undef;

	} elsif ($in->{'keyword'}) {

		$in->{'ma'} = "on";
		foreach $column (keys %{$contentDef->{cfg}}) {
			next if (($column eq 'tresc') && (!$in->{'search_content'}));

			if ( ($contentDef->{cfg}{$column}[1] eq 'alpha'
			      || $contentDef->{cfg}{$column}[1] eq 'textarea') &&
 				  $contentDef->{cfg}{$column}[2] >=0				
			) {
				# Fill %Wywrota::Nut::Session::in with keyword we are looking for.
				push (@search_fields, $column);		
				$in->{$column} = trim($in->{$column}) || trim($in->{'keyword'});
			}

		}
	}
		

	foreach $column (keys %{$contentDef->{cfg}}) {
		if ($in->{$column}   =~ /^\>(.+)$/) { 
											push (@search_gt_fields, $column); next; }
		if ($in->{$column}   =~ /^\<(.+)$/) { 
											push (@search_lt_fields, $column); next; }
		if ($in->{$column}      !~ /^\s*$/) { 
											push(@search_fields, $column); next; }
		if (defined($in->{"$column-gt"})) { 
											push(@search_gt_fields, $column); }
		if (defined($in->{"$column-lt"})) { 
											push(@search_lt_fields, $column); }
		if (defined($in->{"$column-not"})) { 
											push(@search_not_fields, $column); }
	}



	# If we don't have anything to search on, let's complain.
	if (!@search_fields and !@search_gt_fields and !@search_lt_fields and $is_first_search_field) {
		$queryRes->msg('no_search_query');
		return $queryRes;
	}
	
	# Define the maximum number of hits we will allow, and the next hit counter.	
	$in->{'mh'} = $contentDef->{'records_per_page'} if (!defined($in->{'mh'}));
	$in->{'nh'} = 1 if (!defined($in->{'nh'}));
	$cnt = 0;


	# building sql query conditions 


	foreach $field (@search_fields) {
		next if ($in->{user_id} and ($db_operation eq "fav"));
		my (@array) = split (/\Q|\E/o, $in->{$field});
		

		# found elements in $in that are separeted by "|"
		if ($#array > 0) {
			my $fieldsearching = 0;
			$fieldquery="";
			
			$fieldquery = ($in->{'ma'} eq 'on') ? (" OR ") : (" AND ") if !$is_first_search_field;
			$fieldquery .= "(";
			for ($i = 0; $i <= $#array; $i++) {
				if ($contentDef->{cfg}{$field}[1] eq 'alpha'
					|| $contentDef->{cfg}{$field}[1] eq 'textarea') {
					
					$tmpval = Wywrota->db->quote( trim( lc($array[$i]) ) );
					#$tmpval2 = Wywrota->db->quote( trim( lc('%'.$array[$i].'%') ) );
					
					$fieldquery .= " OR " if ($i>0);
					$fieldquery .= "rec.$field=$tmpval ";
					#$fieldquery .= ($in->{'ww'}) ? "LOWER(rec.$field)=$tmpval " : "LOWER(rec.$field) LIKE $tmpval2 ";
					$fieldsearching = 1;
					
				} elsif (int($array[$i])) {
					$fieldquery .= " OR " if ($i>0);
					$fieldquery .= "rec.$field=" .int($array[$i])." " ;
					$fieldsearching = 1;
				};
			}	
			$fieldquery .= ")";
			if ($fieldsearching) {
				$query .= $fieldquery;
				$is_first_search_field=0;
			}
		
		# plain search - no multiple choices
		} else {

			if ($contentDef->{cfg}{$field}[1] eq 'alpha'
				|| $contentDef->{cfg}{$field}[1] eq 'textarea') {
				
				$tmpval = Wywrota->db->quote( trim( lc($in->{$field}) ) );
				$tmpval2 = Wywrota->db->quote( trim( lc('%'. $in->{$field} .'%') ) );
				
				$query .= ($in->{'ma'} eq 'on') ? (" OR ") : (" AND ") if !$is_first_search_field;

				if ($field =~/^.*_urlized/ or $field eq 'wywrotid') {
					#$query .= ($in->{'ww'}) ? "rec.$field = $tmpval " : "rec.$field LIKE $tmpval2 ";
					$query .= "rec.$field = $tmpval ";
				} else {
					#$query .= ($in->{'ww'}) ? "LOWER(rec.$field)= $tmpval " : "LOWER(rec.$field) LIKE $tmpval2 ";
					$query .= "rec.$field= $tmpval ";
				};
				
				$is_first_search_field=0;
			} elsif ($contentDef->{cfg}{$field}[1] eq 'date') {

			
				$tmpval = Wywrota->db->quote( getDate(time()) );
				

				if ($in->{$field} eq 'fromtoday') {
					$query .= ($in->{'ma'} eq 'on') ? (" OR ") : (" AND ") if !$is_first_search_field;
					$query .= "rec.$field > $tmpval";
					$is_first_search_field=0;

				}
				elsif ($in->{$field} =~ /(\d+)D/) {
					# aktualne rekordy: 86400 - 1 dzien

					$query .= ($in->{'ma'} eq 'on') ? (" OR ") : (" AND ") if !$is_first_search_field;
					$query .= "rec.$field BETWEEN ".Wywrota->db->quote( getDate(time() - 86400*$1) ) ." AND $tmpval ";
					$is_first_search_field=0;

				}
				elsif ($in->{$field} =~ /(\d+)M/) {
					# aktualne rekordy: 86400 - 1 dz, 604800 - 1 tydzien, 2592000 - 1 miesiac

					$query .= ($in->{'ma'} eq 'on') ? (" OR ") : (" AND ") if !$is_first_search_field;
					$query .= "rec.$field BETWEEN ".Wywrota->db->quote( getDate(time() - 2592000*$1) ) ." AND $tmpval ";
					$is_first_search_field=0;

				}
				elsif ($in->{$field} =~ /(\d*)\-(\d*)/) {
					# lodowka
					
					$tmpval = $1; #year
					$tmpval2 = $2; #month
					
					if ($tmpval2 >= 12) {
						$tmpval++;
						$tmpval2 = "01";
					} else {
						$tmpval2++;
					}
					

					$query .= ($in->{'ma'} eq 'on') ? (" OR ") : (" AND ") if !$is_first_search_field;
					$query .= " (rec.$field BETWEEN ".Wywrota->db->quote( "$1-$2-01" )." AND ".Wywrota->db->quote( "$tmpval-$tmpval2-01" ). ")";
					$is_first_search_field=0;

				}

	
			} elsif (int($in->{$field}) or $in->{$field} eq "0") {

				if ($in->{'keyword'} && $in->{$field}) {
					# add condition to keyword searching
					$addQuery .= " AND rec.$field=".int($in->{$field});
				} else {
					$query .= ($in->{'ma'} eq 'on') ? (" OR ") : (" AND ") if !$is_first_search_field;
					$query .= "rec.$field=$in->{$field} ";
				}
				$is_first_search_field=0;
			};

		}
	}

	foreach $field (@search_lt_fields) {

		# only numeric comparation implemented
		$fieldquery = "rec.$field<". (int($in->{$field}) or int($in->{"$field-lt"}));
		if ($is_first_search_field) {
			$query = $fieldquery;
			$is_first_search_field=0;
		} else {
			$query = "($query) AND $fieldquery ";
		}
	}

	foreach $field (@search_gt_fields) {

		# only numeric comparation implemented
		$fieldquery = "rec.$field>". (int($in->{$field}) or int($in->{"$field-gt"}));
		if ($is_first_search_field) {
			$query = $fieldquery;
			$is_first_search_field=0;
		} else {
			$query = "($query) AND $fieldquery ";
		}
	}

	foreach $field (@search_not_fields) {

		# only numeric comparation implemented
		$fieldquery = "rec.$field<>". (int($in->{$field}) or int($in->{"$field-not"}));
		if ($is_first_search_field) {
			$query = $fieldquery;
			$is_first_search_field=0;
		} else {
			$query = "($query) AND $fieldquery ";
		}
	}



	if ( Wywrota->content->mng( $contentDef->{cid} )->getSqlAddConditions() ) {
		$query = "1" if (!$query);
		$query = "($query) ". Wywrota->content->mng( $contentDef->{cid} )->getSqlAddConditions() ;
		$query = "($query) $addQuery" if (length($addQuery));
	}

	# checking view/mod permissions
	if ($db_operation eq "mod" and !per('admin')) {
		#($restricted = 1) if ($db_operation eq "view" and !per('admin'));
		$query .= " AND user_id=$Wywrota::session->{user}{id}";
	}

	# count the results
	$query_cnt_from = ($contentDef->{'sql_view'} || $contentDef->{'tablename'} ) ." ";
	$query_cnt_from = " `favorites` f, $contentDef->{'tablename'} " if ($db_operation eq "fav");
	$query_cnt_from = " `_top_views` tv, $contentDef->{'tablename'} " if ($db_operation eq "top");
	$query_cnt_from = " `tag` tag, $contentDef->{'tablename'} " if ($db_operation eq "tag");

	$queryRes->{_sql_query_conditions} = $query;
	$queryRes->{_sql_query_cnt_from}   = $query_cnt_from;

	$cnt = int( Wywrota->db->selectCount($query_cnt_from, $query) );
	if ($cnt == 0) {
		$queryRes->msg('nothing_found');
		return $queryRes;
	}


	# search fields
	foreach (keys %{$contentDef->{cfg}}) {
		next if (!$contentDef->{cfg}{$_}); # skipp buggy empty fields 
	    
		#if ( ($_ eq 'tresc') && (not $in->{'view'}) && (not $in->{'gc'}) && !$config{'shell'} ) {
			# $fields .= " CHAR_LENGTH(rec.tresc) as trescLength,";
		#} else {
			$fields .= " rec.$_,";
		#}
	}
	chop $fields;

	
	$query = $self->buildFullQuery($contentDef, $fields, $query, $db_operation, $in->{gb}) . $self->appendLimitOrderBy($in, $cnt, $contentDef);


	# execute the main query
	$hits = Wywrota->db->buildHashRefArrayRef($query);
	my @hit = @{$hits};
	
	
	if (defined $hit[0]) {
		$queryRes->set({status=>'ok',  hits=>$hits,  cnt=>$cnt });
	} else {
		$queryRes->msg('db_error');
	}

	return $queryRes;
}




sub buildFullQuery {
# --------------------------------------------------------
# generuje kawałek kodu do wstawienia bezposrednio na strone
	my $self = shift;
	my $contentDef = shift;
	my $fields = shift || "rec.*";
	my $conditions = shift;
	my $mode = shift;
	my $group_by = shift;
	my $getDeleted = shift;
	my ($query, $query_from, $addCond, $maintable, $group_conditions);

	# attach user information
	if ( defined $contentDef->{cfg}{user_id} ) {
		$fields .= ", ludzie.imie as ludzie_imie, ludzie.wywrotid as wywrotid, ludzie._grupy as _user_to_ugroup, ludzie._image_filename as _ludzie_photo, ludzie._is_premium as _is_premium";
		$query_from = " LEFT JOIN ludzie ON rec.user_id=ludzie.id "; #RIGHT OUTER 
	}

	$fields .= Wywrota->content->mng( $contentDef->{cid} )->getSqlAddFields(); 

	$fields = "$fields, tv.up_down, tv.count" if ($mode eq "top");
	$fields = "DISTINCT $fields" if ($mode eq "fav" or $mode eq "top");

	$addCond = Wywrota->content->mng( $contentDef->{cid} )->getSqlAddConditions($mode, $getDeleted);
	if ($addCond) {
		$conditions = "1" if (!$conditions);
		$conditions = "($conditions) ".  $addCond;
	}
	
	$maintable = ($contentDef->{'sql_view'} || $contentDef->{'tablename'} ) ;
	
	$group_conditions = $conditions;
	$group_conditions =~ s/rec\./ss./g;
	

	return "SELECT $fields FROM "
		. (($mode eq 'fav') ? " `favorites` f, " : "" )
		. (($mode eq 'top') ? " `_top_views` tv, " : "" )
		. (($mode eq 'tag') ? " `tag` tag, " : "" )
		. $maintable ." rec "
		. Wywrota->content->mng( $contentDef->{cid} )->getSqlAddJoin()
		. $query_from
		. " WHERE " . $conditions
		. (($group_by) ? " AND NOT EXISTS (select 1 from $maintable ss where ss.$group_by = rec.$group_by and ss.id > rec.id and $group_conditions) " : "");

	# soft group by - http://stackoverflow.com/questions/3449757

}


sub appendLimitOrderBy {
# --------------------------------------------------------

	my $self = shift;
	my $in = shift;
	my $cnt = shift;
	my $contentDef = shift;
	my ($first, $orderby );
	my ($kolumna, $wedlug, $so);
	
	$orderby = '';
	if ($in->{sb}) {

		$orderby = " ORDER BY ".$in->{sb};
		$orderby .= " DESC" if ($in->{so} =~ "^(d|D)");
	} elsif ($contentDef->{sort}{by}) {

		# default sort order
		foreach (@{$contentDef->{sort}{by}}) {
			if (ref $_ eq 'HASH' && $_->{default}) {
				($kolumna, $wedlug, $so) = split(/,/, $_->{content});
				$orderby = " ORDER BY $kolumna";
				$orderby .= " DESC" if ($so =~ "^desc");
			}
		}

	}

	$in->{'mh'} = $contentDef->{records_per_page} if (!defined($in->{'mh'}));
	$in->{'nh'} = 1 if (!defined($in->{'nh'}));
	$first = ($in->{'mh'} * ($in->{'nh'} - 1));

	# do the randomisation
	if ($in->{random}) {
		srand;
		$first = int (rand($cnt - $in->{'mh'}));
	}
	$first = 0 if ($first <0);

	return " $orderby LIMIT $first, $in->{'mh'}";

}


1;