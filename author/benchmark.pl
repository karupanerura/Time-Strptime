use strict;
use warnings;
use utf8;

use Benchmark qw/cmpthese timethese/;

use Time::Strptime::Format;
use Time::Piece;
use DateTime::Format::Strptime;
use POSIX qw/tzset/;
use Time::Local qw/timelocal/;
use Time::TZOffset qw/tzoffset/;
use Test::More;

my $pattern = '%Y-%m-%d %H:%M:%S';
my $text    = '2014-01-01 01:23:45';

for my $time_zone (qw|GMT UTC Asia/Tokyo America/Whitehorse|) {
    local $ENV{TZ} = $time_zone;
    tzset();

    my $ts_parser = Time::Strptime::Format->new($pattern);
    my $dt_parser = DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone);
    my $tp_parser = tzoffset(CORE::localtime) eq '+0000' ? Time::Piece->gmtime : Time::Piece->localtime;

    subtest "${time_zone}(@{[ tzoffset(CORE::localtime) ]})" => sub {
        my $dt = $dt_parser->parse_datetime($text);
        my $tp = $tp_parser->strptime($text, $pattern);
        is_deeply([$ts_parser->parse($text)], [$dt->epoch, $dt->offset]);
        is_deeply([$ts_parser->parse($text)], [$tp->epoch, $tp->tzoffset->seconds]);
    };

    cmpthese timethese 100000 => +{
        'dt(cached)' => sub { $dt_parser->parse_datetime($text) },
        'ts(cached)' => sub { $ts_parser->parse($text)          },
        'tp(cached)' => sub { $tp_parser->strptime($text, $pattern) },
        'dt'         => sub { DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone)->parse_datetime($text) },
        'ts'         => sub { Time::Strptime::Format->new($pattern)->parse($text)                                                  },
        'tp'         => sub { Time::Piece->localtime->strptime($text, $pattern) },
    };
}

done_testing;
__END__
    # Subtest: GMT(+0000)
    ok 1
    ok 2
    1..2
ok 1 - GMT(+0000)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 47 wallclock secs (46.43 usr +  0.09 sys = 46.52 CPU) @ 2149.61/s (n=100000)
dt(cached): 27 wallclock secs (27.22 usr +  0.05 sys = 27.27 CPU) @ 3667.03/s (n=100000)
        tp:  2 wallclock secs ( 1.62 usr +  0.00 sys =  1.62 CPU) @ 61728.40/s (n=100000)
tp(cached):  1 wallclock secs ( 0.96 usr +  0.01 sys =  0.97 CPU) @ 103092.78/s (n=100000)
        ts: 34 wallclock secs (34.09 usr +  0.11 sys = 34.20 CPU) @ 2923.98/s (n=100000)
ts(cached):  1 wallclock secs ( 1.12 usr +  0.00 sys =  1.12 CPU) @ 89285.71/s (n=100000)
               Rate       dt       ts dt(cached)        tp ts(cached) tp(cached)
dt           2150/s       --     -26%       -41%      -97%       -98%       -98%
ts           2924/s      36%       --       -20%      -95%       -97%       -97%
dt(cached)   3667/s      71%      25%         --      -94%       -96%       -96%
tp          61728/s    2772%    2011%      1583%        --       -31%       -40%
ts(cached)  89286/s    4054%    2954%      2335%       45%         --       -13%
tp(cached) 103093/s    4696%    3426%      2711%       67%        15%         --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(+0000)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 47 wallclock secs (46.49 usr +  0.08 sys = 46.57 CPU) @ 2147.31/s (n=100000)
dt(cached): 27 wallclock secs (26.62 usr +  0.05 sys = 26.67 CPU) @ 3749.53/s (n=100000)
        tp:  1 wallclock secs ( 1.64 usr +  0.00 sys =  1.64 CPU) @ 60975.61/s (n=100000)
tp(cached):  1 wallclock secs ( 0.81 usr +  0.00 sys =  0.81 CPU) @ 123456.79/s (n=100000)
        ts: 34 wallclock secs (33.53 usr +  0.11 sys = 33.64 CPU) @ 2972.65/s (n=100000)
ts(cached):  1 wallclock secs ( 1.13 usr +  0.00 sys =  1.13 CPU) @ 88495.58/s (n=100000)
               Rate       dt       ts dt(cached)        tp ts(cached) tp(cached)
dt           2147/s       --     -28%       -43%      -96%       -98%       -98%
ts           2973/s      38%       --       -21%      -95%       -97%       -98%
dt(cached)   3750/s      75%      26%         --      -94%       -96%       -97%
tp          60976/s    2740%    1951%      1526%        --       -31%       -51%
ts(cached)  88496/s    4021%    2877%      2260%       45%         --       -28%
tp(cached) 123457/s    5649%    4053%      3193%      102%        40%         --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(+0900)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 55 wallclock secs (54.70 usr +  0.11 sys = 54.81 CPU) @ 1824.48/s (n=100000)
dt(cached): 34 wallclock secs (33.92 usr +  0.06 sys = 33.98 CPU) @ 2942.91/s (n=100000)
        tp:  2 wallclock secs ( 1.61 usr +  0.01 sys =  1.62 CPU) @ 61728.40/s (n=100000)
tp(cached):  1 wallclock secs ( 0.79 usr +  0.00 sys =  0.79 CPU) @ 126582.28/s (n=100000)
        ts: 39 wallclock secs (39.50 usr +  0.13 sys = 39.63 CPU) @ 2523.34/s (n=100000)
ts(cached):  2 wallclock secs ( 1.79 usr +  0.01 sys =  1.80 CPU) @ 55555.56/s (n=100000)
               Rate       dt       ts dt(cached) ts(cached)        tp tp(cached)
dt           1824/s       --     -28%       -38%       -97%      -97%       -99%
ts           2523/s      38%       --       -14%       -95%      -96%       -98%
dt(cached)   2943/s      61%      17%         --       -95%      -95%       -98%
ts(cached)  55556/s    2945%    2102%      1788%         --      -10%       -56%
tp          61728/s    3283%    2346%      1998%        11%        --       -51%
tp(cached) 126582/s    6838%    4916%      4201%       128%      105%         --
    # Subtest: America/Whitehorse(-0700)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(-0700)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 57 wallclock secs (56.63 usr +  0.11 sys = 56.74 CPU) @ 1762.43/s (n=100000)
dt(cached): 36 wallclock secs (35.81 usr +  0.06 sys = 35.87 CPU) @ 2787.84/s (n=100000)
        tp:  2 wallclock secs ( 1.67 usr +  0.01 sys =  1.68 CPU) @ 59523.81/s (n=100000)
tp(cached):  1 wallclock secs ( 0.80 usr +  0.00 sys =  0.80 CPU) @ 125000.00/s (n=100000)
        ts: 40 wallclock secs (40.52 usr +  0.14 sys = 40.66 CPU) @ 2459.42/s (n=100000)
ts(cached):  3 wallclock secs ( 2.06 usr +  0.01 sys =  2.07 CPU) @ 48309.18/s (n=100000)
               Rate       dt       ts dt(cached) ts(cached)        tp tp(cached)
dt           1762/s       --     -28%       -37%       -96%      -97%       -99%
ts           2459/s      40%       --       -12%       -95%      -96%       -98%
dt(cached)   2788/s      58%      13%         --       -94%      -95%       -98%
ts(cached)  48309/s    2641%    1864%      1633%         --      -19%       -61%
tp          59524/s    3277%    2320%      2035%        23%        --       -52%
tp(cached) 125000/s    6992%    4982%      4384%       159%      110%         --
1..4
