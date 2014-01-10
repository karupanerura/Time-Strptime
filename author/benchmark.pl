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
        dt: 45 wallclock secs (45.37 usr +  0.02 sys = 45.39 CPU) @ 2203.13/s (n=100000)
dt(compiled): 28 wallclock secs (27.43 usr +  0.01 sys = 27.44 CPU) @ 3644.31/s (n=100000)
        tp:  0 wallclock secs ( 0.69 usr +  0.00 sys =  0.69 CPU) @ 144927.54/s (n=100000)
        ts: 23 wallclock secs (22.65 usr +  0.04 sys = 22.69 CPU) @ 4407.23/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.55 usr +  0.00 sys =  1.55 CPU) @ 64516.13/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             2203/s         --         -40%       -50%         -97%       -98%
dt(compiled)   3644/s        65%           --       -17%         -94%       -97%
ts             4407/s       100%          21%         --         -93%       -97%
ts(compiled)  64516/s      2828%        1670%      1364%           --       -55%
tp           144928/s      6478%        3877%      3188%         125%         --
    # Subtest: UTC(-0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(-0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 46 wallclock secs (45.71 usr +  0.03 sys = 45.74 CPU) @ 2186.27/s (n=100000)
dt(compiled): 27 wallclock secs (27.23 usr +  0.01 sys = 27.24 CPU) @ 3671.07/s (n=100000)
        tp:  1 wallclock secs ( 0.68 usr +  0.00 sys =  0.68 CPU) @ 147058.82/s (n=100000)
        ts: 23 wallclock secs (22.89 usr +  0.05 sys = 22.94 CPU) @ 4359.20/s (n=100000)
ts(compiled):  1 wallclock secs ( 1.53 usr +  0.00 sys =  1.53 CPU) @ 65359.48/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             2186/s         --         -40%       -50%         -97%       -99%
dt(compiled)   3671/s        68%           --       -16%         -94%       -98%
ts             4359/s        99%          19%         --         -93%       -97%
ts(compiled)  65359/s      2890%        1680%      1399%           --       -56%
tp           147059/s      6626%        3906%      3274%         125%         --
    # Subtest: Asia/Tokyo(-0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(-0900)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 54 wallclock secs (53.66 usr +  0.03 sys = 53.69 CPU) @ 1862.54/s (n=100000)
dt(compiled): 35 wallclock secs (34.35 usr +  0.02 sys = 34.37 CPU) @ 2909.51/s (n=100000)
        tp:  1 wallclock secs ( 1.64 usr +  0.00 sys =  1.64 CPU) @ 60975.61/s (n=100000)
        ts: 24 wallclock secs (23.49 usr +  0.04 sys = 23.53 CPU) @ 4249.89/s (n=100000)
ts(compiled):  2 wallclock secs ( 2.28 usr +  0.00 sys =  2.28 CPU) @ 43859.65/s (n=100000)
                Rate         dt dt(compiled)         ts ts(compiled)          tp
dt            1863/s         --         -36%       -56%         -96%        -97%
dt(compiled)  2910/s        56%           --       -32%         -93%        -95%
ts            4250/s       128%          46%         --         -90%        -93%
ts(compiled) 43860/s      2255%        1407%       932%           --        -28%
tp           60976/s      3174%        1996%      1335%          39%          --
    # Subtest: America/Whitehorse(+0800)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(+0800)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 56 wallclock secs (55.38 usr +  0.03 sys = 55.41 CPU) @ 1804.73/s (n=100000)
dt(compiled): 36 wallclock secs (36.09 usr +  0.02 sys = 36.11 CPU) @ 2769.32/s (n=100000)
        tp:  1 wallclock secs ( 1.57 usr +  0.00 sys =  1.57 CPU) @ 63694.27/s (n=100000)
        ts: 22 wallclock secs (23.64 usr +  0.04 sys = 23.68 CPU) @ 4222.97/s (n=100000)
ts(compiled):  3 wallclock secs ( 2.43 usr +  0.00 sys =  2.43 CPU) @ 41152.26/s (n=100000)
                Rate         dt dt(compiled)         ts ts(compiled)          tp
dt            1805/s         --         -35%       -57%         -96%        -97%
dt(compiled)  2769/s        53%           --       -34%         -93%        -96%
ts            4223/s       134%          52%         --         -90%        -93%
ts(compiled) 41152/s      2180%        1386%       874%           --        -35%
tp           63694/s      3429%        2200%      1408%          55%          --
1..4
