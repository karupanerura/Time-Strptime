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

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

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
