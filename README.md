This repository contains the nl-splitter compound segmentation tool for archival purposes since the original website (ilps.science.uva.nl/resources/compound-splitter-nl/) is no longer available. See https://web.archive.org/web/20200813005715/https://ilps.science.uva.nl/resources/compound-splitter-nl/ for an archived version of the website. All credit goes to the original authors. Find the original README below.

---

Compound word splitter for the Dutch language, v 1.0

(c) 2006-2010 ISLA, University of Amsterdam

Contact: Valentin Jijkoun <jijkoun@uva.nl>


Files
=====

  - compound_server.conf - configuration file for the server.

  - compound_server.pl   - perl script that runs a server which splits words
    that get sent to it into parts. The actual compound splitting is done
    by CompoundSplitter.pm.
    Run the server using command:

        $ perl compound_server.pl &

    The server listens on port 50500 (by default). It accepts one word per
    line. If the word is a compound, it prints back the split version of the
    word. If the word is not a compound, it prints an empty line.

    You can test the server manually to TCP port 50500:
 
        $ telnet localhost 50500 

  - CompoundSplitter.pm  - perl module that does the actual compound splitting,
    used by compound_server.pl  

  - compoundSplitter.t   - test Perl script for CompoundSplitter.pm

  - run.out - frequency counts of Dutch words, based on the Alpino Dutch
    newspaper corpus; used as dictionary by CompoundSplitter.pm

Authors
=======

The following people were involved in the implementation of the compound
splitter at various times (in alphabetical order):

Katja Hofmann
Valentin Jijkoun
Jaap Kamps
Christof Monz
