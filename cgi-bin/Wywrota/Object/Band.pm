package Wywrota::Object::Band;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Data::Dumper;
use Wywrota::Config;
use Wywrota::Utils;
use Wywrota::Nut::Session;
use Wywrota::Forms;
use Wywrota::Object::BaseObject;
use Wywrota::Object::ForumPost;
use Wywrota::Object::User;
use Wywrota::Language;
use Wywrota::Favorites;
use Wywrota::Dictionary;


our @ISA = qw(Wywrota::Object::BaseObject);



# --------------------------------------------------------
#	database table definition 
#	field_name => ['position', 'field_type', 'class', 'maxlength', 'not_null', 'default', 'form_label']

	our $cc = {
		id	=>				[0, 'autoinc',    '_hid',	8,		1,  '',          ''],
		wykonawca	=>		[1, 'alpha',	'title',	256,	1,  '',          ''],
		wykonawca_urlized=>	[2, 'alpha',	'_hid',		256,	0,  '',          ''],
		informacje	=>		[3, 'textarea',	'html',		100000,	0,  '',          ''],
		content_id		=>	[4, 'radio',    '',		8,		1,  '7',          'category'],
		promoted	=>		[5, 'checkbox',	'_ao',		1,	    0,  '0',          'promoted_artist'],
		user_id=>			[6, 'numer',    '_hid',	    16,		1,  '0',         ''],
		time		=>		[7, 'date',		'_hid',     20,		1,  'Wywrota::Utils::getDate()', ''],
		_fav_cnt	 =>		[8, 'numer',    '_hid',		10,		1,  '0',  ''],
		_song_count	 =>		[9, 'numer',    '_hid',		10,		1,  '0',  ''],
		nazwa_pliku		 => [10, 'alpha',	 '_hid',	128,	0,  '',          ''],
		image_id		 => [11, 'numer',    '_hid',	10,		0,  '',          ''],
		lang			=>	[12, 'combo',    '',			8,		1,  '1',          'language'],
		tags	=>			[13, 'textarea',   '',	        4096, 		0,  '',         'article_tags']
	 };


# Various variables
# --------------------------------------------------------
	$foto_dir = "pliki/db/wykonawcy";
	$forumKatId=5;



sub new {
# --------------------------------------------------------
	my ($class, $rec) = @_;
	my $self = $class->SUPER::new($rec);
	return $self;
}


sub preProcess {
# -------------------------------------------------------------------------------------
	my $self = shift;
	my $suffix = shift || 'sq2';
	my $rec = $self->rec;

	$self->SUPER::preProcess();

	my $seo_keyword = ($rec->{val}{content_id} == 7) ? 'teksty piosenek' : 'wiersze';

	$rec->{spiewnik_link} = "http://teksty." . $Wywrota::request->{urlSufix} . "/$rec->{'wykonawca_urlized'}/";
	$rec->{wiersze_link} = "http://literatura." . $Wywrota::request->{urlSufix} . "/$rec->{'wykonawca_urlized'}/";
	
	$rec->{fav_cnt} = $rec->{_fav_cnt};
	$rec->{song_count} = $rec->{_song_count};

	$rec->{fanow} = 	Wywrota::Language::plural($rec->{_fav_cnt}, 'fan');
	$rec->{songs} = 	Wywrota::Language::plural($rec->{_song_count}, 'tekst piosenki');

	
	$rec->{lastfm}	=	Wywrota->lastfm->ask("Artist.getInfo", 	artist => $rec->{wykonawca}	);
	if ($rec->{lastfm} && !$rec->{informacje}) {
		$rec->{informacje} = $rec->{lastfm}{artist}{bio}{content}; $rec->{informacje} =~ s/\n/<br>/g;
		$rec->{informacje} =~ s/(User-contributed .* GNU FDL.)/<span class="txtnews g">$1<\/span>/g;
	}
	
	$rec->{informacje_plain} = 	cutTextTo( dehtml( $rec->{informacje}), 150) ;

	$rec->{photo} = Wywrota->t->getPhotoCode({
		id => $rec->{nazwa_pliku}, 
		width => $Wywrota::in->{img_width}, 
		height => $Wywrota::in->{img_height},
		suffix => $suffix,
		alt => "$rec->{wykonawca} - $seo_keyword",
		lazy_load => 0
	});
	
	return $self;
}



sub recordSmall {
# --------------------------------------------------------
	my ($output, $img);
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess('sq');
	
	return Wywrota->t->process("object/band_record_small.html" , {
		rec		=>	$rec,
		obj		=>	$self
	});
}




sub record {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	$self->preProcess('sq');
	
	return Wywrota->t->process(
		$Wywrota::in->{template} ? "object/band_record_$Wywrota::in->{template}.html" : 'object/band_record.html' , {
		rec		=>	$rec,
		obj		=>	$self
	});

}


sub getBands {
# --------------------------------------------------------
	my $user_id = shift;
	my $limit = shift || 100;
	my ($sth, $record, @hits);

	my $query = qq~
		SELECT DISTINCT f.record_id as wykonawca_id, w.wykonawca, w.wykonawca_urlized
		FROM favorites f
		LEFT JOIN wykonawcy w on f.record_id=w.id 
		WHERE f.user_id = $user_id 
		AND f.content_id = 15
		LIMIT $limit 
	~;

	return Wywrota->db->buildHashRefArrayRef($query);
}


sub toString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return $rec->{wykonawca};
}


sub toHtmlString {
# --------------------------------------------------------
	my $self = shift;
	my $rec = $self->rec;
	return "<span class='band'>". $rec->{wykonawca} ."</span> ";
}


1;