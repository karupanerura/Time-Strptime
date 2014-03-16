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

benchmark:Asia/Tokyo(-0900) C<dt=DateTime, ts=Time::Strptime, tp=Time::Piece>

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
