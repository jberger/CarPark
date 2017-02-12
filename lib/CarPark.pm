package CarPark;

use Mojo::Base 'Mojolicious';

sub startup {
  my $app = shift;
  $app->moniker('carpark');
  $app->renderer->classes([__PACKAGE__]);

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

  $auth->get('/')->to(template => 'index');

  my $api = $auth->any('/api');

  my $door = $api->any('/door');
  $door->get('/')->to('Door#get_state');
  $door->post('/')->to('Door#set_state');
  $door->websocket('/socket')->to('Door#socket')->name('socket');

  my $gpio = $api->any('/gpio');
  $gpio->any([qw/GET POST/] => '/:pin')->to('GPIO#pin');
}

1;

__DATA__

@@ index.html.ep

<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  %= stylesheet begin
    #layer-door {
      transition: transform 3.0s ease;
    }
    #layer-door.open {
      transform: translateY(-100%);
    }
    @media (max-width: 800px) {
      svg { max-width: 100%; }
    }
    @media (min-width: 800px) {
      svg { max-height: 500px }
    }
  % end
</head>
<body>
  <div class="door-holder" onclick="toggleDoor()"><%== app->home->child(qw/art car.min.svg/)->slurp %></div>
  <script>
    var door;
    var ws = new WebSocket('<%= url_for('socket')->to_abs %>');
    ws.onmessage = function(e) {
      door = JSON.parse(e.data);
      var c = document.getElementById('layer-door').classList;
      if (door.open) {
        c.add('open');
      } else {
        c.remove('open');
      }
    }
    function toggleDoor() {
      if (!window.fetch) {
        alert('Your browser is too old');
        return;
      }

      window.fetch('<%= url_for 'door' %>', {
        method: 'POST',
        credentials: 'include',
        body: JSON.stringify({open: !door.open}),
      });
    }
  </script>
</body>
</html>

@@ login.html.ep

<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <!-- style adapted from http://codepen.io/larrygeams/pen/Itear  -->
  %= stylesheet begin
    html, body {
      width: 100%;
      height: 100%;
      margin: 0px;
    }

    .container {
      width: 100%;
      height: 100%;
      margin-top: 20px;
      display: flex;
      justify-content: center;
    }

    .form{
      max-width: 90%;
      width: 400px;
      height: 230px;
      background: #edeff1;
      margin: 0px auto;
      padding-top: 20px;
      border-radius: 10px;
      -moz-border-radius: 10px;
      -webkit-border-radius: 10px;
    }

    input[type="text"], input[type="password"]{
      display: block;
      width: 80%;
      height: 35px;
      margin: 15px auto;
      background: #fff;
      border: 0px;
      padding: 5px;
      font-size: 16px;
      border: 2px solid #fff;
      transition: all 0.3s ease;
      border-radius: 5px;
      -moz-border-radius: 5px;
      -webkit-border-radius: 5px;
    }

    input[type="text"]:focus, input[type="password"]:focus{
      border: 2px solid #1abc9d
    }

    input[type="submit"]{
      display: block;
      background: #1abc9d;
      width: 80%;
      padding: 12px;
      cursor: pointer;
      color: #fff;
      border: 0px;
      margin: auto;
      border-radius: 5px;
      -moz-border-radius: 5px;
      -webkit-border-radius: 5px;
      font-size: 17px;
      transition: all 0.3s ease;
    }

    input[type="submit"]:hover{
      background: #09cca6
    }

    a{
      text-align: center;
      font-family: Arial;
      color: gray;
      display: block;
      margin: 15px auto;
      text-decoration: none;
      transition: all 0.3s ease;
      font-size: 12px;
    }

    a:hover{
      color: #1abc9d;
    }

    ::-webkit-input-placeholder {
      color: gray;
    }

    :-moz-placeholder { /* Firefox 18- */
      color: gray;
    }

    ::-moz-placeholder {  /* Firefox 19+ */
      color: gray;
    }

    :-ms-input-placeholder {
      color: gray;
    }
  % end
</head>
<body>
<div class="container">
  <div class="form">
    %= form_for login => (method => 'POST') => begin
      <input type="text" name="username" placeholder="Username">
      <input type="password" name="password" placeholder="Password">
      <input type="submit" value="Login">
      <!-- <a href="">Lost your password?</a> -->
    % end
  </div>
</div>
</body>
</html>

