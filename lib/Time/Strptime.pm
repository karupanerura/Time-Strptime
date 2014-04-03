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

benchmark:Asia/Tokyo(-0900) C<dt=DateTime, ts=Time::Strptime, tp=Time::Piece>

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

=head1 FAQ

=head2 What's the difference between this module and other modules?

This module is fast and not require XS. but, support epoch C<strptime> only.
L<DateTime> is very useful and stable! but, It is slow.
L<Time::Piece> is fast and useful! but, treatment of time zone is confusing. and, require XS.
L<Time::Moment> is very fast and useful! but, not support C<strptime>. and, require XS.

=head2 How to specify a time zone?

Set time zone to C<$ENV{TZ}> and call C<POSIX::tzset()>.
NOTE: C<POSIX::tzset()> is not supported on C<cygwin> and C<MSWin32>.

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

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
