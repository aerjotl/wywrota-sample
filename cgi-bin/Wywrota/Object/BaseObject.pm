no warnings 'redefine';
package Wywrota::Object::BaseObject;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------
#
# The BaseObject package can be seen as an abstract class for all 
# content objects managed by Wywrota. The fields defined in the object
# will be used to dynamically construct SQL queries, html forms, etc.
#
# Each column is defined in this format:
#
#    field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']
#
#    - field_name     - name of the column in the database
#    - position       - position of the field in the form
#    - field_type     - type of the field: 
#                        'numer'    integer number
#                        'alpha'    alphanumeric (varchar, text, ...)
#                        'radio'    radio select field
#                        'checkbox' checkbox select field
#                        'combo'    combo field
#                        'date'     timestamp field
#                        'auto'     auto-increment (used for primary keys)
#    - class          - flag or css class of the form field. Available flags:
#                        '_hid'     (-1) hidden for everybody 
#                        '_ao'		(-2) admin only, hidden for regular users
#                        '_ao_ne'	(-3) visible for admin only, but not editable
#    - maxlength      - maximum length of the field
#    - not_null       - are null (empty) values allowed
#    - default        - deafult value of the field
#    - form_label     - label of the field in the form
#
#-----------------------------------------------------------------------


use strict;
use Time::Local;
use HTTP::Date;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Log;
use Date::Parse;
use Clone qw(clone);
use Data::Structure::Util qw(_utf8_off _utf8_on has_utf8 utf8_off utf8_on);

use JSON;

 
sub new {
#-----------------------------------------------------------------------
	my ($class, $rec) = @_;
	my $myRec;
	my $self = { 
		rec => clone($rec)
		};
	bless $self, $class;

	return $self;
}


#-----------------------------------------------------------------------
# basic pre-processing of the object 
#-----------------------------------------------------------------------
sub preProcess {
	my $self = shift;
	my $fullProcess = shift;
	my $rec = $self->rec;
	

	eval {
		
		$rec->{tresc} =~ s/<body.*<\/body>//g;	# bugfix - internal body included by CKeditor

		$self->{active} = 1;
		$self->{active} = 0 if (defined $rec->{_active} and !$rec->{_active});

		$self->assignDictionary();
		
		$self->prepareSeo();
		$self->appendUrl();
		$self->appendOldStyleUrl();

		$rec->{hover_url} = sprintf("/cgi-bin/ajax.fcgi?a=getObject&big=1&cid=%d&suffix=sq&id=%d", $self->config->{cid}, $rec->{id});
		
		if ($self->config->{vote}) {
			Wywrota->vote->initRatings($self);
		};


		$self->{uid} = $self->uid();
		$rec->{cid} = $self->cid();

		if (defined $rec->{json}) {
		 	$rec->{json_object}  = decode_json $rec->{json} ;
		 	_utf8_off($rec->{json_object});
		}
				
		if ($self->config->{distinction}) {
			if ($rec->{val}{wyroznienie} == 1 and (str2time($rec->{val}{data_przyslania}) > str2time("2012-03-23") )) {
				$rec->{distinctions} = 'recommended';
				$rec->{distinction_html} = qq|<span class="distinction$rec->{val}{wyroznienie}">$rec->{wyroznienie}</span> |;
			};
			if ($rec->{val}{wyroznienie} > 1) {
				$rec->{distinctions} = 'redstar';
				$rec->{distinction_html} = qq|<span class="distinction$rec->{val}{wyroznienie}">$rec->{wyroznienie}</span> |;
			};
		};
		
		if ($self->config->{vote}) {
			if (Wywrota->vote->isBluestar($rec)) {
				$rec->{distinctions} .= ' bluestar';
				$rec->{distinction_html} .= qq|<span class="distinctionUser">+ wyróżnienie czytelników</span> |;
			};
			
		};
		

		Wywrota->nav->appendEditIcons($self);

        # full pre-processing used for getting additional details for object page
		if ($fullProcess) {
		
			if ($self->config->{comments}) {
			
				if (!$self->cc->{can_comment} || $rec->{val}{can_comment}) {
					$rec->{comments} = Wywrota->view->view('Comment')->getComments($self) ;
				};				
			};

			
			if ($self->config->{vote}) {
				if (!$self->cc->{can_vote} || $rec->{val}{can_vote}) {
					$rec->{votebox} = Wywrota->vote->votePortletsDiv($self) ;
				};				
			};
			
			$self->getViewsCount();

		};

	};
	Wywrota->warn($@) if ($@);

	return $self;
}


