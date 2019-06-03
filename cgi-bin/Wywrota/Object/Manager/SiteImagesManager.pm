package Wywrota::Object::Manager::SiteImagesManager;

#-----------------------------------------------------------------------
# Pan Wywrotek
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use strict;
use Data::Dumper;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Utils;
use Wywrota::Forms;
use Wywrota::Language;
use Wywrota::Object::BaseObject;
use Wywrota::Log;

use Wywrota::Object::Manager::BaseManager;
use base 'Wywrota::Object::Manager::BaseManager';


sub action {
# -------------------------------------------------------------------------------------
	my $output;
	my $self = shift;
	my $nut = shift;
	my $action = $nut->in->{a} || $nut->in->{action};
	
	if    ($action eq 'putIntoEditor')   { 
		$output = '';
	} 
		
	else { 
		$output = Wywrota->unknownAction($action);
	}

	
	return $output;
}


sub onObjectEdit {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my $tablename = $object->config->{tablename};

	my $fileName = "$config{'www_dir'}/pliki/$tablename/$rec->{'nazwa_pliku'}";
	eval {
		my $srcimage = GD::Image->newFromJpeg($fileName, 1);
		my ($srcW,$srcH) = $srcimage->getBounds();
		Wywrota->db->execWriteQuery(qq~UPDATE $tablename SET img_width=$srcW, img_height=$srcH WHERE id = $rec->{id}~);
	};

	# update band photo
	if ($rec->{wykonawca_id}) {
		Wywrota->db->execWriteQueries( Wywrota->t->process("sql/update_band.sql", $rec) );
	}
	
	if ($@) {
		return "ERROR!! $@\n";
	}

}


sub onObjectAdd {
# --------------------------------------------------------
	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($nazwa);

	# set default photo for user
	if ($rec->{typ}==1) {
		($nazwa) = Wywrota->db->quickArray("SELECT _image_filename FROM ludzie WHERE id=".Wywrota->db->quote($rec->{user_id}) );

		if (!length($nazwa)) {
			Wywrota->db->execWriteQuery("UPDATE ludzie SET _image_filename=".Wywrota->db->quote($rec->{nazwa_pliku}).", _image_id=$rec->{id} WHERE id=".Wywrota->db->quote($rec->{user_id}) );
		}
	}


	$self->onObjectEdit($object);
}



sub onObjectDelete {
# --------------------------------------------------------
	my $self = shift;
	my $id = shift;
	my ($cnt, $uid);
	if ($id) {
		# clear default photo for user
		($uid) = Wywrota->db->quickArray( "SELECT user_id FROM site_images WHERE id=" .Wywrota->db->quote($id) );
		$cnt = Wywrota->db->selectCount('site_images', " typ=1 AND _active=1 and user_id = " .Wywrota->db->quote($uid) );

		if (!$cnt) {
			Wywrota->db->execWriteQuery("UPDATE ludzie SET _image_filename=NULL, _image_id=NULL WHERE id=".Wywrota->db->quote($uid) );
		}
	}
}



sub importDir {
# --------------------------------------------------------

	my (@files, $file, $srcimage, $srcW, $srcH);
	my $dir = shift;
	my $label = shift;
	my $article_id = shift;

	opendir (DIR, "$config{'file_dir'}/site_images/$dir");
	@files = readdir(DIR);
	closedir (DIR);

	if ($config{'shell'}) {
		print qq~
		importing $config{'file_dir'}/site_images/$dir	
		found $#files files \n\n\n~;
	}

	# create a set of thumbnails
	foreach $file (sort @files) {
		print "\n processing: $dir/$file";
		if ($config{'linux'} && ($file =~ /\.jpg$/) ) {
			Wywrota::Image::createImageSet("$config{'file_dir'}/site_images/$dir/$file", 
				Wywrota->app->{ccByName}{SiteImages}{dict}{field}{ 'nazwa_pliku' });
				#$config{'dictionary'}->{ 'site_images' }{ 'nazwa_pliku' });

			my $fileName = "$config{'file_dir'}/site_images/$dir/$file";
			eval {
				$srcimage = GD::Image->newFromJpeg($fileName, 1);
				($srcW,$srcH) = $srcimage->getBounds();
			};
			if ($@) {
				return "ERROR!! $@\n";
			}

			Wywrota->db->execWriteQuery(qq~
				INSERT INTO site_images (opis, nazwa_pliku, user_id, typ, stan, wykonawca_id, article_id, isdefault, img_width, img_height) 
				VALUES (~. Wywrota->db->quote($label) .qq~, "$dir/$file", 1, 3, 1, NULL, ~. int($article_id) .qq~,0, $srcW, $srcH)
			~);
		}
	}

}


1;