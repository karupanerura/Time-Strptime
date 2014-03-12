use strict;
use warnings;
use utf8;

use Benchmark qw/cmpthese timethese/;

use Time::Strptime::Format;
use Time::Piece;
use DateTime::Format::Strptime;
use POSIX qw/tzset/;
use Time::Local qw/timelocal/;
use Test::More;

my $pattern = '%Y-%m-%d %H:%M:%S';
my $text    = '2014-01-01 01:23:45';

sub calc_offset {
    my $offset = timelocal(CORE::gmtime(CORE::time)) - timelocal(CORE::localtime(CORE::time));
    return sprintf '%s%02d00', $offset > 0 ? '+' : '-', abs int $offset / 3600;
}

for my $time_zone (qw|GMT UTC Asia/Tokyo America/Whitehorse|) {
    local $ENV{TZ} = $time_zone;
    tzset();

    my $ts_parser = Time::Strptime::Format->new($pattern);
    my $dt_parser = DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone);
    my $tp_parser = calc_offset() eq '-0000' ? sub { Time::Piece->strptime($text, $pattern) } : sub { Time::Piece->localtime->strptime($text, $pattern) };

    subtest "${time_zone}(@{[ calc_offset() ]})" => sub {
        is([$ts_parser->parse($text)]->[0], $dt_parser->parse_datetime($text)->epoch);
        is([$ts_parser->parse($text)]->[0], $tp_parser->()->epoch);
    };

    cmpthese timethese 100000 => +{
        'dt(compiled)' => sub { $dt_parser->parse_datetime($text) },
        'ts(compiled)' => sub { $ts_parser->parse($text)          },
        'dt'           => sub { DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone)->parse_datetime($text) },
        'ts'           => sub { Time::Strptime::Format->new($pattern)->parse($text)                                                  },
        'tp'           => $tp_parser,
    };
}

done_testing;
__END__
    # Subtest: GMT(-0000)
    ok 1
    ok 2
    1..2
ok 1 - GMT(-0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 50 wallclock secs (50.42 usr +  0.08 sys = 50.50 CPU) @ 1980.20/s (n=100000)
dt(compiled): 31 wallclock secs (30.25 usr +  0.05 sys = 30.30 CPU) @ 3300.33/s (n=100000)
        tp:  1 wallclock secs ( 0.71 usr +  0.00 sys =  0.71 CPU) @ 140845.07/s (n=100000)
        ts: 28 wallclock secs (27.97 usr +  0.09 sys = 28.06 CPU) @ 3563.79/s (n=100000)
ts(compiled):  1 wallclock secs ( 1.72 usr +  0.00 sys =  1.72 CPU) @ 58139.53/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             1980/s         --         -40%       -44%         -97%       -99%
dt(compiled)   3300/s        67%           --        -7%         -94%       -98%
ts             3564/s        80%           8%         --         -94%       -97%
ts(compiled)  58140/s      2836%        1662%      1531%           --       -59%
tp           140845/s      7013%        4168%      3852%         142%         --
    # Subtest: UTC(-0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(-0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 50 wallclock secs (49.52 usr +  0.08 sys = 49.60 CPU) @ 2016.13/s (n=100000)
dt(compiled): 30 wallclock secs (29.49 usr +  0.05 sys = 29.54 CPU) @ 3385.24/s (n=100000)
        tp:  0 wallclock secs ( 0.67 usr +  0.00 sys =  0.67 CPU) @ 149253.73/s (n=100000)
        ts: 29 wallclock secs (28.18 usr +  0.10 sys = 28.28 CPU) @ 3536.07/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.68 usr +  0.00 sys =  1.68 CPU) @ 59523.81/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             2016/s         --         -40%       -43%         -97%       -99%
dt(compiled)   3385/s        68%           --        -4%         -94%       -98%
ts             3536/s        75%           4%         --         -94%       -98%
ts(compiled)  59524/s      2852%        1658%      1583%           --       -60%
tp           149254/s      7303%        4309%      4121%         151%         --
    # Subtest: Asia/Tokyo(-0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(-0900)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 59 wallclock secs (59.07 usr +  0.10 sys = 59.17 CPU) @ 1690.05/s (n=100000)
dt(compiled): 38 wallclock secs (38.16 usr +  0.07 sys = 38.23 CPU) @ 2615.75/s (n=100000)
        tp:  2 wallclock secs ( 1.84 usr +  0.00 sys =  1.84 CPU) @ 54347.83/s (n=100000)
        ts: 30 wallclock secs (30.21 usr +  0.11 sys = 30.32 CPU) @ 3298.15/s (n=100000)
ts(compiled):  3 wallclock secs ( 2.61 usr +  0.01 sys =  2.62 CPU) @ 38167.94/s (n=100000)
                Rate         dt dt(compiled)         ts ts(compiled)          tp
dt            1690/s         --         -35%       -49%         -96%        -97%
dt(compiled)  2616/s        55%           --       -21%         -93%        -95%
ts            3298/s        95%          26%         --         -91%        -94%
ts(compiled) 38168/s      2158%        1359%      1057%           --        -30%
tp           54348/s      3116%        1978%      1548%          42%          --
    # Subtest: America/Whitehorse(+0700)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(+0700)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 63 wallclock secs (62.98 usr +  0.12 sys = 63.10 CPU) @ 1584.79/s (n=100000)
dt(compiled): 41 wallclock secs (40.34 usr +  0.07 sys = 40.41 CPU) @ 2474.63/s (n=100000)
        tp:  2 wallclock secs ( 1.83 usr +  0.00 sys =  1.83 CPU) @ 54644.81/s (n=100000)
        ts: 30 wallclock secs (30.11 usr +  0.11 sys = 30.22 CPU) @ 3309.07/s (n=100000)
ts(compiled):  3 wallclock secs ( 2.60 usr +  0.01 sys =  2.61 CPU) @ 38314.18/s (n=100000)
                Rate         dt dt(compiled)         ts ts(compiled)          tp
dt            1585/s         --         -36%       -52%         -96%        -97%
dt(compiled)  2475/s        56%           --       -25%         -94%        -95%
ts            3309/s       109%          34%         --         -91%        -94%
ts(compiled) 38314/s      2318%        1448%      1058%           --        -30%
tp           54645/s      3348%        2108%      1551%          43%          --
1..4
