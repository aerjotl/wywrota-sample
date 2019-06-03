package Wywrota::Object::HashConfirm;


use Digest::MD5;
use Wywrota::Config;
use Wywrota::Object::BaseObject;

our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'auto',		'_hid',		8,		1,  '',     ''],
		date			=>	[1, 'date',      '_ao_ne',	60,		0,  '',		''],
		hash	=>			[2, 'alpha',	'',			32,		1,  '',     ''],
		user_id=>			[3, 'numer',     '_ao',		16,		1,  '',     ''],
		hash_value		=>	[4, 'numer',     '_hid',   8,		0,  '',		'']
	 };

# --------------------------------------------------------


sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	$self->{rec}{hash} = substr(Digest::MD5::md5_hex(time()), 0,32);
	return $self;
}


sub recordSmall {
# --------------------------------------------------------
	my $self = shift;
	return $self->record(@_);
}




sub record {
# --------------------------------------------------------

	my ($output, $mod);
	my $self = shift;
	my $rec = $self->rec;

	$output .= qq~
		<div class="hashconfirm" id="$rec->{uid}">
		$rec->{hash}
		</div>
	~;

	return $output;
}

sub hash : lvalue {	shift->{rec}{hash}	}

1;