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
    my $epoch_f = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my $epoch_o = $fmt->parse('2014-01-01 00:00:00');

=head1 DESCRIPTION

B<THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

Time::Strptime is pure perl date and time string parser.
In other words, This is pure perl implementation a L<strptime(3)>.

This module allows you to perform better by pre-compile the format by string.

benchmark:GMT(-0000) C<dt=DateTime, ts=Time::Strptime, tp=Time::Piece>

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

benchmark:Asia/Tokyo(-0900) C<dt=DateTime, ts=Time::Strptime, tp=Time::Piece>

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
