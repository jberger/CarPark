package CarPark;

use Mojo::Base 'Mojolicious';

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

  $app->plugin('CarPark::Plugin::Model' => {
    config => {pins => $conf->{pins}},
    db     => $conf->{db},
  });

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

  my $auth = $r->under('/' => sub {
    my $c = shift;

    return 1 if $c->session->{username};

    $c->redirect_to('login');
    return 0;
  });

  $auth->get('/')->to(template => 'index')->name('index');

  my $api = $auth->any('/api');

  my $door = $api->any('/door');
  $door->get('/')->to('Door#get_state');
  $door->post('/')->to('Door#set_state');
  $door->websocket('/socket')->to('Door#socket')->name('socket');

  my $gpio = $api->any('/gpio');
  $gpio->any([qw/GET POST/] => '/:pin')->to('GPIO#pin');
}

1;

