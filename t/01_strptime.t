use strict;
use Test::More;

use Time::Strptime qw/strptime/;
use POSIX qw/tzset/;

local $ENV{TZ} = 'GMT';
tzset();
is strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 01:23:45'), 1388539425;

local $ENV{TZ} = 'Asia/Tokyo';
tzset();
is strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 01:23:45'), 1388507025;

done_testing;

