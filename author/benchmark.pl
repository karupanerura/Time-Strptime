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
        dt: 39 wallclock secs (38.31 usr +  0.28 sys = 38.59 CPU) @ 2591.34/s (n=100000)
dt(cached): 23 wallclock secs (22.98 usr +  0.17 sys = 23.15 CPU) @ 4319.65/s (n=100000)
        tp:  1 wallclock secs ( 0.92 usr +  0.00 sys =  0.92 CPU) @ 108695.65/s (n=100000)
tp(cached):  1 wallclock secs ( 0.41 usr + -0.01 sys =  0.40 CPU) @ 250000.00/s (n=100000)
        ts: 32 wallclock secs (32.44 usr +  0.24 sys = 32.68 CPU) @ 3059.98/s (n=100000)
ts(cached):  1 wallclock secs ( 0.84 usr +  0.00 sys =  0.84 CPU) @ 119047.62/s (n=100000)
               Rate       dt       ts dt(cached)        tp ts(cached) tp(cached)
dt           2591/s       --     -15%       -40%      -98%       -98%       -99%
ts           3060/s      18%       --       -29%      -97%       -97%       -99%
dt(cached)   4320/s      67%      41%         --      -96%       -96%       -98%
tp         108696/s    4095%    3452%      2416%        --        -9%       -57%
ts(cached) 119048/s    4494%    3790%      2656%       10%         --       -52%
tp(cached) 250000/s    9547%    8070%      5687%      130%       110%         --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(+0000)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 39 wallclock secs (38.57 usr +  0.29 sys = 38.86 CPU) @ 2573.34/s (n=100000)
dt(cached): 24 wallclock secs (22.99 usr +  0.16 sys = 23.15 CPU) @ 4319.65/s (n=100000)
        tp:  1 wallclock secs ( 0.92 usr +  0.01 sys =  0.93 CPU) @ 107526.88/s (n=100000)
tp(cached):  0 wallclock secs ( 0.40 usr +  0.00 sys =  0.40 CPU) @ 250000.00/s (n=100000)
        ts: 33 wallclock secs (32.36 usr +  0.24 sys = 32.60 CPU) @ 3067.48/s (n=100000)
ts(cached):  1 wallclock secs ( 0.83 usr +  0.01 sys =  0.84 CPU) @ 119047.62/s (n=100000)
               Rate       dt       ts dt(cached)        tp ts(cached) tp(cached)
dt           2573/s       --     -16%       -40%      -98%       -98%       -99%
ts           3067/s      19%       --       -29%      -97%       -97%       -99%
dt(cached)   4320/s      68%      41%         --      -96%       -96%       -98%
tp         107527/s    4078%    3405%      2389%        --       -10%       -57%
ts(cached) 119048/s    4526%    3781%      2656%       11%         --       -52%
tp(cached) 250000/s    9615%    8050%      5687%      133%       110%         --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(+0900)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 46 wallclock secs (45.66 usr +  0.33 sys = 45.99 CPU) @ 2174.39/s (n=100000)
dt(cached): 30 wallclock secs (29.21 usr +  0.21 sys = 29.42 CPU) @ 3399.05/s (n=100000)
        tp:  1 wallclock secs ( 0.94 usr +  0.01 sys =  0.95 CPU) @ 105263.16/s (n=100000)
tp(cached):  0 wallclock secs ( 0.40 usr +  0.00 sys =  0.40 CPU) @ 250000.00/s (n=100000)
        ts: 38 wallclock secs (37.21 usr +  0.28 sys = 37.49 CPU) @ 2667.38/s (n=100000)
ts(cached):  2 wallclock secs ( 1.42 usr +  0.01 sys =  1.43 CPU) @ 69930.07/s (n=100000)
               Rate       dt       ts dt(cached) ts(cached)        tp tp(cached)
dt           2174/s       --     -18%       -36%       -97%      -98%       -99%
ts           2667/s      23%       --       -22%       -96%      -97%       -99%
dt(cached)   3399/s      56%      27%         --       -95%      -97%       -99%
ts(cached)  69930/s    3116%    2522%      1957%         --      -34%       -72%
tp         105263/s    4741%    3846%      2997%        51%        --       -58%
tp(cached) 250000/s   11397%    9272%      7255%       257%      137%         --
    # Subtest: America/Whitehorse(-0700)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(-0700)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 62 wallclock secs (58.29 usr +  1.03 sys = 59.32 CPU) @ 1685.77/s (n=100000)
dt(cached): 34 wallclock secs (33.41 usr +  0.44 sys = 33.85 CPU) @ 2954.21/s (n=100000)
        tp:  1 wallclock secs ( 0.91 usr +  0.01 sys =  0.92 CPU) @ 108695.65/s (n=100000)
tp(cached):  1 wallclock secs ( 0.39 usr +  0.01 sys =  0.40 CPU) @ 250000.00/s (n=100000)
            (warning: too few iterations for a reliable count)
        ts: 47 wallclock secs (44.37 usr +  0.69 sys = 45.06 CPU) @ 2219.26/s (n=100000)
ts(cached):  2 wallclock secs ( 1.50 usr +  0.01 sys =  1.51 CPU) @ 66225.17/s (n=100000)
               Rate       dt       ts dt(cached) ts(cached)        tp tp(cached)
dt           1686/s       --     -24%       -43%       -97%      -98%       -99%
ts           2219/s      32%       --       -25%       -97%      -98%       -99%
dt(cached)   2954/s      75%      33%         --       -96%      -97%       -99%
ts(cached)  66225/s    3828%    2884%      2142%         --      -39%       -74%
tp         108696/s    6348%    4798%      3579%        64%        --       -57%
tp(cached) 250000/s   14730%   11165%      8363%       278%      130%         --
1..4
