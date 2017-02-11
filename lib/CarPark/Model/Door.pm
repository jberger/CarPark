package CarPark::Model::Door;

use Mojo::Base 'CarPark::Model';

use Mojo::IOLoop;
use Mojo::JSON qw/false true/;

has gpio => sub { shift->model('gpio') };

has pins => sub { shift->config->{pins} };

sub initialize {
  my $self = shift;

  my ($trigger, $sensor) = @{ $self->pins }{qw/trigger sensor/};
  die "trigger and sensor pins must be defined" unless $trigger && $sensor;

  # ensure pins are exported correctly
  my $gpio = $self->gpio;
  $gpio->export($trigger);
  $gpio->pin_mode($trigger => 'out');
  $gpio->export($sensor);
  $gpio->pin_mode($sensor => 'in');
}

sub is_open {
  my $self = shift;
  my $sensor = $self->pins->{sensor};
  $self->model->gpio->pin($sensor) ? true : false;
}

sub toggle {
  my $self = shift;
  my $trigger = $self->pins->{trigger};
  Mojo::IOLoop->delay(
    sub {
      $self->gpio->pin($trigger, 1);
      Mojo::IOLoop->timer(0.5 => shift->begin);
    },
    sub {
      $self->gpio->pin($trigger, 0);
    }
  )->wait;
}


1;

