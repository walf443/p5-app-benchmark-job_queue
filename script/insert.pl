package  main;
use strict;
use warnings;
use strict;
use warnings;
use Benchmark;
use Test::mysqld;
use Proc::Guard qw/proc_guard/;
use File::Which qw/which/;
use Test::TCP qw/empty_port wait_port/;

eval {
    use Qudo;
    use Qudo::Test;
    use Qudo::Driver::DBI;
    use TheSchwartz;
    use Data::ObjectDriver::Driver::DBI;
    use TheSchwartz::Simple;
    use Gearman::Client;
};

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',
    }
)
    or die "Can't start mysqld: $Test::mysqld::errstr";

my $gearmand_port = empty_port();
my $gearmand = proc_guard(which('gearmand'), '-p', $gearmand_port);

main(@ARGV); exit;

sub main {
    my $switch_of = +{
    };
    if ( $INC{"Qudo.pm"} ) {
        $switch_of->{qudo_skinny} = \&qudo_skinny;
        $switch_of->{qudo_skinny_cached} = \&qudo_skinny_cached;
        qudo_skinny(); # run for setup database.
    } else {
        warn "skipped qudo_skinny, qudo_skinny_cached";
    }
    if ( $INC{"Qudo/Driver/DBI.pm"} ) {
        $switch_of->{qudo_dbi} = \&qudo_dbi;
        $switch_of->{qudo_dbi_cached} = \&qudo_dbi_cached;
        qudo_dbi(); # run for setup database.
    } else {
        warn "skipped qudo_dbi, qudo_dbi_cached";
    }
    if ( $INC{"TheSchwartz.pm"} ) {
        $switch_of->{the_schwartz} = \&the_schwartz;
        $switch_of->{the_schwartz_cached} = \&the_schwartz_cached;
        the_schwartz(); # run for setup database.
    } else {
        warn "skipped the_schwartz, the_schwartz_cached";
    }
    if ( $INC{"TheSchwartz/Simple.pm"} ) {
        $switch_of->{the_schwartz_simple} = \&the_schwartz_simple;
        $switch_of->{the_schwartz_simple_cached} = \&the_schwartz_simple_cached;
        the_schwartz_simple(); # run for setup database.
    } else {
        warn "skipped the_schwartz_simple, the_schwartz_simple_cached";
    }

    if ( $INC{"Gearman/Client.pm"} ) {
        $switch_of->{gearman} = \&gearman;
        $switch_of->{gearman_cached} = \&gearman_cached;
    } else {
        warn "skipped gearman";
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

my $is_schema_setup_qudo_skinny;
sub _qudo_skinny {
    if ( ! $is_schema_setup_qudo_skinny ) {
        _setup_qudo('qudo_skinny');
        $is_schema_setup_qudo_skinny++;
    }
    my $qudo = Qudo->new(
        driver_class => 'Skinny',
        databases    => [+{
            dsn => $mysqld->dsn(dbname => 'qudo_skinny'),
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

my $is_schema_setup_qudo_dbi;
sub _qudo_dbi {
    my $dsn = $mysqld->dsn(dbname => 'qudo_dbi');
    if ( ! $is_schema_setup_qudo_dbi ) {
        _setup_qudo('qudo_dbi');
        $is_schema_setup_qudo_dbi++;
    }

    my $qudo = Qudo->new(
        driver_class => 'DBI',
        databases    => [+{
            dsn => $dsn,
            username => 'root',
            password => '',
        }],
    );
}

sub _setup_qudo {
    my $database = shift;

    my $schema = Qudo::Test::load_schema;
    my $dbh = DBI->connect($mysqld->dsn, 'root', '', { RaiseError => 1, AutoCommit => 1})
        or die DBI::errstr;
    $dbh->do(qq{ CREATE DATABASE IF NOT EXISTS $database })
        or die $dbh->errstr;

    $dbh->do(qq{ USE $database })
        or die $dbh->errstr;

    for my $sql ( @{ $schema->{'mysql'} } ) {
        $dbh->do($sql)
            or die $dbh->errstr;
    }
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

my $is_schema_setup_the_schwartz;
sub _the_schwartz {
    if ( ! $is_schema_setup_the_schwartz ) {
        _setup_the_schwartz('the_schwartz');
        $is_schema_setup_the_schwartz++;
    }
    my $schwartz = TheSchwartz->new(databases => [ { 
        dsn => $mysqld->dsn(dbname => 'the_schwartz'),
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

my $is_schema_setup_the_schwartz_simple;
sub _the_schwartz_simple {
    if ( ! $is_schema_setup_the_schwartz_simple ) {
        _setup_the_schwartz('the_schwartz_simple');
        $is_schema_setup_the_schwartz_simple++;
    }
    my $dbh = DBI->connect(
        $mysqld->dsn(dbname => 'the_schwartz_simple'), 'root', '', {
        RaiseError => 1,
        AutoCommit => 1,
    })
        or die DBI->errorstr();
    my $schwartz = TheSchwartz::Simple->new([ $dbh ],);
}

sub _setup_the_schwartz {
    my $database = shift;
    my $dbh = DBI->connect($mysqld->dsn, 'root', '', { RaiseError => 1, AutoCommit => 1})
        or die DBI::errstr;
    $dbh->do(qq{ CREATE DATABASE IF NOT EXISTS $database })
        or die $dbh->errstr;

    $dbh->do(qq{ USE $database })
        or die $dbh->errstr;

    open(my $fh, '<', 'the_schwartz.sql')
        or die $!;
    my $schema = '';
    while ( my $line = <$fh> ) {
        $schema .= $line;
    }
    close $fh;
    for my $sql ( split /;/, $schema ) {
        $sql =~ s/^\s+$//m;
        if ( $sql ) {
            $dbh->do($sql);
        }
    }

}

sub gearman {
    my $client = Gearman::Client->new;
    $client->job_servers('127.0.0.1:' . $gearmand_port);
    $client->dispatch_background('Worker::Test', 'test');
}

my $cached_gearman;
sub gearman_cached {
    $cached_gearman ||= do {
        my $client = Gearman::Client->new;
        $client->job_servers('127.0.0.1:' . $gearmand_port);
        $client;
    };
    $cached_gearman->dispatch_background('Worker::Test', 'test');
}

