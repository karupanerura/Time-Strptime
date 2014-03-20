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

benchmark:Asia/Tokyo(-0900) C<dt=DateTime, ts=Time::Strptime, tp=Time::Piece>

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
