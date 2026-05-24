# use Scalar::Util qw(looks_like_number);
use strict;
use warnings;
use Tkx;
use DBI;
use lib '.';

require "./util/Connection.pm";
require "./Obstacle.pm";
require "./Bombe.pm";
require "./Tank.pm";

package Interface;

sub new {
    my $class = shift;
    my $self = {
        dy => 0,
        score => 0,
        tank_ids => [],
    };
    bless $self, $class;
    return $self;
}

sub terrain {
    my ($self) = @_;

    my $mw = Tkx::widget->new(".");
    $mw->g_wm_title("ANGIDIMBY MALAGASY");

    my $canvas = $mw->new_canvas(-width => 800, -height => 800);
    $canvas->configure(-background => 'skyblue');

    $canvas->g_pack(-expand => 1, -fill => 'both');

    my $dbh = $self->connect_db();
    $self->{obstacles} = $self->get_obstacles($dbh);

    foreach my $obstacle (@{$self->{obstacles}}) {
        my $x = $obstacle->{x};
        my $y = $obstacle->{y};
        my $width = $obstacle->{width};
        my $height = $obstacle->{height};

        my $rectangle = $canvas->create_rectangle(
            $x,
            $y, 
            $x + $width, 
            $y + $height, 
            -fill => 'brown'
        );
        $canvas->addtag('obstacle', 'withtag', $rectangle);
        $canvas->itemconfigure($rectangle, -tags => ['obstacle', "width=$width", "height=$height"]);
       
    }

    $self->{canvas} = $canvas;
    $self->{helicopter_x} = 70;
    $self->{helicopter_y} = 487;

    my @tank_positions = ( 
        [350, 790],
        [50, 790], 
        [490, 790],
    );


    $self->{tank_ids} = []; 

    foreach my $pos (@tank_positions) {
        my ($tank_x, $tank_y) = @$pos;
        my $tank_id = $self->draw_tank($tank_x, $tank_y);
        push @{$self->{tank_ids}}, $tank_id;
        $self->move_tank_auto($tank_id, 2, 0);
    }

    $self->draw_helicopter($self->{helicopter_x}, $self->{helicopter_y});
    $self->keyboard_events($mw);
    $self->gravity();

    # LABEL SCORE TOTAL 
    my $score_label = $canvas->create_text(780, 20,
     -text => "Score: 0", -anchor => "ne", -font => "-weight bold -size 15 -family {Arial Black}",
      -fill => "black");
    $self->{score_label} = $score_label;

    Tkx::MainLoop();
}


sub draw_helicopter {
    my ($self, $x, $y) = @_;
    my $helicopter_image = Tkx::image_create_photo(-file => "assets/img/hel-0.png");
    $self->{canvas}->create_image($x, $y, -image => $helicopter_image, -tags => "helicopter");
}

sub draw_tank {
    my ($self, $x, $y) = @_;
    my $tank_image = Tkx::image_create_photo(-file => "assets/img/tank1.png");
    my $tank_id = $self->{canvas}->create_image($x, $y, -image => $tank_image, -tags => "tank");
    return $tank_id;
}

sub keyboard_events {
    my ($self, $mw) = @_;
    $mw->g_bind('<KeyPress-w>', [sub { $self->start_ascend; }]);
    $mw->g_bind('<KeyRelease-w>', [sub { $self->stop_ascend; }]);
    $mw->g_bind('<KeyPress-s>', [sub { $self->move_helicopter(0, 10); }]);
    $mw->g_bind('<KeyPress-a>', [sub { $self->move_helicopter(-10, 0);$self->stop_ascend; }]);
    $mw->g_bind('<KeyPress-d>', [sub { $self->move_helicopter(10, 0);$self->stop_ascend; }]);
    $mw->g_bind('<KeyPress-e>', [sub { $self->start_ascend_diagonal('right');$self->start_ascend;$self->stop_ascend; }]);
    $mw->g_bind('<KeyPress-q>', [sub { $self->start_ascend_diagonal('left');$self->start_ascend;$self->stop_ascend; }]);
    $mw->g_bind('<space>', [sub { $self->drop_bomb; }]);
}

sub move_helicopter {
    my ($self, $dx, $dy) = @_;

    my $new_x = $self->{helicopter_x} + $dx;
    my $new_y = $self->{helicopter_y} + $dy;

    my $canvas_width = $self->{canvas}->cget(-width);
    my $canvas_height = $self->{canvas}->cget(-height);

    $new_x = 24 if $new_x < 24; #droite
    $new_x = $canvas_width - 23 if $new_x > $canvas_width - 23; #gauche
    $new_y = 15 if $new_y < 18;#haut
    $new_y = $canvas_height - 10 if $new_y > $canvas_height - 10; #bas


    my $helicopter_bbox = [$new_x-15, $new_y -15, $new_x + 12, $new_y + 12];
    # my $tank_bbox = [$new_x-15, $new_y -15, $new_x + 12, $new_y + 12];

    foreach my $obstacle (@{$self->{obstacles}}) {
        my $obstacle_bbox = [
            $obstacle->{x}, $obstacle->{y},
            $obstacle->{x} + $obstacle->{width},
            $obstacle->{y} + $obstacle->{height}
        ];
        if ($self->bbox_collision($helicopter_bbox, $obstacle_bbox)) {
            # tsy metsika
            return;
        }
    }

    $self->{helicopter_x} = $new_x;
    $self->{helicopter_y} = $new_y;
    $self->{canvas}->coords("helicopter", $self->{helicopter_x}, $self->{helicopter_y});   
}

