#! /usr/local/bin/perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use IO::Socket;
use IO::File;
use CompoundSplitter;


print "Starting compound server, initializing ... ";
flush STDOUT;

my $configFile = shift || "compound_server.conf";
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
$dictFH->open( " < $conf->{dict}" ) or die "Could not open dictionary file ".$conf->{dict}."\n";
$cSplitter->initDictionary( $dictFH ); 
$dictFH->close;

print "DONE\n";

# run server
run_server( %$conf, splitter => $cSplitter );
exit(1);



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



sub run_server {

    my %args = @_;

    my $sock = new IO::Socket::INET (
            LocalHost => $args{hostname},
            LocalPort => $args{port},
            Proto     => 'tcp',
            Listen    => 1,
            Reuse     => 1,
        ) or die "Could not create socket on $args{hostname}:$args{port}: $@ \n";
    print "Listening on host $args{hostname}, port $args{port}.\n";

    SERVER: while ( my $client = $sock->accept() ) {

        CLIENT: while (<$client>) {
            my $word = $_;
            chomp $word; 
            unless ($word) {
                print $client "\n"; next;
            }
            my $split = $args{splitter}->splitWord($word); 
            print $client join( " ", @$split ) . "\n";
        }
        close $client;
    }

    close($sock);
}




__END__

compound splitting server


