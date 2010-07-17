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
            qudo_dbi_cached => \&qudo_dbi_cached,
            the_schwartz_simple => \&the_schwartz_simple,
            the_schwartz_simple_cached => \&the_schwartz_simple_cached,
            the_schwartz => \&the_schwartz,
            the_schwartz_cached => \&the_schwartz_cached,
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
    my $qudo = _qudo_dbi();

    $qudo->enqueue('Worker::Test', { arg => 'test' });
}

my $cached_qudo_dbi;
sub qudo_dbi_cached {
    $cached_qudo_dbi ||= _qudo_dbi();
    $cached_qudo_dbi->enqueue('Worker::Test', { arg => 'test' });
}

sub _qudo_dbi {
    my $qudo = Qudo->new(
        driver_class => 'DBI',
        databases    => [+{
            dsn => 'dbi:mysql:qudo_test',
            username => 'root',
            password => '',
        }],
    );
}

sub the_schwartz {
    my $schwartz = _the_schwartz();
    my $job = $schwartz->insert('Worker::Test' => "test");
}

my $cacehd_the_schwartz;
sub the_schwartz_cached {
    $cacehd_the_schwartz ||= _the_schwartz();
    my $job = $cacehd_the_schwartz->insert('Worker::Test' => "test");
}

sub _the_schwartz {
    my $schwartz = TheSchwartz->new(databases => [ { 
        dsn => 'dbi:mysql:the_schwartz_test',
        user => 'root',
        password => '',
        verbose => 1,
    },
    ]);
}

sub the_schwartz_simple {
    my $schwartz = _the_schwartz_simple();
    my $job = $schwartz->insert('Worker::Test' => "test");
}

my $cached_the_schwartz_simple;
sub the_schwartz_simple_cached {
    $cached_the_schwartz_simple ||= _the_schwartz_simple();
    my $job = $cached_the_schwartz_simple->insert('Worker::Test' => "test");
}

sub _the_schwartz_simple {
    my $dbh = DBI->connect('dbi:mysql:the_schwartz_test', 'root', '', {
        RaiseError => 1,
        AutoCommit => 1,
    })
        or die DBI->errorstr();
    my $schwartz = TheSchwartz::Simple->new([ $dbh ],);
}
