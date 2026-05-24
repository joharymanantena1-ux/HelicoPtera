#!/usr/bin/perl

use strict;
use warnings;
use DBI;

package Obstacle;

sub new {
    my $class = shift;
    my $self = {
        nom => shift,
        x   => shift,
        y   => shift,
    };
    bless $self, $class;
    return $self;
}

# sub save {
#     my ($self, $dbh) = @_;

#     my $query = "INSERT INTO Obstacle (nom, x, y) VALUES (?, ?, ?)";
#     my $sth = $dbh->prepare($query) or die $dbh->errstr;
#     $sth->execute($self->{nom}, $self->{x}, $self->{y}) or die $dbh->errstr;
    
#     print "Obstacle save.\n";
# }

sub get_obstacles {
    my ($self, $dbh) = @_;
    my $sth = $dbh->prepare("SELECT x, y, width, height FROM Obstacle") or die "Erreur de préparation de la requête SQL: " . $dbh->errstr;
    $sth->execute() or die "Erreur d'execution de la requete SQL: " . $dbh->errstr;

    my @obstacles;
    while (my $row = $sth->fetchrow_hashref()) {
        push @obstacles, $row;
    }
    return \@obstacles;
}

my $dbname   = 'helico';
my $user     = 'postgres';
my $password = 'johary2003';
my $host     = 'localhost';

my $dbh = DBI->connect("DBI:Pg:dbname=$dbname;host=$host", $user, $password, { AutoCommit => 1, PrintError => 0, RaiseError => 1 });

$dbh->disconnect();
