use CHI;

my $chi = CHI->new(driver => 'Redis', debug => 1);

$chi->set('foo', 'bar');

$chi->set('a', 1);
$chi->set('b', 2);
$chi->set('c', 3);
$chi->get_multi_arrayref([qw(a b c)]);
