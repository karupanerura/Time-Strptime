package Time::Strptime;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use parent qw/Exporter/;
our @EXPORT_OK = qw/strptime/;

use Carp ();
use Time::Strptime::Format;

my %instance_cache;
sub strptime {
    my ($format_text, $date_text) = @_;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    my $format = $instance_cache{$format_text} ||= Time::Strptime::Format->new($format_text);
    return $format->parse($date_text);
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Strptime - parse date and time string.

=head1 SYNOPSIS

    use Time::Strptime qw/strptime/;

    # function
    my ($epoch_f, $offset_f) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my ($epoch_o, $offset_o) = $fmt->parse('2014-01-01 00:00:00');

=head1 DESCRIPTION

B<THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a L<strptime(3)>.

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) C<dt=DateTime, ts=Time::Strptime, tp=Time::Piece>

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

benchmark:Asia/Tokyo(-0900) C<dt=DateTime, ts=Time::Strptime, tp=Time::Piece>

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

=head1 FAQ

=head2 What's the difference between this module and other modules?

This module is fast and not require XS. but, support epoch C<strptime> only.
L<DateTime> is very useful and stable! but, It is slow.
L<Time::Piece> is fast and useful! but, treatment of time zone is confusing. and, require XS.
L<Time::Moment> is very fast and useful! but, not support C<strptime>. and, require XS.

=head2 How to specify a time zone?

Set time zone to C<$ENV{TZ}> and call C<POSIX::tzset()>.

example:

    use Time::Strptime qw/strptime/;
    use POSIX qw/tzset/;

    local $ENV{TZ} = 'Asia/Tokyo';
    tzset();
    my $epoch_f = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