sub move_tank_auto {
    my ($self, $tank_id, $dx, $dy) = @_;

    my ($x, $y) = $self->{canvas}->coords($tank_id);
    my ($x_str, $y_str) = split ' ', $x;

    $x = int($x_str // 0);
    $y //= 790;

    my $new_x = $x + $dx;
    my $new_y = $y + $dy;

    my $canvas_width = $self->{canvas}->cget(-width);
    my $canvas_height = $self->{canvas}->cget(-height);

    if ($new_x < 24 || $new_x > $canvas_width - 23) {
        $dx = -$dx;
        $new_x += $dx;
    }

    my $tank_bbox = [$new_x - 25, $new_y - 25, $new_x + 30, $new_y + 30];
    $self->tankborder($tank_id, @{$tank_bbox});

    foreach my $obstacle (@{$self->{obstacles}}) {
        my $obstacle_bbox = [
            $obstacle->{x}, $obstacle->{y},
            $obstacle->{x} + $obstacle->{width},
            $obstacle->{y} + $obstacle->{height}
        ];

        if ($self->bbox_collision($tank_bbox, $obstacle_bbox)) {
            $dx = -$dx;
            $dy = -$dy;
            $new_x += $dx;
            $new_y += $dy;
            last;
        }
    }
    $self->{canvas}->coords($tank_id, $new_x, $new_y);


    Tkx::after(45, sub { $self->move_tank_auto($tank_id, $dx, $dy); });
}

sub tankborder {
    my ($self, $tank_id, $x1, $y1, $x2, $y2) = @_;
    my $bbox = [$x1, $y1, $x2, $y2];

    if ($self->{tank_border_ids}{$tank_id}) {
        $self->{canvas}->coords($self->{tank_border_ids}{$tank_id}, @{$bbox});
    } else {
        $self->{tank_border_ids}{$tank_id} = $self->{canvas}->create('rectangle', @{$bbox}, -outline => 'black');
    }
}


sub drop_bomb {
    my ($self) = @_;
    my $bomb = Bombe->new($self->{canvas}, int($self->{helicopter_x}), int($self->{helicopter_y}),$self->{tank_ids});
    $bomb->draw();
    $bomb->fall();

    my ($bomb_x, $bomb_y) = $self->{canvas}->coords($bomb->{id});
    return $bomb;
}


sub update_score_label {
    my ($self) = @_;
    $self->{canvas}->itemconfigure($self->{score_label}, -text => "Score: $self->{score}");
}

sub start_ascend {
    my ($self) = @_;
    $self->{dy} = -6 if $self->{dy} >= 0;
    $self->move_helicopter(0, $self->{dy});
}

sub stop_ascend {
    my ($self) = @_;
    $self->{dy} = 4;
}

sub start_ascend_diagonal {
    my ($self, $direction) = @_;

    my $dx = 3;
    my $dy = -6;

    if ($direction eq 'right') {
        $dx = 12;
    } elsif ($direction eq 'left') {
        $dx = -12;
    }

    $self->{dx} = $dx;
    $self->{dy} = $dy;

    $self->move_helicopter($dx, $dy);
}

sub gravity {
    my ($self) = @_;

    Tkx::after(100, sub {
        if ($self->{dy} > 0) {
            $self->{dy} += 0.15;
            $self->move_helicopter(0, $self->{dy});
        }
        $self->gravity();
    });
}

sub connect_db {
    my ($self) = @_;
    my $connection = Connection->new('helico', 'postgres', 'johary2003', 'localhost');
    return $connection->connect();
}

sub get_obstacles {
    my ($self, $dbh) = @_;
    my $sth = $dbh->prepare("SELECT x, y, width, height FROM Obstacle") or die "Erreur de preparation de la requête SQL: " . $dbh->errstr;
    $sth->execute() or die "Erreur d'execution de la requete SQL: " . $dbh->errstr;

    my @obstacles;
    while (my $row = $sth->fetchrow_hashref()) {
        push @obstacles, $row;
    }
    return \@obstacles;
}

sub bbox_collision {
    my ($self, $bbox1, $bbox2) = @_;

    return !(
        $bbox1->[2] < $bbox2->[0] ||
        $bbox1->[0] > $bbox2->[2] ||
        $bbox1->[3] < $bbox2->[1] ||
        $bbox1->[1] > $bbox2->[3]   
    );
}
