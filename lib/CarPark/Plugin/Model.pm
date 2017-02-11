package CarPark::Plugin::Model;

use Mojo::Base 'Mojolicious::Plugin';

use DBM::Deep;

use CarPark::Model;

sub register {
  my ($plugin, $app, $conf) = @_;

  # database
  my $file = $conf->{db} // 'carpark.db';
  my $db = DBM::Deep->new($file);
  $app->helper(db => sub { $db });

  # base model
  my $model = CarPark::Model->new(
    config => $conf->{config} || {},
    db     => $db,
  );

  # model aliases
  for my $type (qw/door gpio user/) {
    $app->helper("model.$type" => sub { shift; $model->model($type => @_) });
  }
}

1;

