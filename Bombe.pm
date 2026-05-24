package Bombe;

use strict;
use warnings;
use Tkx;

sub new {
    my ($class, $canvas, $x, $y,@tank) = @_;
    my $self = {
        canvas => $canvas,
        x => $x,
        y => $y,
        vy => 10,
        ay => 0.2,
        exploded => 0,
        id => undef,
        border_id => undef,
        tankId => \@tank,
    };
    bless $self, $class;
    return $self;
}

sub id {
    my ($self) = @_;
    return $self->{id};
}

sub draw_border {
    my ($self) = @_;
    my $bbox = [$self->{x} - 10, $self->{y} - 10, $self->{x} + 10, $self->{y} + 10];

    if ($self->{border_id}) {
        $self->{canvas}->coords($self->{border_id}, @{$bbox});
    } else {
        $self->{border_id} = $self->{canvas}->create('rectangle', @{$bbox}, -outline => 'black');
    }
}

sub draw {
    my ($self) = @_;

    my $bombe_image = Tkx::image_create_photo(-file => "assets/img/bombakelybe.png");
    $self->{id} = $self->{canvas}->create_image($self->{x}, $self->{y}, -image => $bombe_image, -tags => "bombe");
    return $self->{id};
}

sub fall {
    my ($self) = @_;
    $self->{vy} += $self->{ay};
    $self->{y} += $self->{vy};

    $self->{canvas}->coords($self->{id}, $self->{x}, $self->{y});

    $self->draw_border();
    my %elements;
    if ($self->{y} >= 790){
        foreach my $pos (@{$self->{tankId}}) {
            print "MIKASOKA";
            $self->explode();
        } 
    }
    if ($self->{y} >= $self->{canvas}->cget(-height)) {
        $self->explode();
    } else {
        Tkx::after(100, sub { $self->fall });
    }
}

sub explode {
    my ($self) = @_;

    return if $self->{exploded};

    my $explosion_image = Tkx::image_create_photo(-file => "assets/img/mipoka.png");
    $self->{canvas}->itemconfigure($self->{id}, -image => $explosion_image);
    $self->{exploded} = 1;

    $self->{canvas}->delete($self->{border_id}) if $self->{border_id};

    Tkx::after(250, sub { $self->badaboum});
}

sub badaboum {
    my ($self) = @_;
    $self->{canvas}->delete($self->{id});
}

sub get_position {
    my ($self) = @_;
    return ($self->{x}, $self->{y});
}


1;
