#! /usr/local/bin/perl

# Compound splitting (for Dutch)
# Reads text from stdin and outputs processed text to stdout
# Handles plain text or ILPS Lucene input format

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use IO::Socket;
use IO::File;
require "/data/Projects/word_segmentation/tools/compound-splitter-nl/CompoundSplitter.pm";


my $consonant = '[bcdfghjklmnpqrstvwxz]';

print STDERR "Starting compound splitter ($0), initializing ... ";
flush STDOUT;

(my $rundir = $0) =~ s/\/[^\/]*$//;

my $configFile = shift || ($rundir . "/compound_server.conf");
my $configFH = new IO::File;
$configFH->open( " < $configFile" ) or die "Error when trying to open file $configFile: $@";
my $conf = read_properties($configFH);
$configFH->close;

# set default values if neccessary 
$conf->{hostname} ||= $ENV{HOSTNAME};
$conf->{port}     ||= '50500';
$conf->{language} ||= 'dutch';

my $cSplitter = CompoundSplitter->new( 
        language => $conf->{language}, 
        min_compound_length => $conf->{min_compound_length},
     );

my $dictFH = new IO::File;
$dictFH->open( " < $rundir/$conf->{dict}" ) or die "Could not open dictionary file ".$conf->{dict}."\n";
$cSplitter->initDictionary( $dictFH ); 
$dictFH->close;

print STDERR "DONE\n";

run_splitter( %$conf, splitter => $cSplitter );



## functions

sub read_properties {
    my $fh = shift or die "read_properties called without required argument fh \n";
    my %conf;
    while ( <$fh> ) {
        my $line = $_;
        next if $line =~ /^#/;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless $line;
        my ($key,$value) = split /\s*=\s*/, $line;
        next unless $key;
        $conf{$key} = $value;
    }
    return \%conf;
}



sub run_splitter {

    my %args = @_;



    while (<>) {
        chomp;
        
        # if it's ilps-lucene format, only split field content
        # ILPS lucene format: ID <tab> {i,s,*} <tab> fieldname <tab> fieldcontent <endofline>
        my @fields = split(/\t/);
        if (@fields >= 4 and $fields[1] =~ /^(i|s|\*)$/) {
            if (defined $fields[3] and ($fields[1] eq '*' or $fields[1] eq 'i')) {
                # indexable content: print out non-text
                print join("\t", splice(@fields, 0, 3)), "\t";
                # and split the rest...
                $_ = join("\t", @fields);
            } else {
                # ILPS lucene format, but we should not do anything
                print "$_\n";
                next;
            }
        }
        
        my @tokens = split(/(\W+)/);
        my @res = ();
        foreach my $token (@tokens) {
            if ($token =~ /\w/) {
                my $split = $args{splitter}->splitWord($token); 
                if (@$split) {
                    $token = $token . " " . join(" ", @$split);
                }
                # XXX: fix dutch stemming (should not be here!) - remove "...ppen" endings
                $token =~ s/($consonant)\1en\b/$1/g;
            }
            push @res, $token;
        }
        print join("", @res) . "\n";
    }

}




__END__

compound splitting server


