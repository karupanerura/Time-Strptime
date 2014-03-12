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

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

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

# FAQ

## What's the difference between this module and other modules?

This module is fast and not require XS. but, support epoch `strptime` only.
[DateTime](https://metacpan.org/pod/DateTime) is very useful and stable! but, It is slow.
[Time::Piece](https://metacpan.org/pod/Time::Piece) is fast and useful! but, treatment of time zone is confusing. and, require XS.
[Time::Moment](https://metacpan.org/pod/Time::Moment) is very fast and useful! but, not support `strptime`. and, require XS.

## How to specify a time zone?

Set time zone to `$ENV{TZ}` and call `POSIX::tzset()`.

example:

    use Time::Strptime qw/strptime/;
    use POSIX qw/tzset/;

    local $ENV{TZ} = 'Asia/Tokyo';
    tzset();
    my $epoch_f = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
