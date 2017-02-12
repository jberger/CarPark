package CarPark::Controller::Access;

use Mojo::Base 'Mojolicious::Controller';

sub login {
  my $c = shift;
  my $user = $c->param('username');
  my $pass = $c->param('password');
  if ($c->model->user->check_password($user, $pass)) {
    $c->session->{username} = $user;
    return $c->redirect_to('index');
  }
  $c->render('login');
}

sub logout {
  my $c = shift;
  $c->session->{expires} = 1;
  $c->redirect_to('login');
}

sub authenticated {
  my $c = shift;
  return 1 if $c->session->{username};
  $c->redirect_to('login');
  return 0;
}

1;

