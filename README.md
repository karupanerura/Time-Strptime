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

    Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
            dt: 47 wallclock secs (46.49 usr +  0.08 sys = 46.57 CPU) @ 2147.31/s (n=100000)
    dt(cached): 27 wallclock secs (26.62 usr +  0.05 sys = 26.67 CPU) @ 3749.53/s (n=100000)
            tp:  1 wallclock secs ( 1.64 usr +  0.00 sys =  1.64 CPU) @ 60975.61/s (n=100000)
    tp(cached):  1 wallclock secs ( 0.81 usr +  0.00 sys =  0.81 CPU) @ 123456.79/s (n=100000)
            ts: 34 wallclock secs (33.53 usr +  0.11 sys = 33.64 CPU) @ 2972.65/s (n=100000)
    ts(cached):  1 wallclock secs ( 1.13 usr +  0.00 sys =  1.13 CPU) @ 88495.58/s (n=100000)
                   Rate       dt       ts dt(cached)        tp ts(cached) tp(cached)
    dt           2147/s       --     -28%       -43%      -96%       -98%       -98%
    ts           2973/s      38%       --       -21%      -95%       -97%       -98%
    dt(cached)   3750/s      75%      26%         --      -94%       -96%       -97%
    tp          60976/s    2740%    1951%      1526%        --       -31%       -51%
    ts(cached)  88496/s    4021%    2877%      2260%       45%         --       -28%
    tp(cached) 123457/s    5649%    4053%      3193%      102%        40%         --

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

    Benchmark: timing 100000 iterations of dt, dt(cached), tp, tp(cached), ts, ts(cached)...
            dt: 55 wallclock secs (54.70 usr +  0.11 sys = 54.81 CPU) @ 1824.48/s (n=100000)
    dt(cached): 34 wallclock secs (33.92 usr +  0.06 sys = 33.98 CPU) @ 2942.91/s (n=100000)
            tp:  2 wallclock secs ( 1.61 usr +  0.01 sys =  1.62 CPU) @ 61728.40/s (n=100000)
    tp(cached):  1 wallclock secs ( 0.79 usr +  0.00 sys =  0.79 CPU) @ 126582.28/s (n=100000)
            ts: 39 wallclock secs (39.50 usr +  0.13 sys = 39.63 CPU) @ 2523.34/s (n=100000)
    ts(cached):  2 wallclock secs ( 1.79 usr +  0.01 sys =  1.80 CPU) @ 55555.56/s (n=100000)
                   Rate       dt       ts dt(cached) ts(cached)        tp tp(cached)
    dt           1824/s       --     -28%       -38%       -97%      -97%       -99%
    ts           2523/s      38%       --       -14%       -95%      -96%       -98%
    dt(cached)   2943/s      61%      17%         --       -95%      -95%       -98%
    ts(cached)  55556/s    2945%    2102%      1788%         --      -10%       -56%
    tp          61728/s    3283%    2346%      1998%        11%        --       -51%
    tp(cached) 126582/s    6838%    4916%      4201%       128%      105%         --

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
