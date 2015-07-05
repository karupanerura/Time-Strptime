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
        dt: 34 wallclock secs (34.23 usr +  0.02 sys = 34.25 CPU) @ 2919.71/s (n=100000)
dt(cached): 21 wallclock secs (20.50 usr +  0.01 sys = 20.51 CPU) @ 4875.67/s (n=100000)
        tp:  1 wallclock secs ( 1.52 usr +  0.00 sys =  1.52 CPU) @ 65789.47/s (n=100000)
tp(cached):  1 wallclock secs ( 0.61 usr +  0.00 sys =  0.61 CPU) @ 163934.43/s (n=100000)
        ts: 24 wallclock secs (24.32 usr +  0.01 sys = 24.33 CPU) @ 4110.15/s (n=100000)
ts(cached):  1 wallclock secs ( 0.59 usr +  0.00 sys =  0.59 CPU) @ 169491.53/s (n=100000)
               Rate       dt       ts dt(cached)        tp tp(cached) ts(cached)
dt           2920/s       --     -29%       -40%      -96%       -98%       -98%
ts           4110/s      41%       --       -16%      -94%       -97%       -98%
dt(cached)   4876/s      67%      19%         --      -93%       -97%       -97%
tp          65789/s    2153%    1501%      1249%        --       -60%       -61%
tp(cached) 163934/s    5515%    3889%      3262%      149%         --        -3%
ts(cached) 169492/s    5705%    4024%      3376%      158%         3%         --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(+0000)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 34 wallclock secs (34.09 usr +  0.01 sys = 34.10 CPU) @ 2932.55/s (n=100000)
dt(cached): 21 wallclock secs (20.57 usr +  0.01 sys = 20.58 CPU) @ 4859.09/s (n=100000)
        tp:  1 wallclock secs ( 1.55 usr +  0.01 sys =  1.56 CPU) @ 64102.56/s (n=100000)
tp(cached):  1 wallclock secs ( 0.61 usr +  0.00 sys =  0.61 CPU) @ 163934.43/s (n=100000)
        ts: 24 wallclock secs (24.31 usr +  0.01 sys = 24.32 CPU) @ 4111.84/s (n=100000)
ts(cached):  1 wallclock secs ( 0.58 usr +  0.00 sys =  0.58 CPU) @ 172413.79/s (n=100000)
               Rate       dt       ts dt(cached)        tp tp(cached) ts(cached)
dt           2933/s       --     -29%       -40%      -95%       -98%       -98%
ts           4112/s      40%       --       -15%      -94%       -97%       -98%
dt(cached)   4859/s      66%      18%         --      -92%       -97%       -97%
tp          64103/s    2086%    1459%      1219%        --       -61%       -63%
tp(cached) 163934/s    5490%    3887%      3274%      156%         --        -5%
ts(cached) 172414/s    5779%    4093%      3448%      169%         5%         --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(+0900)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 41 wallclock secs (40.74 usr +  0.02 sys = 40.76 CPU) @ 2453.39/s (n=100000)
dt(cached): 26 wallclock secs (26.09 usr +  0.01 sys = 26.10 CPU) @ 3831.42/s (n=100000)
        tp:  2 wallclock secs ( 2.10 usr +  0.00 sys =  2.10 CPU) @ 47619.05/s (n=100000)
tp(cached):  1 wallclock secs ( 1.48 usr +  0.01 sys =  1.49 CPU) @ 67114.09/s (n=100000)
        ts: 27 wallclock secs (26.74 usr +  0.01 sys = 26.75 CPU) @ 3738.32/s (n=100000)
ts(cached):  1 wallclock secs ( 0.83 usr +  0.00 sys =  0.83 CPU) @ 120481.93/s (n=100000)
               Rate       dt       ts dt(cached)        tp tp(cached) ts(cached)
dt           2453/s       --     -34%       -36%      -95%       -96%       -98%
ts           3738/s      52%       --        -2%      -92%       -94%       -97%
dt(cached)   3831/s      56%       2%         --      -92%       -94%       -97%
tp          47619/s    1841%    1174%      1143%        --       -29%       -60%
tp(cached)  67114/s    2636%    1695%      1652%       41%         --       -44%
ts(cached) 120482/s    4811%    3123%      3045%      153%        80%         --
    # Subtest: America/Whitehorse(-0700)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(-0700)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 41 wallclock secs (40.43 usr +  0.02 sys = 40.45 CPU) @ 2472.19/s (n=100000)
dt(cached): 25 wallclock secs (25.80 usr +  0.01 sys = 25.81 CPU) @ 3874.47/s (n=100000)
        tp:  2 wallclock secs ( 2.10 usr +  0.00 sys =  2.10 CPU) @ 47619.05/s (n=100000)
tp(cached):  1 wallclock secs ( 1.56 usr +  0.01 sys =  1.57 CPU) @ 63694.27/s (n=100000)
        ts: 27 wallclock secs (26.86 usr +  0.01 sys = 26.87 CPU) @ 3721.62/s (n=100000)
ts(cached):  1 wallclock secs ( 1.00 usr +  0.01 sys =  1.01 CPU) @ 99009.90/s (n=100000)
              Rate        dt       ts dt(cached)        tp tp(cached) ts(cached)
dt          2472/s        --     -34%       -36%      -95%       -96%       -98%
ts          3722/s       51%       --        -4%      -92%       -94%       -96%
dt(cached)  3874/s       57%       4%         --      -92%       -94%       -96%
tp         47619/s     1826%    1180%      1129%        --       -25%       -52%
tp(cached) 63694/s     2476%    1611%      1544%       34%         --       -36%
ts(cached) 99010/s     3905%    2560%      2455%      108%        55%         --
1..44
