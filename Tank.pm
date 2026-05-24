
package Tank;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub draw_tank {
    my ($self, $x, $y) = @_;
    my $tank_image = Tkx::image_create_photo(-file => "sary/tank0.png");
    $self->{canvas}->create_image($x, $y, -image => $tank_image, -tags => "tank");
}


1;
