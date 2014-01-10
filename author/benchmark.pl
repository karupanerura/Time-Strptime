use strict;
use warnings;
use utf8;

use Benchmark qw/cmpthese timethese/;

use Time::Strptime::Format;
use Time::Piece;
use DateTime::Format::Strptime;
use POSIX qw/tzset/;
use Time::Local qw/timelocal/;
use Test::More;

my $pattern = '%Y-%m-%d %H:%M:%S';
my $text    = '2014-01-01 01:23:45';

sub calc_offset {
    my $offset = timelocal(CORE::gmtime(CORE::time)) - timelocal(CORE::localtime(CORE::time));
    return sprintf '%s%02d00', $offset > 0 ? '+' : '-', abs int $offset / 3600;
}

for my $time_zone (qw|GMT UTC Asia/Tokyo America/Whitehorse|) {
    local $ENV{TZ} = $time_zone;
    tzset();

    my $ts_parser = Time::Strptime::Format->new($pattern);
    my $dt_parser = DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone);
    my $tp_parser = calc_offset() eq '-0000' ? sub { Time::Piece->strptime($text, $pattern) } : sub { Time::Piece->localtime->strptime($text, $pattern) };

    subtest "${time_zone}(@{[ calc_offset() ]})" => sub {
        is($ts_parser->parse($text), $dt_parser->parse_datetime($text)->epoch);
        is($ts_parser->parse($text), $tp_parser->()->epoch);
    };

    cmpthese timethese 200000 => +{
        # 'dt(compiled)' => sub { $dt_parser->parse_datetime($text) },
        'ts(compiled)' => sub { $ts_parser->parse($text)          },
        # 'dt'           => sub { DateTime::Format::Strptime->new(pattern => $pattern)->parse_datetime($text) },
        # 'ts'           => sub { Time::Strptime::Format->new($pattern)->parse($text)                         },
        'tp'           => $tp_parser,
    };
}

done_testing;
