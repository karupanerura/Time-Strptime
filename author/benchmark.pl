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
        'dt(compiled)' => sub { $dt_parser->parse_datetime($text) },
        'ts(compiled)' => sub { $ts_parser->parse($text)          },
        'dt'           => sub { DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone)->parse_datetime($text) },
        'ts'           => sub { Time::Strptime::Format->new($pattern)->parse($text)                                                  },
        'tp'           => sub { $tp_parser->strptime($text, $pattern) },
    };
}

done_testing;
__END__
    # Subtest: GMT(+0000)
    ok 1
    ok 2
    1..2
ok 1 - GMT(+0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 44 wallclock secs (43.61 usr +  0.05 sys = 43.66 CPU) @ 2290.43/s (n=100000)
dt(compiled): 25 wallclock secs (25.12 usr +  0.03 sys = 25.15 CPU) @ 3976.14/s (n=100000)
        tp:  1 wallclock secs ( 0.73 usr +  0.00 sys =  0.73 CPU) @ 136986.30/s (n=100000)
        ts: 30 wallclock secs (30.03 usr +  0.09 sys = 30.12 CPU) @ 3320.05/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.69 usr +  0.00 sys =  1.69 CPU) @ 59171.60/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             2290/s         --       -31%         -42%         -96%       -98%
ts             3320/s        45%         --         -17%         -94%       -98%
dt(compiled)   3976/s        74%        20%           --         -93%       -97%
ts(compiled)  59172/s      2483%      1682%        1388%           --       -57%
tp           136986/s      5881%      4026%        3345%         132%         --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(+0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 42 wallclock secs (42.19 usr +  0.06 sys = 42.25 CPU) @ 2366.86/s (n=100000)
dt(compiled): 26 wallclock secs (25.82 usr +  0.04 sys = 25.86 CPU) @ 3866.98/s (n=100000)
        tp:  1 wallclock secs ( 0.73 usr +  0.00 sys =  0.73 CPU) @ 136986.30/s (n=100000)
        ts: 32 wallclock secs (32.05 usr +  0.12 sys = 32.17 CPU) @ 3108.49/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.73 usr +  0.00 sys =  1.73 CPU) @ 57803.47/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             2367/s         --       -24%         -39%         -96%       -98%
ts             3108/s        31%         --         -20%         -95%       -98%
dt(compiled)   3867/s        63%        24%           --         -93%       -97%
ts(compiled)  57803/s      2342%      1760%        1395%           --       -58%
tp           136986/s      5688%      4307%        3442%         137%         --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(+0900)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 52 wallclock secs (52.25 usr +  0.07 sys = 52.32 CPU) @ 1911.31/s (n=100000)
dt(compiled): 34 wallclock secs (33.05 usr +  0.05 sys = 33.10 CPU) @ 3021.15/s (n=100000)
        tp:  0 wallclock secs ( 0.81 usr +  0.01 sys =  0.82 CPU) @ 121951.22/s (n=100000)
        ts: 33 wallclock secs (31.97 usr +  0.11 sys = 32.08 CPU) @ 3117.21/s (n=100000)
ts(compiled):  1 wallclock secs ( 1.71 usr +  0.00 sys =  1.71 CPU) @ 58479.53/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             1911/s         --         -37%       -39%         -97%       -98%
dt(compiled)   3021/s        58%           --        -3%         -95%       -98%
ts             3117/s        63%           3%         --         -95%       -97%
ts(compiled)  58480/s      2960%        1836%      1776%           --       -52%
tp           121951/s      6280%        3937%      3812%         109%         --
    # Subtest: America/Whitehorse(-0700)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(-0700)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 56 wallclock secs (55.08 usr +  0.09 sys = 55.17 CPU) @ 1812.58/s (n=100000)
dt(compiled): 37 wallclock secs (36.71 usr +  0.09 sys = 36.80 CPU) @ 2717.39/s (n=100000)
        tp:  0 wallclock secs ( 0.82 usr +  0.00 sys =  0.82 CPU) @ 121951.22/s (n=100000)
        ts: 34 wallclock secs (34.18 usr +  0.18 sys = 34.36 CPU) @ 2910.36/s (n=100000)
ts(compiled):  2 wallclock secs ( 2.03 usr +  0.00 sys =  2.03 CPU) @ 49261.08/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             1813/s         --         -33%       -38%         -96%       -99%
dt(compiled)   2717/s        50%           --        -7%         -94%       -98%
ts             2910/s        61%           7%         --         -94%       -98%
ts(compiled)  49261/s      2618%        1713%      1593%           --       -60%
tp           121951/s      6628%        4388%      4090%         148%         --
1..4
