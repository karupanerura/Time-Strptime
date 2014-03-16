# NAME

Time::Strptime - parse date and time string.

# SYNOPSIS

    use Time::Strptime qw/strptime/;

    # function
    my ($epoch_f, $offset_f) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my ($epoch_o, $offset_o) = $fmt->parse('2014-01-01 00:00:00');

# DESCRIPTION

__THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.__

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a [strptime(3)](http://man.he.net/man3/strptime).

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

    Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
                dt: 45 wallclock secs (44.24 usr +  0.02 sys = 44.26 CPU) @ 2259.38/s (n=100000)
    dt(compiled): 26 wallclock secs (26.43 usr +  0.01 sys = 26.44 CPU) @ 3782.15/s (n=100000)
            tp:  2 wallclock secs ( 1.55 usr +  0.00 sys =  1.55 CPU) @ 64516.13/s (n=100000)
            ts: 30 wallclock secs (30.17 usr +  0.05 sys = 30.22 CPU) @ 3309.07/s (n=100000)
    ts(compiled):  1 wallclock secs ( 1.51 usr +  0.00 sys =  1.51 CPU) @ 66225.17/s (n=100000)
                    Rate         dt         ts dt(compiled)          tp ts(compiled)
    dt            2259/s         --       -32%         -40%        -96%         -97%
    ts            3309/s        46%         --         -13%        -95%         -95%
    dt(compiled)  3782/s        67%        14%           --        -94%         -94%
    tp           64516/s      2755%      1850%        1606%          --          -3%
    ts(compiled) 66225/s      2831%      1901%        1651%          3%           --

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

    Benchmark: timing 100000 iterations of dt, dt(compiled), tp, ts, ts(compiled)...
                dt: 53 wallclock secs (53.30 usr +  0.02 sys = 53.32 CPU) @ 1875.47/s (n=100000)
    dt(compiled): 34 wallclock secs (33.96 usr +  0.01 sys = 33.97 CPU) @ 2943.77/s (n=100000)
            tp:  2 wallclock secs ( 1.60 usr +  0.00 sys =  1.60 CPU) @ 62500.00/s (n=100000)
            ts: 31 wallclock secs (31.36 usr +  0.05 sys = 31.41 CPU) @ 3183.70/s (n=100000)
    ts(compiled):  3 wallclock secs ( 2.26 usr +  0.00 sys =  2.26 CPU) @ 44247.79/s (n=100000)
                    Rate         dt dt(compiled)         ts ts(compiled)          tp
    dt            1875/s         --         -36%       -41%         -96%        -97%
    dt(compiled)  2944/s        57%           --        -8%         -93%        -95%
    ts            3184/s        70%           8%         --         -93%        -95%
    ts(compiled) 44248/s      2259%        1403%      1290%           --        -29%
    tp           62500/s      3232%        2023%      1863%          41%          --

# FAQ

## What's the difference between this module and other modules?

This module is fast and not require XS. but, support epoch `strptime` only.
[DateTime](https://metacpan.org/pod/DateTime) is very useful and stable! but, It is slow.
[Time::Piece](https://metacpan.org/pod/Time::Piece) is fast and useful! but, treatment of time zone is confusing. and, require XS.
[Time::Moment](https://metacpan.org/pod/Time::Moment) is very fast and useful! but, not support `strptime`. and, require XS.

## How to specify a time zone?

Set time zone to `$ENV{TZ}` and call `POSIX::tzset()`.
NOTE: `POSIX::tzset()` is not supported on `cygwin` and `MSWin32`.

example:

    use Time::Strptime qw/strptime/;
    use POSIX qw/tzset/;

    local $ENV{TZ} = 'Asia/Tokyo';
    tzset();
    my ($epoch, $offset) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

And, This code is same as:

    use Time::Strptime::Format;

    my $format = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', { time_zone => 'Asia/Tokyo' });
    my ($epoch, $offset) = $format->parse('2014-01-01 00:00:00');

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
