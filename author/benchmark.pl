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
    my $tp_parser = tzoffset(CORE::localtime) eq '-0000' ? Time::Piece->gmtime : Time::Piece->localtime;

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
        dt: 46 wallclock secs (45.78 usr +  0.02 sys = 45.80 CPU) @ 2183.41/s (n=100000)
dt(compiled): 27 wallclock secs (26.79 usr +  0.02 sys = 26.81 CPU) @ 3729.95/s (n=100000)
        tp:  0 wallclock secs ( 0.78 usr +  0.00 sys =  0.78 CPU) @ 128205.13/s (n=100000)
        ts: 32 wallclock secs (31.60 usr +  0.06 sys = 31.66 CPU) @ 3158.56/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.79 usr +  0.01 sys =  1.80 CPU) @ 55555.56/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             2183/s         --       -31%         -41%         -96%       -98%
ts             3159/s        45%         --         -15%         -94%       -98%
dt(compiled)   3730/s        71%        18%           --         -93%       -97%
ts(compiled)  55556/s      2444%      1659%        1389%           --       -57%
tp           128205/s      5772%      3959%        3337%         131%         --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    1..2
ok 2 - UTC(+0000)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 45 wallclock secs (45.19 usr +  0.02 sys = 45.21 CPU) @ 2211.90/s (n=100000)
dt(compiled): 27 wallclock secs (26.28 usr +  0.01 sys = 26.29 CPU) @ 3803.73/s (n=100000)
        tp:  0 wallclock secs ( 0.78 usr +  0.01 sys =  0.79 CPU) @ 126582.28/s (n=100000)
        ts: 32 wallclock secs (31.70 usr +  0.06 sys = 31.76 CPU) @ 3148.61/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.78 usr +  0.00 sys =  1.78 CPU) @ 56179.78/s (n=100000)
                 Rate         dt         ts dt(compiled) ts(compiled)         tp
dt             2212/s         --       -30%         -42%         -96%       -98%
ts             3149/s        42%         --         -17%         -94%       -98%
dt(compiled)   3804/s        72%        21%           --         -93%       -97%
ts(compiled)  56180/s      2440%      1684%        1377%           --       -56%
tp           126582/s      5623%      3920%        3228%         125%         --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    1..2
ok 3 - Asia/Tokyo(+0900)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 54 wallclock secs (53.77 usr +  0.02 sys = 53.79 CPU) @ 1859.08/s (n=100000)
dt(compiled): 35 wallclock secs (34.54 usr +  0.02 sys = 34.56 CPU) @ 2893.52/s (n=100000)
        tp:  0 wallclock secs ( 0.77 usr +  0.00 sys =  0.77 CPU) @ 129870.13/s (n=100000)
        ts: 32 wallclock secs (31.80 usr +  0.06 sys = 31.86 CPU) @ 3138.73/s (n=100000)
ts(compiled):  2 wallclock secs ( 1.83 usr +  0.01 sys =  1.84 CPU) @ 54347.83/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             1859/s         --         -36%       -41%         -97%       -99%
dt(compiled)   2894/s        56%           --        -8%         -95%       -98%
ts             3139/s        69%           8%         --         -94%       -98%
ts(compiled)  54348/s      2823%        1778%      1632%           --       -58%
tp           129870/s      6886%        4388%      4038%         139%         --
    # Subtest: America/Whitehorse(-0700)
    ok 1
    ok 2
    1..2
ok 4 - America/Whitehorse(-0700)
Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
        dt: 56 wallclock secs (55.43 usr +  0.03 sys = 55.46 CPU) @ 1803.10/s (n=100000)
dt(compiled): 35 wallclock secs (34.93 usr +  0.01 sys = 34.94 CPU) @ 2862.05/s (n=100000)
        tp:  1 wallclock secs ( 0.75 usr +  0.00 sys =  0.75 CPU) @ 133333.33/s (n=100000)
        ts: 32 wallclock secs (32.22 usr +  0.06 sys = 32.28 CPU) @ 3097.89/s (n=100000)
ts(compiled):  2 wallclock secs ( 2.03 usr +  0.00 sys =  2.03 CPU) @ 49261.08/s (n=100000)
                 Rate         dt dt(compiled)         ts ts(compiled)         tp
dt             1803/s         --         -37%       -42%         -96%       -99%
dt(compiled)   2862/s        59%           --        -8%         -94%       -98%
ts             3098/s        72%           8%         --         -94%       -98%
ts(compiled)  49261/s      2632%        1621%      1490%           --       -63%
tp           133333/s      7295%        4559%      4204%         171%         --
1..4
