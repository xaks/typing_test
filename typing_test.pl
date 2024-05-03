#!/usr/bin/env perl

use strict;
use warnings;

=pod

=head1 NAME

typing_test.pl - a typing test to find your words-per-minute on the command line

=cut

=head1 DESCRIPTION

This is a command line typing test that calculates a user's words-per-minute (WPM).

=cut

=head1 SYNOPSIS

Run this with "perl typing_test.pl" and type the words as they appear. Press
"enter" to submit a word and go on to the next word.

Example usage:

    $ perl typing_test.pl
    conceal
    conceal
    arbitrary
    arbitrary
    ...
    release
    release
    33 words correct in 60 seconds for a WPM of 33.00

Run a typing test for 2 minutes (120 seconds):

    $ perl typing_test.pl --time 120

Enable debug output:

    $ perl typing_test.pl -d
    $ perl typing_test.pl --debug

=cut

=head1 COPYRIGHT

Copyright Xaks (github.com/xaks)

Licensed under AGPLv3.0 or later. Full license text here:
https://www.gnu.org/licenses/agpl-3.0.html

SPDX identifier:
AGPL-3.0-or-later

=cut

use Getopt::Long;
use Pod::Usage qw(pod2usage);
use Readonly;
use Time::HiRes;

Readonly::Scalar my $SECONDS_TO_MINUTES  => 60;    # in seconds

my $DEBUG;
my $TEST_LENGTH_SECONDS = 60;    # in seconds (default one minute)

=head2 METHODS

=over

=item

main()

Runs the program:

    builds a dictionary of words to test the user with
    picks random words and displays the words to the user, then collects input
    scores and displays user input

=cut

sub main {

    my $dictionary = build_dictionary();
    my $results    = run_test($dictionary);

    score_test($results);
}

=item

build_dictionary()

Builds a dictionary of words to test the user with by loading a list of words
from the __DATA__ section of this file. These words are loaded into an array,
which allows for words to be duplicated in the test set. Doing this will make
those repeated words be more likely to show up during testing compared to other
words, if that is desired. The source data set does have a collection of longer
words, so WPM scores might be lower. It might be a nice feature to allow for a
custom file to be used as a dictionary.

args:
    none
returns:
    $dictionary => scalar arrayref, list of words to select from typing test

=cut

sub build_dictionary {
    my @dictionary;
    while ( my $line = <DATA> ) {
        chomp($line);

        # skip empty lines. we don't need that kinda nonsense
        if ($line) {
            push( @dictionary, $line );
        }
    }

    # clean up the open file handle
    close DATA;
    return \@dictionary;
}

=item

run_test()

Performs the following:

    sets a timer (default 60 seconds)
    displays the list of randomly picked words from the dictionary
    records list of displayed 
    captures user input
    returns the list of words tested and the user's answers



This does have a non-standard approach to displaying words, which can lead to
lower WPM scores. Perhaps in the future, more words can be displayed, and input
can be taken in via spaces instead of carriage returns, to more closely match
the typing experience. As a note, the test does allow for words to be repeated.

There's a potential for a user to take longer than the stated time of the
typing test. The loop displaying the next word waits on user input, which leads
to the possibility of a user timing the test and taking as much time on the
last word as desired. In the future, new functionality can be added to lock
down the test time to a more precise duration.

args:
    $dictionary => scalar arrayref, list of words to select from typing test
returns:
    $results => scalar hashref, with two keys:
        test_words  => array of words, in order, selected for the typing test
        input_words => array of words, in order, gathered from the user
    $results = {
        test_words  => \@test_words,
        input_words => \@input_words,
    }

=cut

sub run_test {
    my ($dictionary) = @_;

    my @test_words  = ();
    my @input_words = ();

    my $dictionary_length = scalar @{$dictionary};
    my $current_time      = Time::HiRes::gettimeofday();    # in seconds
    my $end_time          = $current_time + $TEST_LENGTH_SECONDS;

    if ($DEBUG) {
        printf("DEBUG - dictionary loaded: %d\n", $dictionary_length );
        printf("DEBUG - current time: %s\n", $current_time );
        printf("DEBUG - test end time: %s\n", $end_time );
    }

    while ( $end_time > $current_time ) {

        my $index = int( rand($dictionary_length) );

        printf("DEBUG - dictionary index: %d\n", $index ) if $DEBUG;
        my $word = $dictionary->[$index];
        push( @test_words, $word );
        printf("%s\n", $word );

        my $input = <STDIN>;
        chomp($input);
        push( @input_words, $input );

        $current_time = Time::HiRes::gettimeofday();
    }

    my $results = {
        test_words  => \@test_words,
        input_words => \@input_words,
    };
    return $results;
}

=item

score_test()

Takes in two lists, test words and user input words, and compares user input to
the test words in the order the words were displayed. Calculates and displays
the total correct number of typed words along with the words per minute. A
future improvement could be to have a character count and percentage of correct
characters.

