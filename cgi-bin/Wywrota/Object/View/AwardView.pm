package Wywrota::Object::View::AwardView;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use base 'Wywrota::Object::View::BaseView';

sub header {
# -------------------------------------------------------------------------------------
# dolacza naglowek z tytulem strony
# 0 - tytul strony
# 1 - menu / nomenu / bar
# 2 - meta description
# 3 - meta keywords
# 4 - no http cache (default 0 - cache enabled)
# 5 - no billboard (default 0 - billboard showed)

	my ($output, $search_form);
	my $self = shift; 
	my $param=shift;
	$param->{nomenu}=3;

	$output = $self->SUPER::header($param)
		. qq~ <div class="awardContent">~;

}


sub searchHeader {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my ($output);
	
	$output = $self->SUPER::searchHeader($queryRes, $tytul) ;

	$output .= qq~

		<table class="awardTable">
		<tr>
			<th style="width: 30%;">praca</th>
			<th>autor</th>
			<th>informacje o nagrodzie</th>
		</tr>
	~ if ($queryRes->{in}->{small});

	return $output;

}

sub searchFooter {
# --------------------------------------------------------
	my $self = shift;
	my $queryRes = shift;
	my $tytul = shift;
	my ($output);
	
	$output = qq~
		</table>
	~ if ($queryRes->{in}->{small});

	$output .= $self->SUPER::searchFooter( $queryRes, $tytul );

	return $output;

}

1;