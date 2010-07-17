package  main;
use strict;
use warnings;
use strict;
use warnings;
use Benchmark;
use Object::Container;
use Qudo;
use Qudo::Test;
use Qudo::Driver::DBI;
use TheSchwartz;
use Data::ObjectDriver::Driver::DBI;
use TheSchwartz::Simple;

main(@ARGV); exit;

sub main {
    Benchmark::cmpthese(1000, +{
            qudo_skinny => \&qudo_skinny,
            qudo_skinny_cached => \&qudo_skinny_cached,
            qudo_dbi => \&qudo_dbi,
            the_schwartz_simple => \&the_schwartz_simple,
            the_schwartz => \&the_schwartz,
    });
}

sub qudo_skinny {
    my $qudo = _qudo_skinny();

    $qudo->enqueue('Worker::Test', { arg => 'test' });
}

my $cached_qudo_skinny;
sub qudo_skinny_cached {
    $cached_qudo_skinny ||= _qudo_skinny();
    $cached_qudo_skinny->enqueue('Worker::Test', { arg => 'test' });
}

sub _qudo_skinny {
    my $qudo = Qudo->new(
        driver_class => 'Skinny',
        databases    => [+{
            dsn => 'dbi:mysql:qudo_test',
            username => 'root',
            password => '',
        }],
    );
}

sub qudo_dbi {
    my $qudo = Qudo->new(
        driver_class => 'DBI',
        databases    => [+{
            dsn => 'dbi:mysql:qudo_test',
            username => 'root',
            password => '',
        }],
    );

    $qudo->enqueue('Worker::Test', { arg => 'test' });
}

sub the_schwartz {
    my $schwartz = TheSchwartz->new(databases => [ { 
        dsn => 'dbi:mysql:the_schwartz_test',
        user => 'root',
        password => '',
        verbose => 1,
    },
    ]);
    my $job = $schwartz->insert('Worker::Test' => "test");
}

sub the_schwartz_simple {
    my $dbh = DBI->connect('dbi:mysql:the_schwartz_test', 'root', '', {
        RaiseError => 1,
        AutoCommit => 1,
    })
        or die DBI->errorstr();
    my $schwartz = TheSchwartz::Simple->new([ $dbh ],);
    my $job = $schwartz->insert('Worker::Test' => "test");
}
