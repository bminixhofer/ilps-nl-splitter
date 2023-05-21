#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';


use Test::More 'no_plan';
use IO::String;
use Test::Differences;


my $testLang = 'dutch';
my $testMinLength = 4;

my $testDict = <<DICT;
    610 hypotheek
     11 hypotheekaftrek
    804 aftrek
   5221 rente 
   5555 test
DICT

use_ok( 'CompoundSplitter' ) or exit;


NEW: {

    eval {
        CompoundSplitter->new();
    };
    like( $@, qr/Required argument 'language' missing/, "new throws exception when called without 'language'" );

    eval {
        CompoundSplitter->new( language => $testLang );
    };
    like( $@, qr/Required argument 'min_compound_length' missing/, "new throws exception when called without 'min_compound_length'" );

    eval {
        CompoundSplitter->new( language => $testLang, min_compound_length => $testMinLength );
    };
    ok(!$@, "new lives when called with correct arguments");
    diag($@) if ($@);


    # TODO: check object returned by new
}


INITDICTIONARY: {

    my $splitter1 = CompoundSplitter->new( language => $testLang, min_compound_length => $testMinLength );
    eval {
       $splitter1->initDictionary();
    };
    like($@, qr/Required argument 'dictionary' missing/, "initDictionary throws exception when called without 'dictionary'");
    
    my $splitter2 = CompoundSplitter->new( language => $testLang, min_compound_length => $testMinLength );
    my $testDictFH = IO::String->new($testDict);
    eval {
       $splitter2->initDictionary( $testDictFH );
    };
    ok(!$@, "initDictionary lives when called with correct arguments"); 
    diag($@) if ($@);

    is($splitter2->{dict}->{test}, 5555, "dictionary parsed correctly");
}


SPLITWORD: {
    my $splitter = CompoundSplitter->new( language => $testLang, min_compound_length => $testMinLength );
    my $testDictFH = IO::String->new($testDict);
    $splitter->initDictionary( $testDictFH );

    eval {
        $splitter->splitWord();
    };
    ok(!$@, "splitWord lives when called without word");
    diag($@) if ($@);

    my $result1;
    eval {
        $result1 = $splitter->splitWord("hypotheekaftrek");
    };
    ok(!$@, "splitWord lives when called with word");
    diag($@) if ($@);
    my $testresult1 = [ 'hypotheek', 'aftrek' ];
    is_deeply($result1, $testresult1, 'hypotheekaftrek split correctly' );

    my $result2;
    eval {
        $result2 = $splitter->splitWord("hypotheekrenteaftrek");
    };
    ok(!$@, "splitWord lives when called with word");
    diag($@) if ($@);
    my $testresult2 = [ 'hypotheek', 'rente', 'aftrek' ];
    eq_or_diff($result2, $testresult2, 'hypotheekrenteaftrek split correctly' );
}






