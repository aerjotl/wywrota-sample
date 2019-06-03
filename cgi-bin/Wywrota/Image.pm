package Wywrota::Image;

#-----------------------------------------------------------------------
# Pan Wywrotek
# Content Manager 
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

 
use GD;
use Exporter; 
our @ISA = qw(Exporter);
our @EXPORT = qw(createImageSet getImageResized);

use Wywrota;
use Wywrota::Config;


sub openImage {
# --------------------------------------------------------
	my $filename = shift;
	my $srcimage;

	if ($filename =~ /png$/i) {
		$srcimage = GD::Image->newFromPng($filename, 1);
	} elsif ($filename =~ /gif$/i) {
		$srcimage = GD::Image->newFromGif($filename, 1);
	} else {
		$srcimage = GD::Image->newFromJpeg($filename, 1);
	}
	
	return $srcimage;
}


sub testImage {
# --------------------------------------------------------
	my $filename = shift;
	eval {
		openImage($filename);
	};

	if ($@) {
		return $@;
	} else {
		return "ok";
	}
}

sub createImageSet {
# --------------------------------------------------------
	my $filename = shift;
	my $sizes = shift;
	my ($image, $size, $quality);

	foreach $size (keys %{$sizes->{size}}) {
		$image = getImageResized($filename, $sizes->{size}->{$size});
		
		return "Wystąpił problem podczas wczytywania pliku graficznego. Ten plik nie jest poprawnym plikiem JPG." if (!$image);

		open(IMAGE, ">$filename-$size") || return "Cannot open $filename-$size for write: $!\n";
		print IMAGE $image;
		close IMAGE;
	}
	return "ok";
}


sub getImageResized {
# --------------------------------------------------------
	my $filename = shift;
	my $size = shift;
	my ($image, $quality);

	return undef if !(-e $filename );

	eval {
		$image = &resizeImage($filename, $size->{width}, $size->{height}, $size->{force_enlarge}, $size->{crop});
		$image = &placeLogo($image, $config{'embedded_logo_path'}, 20) if ($size->{include_logo} && $image);
		$quality = ($size->{width}>300 || $size->{width}<70) ? $config{'jpeg_hq'} : $config{'jpeg_lq'};
		$image = $image->jpeg($quality);
	};
	if ($@) {
		print $@;		
		return undef;
	}

	return $image;
}

sub resizeImage {
# --------------------------------------------------------
	my $filename = shift;
	my $maxwidth = shift;
	my $maxheight = shift;
	my $forceEnlarge = shift;
	my $crop = shift;
	my $srcX = 0;
	my $srcY = 0;


	my $srcimage = openImage($filename);
	
	if (!$srcimage) {return 0;}

	my ($srcW,$srcH) = $srcimage->getBounds();
	#print qq~my ($srcW,$srcH) = $srcimage->getBounds();~;

	my $wdiff = $srcW - $maxwidth;
	my $hdiff = $srcH - $maxheight;
	my ($newH, $newW, $aspect);

	if ($wdiff > $hdiff) {
		$newW = $maxwidth;
		$aspect = ($newW/$srcW);
		$newH = int($srcH * $aspect);
	} else {
		$newH = $maxheight;
		$aspect = ($newH/$srcH);
		$newW = int($srcW * $aspect);
	}

	# crop - other way
	if ($crop) {
		if ($wdiff > $hdiff) {
			$srcX = int( ($srcW - $srcH) / 2);
			$srcW = $srcH ;
		} else {
			$srcY = int( ($srcH - $srcW) / 2);
			$srcH = $srcW;
		}

		$newW = $maxwidth;
		$newH = $maxheight;
	}

	if (!$forceEnlarge && $aspect > 1) {
		return $srcimage;
	}

	my $newimage = GD::Image->newTrueColor($newW,$newH);
	$newimage->copyResampled($srcimage, 0, 0, $srcX, $srcY, $newW, $newH, $srcW, $srcH);
	#print qq~ $newimage->copyResampled($srcimage, 0, 0, $srcX, $srcY, $newW, $newH, $srcW, $srcH); ~;
	return $newimage; 
}



sub placeLogo {
# --------------------------------------------------------
	my $image = shift;
	my $filename = shift;
	my $transparency = shift;

	my ($imageW,$imageH) = $image->getBounds();
	my $logoImg = GD::Image->newFromGif($filename);
	my ($logoW,$logoH) = $logoImg->getBounds();

	$image->copyMerge($logoImg, $imageW-$logoW-10, $imageH-$logoH-10, 0, 0, $logoW, $logoH, $transparency);
	return $image;
}







package Wywrota::Image::EXIF;

#-----------------------------------------------------------------------
# Pan Wywrotek
# Content Manager 
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

use Storable qw(freeze thaw);
use Image::ExifTool qw(:Public);


sub read {
# --------------------------------------------------------
	my $filename = shift;
	my ($info);

	# Get hash of meta information tag names/values from an image
	eval{
		$info = ImageInfo($filename);
	};

	foreach  (keys %{$info}) {
	  delete $info->{$_} if (ref $info->{$_});		  
	}
	return $info;
}


sub store {
# --------------------------------------------------------
	my $id = shift;
	my $cid = shift;
	my $exif = shift;
	my $ok = 1;

	return unless ($id=~ /^\d+$/ );
	return unless ($cid=~ /^\d+$/ );
	return unless ($exif);

	eval {
		$ok = Wywrota->db->execWriteQuery("DELETE FROM `exif` WHERE id=? AND cid=? ", $id, $cid );
		$ok = $ok && Wywrota->db->execWriteQuery("INSERT INTO `exif` (id,cid,exif) VALUES (?,?,?)", $id, $cid, freeze($exif) ) ;
	};
	return $ok;
}



sub fetch {
# --------------------------------------------------------
	my $id = shift;
	my $cid = shift;
	my ($exif);

	return if (!$id || !$cid);
	($exif) = Wywrota->db->quickArray("SELECT exif FROM exif ");

	return thaw($exif);
}





1;