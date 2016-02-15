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

**THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.**

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a [strptime(3)](http://man.he.net/man3/strptime).

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

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

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

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

karupanerura &lt;karupa@cpan.org>
