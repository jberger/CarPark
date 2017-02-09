package CarPark::Model::GPIO;

use Mojo::Base 'CarPark::Model';

use Mojo::File;
use Time::HiRes ();

sub _gpio { return Mojo::File->new('/sys/class/gpio') }

sub _pin {
  my $pin = shift;
  $pin // die 'pin is required';
  return _gpio->child("gpio$pin");
}

sub is_exported {
  my ($self, $pin) = @_;
  my $dir = _pin($pin)->child('direction');
  return -w $dir;
}

sub export {
  my ($self, $pin) = @_;
  return 1 if -e _pin($pin);
  _gpio->child('export')->spurt($pin);

  # it takes a while for gpio export to occur
  my $max = 10;
  while ($max--) {
    # export is complete once this file is writeable
    return 1 if $self->is_exported($pin);
    Time::HiRes::sleep 0.1;
  }
  die "pin $pin did not export";
}

sub unexport {
  my ($self, $pin) = @_;
  return unless -e _pin($pin);
  _gpio->child('unexport')->spurt($pin);
};

sub pin_mode {
  my ($self, $pin, $set) = @_;
  my $file = _pin($pin)->child('direction');
  $file->spurt($set) if defined $set;
  chomp (my $out = $file->slurp);
  return $out;
}

sub pin {
  my ($self, $pin, $val) = @_;
  my $file = _pin($pin)->child('value');
  $file->spurt($val) if defined $val;
  chomp (my $out = $file->slurp);
  return $out;
}

1;

