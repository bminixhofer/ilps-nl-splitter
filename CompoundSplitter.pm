package CompoundSplitter;

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use IO::Socket;
use IO::File;

our $VERSION = '0.01';


## Class Methods

sub new {
    # assign and check arguments
    my ($class, %args) = @_;
    die __PACKAGE__."->new(): Required argument 'language' missing"
           unless $args{language};
    die __PACKAGE__."->new(): Required argument 'min_compound_length' missing"
           unless $args{min_compound_length};

    # See: Andrea Krott 2001 (Dutch) / 1999 (All); 
    #      Turid Hedlund 2001 (Swedish) / 2002 (Dutch, German, Finnish).
    if ($args{language} =~ /dutch/) {
        $args{linking_morpheme1} = "(s|e)";
        $args{linking_morpheme2} = "(en)";
    } elsif ($args{language} =~ /finnish/) {
    } elsif ($args{language} =~ /german/) {
        $args{linking_morpheme1} = "(s|n|e)";
        $args{linking_morpheme2} = "(en)";
    } elsif ($args{language} =~ /swedish/) {
        $args{linking_morpheme1} = "(o|u|e|s)";
    } elsif ($args{language} =~ /afrikaans/) {
        $args{linking_morpheme1} = "(s|e)";
        $args{linking_morpheme2} = "(en)";
    } else {
        die "Unknown language: $args{language}\n";
    };

    bless \%args, $class;
}



## Object Methods

sub initDictionary {
    my ($self, $dictFH) = @_;
    die __PACKAGE__."->initDictionary(): Required argument 'dictionary' missing"
           unless $dictFH;

    while (<$dictFH>) {
        my ($freq, $word) = split;
        next unless $word;
        next if ( length $word < $self->{min_compound_length} );
        $self->{dict}->{$word} = $freq;
    }
}



sub splitWord {
    my ($self,$word) = @_;
    ref( $self ) or die __PACKAGE__."->split() must be called as instance method";

    ## remove all leading and trailing whitespace TODO: remove weird characters
    return [] unless $word;
    $word =~ s/^[\s\n]+//;
    $word =~ s/[\s\n]+$//;
    return [] unless $word;
    return $self->_SPLIT7($word);
}



sub _SPLIT7 {
    my ($self,$word) = @_;
    ref( $self ) or die __PACKAGE__."->_SPLIT7() must be called as instance method";

    return [] if ( length($word) < 2*$self->{min_compound_length} );

    my $splits = {};
    for my $i ($self->{min_compound_length}-1 .. length($word)-$self->{min_compound_length}) {
        ## if ( defined ($self->{dict}->{substr($word,0,$i)}) && defined $self->{dict}->{$word}
	##     && ($self->{dict}->{substr($word,0,$i)} > $self->{dict}->{$word}) ) {
        if ( defined $self->{dict}->{substr($word,0,$i)} 
                && ( !defined $self->{dict}->{$word} || ($self->{dict}->{substr($word,0,$i)} > $self->{dict}->{$word}) ) ) {
            my $left = substr($word,0,$i) . "#";
            $self->_SPLIT7b($splits,$left,($self->{dict}->{$word} || 0),substr($word,$i));
        }
    }

    my $split = "";
    if (scalar keys( %$splits ) > 0 ) { 
        my $max = 0;
        foreach (keys %{$splits}) {
            my @components = split '#';
            my $score = 1;
            foreach (@components) {
                $score *= $self->{dict}->{$_};
            };
            $score = $score ** (1 / @components);
            if ($score > $max) {
	        $max = $score;
	        $split = $_;
            }
        }
    }

    my @compounds = split '#', $split;
    return \@compounds;   # return array of compounds
}



sub _SPLIT7b {
    my ($self,$splits,$pre,$cf,$rest) = @_;
    my $length = length $rest;
    if ( $self->{dict}->{$rest} && ( $self->{dict}->{$rest} > $cf ) ) {
        $splits->{"$pre$rest"}++; 
    };
    if ($self->{linking_morpheme1} && substr($rest,0,1) =~ qr($self->{linking_morpheme1}) ) {
        $self->_SPLIT7b($splits,$pre,$cf,substr($rest,1));
    };
    if ($self->{linking_morpheme2} && substr($rest,0,2) =~ qr($self->{linking_morpheme2}) ) {
        $self->_SPLIT7b($splits,$pre,$cf,substr($rest,2));
    };
    return if ( $length < 2*$self->{min_compound_length} );
    for my $i ($self->{min_compound_length}-1 .. $length-$self->{min_compound_length}) {
        if (defined ($self->{dict}->{substr($rest,0,$i)}) && ($self->{dict}->{substr($rest,0,$i)} > $cf) ) {
            my $left = $pre . substr($rest,0,$i) . "#";
            $self->_SPLIT7b($splits,$left,$cf,substr($rest,$i));
        }
    };
}


__END__

compound splitting module based on script decompound-irj.pl by Jaap Kamps


