package CarPark::Controller::GPIO;

use Mojo::Base 'Mojolicious::Controller';

sub pin {
  my $c = shift;
  my $pin = $c->stash('pin');
  my $gpio = $c->model->gpio;
  return $c->reply->not_found
    unless $gpio->is_exported($pin);

  if ($c->req->method eq 'POST') {
    $gpio->pin($pin, $c->req->body);
  }
  $c->render(text => $gpio->pin($pin));
}

1;

