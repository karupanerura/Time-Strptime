use strict;

use Time::Strptime::Format;
use Test::More;

subtest 'year 0050' => sub {
    for my $strict (0, 1) {
        subtest "strict: $strict" => sub {
            my ($epoch, $offset) = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', {
                time_zone => 'GMT',
                strict    => 0,
            })->parse('0050-01-01 00:00:00');
            is $epoch, -60589296000, 'epoch';
            is $offset, 0,           'offset';
        };
    }
};

subtest 'year 2020' => sub {
    for my $strict (0, 1) {
        subtest "strict: $strict" => sub {
            my ($epoch, $offset) = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S', {
                time_zone => 'GMT',
                strict    => 0,
            })->parse('2020-01-01 00:00:00');
            is $epoch, 1577836800, 'epoch';
            is $offset, 0,         'offset';
        };
    }
};

done_testing;
