package CarPark::Model;

use Mojo::Base -base;

use CarPark::Model::Door;
use CarPark::Model::GPIO;
use CarPark::Model::User;

use Carp ();

has [qw/config db/];

my %classes = (
  door => 'CarPark::Model::Door',
  gpio => 'CarPark::Model::GPIO',
  user => 'CarPark::Model::User',
);

sub model {
  my ($self, $type, @args) = @_;
  Carp::croak "type $type not understood"
    unless my $class = $classes{$type};

  my %args = (@args == 1 ? %{$args[0]} : @args);
  $args{$_} //= $self->$_() for (qw/db config/);
  return $class->new(%args);
}


1;

