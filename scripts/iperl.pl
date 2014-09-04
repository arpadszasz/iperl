#!/usr/bin/env perl

use 5.10.1;
use strict;
use warnings;
use utf8;
use threads;
use threads::shared;
use Thread::Queue;
use PadWalker 'peek_my';
use Package::Stash;
use Capture::Tiny ':all';

$|++;

my $command_queue = Thread::Queue->new;
my $output_queue  = Thread::Queue->new;
my $worker        = threads->create(
    'evaluator',
    $command_queue,
    $output_queue,
)->detach;

threads->create(
    sub {
        while (<>) {
            $_[0]->enqueue($_);
            if (my $output = $_[1]->dequeue) {
                chomp $output;
                print $output, "\n";
            }
            sleep 1;
        }
    },
    $command_queue,
    $output_queue,
)->join;

exit 0;

sub evaluator {
    my $command_queue = shift;
    my $output_queue  = shift;

    my $stash = Package::Stash->new('main');

    while (1) {
        state ($context);

        if (my $command = $command_queue->dequeue) {
            my $output = capture_merged{
                eval $command . '; $context = peek_my(0)';
                print $@;
            };
            $output_queue->enqueue($output) if $output;
        }

        sleep 1;
    }

    return;
} 