args:
    $results => scalar hashref, with two keys:
        test_words  => array of words, in order, selected for the typing test
        input_words => array of words, in order, gathered from the user
    $results = {
        test_words  => \@test_words,
        input_words => \@input_words,
    }
returns:
    nothing

=cut

sub score_test {
    my ($results) = @_;

    my $score = 0;

    my @test_words  = @{ $results->{test_words} };
    my @input_words = @{ $results->{input_words} };

    foreach my $test_word (@test_words) {
        my $input_word = shift @input_words;

        printf("DEBUG - comparing %s to %s\n", $test_word, $input_word) if $DEBUG;
        if ( $test_word eq $input_word ) {
            $score++
        }
    }

    my $wpm = $score / ( $TEST_LENGTH_SECONDS / $SECONDS_TO_MINUTES );
    printf( "%d words correct in %d seconds for a WPM of %.2f\n",
        $score, $TEST_LENGTH_SECONDS, $wpm );
}

=back

=cut

# process CLI options
my $opts = {};
GetOptions( $opts, "debug", "help", "manual", "time=i" ) or exit;

if ( $opts->{debug} ) {
    $DEBUG = 1;
}
if ( $opts->{help} && !$opts->{manual} ) {
    pod2usage(1);    # show help, but only if not also asking for the full manual
}
if ( $opts->{manual} ) {
    pod2usage( -exitval => 0, -verbose => 2 );    # equivalent to "perldoc typing_test.pl"
}
if ( $opts->{time} ) {
    $TEST_LENGTH_SECONDS = $opts->{time};
}

main();

# dictionary from:
# https://www.prepscholar.com/toefl/blog/toefl-vocabulary-list/
__DATA__
abundant
accumulate
accurate
accustomed
acquire
adamant
adequate
adjacent
adjust
advantage
advocate
adverse
aggregate
aggressive
allocate
alternative
amateur
ambiguous
ambitious
amend
ample
anomaly
annual
antagonize
attitude
attribute
arbitrary
arduous
assuage
assume
augment
benefit
berate
bestow
boast
boost
brash
brief
brusque
cacophony
cease
censure
chronological
clarify
coalesce
coerce
cognizant
cohesion
coincide
collapse
collide
commitment
community
conceal
concur
conflict
constrain
contemplate
continuously
contradict
contribute
convey
copious
core
corrode
cumbersome
curriculum
data
decay
deceive
decipher
declaration
decline
degrade
demonstrate
deny
deplete
deposit
desirable
despise
detect
deter
deviate
devise
diatribe
digress
dilemma
diminish
dispose
disproportionate
disrupt
distort
distribute
diverse
divert
dynamic
ease
efficient
eliminate
elite
eloquent
emphasize
endure
enhance
epitome
equivalent
erroneous
estimate
evade
evaluate
evidence
evolve
exemplary
exclude
exclusive
expand
expertise
exploit
expose
extension
extract
famine
feasible
finite
flaw
fluctuate
focus
fortify
framework
frivolous
function
fundamental
gap
garbled
generate
grandiose
hackneyed
haphazard
harsh
hasty
hazardous
hesitate
hierarchy
hindrance
hollow
horror
hostile
hypothesis
identical
illiterate
illustrate
impact
impair
implement
imply
impose
impoverish
incentive
incessant
incidental
incite
inclination
incompetent
inconsistent
indefatigable
indisputable
ineffective
inevitable
infer
inflate
influence
inhibit
initial
inquiry
integral
integrate
interpret
intervene
intrepid
intricate
invasive
investigate
irascible
irony
irresolute
jargon
jointly
knack
labor
lag
lampoon
languish
lecture
leery
legitimate
lenient
likely
ludicrous
maintain
major
manipulate
maximize
measure
mediocre
mend
method
migrate
minimum
misleading
modify
morose
negligent
nonchalant
obey
obtain
obvious
opponent
oppress
origin
paradigm
parsimonious
partake
partial
paucity
peak
peripheral
permeate
persist
pertain
phase
poll
potent
pragmatic
praise
precede
precise
prestigious
prevalent
primary
prior
proceed
progeny
promote
prosper
proximity
quarrel
range
rank
rebuke
recapitulate
recede
recommend
reform
regulate
reinforce
reject
release
rely
reproach
require
resent
resign
resist
resolve
restrict
retain
retract
retrieve
rhetorical
rigid
rotate
safeguard
scrutinize
section
select
sequence
severe
shallow
shelter
shrink
significant
source
sparse
specify
speculate
solitary
somber
soothe
squalid
stable
stagnant
strategy
subsequent
substitute
subtle
sufficient
summarize
supervise
supplant
suspend
suspicious
sustain
symbolic
technical
terminal
tolerate
transfer
transition
transparent
tuition
unobtrusive
unscathed
upbeat
unjust
vacillate
valid
vanish
vary
verdict
vestige
vial
vilify
voluminous
whereas
wholly
widespread
wilt
