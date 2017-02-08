package CarPark::Model;

use Mojo::Base -base;

has app => sub { die 'app is required' };

has db => sub { shift->app->db };

1;

