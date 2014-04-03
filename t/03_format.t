use strict;

BEGIN {
    # Windows can't change timezone inside Perl script
    if (($ENV{TZ}||'') ne 'GMT') {
        $ENV{TZ} = 'GMT';
        exec $^X, (map { "-I\"$_\"" } @INC), $0;
    };
}

use Time::Strptime::Format;
use Test::More;

my %TEST_CASE = (
    '2014-01-01 01:23:45' => [
        {
            format => '%Y-%m-%d %H:%M:%S',
            result => [1388539425, 0],
        },
        {
            format => '%F %H:%M:%S',
            result => [1388539425, 0],
        },
        {
            format => '%Y-%m-%d %T',
            result => [1388539425, 0],
        },
        {
            format => '%F %T',
            result => [1388539425, 0],
        },
    ],
    '[0-9] 2014-01-01 [a-z] 01:23:45 [A-Z]' => [
        {
            format => '[0-9] %Y-%m-%d [a-z] %H:%M:%S [A-Z]',
            result => [1388539425, 0],
        },
        {
            format => '[0-9] %F [a-z] %H:%M:%S [A-Z]',
            result => [1388539425, 0],
        },
        {
            format => '[0-9] %Y-%m-%d [a-z] %T [A-Z]',
            result => [1388539425, 0],
        },
        {
            format => '[0-9] %F [a-z] %T [A-Z]',
            result => [1388539425, 0],
        },
    ],
    "20-Mar-2014" => [
        {
            format => "%e-%b-%Y",
            result => [1395273600, 0],
        },
        {
            format => "%d-%b-%Y",
            result => [1395273600, 0],
        },
        {
            format => "%v",
            result => [1395273600, 0],
        },
    ],
);

for my $str (keys %TEST_CASE) {
    subtest "String: $str" => sub {
        for my $wanted (@{ $TEST_CASE{$str} }) {
            my @result = Time::Strptime::Format->new($wanted->{format}, { locale => 'C' })->parse($str);
            is_deeply \@result, $wanted->{result}, "Format: $wanted->{format}";
        }
    };
}

done_testing;
