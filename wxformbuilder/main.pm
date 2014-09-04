package iPerl;

use 5.008005;
use utf8;
use strict;
use warnings;
use Wx 0.98 ':everything';

our $VERSION = '0.01';
our @ISA     = 'Wx::Frame';

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		'',
		wxDefaultPosition,
		[ 800, 500 ],
		wxDEFAULT_FRAME_STYLE | wxTAB_TRAVERSAL,
	);

	$self->{m_panel1} = Wx::Panel->new(
		$self,
		-1,
		wxDefaultPosition,
		wxDefaultSize,
		wxTAB_TRAVERSAL,
	);

	$self->{main_textctrl_code} = Wx::TextCtrl->new(
		$self->{m_panel1},
		-1,
		"",
		wxDefaultPosition,
		wxDefaultSize,
		wxTE_MULTILINE,
	);
	$self->{main_textctrl_code}->SetMaxLength(-1);

	$self->{main_button_evaluate} = Wx::Button->new(
		$self->{m_panel1},
		-1,
		"Evaluate",
		wxDefaultPosition,
		wxDefaultSize,
	);

	$self->{main_textctrl_output} = Wx::TextCtrl->new(
		$self->{m_panel1},
		-1,
		"",
		wxDefaultPosition,
		[ -1, 120 ],
		wxTE_MULTILINE | wxTE_READONLY,
	);
	$self->{main_textctrl_output}->SetMaxLength(-1);
	$self->{main_textctrl_output}->SetBackgroundColour(
		Wx::SystemSettings::GetColour( wxSYS_COLOUR_BTNTEXT )
	);
	$self->{main_textctrl_output}->SetFont(
		Wx::Font->new( wxNORMAL_FONT->GetPointSize, 76, 90, 90, 0, "" )
	);

	my $bSizer3 = Wx::BoxSizer->new(wxHORIZONTAL);
	$bSizer3->Add( 0, 0, 1, wxEXPAND, 5 );
	$bSizer3->Add( $self->{main_button_evaluate}, 0, wxALL, 5 );
	$bSizer3->Add( 0, 0, 1, wxEXPAND, 5 );

	my $bSizer2 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer2->Add( $self->{main_textctrl_code}, 1, wxALL | wxEXPAND, 5 );
	$bSizer2->Add( $bSizer3, 0, wxEXPAND, 5 );
	$bSizer2->Add( $self->{main_textctrl_output}, 0, wxALL | wxEXPAND, 5 );

	$self->{m_panel1}->SetSizerAndFit($bSizer2);
	$self->{m_panel1}->Layout;

	my $bSizer1 = Wx::BoxSizer->new(wxVERTICAL);
	$bSizer1->Add( $self->{m_panel1}, 1, wxEXPAND | wxALL, 0 );

	$self->SetSizer($bSizer1);
	$self->Layout;

	return $self;
}

1;
