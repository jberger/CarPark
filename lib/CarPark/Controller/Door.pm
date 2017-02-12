use CarPark::Controller::Door;

use Mojo::Base 'Mojolicious::Controller';

sub get_state {
  my $c = shift;
  $c->render(json => { open => $c->model->door->is_open });
}

sub set_state {
  my $c = shift;
  my $open = $c->req->json('/open');
  my $door = $c->model->door;
  $door->toggle if (!!$door->is_open) ^ (!!$open);
  $c->rendered(202);
}

sub socket {
  my $c = shift;
  my $door = $c->model->door;
  my $r = Mojo::IOLoop->recurring(1 => sub { $c->send({json => { open => $door->is_open }}) });
  $c->on(finish => sub { Mojo::IOLoop->remove($r) });
  $c->send({json => { open => $door->is_open }});
}

1;

