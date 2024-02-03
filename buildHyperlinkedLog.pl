# converts ORE log files to a hyperlinked HTML file, directing the location to either github or the OREAnnotatedSource
# if a parameter file is given as argument, converts multiple logfiles, otherwise asks for parameters and one single logfile.
# layout of parameter file:
#   ORE rootdir (where full path informations are taken from)
#   root HTML path (either a github.com blob or the root of an annotated doxygen source. links not to "https://github.com" are treated as fully annotated doxygen sources)
#   skip same logs (1 to skip repeating same log lines with "...", up to four repeating lines are regarded as "repeating same"; 0 for full conversion)
#   full path to log 1
#   ...
#   full path to log n
# any blank line marks the end of the logs.
use Cwd; use Data::Dumper; use strict;
# default hyperlink target if no github source is chosen
my $rootHTML = 'https://rkapl123.github.io/OREAnnotatedSource/';
my $skipSameLogs;
my $rootdir;
my @logfiles;

if ($ARGV[0]) {
	open(PARAMFILE, "<$ARGV[0]") or die "Unable to open parameter file $ARGV[0] in argument 1:$!\n";
	$rootdir = <PARAMFILE>;
	$rootHTML = <PARAMFILE>;
	chomp $rootHTML;
	$skipSameLogs = <PARAMFILE>;
	chomp $skipSameLogs;
	my $i=0;
	while (<PARAMFILE>) {
		chomp $_;
		last if $_ eq "";
		$logfiles[$i] = $_;
		$i++;
	}
} else {
	$rootdir = $ENV{ORE};
	if (!$rootdir) {
		print "didn't find ORE in environment, enter your ORE root folder (tip: drag folder into console):";
		$rootdir = <>;
	}
	print "enter target ORE version for linking to tags in github blob (only pass sub-version, e.g. 9, 10 or 11), empty to create links to current master, enter 'a' to link to OREannotated source instad (currently on sub-version 11):";
	my $OREversion = <>;
	chomp $OREversion;
	$rootHTML = "https://github.com/OpenSourceRisk/Engine/blob/".($OREversion ? "v1.8.$OREversion.0/" : "master/") if $OREversion ne "a";
	print "should consecutive log entries from same src/line be truncated, shortening the result (n/N to convert full log, all else/empty to truncate):";
	$skipSameLogs = <>;
	chomp $skipSameLogs;
	$skipSameLogs = 1 if !$$skipSameLogs;
	$skipSameLogs = 0 if $skipSameLogs =~/n/i;
	print "enter your log file to be converted (tip: drag file into console):";
	$logfiles[0] = <>;
	chomp $logfiles[0];
}
my $githubSrc = ($rootHTML =~ /https:\/\/github\.com/);
chomp $rootdir;
$rootdir =~ s/\\/\//g;
my (%multiCheck, %pathForMultis, %searchStruct, %samePathCheck);
print "scanning ORE sources in $rootdir\n";
ScanDirectory($rootdir);
# replace srcpaths (filename prefix for doxygen) for files having multiple common names (in different paths). doxygen puts the least common path there
for my $key (keys %samePathCheck) {
	next if $multiCheck{$key} == 1; # only for multiples, else there are problems with termination of common check below.
	my @pathCheckList = sort @{$samePathCheck{$key}};
	my ($entry) = ($pathCheckList[0] =~ /.+\/(.*?)$/); # extract file entry
	my ($first, $last) = @pathCheckList[0,-1];
	$first =~ s/$entry$//; $last =~ s/$entry$//;
	my $i = 0; 
	while (substr($first, $i, 1) eq substr($last, $i, 1)) {$i++;}
	my $common = substr $first, 0, $i;
	# now store srcpath in pathForMultis lookup (taken instead of simple filename for non-multiples)
	for my $filename (@pathCheckList) {
		my $srcpath = $filename;
		$srcpath =~ s/^$common//; $srcpath =~ s/$entry$//;
		$srcpath =~ s/\//_2/g;
		$pathForMultis{$filename} = $srcpath;
	}
}
print "converting logs,\$rootHTML: $rootHTML,\$githubSrc: $githubSrc, \$skipSameLogs: $skipSameLogs\n";
scanlog($_) for @logfiles;
print "all logfiles processed, press ENTER to finish\n";
my $wait = <>;

