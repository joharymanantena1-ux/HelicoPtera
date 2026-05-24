
package Helico;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub draw_helicopter {
    my ($self, $x, $y) = @_;
    my $helicopter_image = Tkx::image_create_photo(-file => "sary/hel-0.png");
    my $helico_height = Tkx::image_height($helicopter_image);

    $self->{canvas}->create_image($x, $y, -image => $helicopter_image, -tags => "helicopter");

    print "La hauteur de l'helicoptere est : $helico_height\n";
    return $helico_height;
}

1;
