use strict;

BEGIN {
    # Windows can't change timezone inside Perl script
    if (($ENV{TZ}||'') ne 'GMT') {
        $ENV{TZ} = 'GMT';
        exec $^X, (map { "-I\"$_\"" } @INC), $0;
    };
}

use Time::Strptime qw/strptime/;
use Test::More tests => 2;

my ($epoch, $offset) = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 01:23:45');
is $epoch,  1388539425, 'epoch  OK';
is $offset, 0,          'offset OK';
