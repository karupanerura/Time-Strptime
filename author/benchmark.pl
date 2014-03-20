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
        dt: 46 wallclock secs (45.52 usr +  0.02 sys = 45.54 CPU) @ 2195.87/s (n=100000)
dt(compiled): 27 wallclock secs (26.75 usr +  0.01 sys = 26.76 CPU) @ 3736.92/s (n=100000)
        tp:  1 wallclock secs ( 0.76 usr +  0.00 sys =  0.76 CPU) @ 131578.95/s (n=100000)
        ts: 33 wallclock secs (33.47 usr +  0.05 sys = 33.52 CPU) @ 2983.29/s (n=100000)
ts(compiled):  1 wallclock secs ( 1.12 usr +  0.00 sys =  1.12 CPU) @ 89285.71/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             2196/s         --       -26%         -41%         -98%       -98%
ts             2983/s        36%         --         -20%         -97%       -98%
dt(compiled)   3737/s        70%        25%           --         -96%       -97%
ts(compiled)  89286/s      3966%      2893%        2289%           --       -32%
tp           131579/s      5892%      4311%        3421%          47%         --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(+0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 45 wallclock secs (44.81 usr +  0.02 sys = 44.83 CPU) @ 2230.65/s (n=100000)
dt(compiled): 27 wallclock secs (26.58 usr +  0.01 sys = 26.59 CPU) @ 3760.81/s (n=100000)
        tp:  1 wallclock secs ( 0.76 usr +  0.00 sys =  0.76 CPU) @ 131578.95/s (n=100000)
        ts: 38 wallclock secs (38.34 usr +  0.06 sys = 38.40 CPU) @ 2604.17/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.78 usr +  0.00 sys =  1.78 CPU) @ 56179.78/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             2231/s         --       -14%         -41%         -96%       -98%
ts             2604/s        17%         --         -31%         -95%       -98%
dt(compiled)   3761/s        69%        44%           --         -93%       -97%
ts(compiled)  56180/s      2419%      2057%        1394%           --       -57%
tp           131579/s      5799%      4953%        3399%         134%         --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(+0900)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 53 wallclock secs (53.11 usr +  0.02 sys = 53.13 CPU) @ 1882.18/s (n=100000)
dt(compiled): 34 wallclock secs (33.98 usr +  0.02 sys = 34.00 CPU) @ 2941.18/s (n=100000)
        tp:  1 wallclock secs ( 0.75 usr +  0.00 sys =  0.75 CPU) @ 133333.33/s (n=100000)
        ts: 39 wallclock secs (38.37 usr +  0.06 sys = 38.43 CPU) @ 2602.13/s (n=100000)
ts(compiled):  1 wallclock secs ( 1.81 usr +  0.00 sys =  1.81 CPU) @ 55248.62/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             1882/s         --       -28%         -36%         -97%       -99%
ts             2602/s        38%         --         -12%         -95%       -98%
dt(compiled)   2941/s        56%        13%           --         -95%       -98%
ts(compiled)  55249/s      2835%      2023%        1778%           --       -59%
tp           133333/s      6984%      5024%        4433%         141%         --
    # Subtest: America/Whitehorse(-0700)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(-0700)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 55 wallclock secs (54.86 usr +  0.03 sys = 54.89 CPU) @ 1821.83/s (n=100000)
dt(compiled): 36 wallclock secs (35.35 usr +  0.01 sys = 35.36 CPU) @ 2828.05/s (n=100000)
        tp:  1 wallclock secs ( 0.75 usr +  0.00 sys =  0.75 CPU) @ 133333.33/s (n=100000)
        ts: 38 wallclock secs (38.43 usr +  0.06 sys = 38.49 CPU) @ 2598.08/s (n=100000)
ts(compiled):  2 wallclock secs ( 2.11 usr +  0.00 sys =  2.11 CPU) @ 47393.36/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             1822/s         --       -30%         -36%         -96%       -99%
ts             2598/s        43%         --          -8%         -95%       -98%
dt(compiled)   2828/s        55%         9%           --         -94%       -98%
ts(compiled)  47393/s      2501%      1724%        1576%           --       -64%
tp           133333/s      7219%      5032%        4615%         181%         --
1..4
