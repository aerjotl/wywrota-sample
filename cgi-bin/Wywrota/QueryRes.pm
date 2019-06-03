package Wywrota::QueryRes;



use strict;
use JSON;
use Wywrota;
use Wywrota::Language;
use Wywrota::Config;
use Wywrota::Utils;
use Date::Parse;


use Wywrota::DAO::QueryRes;
use base 'Wywrota::DAO::QueryRes';

sub html {
# --------------------------------------------------------
# usage:
# 	$output = $queryRes->html({
#		title			=>
#		generate		=>
#		forceHeaders	=>
#		disable			=>
#		chrono			=>
#		list			=>
#		nomore			=>
#		norss			=>
#		itemIconFlag	=>
#	})

	my $self = shift;
	my $param = shift;
	
	my $title = $param->{title};
	my $generate = $param->{generate};
	my ($output, $object, $age, $last_label, $lastObj, $objectHtml, $even);
	


	$self->nomore = $param->{nomore};
	$self->norss = $param->{norss};


	if ($param->{forceHeaders} || ($self->status eq "ok" and $self->cnt >= 0)) {

		foreach (@{$self->{hits}}) {
			eval {
			$object =  Wywrota->content->createObject( $_, $self->config->package )  ;
			$object->preProcess();
			$object->fixIcons( $param->{itemIconFlag}, $param->{itemIconId}  ) if ($param->{itemIconFlag});
			$object->even = ($even++)%2;
			
			};
			Wywrota->error("QueryRes :: html ". $self->config->package, $@, $_) if ($@);
			
			# add preety formatting
			if ($param->{chrono}) {
				$age = time() - str2time($object->val( $param->{chrono} ));

				if (($last_label < 86400) and ($age < 86400)) {
					$output .= qq~	<h3 class="listhd">Dzisiaj</h3>	~;
					$last_label = 86400;

				} elsif (($last_label < 86400*2) and ($age < 86400*2) and ($age > 86400)) {
					$output .= qq~	<h3 class="listhd">Wczoraj</h3>	~;
					$last_label = 86400*2;

				} elsif (($last_label < 86400*7) and ($age < 86400*7) and ($age > 86400*2)) {
					$output .= qq~	<h3 class="listhd">W ostatnim tygodniu</h3>	~;
					$last_label = 86400*7;

				} elsif (($last_label < 86400*30) and ($age < 86400*30) and ($age > 86400*7)) {
					$output .= qq~	<h3 class="listhd">W ostatnim miesiÄ…cu</h3>	~;
					$last_label = 86400*30;

				} elsif (($last_label < 86400*61) and ($age < 86400*61) and ($age > 86400*30)) {
					$output .= qq~	<h3 class="listhd">Dwa miesiÄ…ce temu</h3>	~;
					$last_label = 86400*61;

				} elsif ($last_label && ($last_label < 86400*61+1) and ($age > 86400*61)) {
					$output .= qq~	<h3 class="listhd">Starsze</h3>	~;
					$last_label = 86400*61+1;
				}
			};

			
			
			if ($generate eq 'newsletter' || $self->in->{list} eq 'newsletter' || $param->{list} eq 'newsletter') {
				$objectHtml = $object->recordNewsletter();
				
			} elsif ($self->in->{small} || $self->in->{list} eq 'small' || $param->{list} eq 'small' ) {
				$objectHtml = $object->recordSmall();
				
			} elsif ($self->in->{mini} || $self->in->{list} eq 'mini' || $param->{list} eq 'mini') {
				$objectHtml = $object->recordMini();

			} elsif ($self->in->{miniature} || $self->in->{list} eq 'miniature' || $param->{list} eq 'miniature') {
				$objectHtml = $object->recordMiniature();

	
			} elsif ($self->in->{list} eq 'wall' || $param->{list} eq 'wall') {
				
				$objectHtml = $object->recordWall();
					
				if (!$lastObj || ($lastObj->rec->{content_id} != $object->rec->{content_id}) || ($lastObj->user_id != $object->user_id)) {
					$objectHtml = qq|<div class="itemsType">| . $objectHtml;						
				}
				
				if (!$lastObj || ($lastObj->user_id != $object->user_id)) {
					$objectHtml = qq|<div class="authorItems">| . $object->avatar	. $objectHtml;					
				}
				
				if ($lastObj) {
					$objectHtml = "</div><!--itemsType-->".$objectHtml if ($lastObj->user_id != $object->user_id) || ($lastObj->rec->{content_id} != $object->rec->{content_id});
					$objectHtml = "</div><!--authorItems-->".$objectHtml if ($lastObj->user_id != $object->user_id);
				}
				$lastObj = $object;
				
			} else {
				$objectHtml = $object->record() ;
			};
			
			if ($param->{disable} && $param->{disable}{ $object->id }) {
				$objectHtml = qq|<span class="disabled">$objectHtml</span>|;
			}
			
			$output	.= $objectHtml;
		}
		
		if ($self->in->{list} eq 'wall' || $param->{list} eq 'wall') {
			$output	.= "</div><!--last itemsType--></div><!--last authorItems-->"; 
		}

		if ($generate) {
			$output = Wywrota->view( $self->cid )->wrapSearchHeaderFooterGenerate($output, $self, $title, $param)
		} else {
			$output = Wywrota->view( $self->cid )->wrapSearchHeaderFooter($output, $self, $title, $param);
		}
	
	} else {
		return ;
	}
	
	if ($param->{active} ) {
				
		$output = Wywrota->t->process('form/active_list.html', {
			items		=>	$output,
			fieldname	=>	'ids',
		});
			
	}
	
	$output .= qq|
		<a href="#" class="showHide">sql (|. $self->timer .qq|)</a>
		<div class="debugWW txtsm hidden">|. $self->sql .qq|</div>
	| if ($config{debug}{debug} and $self->sql);
	
	return $output;
}





