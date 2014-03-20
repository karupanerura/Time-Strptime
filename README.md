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

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

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
