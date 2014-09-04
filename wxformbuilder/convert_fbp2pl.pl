#!/usr/bin/env perl

use 5.10.1;
use strict;
use warnings;
use utf8;
use FBP;
use FBP::Perl;

my $fbp_file = $ARGV[0] or die "No input FBP file given";
my $pm_file  = $ARGV[1] or die "No input Perl module file given";

my $fbp = FBP->new;
$fbp->parse_file($fbp_file);

my $generator = FBP::Perl->new(
    project => $fbp->project
);

open( FILE, '>', $pm_file);
print FILE $generator->flatten(
    $generator->dialog_class(
        $fbp->form('iPerl')
    )
);
close FILE;
