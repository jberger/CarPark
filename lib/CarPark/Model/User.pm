package CarPark::Model::User;

use Mojo::Base 'CarPark::Model';

use Carp ();
use Passwords ();

sub add_user {
  my ($self, $username, $pass, @roles) = @_;
  my $db = $self->db;
  $db->lock_exclusive;
  Carp::croak "user $username already exists"
    if exists $db->{users}{$username};
  $db->{users}{$username} = {
    password => '',
    roles => {},
  };
  $self->set_password($username, $pass);
  $self->set_roles($username, @roles) if @roles;
  $db->unlock;
  return 1;
}

sub set_password {
  my ($self, $username, $pass) = @_;
  my $user = $self->_user($username);
  $user->{password} = Passwords::password_hash($pass);
  return 1;
}

sub check_password {
  my ($self, $username, $pass) = @_;
  my $user = $self->_user($username);
  return Passwords::password_verify($pass, $user->{password});
}

sub add_roles {
  my ($self, $username, @roles) = @_;
  my $user = $self->_user($username);
  @{$user->{roles}}{@roles} = (1) x @roles;
  return [sort keys %{$user->{roles}}];
}

sub remove_roles {
  my ($self, $username, @roles) = @_;
  my $user = $self->_user($username);
  delete @{$user->{roles}}{@roles};
  return [sort keys %{$user->{roles}}];
}

sub check_role {
  my ($self, $username, $role) = @_;
  my $user = $self->_user($username);
  return $user->{roles}{$role};
}

sub _user {
  my ($self, $username) = @_;
  Carp::croak "user $username does not exist"
    unless my $user = $self->db->{users}{$username};
  return $user;
}

1;


