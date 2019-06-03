use Data::Dumper;


print getServerLoad();
print getHDDCapacity();


sub getServerLoad {
#-----------------------------------------------------------------------
	my ($load, $string, $cnt, @tmp, @lines );

#	$string = `top -b | head -n5`;
$string = qq|top - 16:40:12 up 22:16,  1 user,  load average: 0.61, 0.65, 0.77
Tasks: 146 total,  15 running, 131 sleeping,   0 stopped,   0 zombie
Cpu(s): 41.7%us,  6.3%sy,  1.1%ni, 47.8%id,  2.4%wa,  0.0%hi,  0.7%si,  0.0%st
Mem:   4056652k total,  3560516k used,   496136k free,   202780k buffers
Swap:   397308k total,    64280k used,   333028k free,  1392764k cached
|;

	@lines = split (/\n/, $string);

	$lines[0] =~ /(.*)load average: (.*), (.*), (.*)/;
	
	@load = [$2, $3, $4];
	
	print Dumper(@load);
	print "\n-----------\n";

	$string =~ s/\s+/ /g;
	@tmp = split (/\s/, $string);
	$cnt = $tmp[6] * 100;

	if   ($cnt<30)  {$load = 'JEST COOL ;]'}
	elsif ($cnt<70) {$load = 'JEST OK'}
	elsif ($cnt<100) {$load = 'JEST CIEPLO!'}
	elsif ($cnt<200) {$load = 'JEST GORACO!'}
	else {$load = 'RED ALERT!'}

	return qq~$load 
load: $tmp[5] $tmp[6] $tmp[7], uptime: $tmp[9] 
$lines[3]
$lines[4]
$lines[5]~ 
}



sub getHDDCapacity {
#-----------------------------------------------------------------------
	my ($string, $output, $proc, $icon, @drive);

#	$string = `df -P -h`;
$string = qq|Filesystem            Size  Used Avail Use% Mounted on
/dev/mapper/cloudsigma-root  7.3G  5.1G  1.9G  74% /
udev                  2.0G  4.0K  2.0G   1% /dev
tmpfs                 793M  276K  793M   1% /run
none                  5.0M     0  5.0M   0% /run/lock
none                  2.0G     0  2.0G   0% /run/shm
/dev/vdb1              22G   20G  2.1G  91% /data
/dev/vda1             228M   47M  170M  22% /boot|;
	
	foreach  ( split (/\n/, $string) ) {
		s/\s+/ /g;
		@drive = split (/\s/, $_);
		next if (!int($drive[1]) || $drive[5] eq '/dev');
		$proc = 100 - int($drive[4]);
		$icon = ($proc>25) ? '<ok>' : '!!';
		$output .= qq~ $drive[1]B\t$drive[5]\t wolne: $drive[3]B - $proc% $icon\n~;
	}
	
	return $output;
}
