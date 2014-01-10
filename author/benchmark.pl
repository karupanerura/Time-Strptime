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
        is($ts_parser->parse($text), $dt_parser->parse_datetime($text)->epoch);
        is($ts_parser->parse($text), $tp_parser->()->epoch);
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
        dt: 52 wallclock secs (51.51 usr +  0.05 sys = 51.56 CPU) @ 1939.49/s (n=100000)
dt(compiled): 32 wallclock secs (31.79 usr +  0.04 sys = 31.83 CPU) @ 3141.69/s (n=100000)
        tp:  1 wallclock secs ( 0.86 usr +  0.00 sys =  0.86 CPU) @ 116279.07/s (n=100000)
        ts: 32 wallclock secs (31.41 usr +  0.13 sys = 31.54 CPU) @ 3170.58/s (n=100000)
ts(compiled):  1 wallclock secs ( 1.69 usr +  0.00 sys =  1.69 CPU) @ 59171.60/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             1939/s         --         -38%       -39%         -97%       -98%
dt(compiled)   3142/s        62%           --        -1%         -95%       -97%
ts             3171/s        63%           1%         --         -95%       -97%
ts(compiled)  59172/s      2951%        1783%      1766%           --       -49%
tp           116279/s      5895%        3601%      3567%          97%         --
    # Subtest: UTC(-0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(-0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 52 wallclock secs (50.98 usr +  0.05 sys = 51.03 CPU) @ 1959.63/s (n=100000)
dt(compiled): 30 wallclock secs (30.11 usr +  0.02 sys = 30.13 CPU) @ 3318.95/s (n=100000)
        tp:  1 wallclock secs ( 0.79 usr +  0.00 sys =  0.79 CPU) @ 126582.28/s (n=100000)
        ts: 30 wallclock secs (30.46 usr +  0.11 sys = 30.57 CPU) @ 3271.18/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.87 usr +  0.00 sys =  1.87 CPU) @ 53475.94/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             1960/s         --       -40%         -41%         -96%       -98%
ts             3271/s        67%         --          -1%         -94%       -97%
dt(compiled)   3319/s        69%         1%           --         -94%       -97%
ts(compiled)  53476/s      2629%      1535%        1511%           --       -58%
tp           126582/s      6359%      3770%        3714%         137%         --
    # Subtest: Asia/Tokyo(-0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(-0900)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 62 wallclock secs (61.18 usr +  0.06 sys = 61.24 CPU) @ 1632.92/s (n=100000)
dt(compiled): 39 wallclock secs (39.10 usr +  0.04 sys = 39.14 CPU) @ 2554.93/s (n=100000)
        tp:  2 wallclock secs ( 1.86 usr +  0.00 sys =  1.86 CPU) @ 53763.44/s (n=100000)
        ts: 31 wallclock secs (31.35 usr +  0.11 sys = 31.46 CPU) @ 3178.64/s (n=100000)
ts(compiled):  3 wallclock secs ( 2.60 usr +  0.00 sys =  2.60 CPU) @ 38461.54/s (n=100000)
                Rate         dt dt(compiled)         ts ts(compiled)          tp
dt            1633/s         --         -36%       -49%         -96%        -97%
dt(compiled)  2555/s        56%           --       -20%         -93%        -95%
ts            3179/s        95%          24%         --         -92%        -94%
ts(compiled) 38462/s      2255%        1405%      1110%           --        -28%
tp           53763/s      3192%        2004%      1591%          40%          --
    # Subtest: America/Whitehorse(+0800)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(+0800)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 62 wallclock secs (62.15 usr +  0.06 sys = 62.21 CPU) @ 1607.46/s (n=100000)
dt(compiled): 40 wallclock secs (40.90 usr +  0.05 sys = 40.95 CPU) @ 2442.00/s (n=100000)
        tp:  2 wallclock secs ( 1.85 usr +  0.00 sys =  1.85 CPU) @ 54054.05/s (n=100000)
        ts: 31 wallclock secs (31.54 usr +  0.11 sys = 31.65 CPU) @ 3159.56/s (n=100000)
ts(compiled):  3 wallclock secs ( 2.63 usr +  0.00 sys =  2.63 CPU) @ 38022.81/s (n=100000)
                Rate         dt dt(compiled)         ts ts(compiled)          tp
dt            1607/s         --         -34%       -49%         -96%        -97%
dt(compiled)  2442/s        52%           --       -23%         -94%        -95%
ts            3160/s        97%          29%         --         -92%        -94%
ts(compiled) 38023/s      2265%        1457%      1103%           --        -30%
tp           54054/s      3263%        2114%      1611%          42%          --
1..4
