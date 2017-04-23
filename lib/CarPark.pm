package CarPark;

use Mojo::Base 'Mojolicious';

use File::Share ();
use Mojo::File;

use DBM::Deep;
use CarPark::Model;

has share_dir => sub {
  Mojo::File->new( File::Share::dist_dir( 'CarPark' ) );
};

sub startup {
  my $app = shift;
  $app->moniker('carpark');

  my $conf = $app->plugin(Config => {
    default => {
      db => undef,
      pins => {
        trigger => 6,
        sensor  => 16,
      },
      plugins => {},
    },
  });

  $app->renderer->paths([ $app->share_dir->child('templates')->to_string ]);

  # database
  my $file = $conf->{db} // 'carpark.db';
  my $db = DBM::Deep->new($file);
  $app->helper(db => sub { $db });

  # base model
  my $model = CarPark::Model->new(
    config => {pins => $conf->{pins}},
    db     => $db,
  );
  $app->plugin(TypeModel => {base => $model});

  for my $plugin (keys %{ $conf->{plugins} }) {
    $app->plugin($plugin => ($conf->{plugins}{$plugin} // {}));
  }

  # ensure pins are exported correctly
  $app->model->door->initialize unless $conf->{no_init};

  # routes
  my $r = $app->routes;

  $r->get('/login')->to(template => 'login');
  $r->post('/login')->to('Access#login');
  $r->get('/logout')->to('Access#logout');

  my $auth = $r->under('/')->to('Access#authenticated');

  $auth->get('/')->to(template => 'index')->name('index');

  my $api = $auth->any('/api');

  my $door = $api->any('/door')->to('Door#');
  $door->get('/')->to('#get_state');
  $door->post('/')->to('#set_state');
  $door->websocket('/socket')->to('#socket')->name('socket');

  my $gpio = $api->any('/gpio')->to('GPIO#');
  $gpio->any([qw/GET POST/] => '/:pin')->to('#pin');
}

1;

