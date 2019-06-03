package Wywrota::DAO::QueryRes;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# Wrapper for results of a query
#
#-----------------------------------------------------------------------

use strict;
use JSON;
use Wywrota;
use Time::HiRes qw(gettimeofday tv_interval);


sub new {
# --------------------------------------------------------

	my $class = shift;
	my $init = shift;

	if (defined $init->{contentDef} and !ref $init->{contentDef}) {
		$init->{contentDef} = Wywrota->cc( $init->{contentDef} );
	};

	my $self = {
		contentDef=>	$init->{contentDef},
		in=>			$init->{in} || {}, 
		cnt=>			$init->{cnt} || '0',  
		hits=>			$init->{hits},  
		status=>		$init->{status} || '0',
		msg=>			$init->{msg} || 'empty_query',
		mode=>			$init->{mode},
		timer => 		gettimeofday
	};
	bless $self , $class;

	if ($init->{query}) {
		$self->fromQuery($init->{query}, $init->{cnt});
	}
	
	return $self;

}

sub DESTROY {
# --------------------------------------------------------
	my $self = shift;
	undef $self;
}


sub fromQuery {
# --------------------------------------------------------
	my $self = shift;
	my $query = shift;
	my $cnt = shift;
	return unless $query;
	
	$self->sql = $query;

	# execute the main query
	$self->{hits} = Wywrota->db->buildHashRefArrayRef($query) or Wywrota->error($@);
	
	if ($self->hits) {
		$self->status = 'ok';
		$self->cnt = $cnt;
	} else {
		$self->msg = 'db_error';
		$self->cnt = 0;
	}
	
	return $self;	
}

sub contentDef	: lvalue	{ shift->{contentDef}; }
sub config		: lvalue	{ shift->{contentDef}; }
sub in			: lvalue	{ shift->{in}; }
sub cnt			: lvalue	{ shift->{cnt}; }
sub sql			: lvalue	{ shift->{sql}; }
sub status		: lvalue	{ shift->{status}; }
sub msg			: lvalue	{ shift->{msg}; }
sub mode		: lvalue	{ shift->{mode}; }
sub nomore		: lvalue	{ shift->{nomore}; }
sub norss		: lvalue	{ shift->{norss}; }
sub records_per_page: lvalue{ shift->contentDef->{'records_per_page'}; }

sub hits { 
# --------------------------------------------------------
	my $self = shift;
	return (defined $self->{hits}) ? $self->{hits} : [];
}


sub pushHit {
# --------------------------------------------------------
	my $self = shift;
	my $hit = shift;
	my $noinc = shift;

	if ($self->cnt) {
		push (@{$self->{hits}}, $hit);
	} else {
		$self->{hits} = \@{[$hit]};
	}
	return if $noinc;
	$self->{cnt}++;
}

sub set {
# --------------------------------------------------------
	my $self = shift;
	my $set = shift;
	my $key;
	foreach $key (keys %{$set}) {
		$self->{$key} = $set->{$key};# if ( defined($self->{$key}) );
	}
	return $self;
}

sub webSafeHits {
# --------------------------------------------------------
# returns array of hits - only fields that are safe to be sent via AJAX

	my $self = shift;
	my $safefields = shift;
	my (@safeHits, $hit, $safeHit);

	foreach $hit (@{$self->{hits}}) {
		$safeHit = undef;
		foreach ( split(/\,/,  $safefields ) ) {
			$safeHit->{$_} = $hit->{$_};
		}
		push (@safeHits, $safeHit);
	}
	return \@safeHits;
}

sub timer {
# --------------------------------------------------------
	my $self = shift;
	return sprintf ("%.3f sec.", tv_interval([$self->{timer}], [gettimeofday])) ;
}

sub hitsJSON {
# --------------------------------------------------------
	my $self = shift;
	return to_json( $self->webSafeHits( $self->contentDef()->{'safefields'} ) );
}


sub DESTROY {
	my $self = shift;
	
	foreach (keys %{$self}) {
		delete $self->{$_};
	}
	
}



1;
