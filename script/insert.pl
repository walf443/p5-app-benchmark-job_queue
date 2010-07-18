package  main;
use strict;
use warnings;
use strict;
use warnings;
use Benchmark;

eval {
    use Qudo;
    use Qudo::Test;
    use Qudo::Driver::DBI;
    use TheSchwartz;
    use Data::ObjectDriver::Driver::DBI;
    use TheSchwartz::Simple;
};

# TODO: use Test::mysqld
#       autosetup schema

main(@ARGV); exit;

sub main {
    my $switch_of = +{
    };
    if ( $INC{"Qudo.pm"} ) {
        $switch_of->{qudo_skinny} = \&qudo_skinny;
        $switch_of->{qudo_skinny_cached} = \&qudo_skinny_cached;
    } else {
        warn "skipped qudo_skinny, qudo_skinny_cached";
    }
    if ( $INC{"Qudo/Driver/DBI.pm"} ) {
        $switch_of->{qudo_dbi} = \&qudo_dbi;
        $switch_of->{qudo_dbi_cached} = \&qudo_dbi_cached;
    } else {
        warn "skipped qudo_dbi, qudo_dbi_cached";
    }
    if ( $INC{"TheSchwartz.pm"} ) {
        $switch_of->{the_schwartz} = \&the_schwartz;
        $switch_of->{the_schwartz_cached} = \&the_schwartz_cached;
    } else {
        warn "skipped the_schwartz, the_schwartz_cached";
    }
    if ( $INC{"TheSchwartz/Simple.pm"} ) {
        $switch_of->{the_schwartz_simple} = \&the_schwartz_simple;
        $switch_of->{the_schwartz_simple_cached} = \&the_schwartz_simple_cached;
    } else {
    }
    Benchmark::cmpthese(1000, $switch_of);
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

