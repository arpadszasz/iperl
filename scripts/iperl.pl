#!/usr/bin/env perl

use 5.10.1;
use strict;
use warnings;
use utf8;
use threads;
use Thread::Queue;
use PadWalker 'peek_my';
use Package::Stash;
use AnyEvent;
use Capture::Tiny ':all';

$|++;

package iPerl::Wx;

sub init_gui {
    my $command_queue = shift;
    my $output_queue  = shift;

    use Wx ':everything';
    use Wx::Event ':everything';

    my $app = Wx::SimpleApp->new;

    my $frame = Wx::Frame->new(
        undef,
        -1,
        'iPerl',
        wxDefaultPosition,
        [ 800, 500 ],
        wxDEFAULT_FRAME_STYLE | wxTAB_TRAVERSAL,
    );

    my $panel = Wx::Panel->new(
        $frame,
        -1,
        wxDefaultPosition,
        wxDefaultSize,
        wxTAB_TRAVERSAL,
    );

    my $textctrl_code = Wx::TextCtrl->new(
        $panel,
        -1,
        "",
        wxDefaultPosition,
        wxDefaultSize,
        wxTE_MULTILINE,
    );
    $textctrl_code->SetFont(
        Wx::Font->new( 10, wxFONTFAMILY_TELETYPE, 90, 90, 0, "" )
    );

    my $textctrl_output = Wx::TextCtrl->new(
        $panel,
        -1,
        "",
        wxDefaultPosition,
        [ -1, 120 ],
        wxTE_MULTILINE | wxTE_READONLY,
    );
    $textctrl_output->SetBackgroundColour(
        Wx::SystemSettings::GetColour( wxSYS_COLOUR_BTNTEXT )
    );
    $textctrl_output->SetForegroundColour( wxWHITE );
    $textctrl_output->SetFont(
        Wx::Font->new( 10, wxFONTFAMILY_TELETYPE, 90, 90, 0, "" )
    );

    my $button_evaluate = Wx::Button->new(
        $panel,
        -1,
        "Evaluate (F5)",
        wxDefaultPosition,
        wxDefaultSize,
    );
    EVT_BUTTON(
        $button_evaluate,
        -1,
        sub {
            return iPerl::Wx::button_evaluate_action(
                $command_queue,
                $output_queue,
                $textctrl_code,
                $textctrl_output,
            );
        }
    );

    EVT_CHAR(
        $textctrl_code,
        sub {
            my $self    = shift;
            my $key_evt = shift;

            if ($key_evt->GetKeyCode == Wx::WXK_F5) {
                return iPerl::Wx::button_evaluate_action(
                    $command_queue,
                    $output_queue,
                    $textctrl_code,
                    $textctrl_output,
                );
            }
            else {
                $key_evt->Skip;
            }
        }
    );

    my $bSizer3 = Wx::BoxSizer->new(wxHORIZONTAL);
    $bSizer3->Add( 0, 0, 1, wxEXPAND, 5 );
    $bSizer3->Add( $button_evaluate, 0, wxALL, 5 );
    $bSizer3->Add( 0, 0, 1, wxEXPAND, 5 );

    my $bSizer2 = Wx::BoxSizer->new(wxVERTICAL);
    $bSizer2->Add( $textctrl_code, 1, wxALL | wxEXPAND, 5 );
    $bSizer2->Add( $bSizer3, 0, wxEXPAND, 5 );
    $bSizer2->Add( $textctrl_output, 0, wxALL | wxEXPAND, 5 );

    $panel->SetSizerAndFit($bSizer2);
    $panel->Layout;

    my $bSizer1 = Wx::BoxSizer->new(wxVERTICAL);
    $bSizer1->Add( $panel, 1, wxEXPAND | wxALL, 0 );

    $frame->SetSizer($bSizer1);
    $frame->Layout;
    $frame->Show;

    $app->MainLoop;

    return;
}

sub button_evaluate_action {
    my $command_queue   = shift;
    my $output_queue    = shift;
    my $textctrl_code   = shift;
    my $textctrl_output = shift;

    my $command
      = $textctrl_code->GetStringSelection
      ? $textctrl_code->GetStringSelection
      : $textctrl_code->GetValue;
    return if $command =~ /^\s*$/;

    $command_queue->enqueue($command);

    if (my $output = $output_queue->dequeue) {
        $textctrl_output->AppendText($output . "\n");
    }

    return;
}

package main;

{
    my $command_queue = Thread::Queue->new;
    my $output_queue  = Thread::Queue->new;
    my $worker        = threads->create(
        'evaluator',
        $command_queue,
        $output_queue,
    )->detach;

    iPerl::Wx::init_gui($command_queue, $output_queue);
}

exit 0;

sub evaluator {
    my $command_queue = shift;
    my $output_queue  = shift;

    my $stash = Package::Stash->new('main');

    my $loop = AE::timer 0, 1/20, sub {
        state ($context);

        if (my $command = $command_queue->pending && $command_queue->dequeue) {
            my $output = capture_merged{
                eval $command . '; $context = peek_my(0)';
                print $@;
            };
            map { $stash->add_symbol($_, $context->{$_}) } keys $context;
            $output_queue->enqueue($output || '');
        }
    };
    AE::cv->recv;

    return;
}

