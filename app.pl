use Mojolicious::Lite;

get '/' => 'index';

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
  <div onclick="openDoor()"><%== app->home->child(qw/art car.svg/)->slurp %></div>
  <script>
    function openDoor() {
      document.getElementById('layer2').classList.toggle('open');
    }
  </script>
</body>
</html>
