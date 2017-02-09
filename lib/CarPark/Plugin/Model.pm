package CarPark::Plugin::Model;

use Mojo::Base 'Mojolicious::Plugin';

use DBM::Deep;

use CarPark::Model::Door;
use CarPark::Model::GPIO;
use CarPark::Model::User;

sub register {
  my ($plugin, $app, $conf) = @_;

  my $file = $conf->{file} // 'carpark.db';
  my $db = DBM::Deep->new($file);
  $app->helper(db => sub { $db });

  $app->helper('model.door' => sub { _build_model('CarPark::Model::Door' => @_) });
  $app->helper('model.gpio' => sub { _build_model('CarPark::Model::GPIO' => @_) });
  $app->helper('model.user' => sub { _build_model('CarPark::Model::User' => @_) });
}

sub _build_model {
  my ($class, $c) = (shift, shift);
  return $class->new(@_)->app($c->app);
}

1;

