package CarPark::Model;

use Mojo::Base 'Mojo::TypeModel';

use CarPark::Model::Door;
use CarPark::Model::GPIO;
use CarPark::Model::User;

has [qw/config db/];

sub copies { state $copies = [qw/config db/] }

sub types {
  state $types = {
    door => 'CarPark::Model::Door',
    gpio => 'CarPark::Model::GPIO',
    user => 'CarPark::Model::User',
  };
}

1;

