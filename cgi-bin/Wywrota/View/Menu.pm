package Wywrota::View::Menu;

use strict;
use Data::Dumper;
use Wywrota;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Language;

sub new {
# --------------------------------------------------------
	my $class = shift;
	my $items = shift;
	my $className = shift;
	my $title = shift;
	bless {
		_items =>$items,
		_className =>$className,
		_title => $title, 
	}, $class;
}

sub DESTROY {
# --------------------------------------------------------
	my $self = shift;
	undef $self;
}


sub addItem {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $item = shift;
	if ($self->{_items}) {
		push (@{$self->{_items}}, $item);
	} else {
		$self->{_items} = \@{[$item]};
	}
}


sub getNavMenu {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my ($output) ;

	$output = $self->_getItems();

	$output = qq~
		<div class="navMenu">
			<a href="javascript:void(0);"><span class="contextDropDown">$self->{_title}</span></a>

			<ul class="contextMenu $self->{_className}">
				$output
			</ul>

		</div> 
	~;
	return $output;

}


sub getAccordionMenu {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $output ;
	$output = $self->_getItems();

	$output = qq~
		<li class="$self->{_className}">
		<a href="javascript:void(0);" class="hd">$self->{_title}</a>
		<ul class="arrows">
			$output
		</ul>
		</li>
	~ if ($output);
	return $output;
}


sub getUnorderedList {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $cssclass = shift || $self->{_className};
	my $output;
	$output = $self->_getItems();

	$output = qq~
		<ul class="$cssclass">
			$output
		</ul>
		<div class="clr"></div>
	~ if ($output);
	return $output;
}


sub addSpace {
# -------------------------------------------------------------------------------------
	my $self = shift;
	$self->addItem({ class=>"space", content=>"" });
}

sub _getItems {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my ($output, $item, $class) ;

	foreach $item (@{$self->{_items}}) {
		if (defined $item->{content}) {
			$output .= "<li class='content $item->{class}'>".$item->{content}.'</li>';
			next;
		};
		$class = ($item->{class}) ? qq~ class="$item->{class}" ~ : "";
		$output .= qq~
			<li><a $class href="$item->{link}">$item->{title}</a></li>
		~;
	}
	return $output;
}



1;