# scans $rootdir for all source files and assembles their info in %searchstruct
sub ScanDirectory {
	my ($workdir) = shift;
	return if $workdir eq "build" or $workdir eq "QuantLib";
	my ($startdir) = cwd();
	chdir($workdir) or die "Unable to enter dir $workdir:$!\n";
	opendir(DIR, ".") or die "Unable to open $workdir:$!\n";
	my @names = readdir(DIR) or die "Unable to read $workdir:$!\n"; 
	closedir(DIR); 
	foreach my $entry (@names) {
		next if ($entry eq "."); 
		next if ($entry eq ".."); 
		if (-d $entry){ # is this a directory? 
			ScanDirectory($entry); 
			next;
		}
		if ($entry =~ /.*(\.cpp|\.hpp)/ and $entry ne "all.hpp") {
			my $filename = "$startdir/".($workdir eq "." ? "" : "$workdir/")."$entry";
			my ($fname, $ext) = ($entry =~ /^(.+?)\.(.+?)$/);
			$filename =~ s/$rootdir\///;
			my $fullpath = $filename;
			$fullpath =~ s/$entry//;
			if ($githubSrc) {
				$ext = ".$ext";
			} else {
				$ext = "_8${ext}_source.html";
			}
			my ($root,$srcroot) = ($filename =~ /(.+?)\/(.+?)\/.*/);
			my $srcpath = $fullpath;
			$srcpath =~ s/$root\///;
			$srcpath =~ s/\//_2/g;
			$multiCheck{$root.$entry}++;
			push @{$samePathCheck{$root.$entry}}, $filename;
			$searchStruct{$filename} = [$srcroot."/", $fname, $ext, $fullpath, $root, $entry]
		}
	}
	chdir($startdir) or die "Unable to change to dir $startdir:$!\n";
}

sub scanlog {
	my $logfile = @_[0];
	open(CNTFILE, "<$logfile") or die "Unable to open $logfile for reading: $!\n";
	my $linecount;
	$linecount += tr/\n/\n/ while sysread(CNTFILE, $_, 2 ** 16);
	close CNTFILE;
	print "processing $logfile\n";
	open(LOGFILE, "<$logfile") or die "Unable to open $logfile for reading: $!\n";
	my $hyperlinkedFilename;
	map {$hyperlinkedFilename.="$_."} ($logfile =~ /^.*[\\\/](.*?)[\\\/](.*?)[\\\/](.*?)[\\\/](.*?)$/);
	$hyperlinkedFilename.="html";
	open(HTML, ">$hyperlinkedFilename") or die "Unable to open $hyperlinkedFilename for writing: $!\n";
	print HTML '<!DOCTYPE html><html><head><link href="extra.css" rel="stylesheet" type="text/css"/></head><body>'."\n";

	my $lineProc;
	my ($prevLogentry, $prev2Logentry, $prev3Logentry, $prev4Logentry);
	my $stillTheSame = 0;
	while (<LOGFILE>) {
		chomp;
		$lineProc++;
		next unless $_;
		my ($prefix, $logentry, $postfix) = /^(.*?)\s\((.*?)\)(.*?)$/;
		if ($skipSameLogs and ($prevLogentry eq $logentry or $prev2Logentry eq $logentry or $prev3Logentry eq $logentry or $prev4Logentry eq $logentry)) {
			print HTML "...<br/>\n" unless $stillTheSame;
			$stillTheSame = 1;
		} else {
			$stillTheSame = 0;
		}
		$prev4Logentry = $prev3Logentry;
		$prev3Logentry = $prev2Logentry;
		$prev2Logentry = $prevLogentry;
		$prevLogentry = $logentry;
		next if $stillTheSame and $skipSameLogs;
		$logentry =~ s/(\(|\)|\.{3})//g; # remove opening/closing bracket and ... from logentry
		my ($fileinfo, $lineinfo) = ($logentry =~ /(.*?):(\d+)/); # separate line no
		my $lineno = ($githubSrc ? "/#L".$lineinfo : "#l".sprintf("%05d", $lineinfo));
		$fileinfo =~ s/\\/\//g; # make path seps regexable.

		my $notfound = 1;
		for my $filename (keys %searchStruct) {
			if ($filename =~ qr/$fileinfo/) {
				$notfound = 0;
				# for double appearances and doxygen target, add encoded path to fname
				my $fname = ($multiCheck{$searchStruct{$filename}[4].$searchStruct{$filename}[5]} > 1 and !$githubSrc ? $pathForMultis{$filename} : "").$searchStruct{$filename}[1];
				my $path = ($githubSrc ? $searchStruct{$filename}[3] : $searchStruct{$filename}[0]).$fname.$searchStruct{$filename}[2];
				print HTML $prefix.' <a href="'.$rootHTML.$path.$lineno.'" target="_blank">'.$searchStruct{$filename}[3].$searchStruct{$filename}[5].":".$lineinfo.'</a> '.$postfix."<br/>\n";
				next;
			}
		}
		die "no path found for $fileinfo in $prefix $logentry $postfix\n" if $notfound;
		print "\rprocessed lines: $lineProc/$linecount";
	}
	print "\rprocessed lines: $lineProc/$linecount";
	print HTML "</body></html>\n";
	close HTML;
	close LOGFILE;
	print "\nhyperlinked logfile available in $hyperlinkedFilename\n";
}