sub prepareSeo {
	return shift;
}



sub processTextObject {
# --------------------------------------------------------

	my $self = shift;
	my $rec = $self->rec();
	my $useContentPagination = shift;
	my ($tytul, $output, $cnt, $status, $mar, @hits);

	my $contentLength;
	my $divideTo ;
	my $divideAvg;
	my $tresc;

	$rec->{tytul} = dehtml($rec->{tytul});
	$rec->{opis} = dehtml($rec->{opis});
	$rec->{autor} = dehtml($rec->{autor});

	#zamiana cudzysłowów
	$rec->{opis} =~ s/\n/ /g;
	$rec->{opis} =~ s/"/&quot\;/g;
	$rec->{autor} =~ s/"/&quot\;/g;
	$rec->{tytul} =~ s/"/&quot\;/g;

	$rec->{description}="$rec->{'typ'} na Wywrocie - $rec->{tytul} $rec->{opis} autor: $rec->{autor}";
	$rec->{keywords}="$rec->{'typ'} Wywrota $rec->{opis} $rec->{tytul} $rec->{autor}";
	$rec->{pagination1}="";
	$rec->{pagination2}="";

	
	# TODO !!!!!!!!!!
	# $useContentPagination = 0 if ($rec->{czy_tresc_to_html});


	# content pagination
	$rec->{tresc} =~ s/\n/ /g;
	$rec->{tresc} =~ s/(<br[^>]*>)/$1\n/g;
	$rec->{tresc} =~ s/(<p[^>]*>)/\n$1/g;
	$contentLength = length($rec->{tresc});


	if ($useContentPagination && $contentLength > 12000) {

		$divideTo = ceil($contentLength / 12000);
		$divideAvg = $contentLength / $divideTo;
		$tresc = substr($rec->{tresc}, $divideAvg*$Wywrota::in->{page}, $divideAvg);

		# remove line from previous
		if ($Wywrota::in->{page}>0) {
			$tresc = substr($tresc, index($tresc,"\n"), $divideAvg);
		}	

		# add line from next
		my $nextPart = substr($rec->{tresc}, $divideAvg*($Wywrota::in->{page}+1), $divideAvg/3);
		$tresc .= substr($nextPart, 0, index( $nextPart ,"\n"));

		# $rec->{pagination} = Wywrota->nav->makePagination("/db/$Wywrota::request->{currentContent}->url/$rec->{id}", $divideTo);

		$rec->{tresc} = $tresc;
	} 	

	return $rec;
}


sub getViewsCount {
# --------------------------------------------------------
	my $self = shift;
	my $cnt = Wywrota->db->quickOne("SELECT count FROM _content_views WHERE content_id=? AND record_id=?", $self->cid, $self->id);
	$self->rec->{view_count} = $cnt;
}


sub getClass {
# --------------------------------------------------------
	my $self = shift;
	my @tokens = split(/::/, ref $self);
	return $tokens[$#tokens];
}

sub appendUrl {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	my $link;
	$Wywrota::request->{urlSufix} = "wywrota.pl" if (!$Wywrota::request->{urlSufix}); # for cron


	if ($self->config->{record_url}) {
		$link = $self->config->{record_url};
		$link =~ s/\{([^\}]+)\}/substr(simpleAscii($rec->{$1}), 0, 40)/eg;
	} else {
		$link = "/".$rec->{id} . ".html";
	}


	if ($self->config->{record_url_domain}) {
		$rec->{uri} = $link;
		$rec->{uri} = "http://".$self->config->{record_url_domain}.".".$Wywrota::request->{urlSufix}.$rec->{uri} ;
	} else {
		$rec->{uri} = $link;
		$rec->{uri} = "http://www.".$Wywrota::request->{urlSufix}.$rec->{uri} if ($Wywrota::request->{urlPrefix} ne 'www');
	}


	if (!defined($rec->{url})) {
		if ($rec->{uri} =~ /^http/) {
			$rec->{url} = $rec->{uri};
		} else {
			$rec->{url} = $config{'site_url'}.$rec->{uri} ;
		}
	}

	return $rec;
}



