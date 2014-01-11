# NAME

Time::Strptime - parse date and time string.

# SYNOPSIS

    use Time::Strptime qw/strptime/;

    # function
    my $epoch_f = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my $epoch_o = $fmt->parse('2014-01-01 00:00:00');

# DESCRIPTION

__THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.__

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a [strptime(3)](http://man.he.net/man3/strptime).

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

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

benchmark:Asia/Tokyo(-0900) `dt=DateTime, ts=Time::Strptime, tp=Time::Piece`

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
