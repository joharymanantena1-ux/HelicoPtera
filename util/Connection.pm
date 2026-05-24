
use strict;
use warnings;
use DBI;

package Connection;

sub new {
    my $class = shift;
    my $self = {
        dbname   => shift,
        user     => shift,
        password => shift,
        host     => shift,
        port     => shift || 5432,
    };
    bless $self, $class;
    return $self;
}

sub connect {
    my ($self) = @_;
    my $dsn = "DBI:Pg:dbname=$self->{dbname};host=$self->{host};port=$self->{port}";
    my $dbh = DBI->connect($dsn, $self->{user}, $self->{password}, { AutoCommit => 1, PrintError => 0, RaiseError => 1 });
    return $dbh;
}

my $dbname   = 'helico';
my $user     = 'postgres';
my $password = 'johary2003';
my $host     = 'localhost';

my $connection = Connection->new($dbname, $user, $password, $host);

my $dbh = $connection->connect();
