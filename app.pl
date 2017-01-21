use Mojolicious::Lite;

use Mojo::File 'path';
use Mojo::JSON qw/false true/;

sub _gpio { return path('/sys/class/gpio') }

sub _pin {
  my $pin = shift;
  $pin // die 'pin is required';
  return _gpio->child("gpio$pin");
}

helper export => sub {
  my ($c, $pin) = @_;
  return if -e _pin($pin);
  _gpio->child('export')->spurt($pin);
};

helper unexport => sub {
  my ($c, $pin) = @_;
  return unless -e _pin($pin);
  _gpio->child('unexport')->spurt($pin);
};

helper pin_mode => sub {
  my ($c, $pin, $set) = @_;
  my $file = _pin($pin)->child('direction');
  $file->spurt($set) if defined $set;
  chomp (my $out = $file->slurp);
  return $out;
};

helper pin => sub {
  my ($c, $pin, $val) = @_;
  my $file = _pin($pin)->child('value');
  $file->spurt($val) if defined $val;
  chomp (my $out = $file->slurp);
  return $out;
};

helper is_door_open => sub { shift->pin(16) ? false : true };

helper toggle_door => sub {
  my $c = shift;
  Mojo::IOLoop->delay(
    sub {
      $c->pin(6, 1);
      Mojo::IOLoop->timer(0.5 => shift->begin);
    },
    sub {
      $c->pin(6, 0);
    }
  )->wait;
};

# >0 is out
my %pins = (
  6  =>  1,
  16 => -1,
);

# ensure pins are exported correctly
for my $pin (keys %pins) {
  next unless my $mode = $pins{$pin};
  app->export($pin);
  app->pin_mode($pin, $mode > 0 ? 'out' : 'in');
}

my $r = app->routes;

$r->get('/' => 'index');

my $api = $r->any('/api');

my $door = $api->any('/door');

$door->get('/' => sub {
  my $c = shift;
  $c->render(json => { open => $c->is_door_open });
});

$door->websocket('/socket' => sub {
  my $c = shift;
  my $r = Mojo::IOLoop->recurring(1 => sub { $c->send({json => { open => $c->is_door_open }}) });
  $c->on(finish => sub { Mojo::IOLoop->remove($r) });
  $c->send({json => { open => $c->is_door_open }});
})->name('socket');

$door->post('/' => sub {
  my $c = shift;
  my $open = $c->req->json('/open');
  $c->toggle_door if (!!$c->is_door_open) ^ (!!$open);
  $c->rendered(202);
});

my $gpio = $api->any('/gpio');

$gpio->any([qw/GET POST/] => '/:pin' => sub {
  my $c = shift;
  my $pin = $c->stash('pin');
  return $c->reply->not_found unless $pins{$pin};
  if ($c->req->method eq 'POST') {
    $c->pin($pin, $c->req->body);
  }
  $c->render(text => $c->pin($pin));
});

app->start;

__DATA__

@@ index.html.ep

<!DOCTYPE html>
<html>
<head>
  %= stylesheet begin
    #layer2 {
      transition: transform 3.0s ease;
    }
    #layer2.open {
      transform: translateY(-100%);
    }
  % end
</head>
<body>
  <div class="door-holder" onclick="toggleDoor()"><%== app->home->child(qw/art car.svg/)->slurp %></div>
  <script>
    var door;
    var ws = new WebSocket('<%= url_for('socket')->to_abs %>');
    ws.onmessage = function(e) {
      door = JSON.parse(e.data);
      var c = document.getElementById('layer2').classList;
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
        body: JSON.stringify({open: !door.open}),
      });
    }
  </script>
</body>
</html>
