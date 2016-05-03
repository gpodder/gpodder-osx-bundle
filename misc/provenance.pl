#!/usr/bin/perl

use strict;

require File::Spec;

sub usage
{
	my ($exitcode,$msg) = @_;
	print "Usage: $0 <jhbuild_prefix> </path/to/gPodder.app>\n";
	print $msg if $msg;
	exit $exitcode;
}

usage(-1) unless scalar(@ARGV) == 2;
usage(0) if $ARGV[0] =~ /--?h(elp)?/;


my $gPodderResources="$ARGV[1]/Contents/Resources";

usage(-1,"$gPodderResources is not a directory\n") unless -d $gPodderResources;

my $gtk_inst=$ARGV[0];
my $jhbuild="$gtk_inst/_jhbuild";
my $manifests="$jhbuild/manifests";
my $packagedbfile="$jhbuild/packagedb.xml";

print STDERR "I: loading manifests...\n";

my %pkg_by_f;

opendir(my $dh, $manifests) || die "can't open $manifests: $!\n";
my @manifest_files = grep { -f "$manifests/$_" } readdir($dh);
closedir($dh);

foreach my $pkg (@manifest_files) {
	my $manifest = "$manifests/$pkg";
	open(my $MANIFEST, "<", $manifest) || die "can't open $manifest for reading: $!\n";
	while(my $l = <$MANIFEST>){
		chomp $l;
		push(@{$pkg_by_f{"/$l"}}, $pkg);
	}
}

my @files= `find "$gPodderResources"`;

my %prov;

print STDERR "I: grabbing packages provenance...\n";
foreach my $file (@files) {
	chomp $file;
	next if -d $file;
	my $short = $file;
	$short =~ s/$gPodderResources//;
	my @pkgs;
	if($pkg_by_f{$short}){
		@pkgs = @{$pkg_by_f{$short}};
	} else {
		@pkgs = ();
	}
	if(scalar(@pkgs) eq 0) {
		print STDERR "W: pkg not found for $short\n";
	} else {
		if(scalar(@pkgs) > 1) {
			print STDERR "W: multiple pkgs found for $short: " . join(', ',@pkgs) . "\n";
		}
		foreach my $pkg (@pkgs){
			push(@{$prov{$pkg}}, $short);
		}
	}
}
print STDERR "I: packages provenance done\n";

my %versions;

print STDERR "I: grabbing packages versions...\n";
open(my $PACKAGEDB, '<', "$packagedbfile") || die "Unable to read $packagedbfile: $!\n";

while(defined(my $entry = <$PACKAGEDB>)){
	if($entry =~ /.*package="(.+?)" version="(.+?)"/){
		$versions{$1} = $2;
	}
}
close($PACKAGEDB);
print STDERR "I: packages versions done...\n";

print STDERR "I: exporting...\n";
foreach my $pkg (sort(keys(%prov))){
	my $version = $versions{$pkg};
	print "$pkg $version\n";
	foreach my $file (@{$prov{$pkg}}){
		print "  $file\n";
	}
}
print STDERR "I: export done\n";