sub hitsJSON {
# --------------------------------------------------------
	my $self = shift;
	return to_json( $self->webSafeHits( $self->config->safefields ) );
}




sub pagination {
# --------------------------------------------------------

	my $self = shift;
	

	return if ($self->{status} ne 'ok');

	my $in = $self->{in};
	my ($next_url, $left, $right, $upper, $lower, $i, $next_hit, $prev_hit, $output );
	my $navSpan = 4;

	$in->{'mh'} = $self->records_per_page if (!defined($in->{'mh'}));
	$in->{'nh'} = 1 if (!defined($in->{'nh'}));
	$in->{'favorites'} = 'list' if (!defined($in->{'favorites'}) and defined($in->{'set'}) );

	# Remove the nh= from the query string.		
	$next_url = $self->param();

	$next_hit = $in->{'nh'} + 1; 
	$prev_hit = $in->{'nh'} - 1;

	# First, set how many pages we have on the left and the right.
	$left  = $in->{'nh'}; 
	$right = int($self->{cnt}/$in->{'mh'}) - $in->{'nh'};

	# Then work out what page number we can go above and below.		
	($left > $navSpan)  ? ($lower = $left - $navSpan) : ($lower = 1); 
	($right > $navSpan) ? ($upper = $in->{'nh'} + $navSpan)   : ($upper = int($self->{cnt}/$in->{'mh'}) + 1);
	($navSpan - $in->{'nh'} >= 0) and ($upper = $upper + (1 + $navSpan - $in->{'nh'})); # Finally, adjust those page numbers if we are near an endpoint.		
	($in->{'nh'} > ($self->{cnt}/$in->{'mh'} - $navSpan)) and ($lower = $lower - ($in->{'nh'} - int($self->{cnt}/$in->{'mh'} - $navSpan) - 1));


	# Then let's go through the pages and build the HTML.
	if ( ($self->{cnt}/$in->{'mh'}) > 1 ) {
		$output = "<span>".Wywrota::Language::msg('pages').":</span> ";
		if ($in->{'nh'} > 1) {
			$output .= qq~<a href="$next_url,nh,$prev_hit" class="arLeft"><span>&laquo;</span></a> ~;
		};
		for ($i = 1; $i <= int($self->{cnt}/$in->{'mh'}) + 1; $i++) {
			if ($i < $lower) { $output .= "<span>...</span> "; $i = ($lower-1); next; }			
			if ($i > $upper) { $output .= "<span>...</span> "; last; }
			($i == $in->{'nh'}) ?
				($output .= qq~<span class=g>$i</span> ~) :
				($output .= qq~<a href="$next_url,nh,$i">$i</a> ~);
			if (($i * $in->{'mh'}) >= $self->{cnt}) { last; }  # Special case if we hit exact.
		}
		($output .= qq~<a href="$next_url,nh,$next_hit" class="arRight"><span>&raquo;</span></a> ~) unless ($in->{'nh'} == $i);
	} 

	$self->{pagination} = $output;
	return $output ? qq|<div class="listPagination">$output</div><div class="clrl"></div>| : '' ;
}



sub param {
#--------------------------------------------------------------------
# ta procedura tworzy link strony z listą rekordow 

	my $self = shift;
	my ($param, $link, $key, %leave);
	my $in = $self->{in};
	
	foreach (@_) {
		$leave{$_}=1;
	}

	foreach $key (keys %{$in}) {	

		next if (($in->{'keyword'}) && ($key ne 'keyword') && ($key ne 'sb') && ($key ne 'so') && !$leave{$key}); 
		next if ($key =~ /(txt|tabela|kolumna|suffix|postfix|random|count|db|count|generate|mh|nh|val|cn|small|sliders|gb|id-not|pagination|img_height|img_width)/ && !$leave{$key});
		next if ($key eq 'template' && $in->{$key} ne 'quickimport' && !$leave{$key});
		$param->{$key} = urlencode($in->{$key}) if ( length($in->{$key}) );
	 }

	foreach (sort keys %{$param}) {$link.="$_,$param->{$_},"};
	chop $link;
	
	#if ($self->mode eq 'rel') {
	#	$link = "/rel,".$self->{rel}. ',' . $link;
	#} elsif ($self->{contentDef}{url}) {
		$link = "/db/".($self->{in}{db} || $self->{contentDef}{url})."/".$link;
	#}
	
	return $link;
}


















1;