#-----------------------------------------------------------------------
# change ulrs to old-style only for old objects
# used to maintain facebook 'like' links created with old style
#-----------------------------------------------------------------------
sub appendOldStyleUrl {
	my $self = shift;
	my $rec = $self->rec;

	$rec->{old_style_url} = $rec->{url};
	
	# artykuly
	if ($self->config->{cid} == 3) {
		if (!$rec->{val}{data_przyslania} || (str2time($rec->{val}{data_przyslania}) < str2time("2012-12-19") ) ) {
			$rec->{old_style_url} = $rec->{id}."-".$rec->{tytul}."-".$rec->{autor};
			$rec->{old_style_url} = substr(simpleAscii($rec->{old_style_url}), 0, 46);
			$rec->{old_style_url} = "http://www.wywrota.pl/db/artykuly/" . $rec->{old_style_url} . ".html";
		};	
	}
	
	# literatura
	if ($self->config->{cid} == 1) {
		if (!$rec->{val}{data_przyslania} || (str2time($rec->{val}{data_przyslania}) < str2time("2012-12-19") ) ) {
			$rec->{old_style_url} = $rec->{id}."-".$rec->{autor}."-".$rec->{tytul};
			$rec->{old_style_url} = substr(simpleAscii($rec->{old_style_url}), 0, 46);
			$rec->{old_style_url} = "http://literatura.wywrota.pl/" . $rec->{old_style_url} . ".html";
		};	
	}
	
	# spiewnik
	if ($self->config->{cid} == 7) {
		if (!$rec->{val}{data_przyslania} || (str2time($rec->{val}{data_przyslania}) < str2time("2013-01-25") ) ) {
			$rec->{old_style_url} = "http://teksty.wywrota.pl/{id}-{wykonawca}-{tytul}.html";
			$rec->{old_style_url} =~ s/\{([^\}]+)\}/substr(simpleAscii($rec->{$1}), 0, 40)/eg;
		};	
	}
	
	# wykonawca
	if ($self->config->{cid} == 15) {
		$rec->{old_style_url} = "http://www.wywrota.pl/wykonawcy/{wykonawca}.htm";
		$rec->{old_style_url} =~ s/\{([^\}]+)\}/simpleAscii($rec->{$1})/eg;
	}
	
	if (!$rec->{data_przyslania} || (str2time($rec->{data_przyslania}) < str2time("2012-06-08") ) ) {
		$rec->{old_style_url} =~ s/\-/_/g;
	};
}




sub record {
#-----------------------------------------------------------------------
	return  Wywrota::Forms::buildHtmlRecord(shift);
}

sub recordSmall {
#-----------------------------------------------------------------------
	return  Wywrota::Forms::buildHtmlRecord(shift);
}

sub recordBig {
	return  shift->record(@_);
}


sub recordMedium {
	return  shift->record(@_);
}


sub recordNewsletter {
	return  shift->record(@_);
}




# --------------------------------------------------------
# Returns a hash of the defaults used for a new record.
# --------------------------------------------------------
sub getDefaults {

	my $self = shift;
	my ($field);

	my $cc = $self->cc;

	foreach $field (keys %{$cc}) {
		$self->{rec}->{$field} =  eval($cc->{$field}[5]);
	}
	
	if ($self->cc->{id}[1] ne 'auto') {
		$self->{rec}->{id} = Wywrota->db->selectMax( $self->config->{'tablename'}, undef, 'id')+1;
	}	

	$self->{rec}->{user_id}=$Wywrota::session->{user}{id};

	return $self;
}



