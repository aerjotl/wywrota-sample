package Wywrota::File;

#-----------------------------------------------------------------------
# Pan Wywrotek
# Content Manager 
#-----------------------------------------------------------------------
# Copyright (c) 1998-2009 Wywrota.pl
# legal notices in 'readme.txt'
#-----------------------------------------------------------------------

 
use Class::Singleton;
use base 'Class::Singleton';

use Wywrota;
use Wywrota::Config;
use Wywrota::Nut::Session;
use Wywrota::Language;
use Wywrota::Image;
use Wywrota::Log;

use Data::Dumper;


sub fileUpload {
# --------------------------------------------------------
# uploads file sent in HTTP form, the attributes are:
# 1) form variable name  
# 2) local directory name, where the file will be saved

	my $self = shift;
	my $file = shift;
	my $dir = shift;
	my $sufix = shift; 

	my ($output, $name, $hash);

	$hash = substr(Digest::MD5::md5_hex(time()), 0,8);

	$file=~m/^.*(\\|\/)(.*)\.(.*)$/; # strip the remote path and keep the filename
	$name = $file;
	$name =~ s/^(.*)\.(.*)$/$hash\_$2/g;
	$name = $name.$sufix;
	$name =~ tr/A-Z/a-z/;

	# create dir if needed
	unless (-e "$config{'file_dir'}/$dir") {
		Wywrota->debug("creating dir: $config->{file_dir}/$dir");
		eval {
			mkdir "$config{'file_dir'}/$dir";
			chmod 755, "$config{'file_dir'}/$dir";
		};
		Wywrota->warn("error creating dir",$@) if $@;
	}

	Wywrota->debug("$config{'file_dir'}/$dir/$name");
	open(LOCAL, ">$config{'file_dir'}/$dir/$name") or return;
	binmode LOCAL;
	while(<$file>) {
		print LOCAL $_;
	}
	close LOCAL;

	return $name;
}


sub uploadFormFiles {
# --------------------------------------------------------
# uploads all the files sent in HTTP form

	my $self = shift;
	my $object = shift;
	my $rec = $object->rec;
	my ($output, $status, $formKey);

	my $dir = $object->config->{url};


	foreach $key (keys %{$object->config->{cfg}}) {

		# record update - look for the new version of file
		$formKey = $key;
		$formKey = "_new_".$key if (defined($rec->{"_new_".$key}));

		if ($object->config->{cfg}{$key}[1] eq 'file') {
				
			if (length($rec->{$formKey})) {

				$name = $self->fileUpload($Wywrota::in->{$formKey}, $dir, $rec->{id} );
				return ("error uploading file", $rec) if (!$name);
				$rec->{$key} = $name;
			}

		} elsif ($object->config->{cfg}{$key}[1] eq 'image') {
			if (length($rec->{$formKey})) {

				$name = $self->fileUpload($Wywrota::in->{$formKey}, $dir, $rec->{id});

				return "error uploading file" if (!$name);
				$rec->{$key} = $name;

				# create a set of thumbnails
				#if ($config{'linux'}) {

					eval {
						$status = Wywrota::Image::testImage("$config{'file_dir'}/$dir/$name");
					};

					if ($status ne 'ok') {
						unlink("$config{'file_dir'}/$dir/$name");
						return $status;
					} 

					$status = Wywrota::Image::createImageSet("$config{'file_dir'}/$dir/$name", 
						$object->config->{dict}{field}{$key});
						

				#} 
			}

		}
	}

	return "ok";
}

1;