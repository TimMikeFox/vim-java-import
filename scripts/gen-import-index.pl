#!/usr/bin/env perl

use strict;
use warnings;

use v5.10;
use File::Basename;

# colon separated path of directories containing source and class files
my $IMPORTPATH = $ARGV[0];

unless ($IMPORTPATH) {
    say "usage: " . basename($0) . " <IMPORTPATH>";
    exit 1;
}

if ($IMPORTPATH eq '-') {
    # read from stdin
    $IMPORTPATH = <STDIN>;
    chomp $IMPORTPATH
}

my %CLASSES;
my @FIND_DIRS;

process_java_files( find_java_files() );

for my $classname (keys %CLASSES) {
    my @packages = keys %{$CLASSES{$classname}};

    say "$classname:".join(',', @packages);
}


# utility functions

sub add_class {
    my ($package, $classname) = @_;

    if ( !exists $CLASSES{$classname} ) {
        $CLASSES{$classname} = {};
    }

    $CLASSES{$classname}->{"$package.$classname"} = 1;
}

sub process_jar {
    my ($jar_file) = @_;

    my $jar_cmd    = "jar tvf $jar_file | awk '{print \$NF}'";
    my @jar_files  = qx($jar_cmd);

    unless ($? == 0) {
        die "command '$jar_cmd' failed";
    }

    chomp for @jar_files;
    my @java_files = grep /\.(class|java)$/, @jar_files;

    for my $java_file (@java_files) {
        process_file($java_file);
    }
}

sub process_file {
    my ($java_file) = @_;

    # strip directory prefix so we only have package root
    for my $find_dir (@FIND_DIRS) {
        $java_file =~ s!$find_dir/?!!;
    }

    # strip inner class suffixes from filename
    $java_file =~ s/\$.*\.class$//;

    my $classname = basename $java_file, '.java', '.class';

    my $package = dirname $java_file;
    $package =~ s{/}{.}g;

    add_class($package, $classname);
}

sub process_java_files {
    my @java_files = @_;

    for my $java_file (@java_files ) {
        chomp $java_file;

        if ($java_file =~ m/\.(class|java)$/) {
            process_file($java_file);
        }
        else {
            process_jar($java_file);
        }
    }
}

sub find_user_java_files {
    my @java_files;
    for my $path_element (split ':', $IMPORTPATH) {

        if ( -e $path_element && -f $path_element ) {
            push @java_files, $path_element;
        }

        if ( -e $path_element && -d $path_element ) {
            push @FIND_DIRS, $path_element;
        }
    }

    my $find_arg = join ' ', @FIND_DIRS;
    my $find_cmd = join ' ', (
        "find $find_arg",
        "-type f",
        "-name '*.java'",
        "-or -name '*.class'",
        "-or -name '*.jar'"
    );

    push @java_files, qx($find_cmd);

    unless ($? == 0) {
        die "command '$find_cmd' failed";
    }

    return @java_files;
}

sub find_system_java_files {
    my $system_files_cmd = join ' ', (
        q(java -verbose 2>/dev/null),
        q(| grep Opened),
        q(| awk '{print $2}'),
        q(| sed 's/]//')
    );

    return qx($system_files_cmd);
}

sub find_java_files {
    my @user_files   = find_user_java_files($IMPORTPATH);
    my @system_files = find_system_java_files();

    my %uniq_java_files;
    for my $java_file (@user_files, @system_files) {
        chomp $java_file;
        $uniq_java_files{$java_file} = 1;
    }

    return keys %uniq_java_files;
}

