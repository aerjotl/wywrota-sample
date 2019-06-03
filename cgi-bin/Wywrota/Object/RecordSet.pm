package Wywrota::Object::RecordSet;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

#use strict;
use Data::Dumper;
use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Language;


our @ISA = qw(Wywrota::Object::BaseObject);


# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id			=> [0, 'auto',       '_hid',		16,			1,  '',          ''],
		content_id	=> [1, 'numer',      '_hid',		16,			1,  '',          ''],
		user_id		=> [2, 'numer',      '_hid',		16,			1,  '',          ''],
		title		=> [3, 'alpha',      'inputWide',	128,		1,  '',          'title'],
		description	=> [4, 'textarea',   'txtAreaSm1',  4096,		0,  '',          'description'],
		privacy		=> [5, 'radio',      '',			1,			1,  '1',         'privacy'],
		image_id	=> [6, 'numer',      '_hid',		16,			0,  '',          ''],
		_record_cnt	=> [7, 'numer',      '_hid',		16,			1,  '0',         '']
	 };


# --------------------------------------------------------



sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	return $self;
}


sub preProcess {
# --------------------------------------------------------
	my ($output, $year);
	my $self = shift;
	my $rec = $self->rec;

	$self->SUPER::preProcess(@_);

	$rec->{cnt_word} = Wywrota::Language::plural($rec->{_record_cnt}, Wywrota->cc->{$rec->{content_id}}{keyword} );
	return $self;
}


sub record {
# --------------------------------------------------------
# duzy rekord

	my $self = shift;
	my $rec = $self->rec;
	my ($output);
	$self->preProcess();

	$output = qq~
		<div class="recordSet">
			<a href="$rec->{uri}">$rec->{title}</a>
			<div>$rec->{description}</div>
			<div>
				<span class="cnt">$rec->{_record_cnt} $rec->{cnt_word}</span> &middot;
				<span class="privacy$rec->{val}->{privacy}">zestaw $rec->{privacy}</span> &middot;
				<span class="author">$rec->{ludzie_imie}</span> 
			</div>
		</div>
	~;

	return $output;
}


sub recordSmall {
# --------------------------------------------------------
# duzy rekord

	my $self = shift;
	my $rec = $self->rec;
	my ($output);
	$self->preProcess();

	$output = qq~
		<div class="recordSetSm">
			<a href="$rec->{uri}">$rec->{title}</a>
			<div>
				<span class="cnt">$rec->{_record_cnt} $rec->{cnt_word}</span> 
			</div>
		</div>
	~;

	return $output;
}


1;
