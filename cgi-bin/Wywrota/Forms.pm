package Wywrota::Forms;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

 
use strict;
use Exporter; 
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Data::Dumper;
use HTML::Entities;


our @ISA = qw(Exporter);
our @EXPORT = qw(
	buildSelectField buildCheckboxField buildCheckboxFieldForArray buildRadioField 
	buildHtmlRecord buildHtmlRecordForm
);



sub buildSelectField {
# --------------------------------------------------------
# Builds a SELECT field based on information found in the database definition. 

	my ($column, $value, $class, $mode, $prefix, $dictRef) = @_;	
	my (@fields, $output, $field_name, $field);

	# get sorted fields
	@fields = sort {$dictRef->{$a}{label} cmp $dictRef->{$b}{label}} keys %{$dictRef};
	return "błąd: źle skonfigurowany słownik dla kolumny '$column'!" if ($#fields == -1);

	$class = " class=\"$class\"" if ($class);

	$output = qq|\n<select name="$prefix$column" $class><option value="">---|;
	foreach $field (@fields) {
		next if (!$dictRef->{$field}{active});
		$field_name = $dictRef->{$field}{label};
		$field eq $value ?
			($output .= qq~<option value="$field" selected>$field_name</option>\n~) :
			($output .= qq~<option value="$field">$field_name</option>\n~);
	}
	$output .= "</select>";

	return $output;

}


sub buildCheckboxField {
# --------------------------------------------------------
# Builds a CHECKBOX field based on information found in the database definition. 

	my ($column, $value, $mode, $prefix, $dictRef) = @_;	
	my (@fields, $output, $field_name, $field);

	# get sorted fields
	@fields = sort {$dictRef->{$a}{label} cmp $dictRef->{$b}{label}} keys %{$dictRef};
	return "błąd: źle skonfigurowany słownik dla kolumny '$column'!" if ($#fields == -1);


	foreach $field (@fields) {
		next if (!$dictRef->{$field}{active});
		$field_name =  $dictRef->{$field}{label};
		next if (!$field && !$field_name);
		(checkBinary($field,$value)) ?
			($output .= qq~<input type="checkbox" name="$prefix$column" id="$column$field" value="$field" checked><label for="$column$field">$field_name</label><br> \n~) :
			($output .= qq~<input type="checkbox" name="$prefix$column" id="$column$field" value="$field"><label for="$column$field">$field_name</label><br> \n~);
	}

	return $output;
}

sub buildImageField {
# --------------------------------------------------------
# Builds a Image field 

	my ($column, $value, $mode, $prefix) = @_;	
	my ($output, $file);
	my $dir = $Wywrota::request->{content}{current}{'url'};


	if ($mode eq 'add') {
		$output = qq~
			<input type="file" name="$prefix$column">
		~;
	} elsif ($mode eq 'edit') {
		if (-e "$config{'file_dir'}/$dir/$value"."-sm") {
			$file = qq~<img src="/pliki/$dir/$value~.qq~-sm">~;
		} elsif (-e "$config{'file_dir'}/$dir/$value"."-px") {
			$file = qq~<img src="/pliki/$dir/$value~.qq~-px">~;
		} else {
			$file = $value;
		}
		$output = qq~
			<input type="hidden" name="$prefix$column" value="$value">
			<a href="/pliki/$dir/$value" target="_blank">$file</a>
			<div class="showHide">
			<a href="#" class="arMod">podmień plik</a>
				<div class="hidden">
					<input type="file" name="_new_$column">
				</div>			
			</div>
		~;
	}
	return $output;
}



sub buildFileField {
# --------------------------------------------------------
# Builds a Image field 

	my ($column, $value, $mode, $prefix) = @_;	
	my ($output, $file);
	my $dir = $Wywrota::request->{content}{current}{'url'};


	if ($mode eq 'add') {
		$output = qq~
			<input type="file" name="$prefix$column">
		~;
	} elsif ($mode eq 'edit') {
		$output = qq~
			<input type="hidden" name="$prefix$column" value="$value">
			<a href="/pliki/$dir/$value" target="_blank">$value</a>
			<div class="showHide">
			<a href="#" class="arMod">podmień plik</a>
				<div class="hidden">
					<input type="file" name="_new_$column">
				</div>			
			</div>
		~;
	}
	return $output;
}




sub buildCheckboxFieldForArray {
# --------------------------------------------------------
# Builds a CHECKBOX field based on information from the array

	my ($column, $value, $mode, $prefix, $dictRef) = @_;	
	my (@fields, $output, $field_name, $field, $val, $found);

	# get sorted fields
	@fields = sort {$dictRef->{$a}{label} cmp $dictRef->{$b}{label}} keys %{$dictRef};
	return "błąd: źle skonfigurowany słownik dla kolumny '$column'!" if ($#fields == -1);


	foreach $field (@fields) {
		next if (!$dictRef->{$field}{active});
		$field_name = $dictRef->{$field}{label};
		$found = 0;
		foreach $val (@{$value}) {
			$found = 1 if ($field eq $val);
		}
		($found) ?
			($output .= qq~<span class="$prefix$column$field"><input type="checkbox" name="$prefix$column" value="$field" id="$column$field" checked><label for="$column$field">$field_name</label> </span>\n~) :
			($output .= qq~<span class="$prefix$column$field"><input type="checkbox" name="$prefix$column" value="$field" id="$column$field"><label for="$column$field">$field_name</label> </span>\n~);
	}

	return $output;
}


sub checkBinary {
	my $i;
	my ($val,$encoded) = @_;

	for ($i=1048576; $i>=1; $i=$i/2) {
		if ($encoded>=$i) {
			if ($i==$val) {
				return 1;
			} else {
				$encoded = $encoded - $i;
			}
		}
	}
	return 0;
}

sub buildRadioField {
# --------------------------------------------------------
# Builds a RADIO Button field based on information found in the database definition. 

	my ($column, $value, $mode, $prefix, $dictRef) = @_;	
	my (@fields, $output, $field_name, $class, $field);

	# get sorted fields
	@fields = sort {$dictRef->{$a}{label} cmp $dictRef->{$b}{label}} keys %{$dictRef};
	return "błąd: źle skonfigurowany słownik dla kolumny '$column'!" if ($#fields == -1);

	#($column eq 'stan') ? ($separator='&nbsp; &nbsp; ') : ($separator='<br>');

	foreach $field (@fields) {
		next if (!$dictRef->{$field}{active});
		$field_name = $dictRef->{$field}{label};
		$class = "";
		next if (!length($field_name));

		# if the key is hidden
		#if ( $#{$field_name}>0 and Wywrota->per( ${$field_name}[1] )  ) {
		#	$field_name = ${$field_name}[0];
		#	$class = "locked";
		#} 

		$field eq $value ?
			($output .= qq~<span class="$prefix$column$field"><input type="radio" name="$prefix$column" value="$field" id="$column$field" checked="true"><label for="$column$field" class="$class">$field_name</label> </span>\n~) :
			($output .= qq~<span class="$prefix$column$field"><input type="radio" name="$prefix$column" value="$field" id="$column$field"><label for="$column$field" class="$class">$field_name</label> </span>\n~);

	}

	return $output;
}



sub buildDateField {
# --------------------------------------------------------
# Builds a data format field

	my ($column, $value, $mode, $prefix) = @_;	
	my $output;
	my ($date, $time) = split(/\s/, $value);
	my ($h,$m,$s)  = split(/:/, $time);

	$date = '' if ($date eq '0000-00-00');
	$h=$m=$s=''  if ($h eq '00' && $m eq '00');

	$output = qq~
	<span class="dateField">
	<input type="text" class="date_input" name="date_$prefix$column" value="$date" id="date_$column" maxlength="19">
	<input type="text" class="hour_input" name="time_h_$prefix$column" value="$h" maxlength="2"><span>:</span><input type="text" class="minute_input" name="time_m_$prefix$column" value="$m" maxlength="2">
	<input type="hidden" name="time_s_$prefix$column" value="$s">
	</span>
	~;
	return $output;
}




sub buildWysiwygField {
# --------------------------------------------------------
# Builds a data format field

	my ($column, $value,  $mode, $prefix, $simple, $object, $rec) = @_;	
	my $output;

	if (!$value) {
		$value = "<p>&nbsp;</p>";
	} elsif ($value !~ /^<p>/) {
		$value = "<p>$value";
	}
	
	return Wywrota->t->process('form/wysywig_ckedit.html', {
		value 		=> HTML::Entities::encode($value, '<>&"'),
		prefix 		=> $prefix,
		column		=> $column,
		mode		=> $mode,
		simple		=> $simple,
		obj 		=> $object,
		rec 		=> $rec,
		is_admin	=> Wywrota->per('admin')
	});
	
}



sub buildTextField {
# --------------------------------------------------------
# Builds a Input Text field based on information found in the database definition. 

	my ($column, $value, $mode, $prefix) = @_;	
	my ($class, $output);
	my $tableDef = $Wywrota::request->{content}{current}{cfg};

	$value = HTML::Entities::encode($value, '<>&"');
	$class = $tableDef->{$column}[2];
	$class = "" if ($mode eq "search" and $class eq "title");
	$output = qq~
		<input type="text" name="$prefix$column" value="$value" class="$class" maxlength="$tableDef->{$column}[3]">
	~;

	return $output;
}


sub buildHtmlRecord {
# --------------------------------------------------------
# Builds a record based on the config information.
#
	my $object = shift;

	my $rec = $object->rec;
	my ($output, $field);

	$object->preProcess;
	
	$output = "<p><table>";
	foreach $field (keys %{$Wywrota::request->{content}{current}{cfg}}) {
		#next if ($db_form_len{$field} == -1);
		$output .= qq~
			<tr>
			<td class="formLabel" width="20%">$field</td>
		    <td width="80%">$rec->{$field}</td>
			</tr>
		~;
	}
	$output .= qq~
		</table>
		$rec->{edit_icons}
	~;
	return $output;
}



sub buildHtmlRecordForm {
# --------------------------------------------------------
# Builds a record form based on the config information.
#

	my ($rec, $output, $fieldoutput, $field, $field_, $required, $jsValidation, $lastfieldset, $fieldTags, $package, $dictRef, $value );
	my $object = shift;
	my $tableDef = shift;
	my $prefix = shift;
	my $replaceDict = shift;
	my $mode = shift || 'search';

	if (!defined $tableDef) {
		if ($object) {
			$package = $object->getClass();
			$tableDef = Wywrota->cc($package)->{cfg};
		} else {
			$tableDef = $Wywrota::request->{content}{current}{cfg};
			$package = $Wywrota::request->{content}{current}{'package'};
		}
	} 

	$rec = $object->rec if ($object);

	$mode = 'add' if ($Wywrota::in->{'add'} || $Wywrota::in->{'addrecord'});
	$mode = 'edit' if ($Wywrota::in->{'modifyrecord'} || $Wywrota::in->{'modify'});

	#$output = "<pre>".Dumper(keys %{$tableDef}).Dumper($tableDef)."</pre>";
	
	foreach $field (sort ({$tableDef->{$a}[0] <=> $tableDef->{$b}[0]} keys %{$tableDef})) {

		#next if (($field =~ "^_.*") && ($mode eq 'edit'));

		$field_ = msg($tableDef->{$field}[6]) || $field; 

		$dictRef = Wywrota->dict->getRefForLabel($package, $field);

		$dictRef = $replaceDict->{$field} if (defined $replaceDict and defined $replaceDict->{$field} );

		# check fieldset
		if ($mode ne 'search' and $lastfieldset ne $tableDef->{$field}[7]) {
			$output .= wrapFieldset($fieldoutput, $lastfieldset);
			$fieldoutput = '';
			$lastfieldset = $tableDef->{$field}[7];
		}


		# check the required property
		if ($mode ne 'search') {
			if ($tableDef->{$field}[4] && ($tableDef->{$field}[2] !~ /_hid|_ao|_ao_ne/)  ) {
				$required =  'required';
				$jsValidation .= qq~if (!validrequired(formObj.$field,"Uzupełnij pole '$field_'.")) return false;\n~;
			} else {
				$required =  '';
			}


			if ($tableDef->{$field}[3] && ($tableDef->{$field}[2] !~ /_hid|_ao|_ao_ne/)  && ($tableDef->{$field}[1] =~ /alpha|textarea/)  ) {
				$jsValidation .= qq~if (formObj.$field.value.length>$tableDef->{$field}[3]) {
					showpoperror(formObj.$field,"Zbyt długi wpis w polu '$field_'.\\n Wpisałeś "+formObj.$field.value.length+" znaków a maksymalna długość to $tableDef->{$field}[3].");
					formObj.$field.focus();return false; }\n~;
			} else {
				#$required =  '';
			}

			
		}

		$rec->{$field} = formatDataType($field, $rec->{$field}, $tableDef);

		if	   (  ($tableDef->{$field}[2] eq '_hid') 
					|| (!Wywrota->per('admin') && ($tableDef->{$field}[2] eq '_ao') )
					|| (!Wywrota->per('admin') && ($tableDef->{$field}[2] eq '_add' && $mode ne 'add'))  ){  

			$value = HTML::Entities::encode($rec->{$field}, '<>&"');
			$output  = qq~<input type="hidden" name="$prefix$field" value="$value">\n$output~  if ($mode ne 'search') ; 

		} elsif ($tableDef->{$field}[2] eq '_ao_ne') { 
			 
			if ($mode ne 'search') {

				$fieldoutput  = qq~<input type="hidden" name="$prefix$field" value="$rec->{$field}">\n$fieldoutput~;
				$fieldoutput .= qq~
					<div class="formLabel">$field_</div>
					<div class="formInput notEditable">~ . (defined(Wywrota->app->{dict}{$package}{$field}) ? 
						Wywrota->app->{dict}{$package}{$field}{$rec->{$field}} : $rec->{$field} )
				. "</div>" if (Wywrota->per('admin') && $rec->{$field});
				
			}

		} elsif ($tableDef->{$field}[2] eq 'html' and $mode ne 'search') { 

			$fieldoutput .= buildWysiwygField ($field, $rec->{$field}, $mode, $prefix, 0, $object, $rec); 

		} elsif ($tableDef->{$field}[2] eq 'html_simple' and $mode ne 'search') { 

			$fieldoutput .= buildWysiwygField ($field, $rec->{$field}, $mode, $prefix, 1, $object, $rec); 
			
		} elsif ($tableDef->{$field}[2] eq 'title' and $mode ne 'search') { 
			
			$value = HTML::Entities::encode($rec->{$field}, '<>&"');
			$fieldoutput .= qq~
				<div class="formField field_$field">
					<div class="formLabel $required">$field_</div>
					<input type="text" name="$prefix$field" value="~. $value . qq~" maxlength="$tableDef->{$field}[3]" class="title">
				</div>
			~; 
			
			
		} else  {

			if ($tableDef->{$field}[1] eq 'combo') { 
				$fieldTags = buildSelectField($field, $rec->{$field}, undef, $mode, $prefix, $dictRef) ;

			} elsif ($tableDef->{$field}[1] eq 'radio') { 
				$fieldTags = buildRadioField($field, $rec->{$field}, $mode, $prefix, $dictRef);

			} elsif ($tableDef->{$field}[1] eq 'checkbox') { 
				$fieldTags = buildCheckboxField ($field, $rec->{$field}, $mode, $prefix, $dictRef);

			} elsif ($tableDef->{$field}[1] eq 'date') { 
				$fieldTags = buildDateField ($field, $rec->{$field}, $mode, $prefix) if ($mode ne 'search');

			} elsif ($tableDef->{$field}[1] eq 'image') { 
				$fieldTags = buildImageField ($field, $rec->{$field}, $mode, $prefix) if ($mode ne 'search');

			} elsif ($tableDef->{$field}[1] eq 'file') { 
				$fieldTags = buildFileField ($field, $rec->{$field}, $mode, $prefix) if ($mode ne 'search');

			} elsif ($tableDef->{$field}[1] eq 'textarea' and $mode ne 'search') { 
				$fieldTags = qq~<textarea name="$prefix$field" class="$tableDef->{$field}[2] autogrow">$rec->{$field}</textarea>~; 

			} else  {
				$jsValidation .= qq~if (!validNum(formObj.$field,"Pole '$field_' powinno być liczbą.")) return false;~ if ($mode ne 'search' and $tableDef->{$field}[1] eq 'numer');
				$fieldTags = buildTextField ($field, $rec->{$field}, $mode, $prefix); 
			}

			$fieldoutput .= qq~
				<div class="formField field_$field">
					<div class="formLabel $required">$field_</div>
					<div class="formInput">$fieldTags</div>
				</div>
				~; 


		}

	}

	$output .= wrapFieldset($fieldoutput, $lastfieldset);

	
	return Wywrota->t->process('form/generated_form.html', {
		js_validation 	=>	$jsValidation,
		fields			=> $output,
		package			=> $package		
	});

}		


sub wrapFieldset {
	my $fieldoutput = shift;
	my $fieldsetname = shift;
	
	return unless $fieldoutput;
	
	if ($fieldsetname) {
		$fieldsetname = msg($fieldsetname);
		return qq|
				<fieldset class="collapsible collapsed">
					<legend>$fieldsetname</legend> 
					$fieldoutput
				</fieldset>
		|;
	} else {
		return $fieldoutput;
	}

}

		
sub formatDataType {
	my $fieldName = shift;
	my $fieldValue = shift;
	my $tableDef = shift;

	if ($tableDef->{$fieldName}[1] eq "numer") { 
		if (length($fieldValue)) {
			$fieldValue=int($fieldValue);
		}
	}
	return $fieldValue;

}


1;
