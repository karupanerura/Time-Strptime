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
        dt: 37 wallclock secs (36.29 usr +  0.12 sys = 36.41 CPU) @ 2746.50/s (n=100000)
dt(cached): 20 wallclock secs (20.66 usr +  0.07 sys = 20.73 CPU) @ 4823.93/s (n=100000)
        tp:  0 wallclock secs ( 0.91 usr +  0.01 sys =  0.92 CPU) @ 108695.65/s (n=100000)
tp(cached):  1 wallclock secs ( 0.46 usr +  0.00 sys =  0.46 CPU) @ 217391.30/s (n=100000)
        ts: 28 wallclock secs (28.13 usr +  0.17 sys = 28.30 CPU) @ 3533.57/s (n=100000)
ts(cached):  1 wallclock secs ( 0.68 usr +  0.01 sys =  0.69 CPU) @ 144927.54/s (n=100000)
               Rate       dt       ts dt(cached)        tp ts(cached) tp(cached)
dt           2746/s       --     -22%       -43%      -97%       -98%       -99%
ts           3534/s      29%       --       -27%      -97%       -98%       -98%
dt(cached)   4824/s      76%      37%         --      -96%       -97%       -98%
tp         108696/s    3858%    2976%      2153%        --       -25%       -50%
ts(cached) 144928/s    5177%    4001%      2904%       33%         --       -33%
tp(cached) 217391/s    7815%    6052%      4407%      100%        50%         --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(+0000)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 37 wallclock secs (36.91 usr +  0.13 sys = 37.04 CPU) @ 2699.78/s (n=100000)
dt(cached): 20 wallclock secs (21.26 usr +  0.07 sys = 21.33 CPU) @ 4688.23/s (n=100000)
        tp:  1 wallclock secs ( 0.91 usr +  0.01 sys =  0.92 CPU) @ 108695.65/s (n=100000)
tp(cached):  0 wallclock secs ( 0.44 usr +  0.00 sys =  0.44 CPU) @ 227272.73/s (n=100000)
        ts: 29 wallclock secs (28.03 usr +  0.17 sys = 28.20 CPU) @ 3546.10/s (n=100000)
ts(cached):  1 wallclock secs ( 0.67 usr +  0.01 sys =  0.68 CPU) @ 147058.82/s (n=100000)
               Rate       dt       ts dt(cached)        tp ts(cached) tp(cached)
dt           2700/s       --     -24%       -42%      -98%       -98%       -99%
ts           3546/s      31%       --       -24%      -97%       -98%       -98%
dt(cached)   4688/s      74%      32%         --      -96%       -97%       -98%
tp         108696/s    3926%    2965%      2218%        --       -26%       -52%
ts(cached) 147059/s    5347%    4047%      3037%       35%         --       -35%
tp(cached) 227273/s    8318%    6309%      4748%      109%        55%         --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(+0900)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 43 wallclock secs (43.40 usr +  0.15 sys = 43.55 CPU) @ 2296.21/s (n=100000)
dt(cached): 28 wallclock secs (27.09 usr +  0.09 sys = 27.18 CPU) @ 3679.18/s (n=100000)
        tp:  1 wallclock secs ( 0.95 usr +  0.01 sys =  0.96 CPU) @ 104166.67/s (n=100000)
tp(cached):  0 wallclock secs ( 0.43 usr +  0.00 sys =  0.43 CPU) @ 232558.14/s (n=100000)
        ts: 34 wallclock secs (33.48 usr +  0.18 sys = 33.66 CPU) @ 2970.89/s (n=100000)
ts(cached):  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 95238.10/s (n=100000)
               Rate       dt       ts dt(cached) ts(cached)        tp tp(cached)
dt           2296/s       --     -23%       -38%       -98%      -98%       -99%
ts           2971/s      29%       --       -19%       -97%      -97%       -99%
dt(cached)   3679/s      60%      24%         --       -96%      -96%       -98%
ts(cached)  95238/s    4048%    3106%      2489%         --       -9%       -59%
tp         104167/s    4436%    3406%      2731%         9%        --       -55%
tp(cached) 232558/s   10028%    7728%      6221%       144%      123%         --
    # Subtest: America/Whitehorse(-0800)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(-0800)
Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
        dt: 45 wallclock secs (44.85 usr +  0.14 sys = 44.99 CPU) @ 2222.72/s (n=100000)
dt(cached): 29 wallclock secs (28.48 usr +  0.09 sys = 28.57 CPU) @ 3500.18/s (n=100000)
        tp:  1 wallclock secs ( 0.95 usr +  0.01 sys =  0.96 CPU) @ 104166.67/s (n=100000)
tp(cached):  1 wallclock secs ( 0.43 usr +  0.00 sys =  0.43 CPU) @ 232558.14/s (n=100000)
        ts: 34 wallclock secs (34.27 usr +  0.18 sys = 34.45 CPU) @ 2902.76/s (n=100000)
ts(cached):  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 90090.09/s (n=100000)
               Rate       dt       ts dt(cached) ts(cached)        tp tp(cached)
dt           2223/s       --     -23%       -36%       -98%      -98%       -99%
ts           2903/s      31%       --       -17%       -97%      -97%       -99%
dt(cached)   3500/s      57%      21%         --       -96%      -97%       -98%
ts(cached)  90090/s    3953%    3004%      2474%         --      -14%       -61%
tp         104167/s    4586%    3489%      2876%        16%        --       -55%
tp(cached) 232558/s   10363%    7912%      6544%       158%      123%         --
1..4