# --------------------------------------------------------
# validates the fields of the object
# used before saving the object to the database
# --------------------------------------------------------
sub validate {

	my $self = shift;
	my $mode = shift;
	my $rec;
	my ($col, @input_err, $errstr, $err, $query);	


	eval {
		$rec = $self->rec;
		
		foreach $col (keys %{$self->cc}) {

			# skip fields that were not changed
			next if (!defined($rec->{$col}) && $self->cc->{$col}[1] ne 'checkbox'); 
			next if ($self->cc->{$col}[1] eq 'auto');
			
			# entry is null or only whitespace
			if ( ($rec->{$col} =~ /^\s*$/) and ($self->cc->{$col}[4]) ) {
				push(@input_err, "<b>$col</b> – pole nie może być puste");  
			}

			# max lenght exceeded
			if ( (length($rec->{$col}) > $self->cc->{$col}[3]) and	($self->cc->{$col}[3] != 0) ) {
				push (@input_err, "<b>$col</b> – wpis za długi. maxymalna długość: " . $self->cc->{$col}[3] )
			};

			if (  ($self->cc->{$col}[1] eq "numer") and ($rec->{$col} !~ /^\d*$/) ) {
				push (@input_err, "<b>$col</b> – niepoprawny numer"  )
			};
			
		}

	};
	Wywrota->error("validation error", $@) if ($@);
	
	if ($#input_err+1 > 0) {					
		$self->{errors} = \@input_err;
		return "err";
	}
	else {
		delete $self->{errors};
		return "ok";							# no errors, return ok.
	}
	
	
}


sub getErrors {
# --------------------------------------------------------
	my $self = shift;
	my $message;
	
	return unless (defined $self->{errors});
	
	foreach (@{$self->{errors}}) {	
		$message .= "<li>".$_;
	}
		
	return qq|
		<div class="div_warning">
			<h2>Błąd</h2>
			<p>Wystąpiły problemy z następującymi polami:
			<ul>$message</ul>
			<p>Popraw błędy i spróbuj ponownie.
		</div>
	|;
}

sub getErrorString {
# --------------------------------------------------------
	my $self = shift;
	my $message;
	
	return unless (defined $self->{errors});
	
	foreach (@{$self->{errors}}) {	
		$message .= $_.";";
	}
		
	return $message;
}


sub assignDictionary {
# --------------------------------------------------------
	my $self = shift;
	my $record = $self->rec;
	my ($prefix,$col);

	eval{
		foreach (keys %{$self->cc}) {
			if ( not defined($record->{val}{$_}) ) {
				$record->{val}{$_} = $record->{$_};
			}
			if ( defined $self->dict and defined $self->dict->{$_} && 
				$self->cc->{$_}[1] ne "image" && $self->cc->{$_}[1] ne "file" ) {
				$record->{$_} = Wywrota->dict->getLabel($_, $record->{val}{$_}, $self->getClass) || $record->{$_} || "" ; # bugfix - znikajace tytuly i id w listingach
			}
		}
	};
	Wywrota->warn("BaseObject : assignDictionary " . $@) if ($@);

}

sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return ($rec->{autor} || $rec->{ludzie_imie}) . ' – "' . ($rec->{tytul} || $rec->{podpis} || $rec->{temat} || "bez tytułu") . '"';
}

sub toHtmlString {
# --------------------------------------------------------
	my $self = shift;
	return $self->toString();
}


sub per { Wywrota->perRecord(shift, shift); }
sub rec { shift->{rec} };
sub config { Wywrota->app->{ccByName}{ shift->getClass } };
sub cc { shift->config->{cfg} };

sub getClass {
	my $self = shift;
	my @tokens = split(/::/, ref $self);
	return $tokens[$#tokens];
}
sub uid { 
	my $self = shift;
	return "c" . $self->config->{cid} ."x". $self->{rec}->{id};
}
sub val { 
	my $self = shift;
	my $variable = shift;
	return if (!$self->rec || !$variable);
	if (defined $self->{rec}{val}) {
		return $self->{rec}{val}{$variable};
	} else {
		return $self->{rec}{$variable};
	}
}


sub package { shift->config->package };
sub mng 	{ Wywrota->mng( shift->getClass );}
sub view 	{ Wywrota->view( shift->getClass );}
sub url  {	
	my $self = shift;
	$self->appendUrl();
	return 	$self->rec->{url};
}
sub uri  				{	shift->rec->{uri}		 }
sub id : lvalue 		{	shift->rec->{id} }
sub cid  : lvalue		{	shift->config->{cid} }
sub user_id : lvalue 	{	shift->rec->{user_id} }
sub listIndex : lvalue 	{	shift->{listIndex} }
sub dict { Wywrota->app->{ccByName}{  shift->getClass }{dict}{field} };


sub DESTROY {
	my $self = shift;
	foreach my $key (qw/rec cc/) {
		delete $self->{$key};
	}
}

	

1;
