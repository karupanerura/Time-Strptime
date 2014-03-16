use strict;

use Test::More;

use File::Basename;

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);

my $found;
for my $tz (qw( Europe/Paris CET-1CEST )) {
    $ENV{TZ} = $tz;
    my $res = `$^X $inc $dir/strptime.pl '%Y-%m-%d %H:%M:%S' '2014-01-01 01:23:45'`;
    if ($res && $res =~ /^[0-9]+ -?[0-9]+$/) {
        $found = $tz;
        last;
    }
}

if ($found) {
    plan tests => 3;
}
else {
    plan skip_all => 'Missing tzdata on this system';
}

is `$^X $inc $dir/strptime.pl '%Y-%m-%d %H:%M:%S %z' '2014-01-01 01:23:45 -0900'`, "1388571825 -32400";
is `$^X $inc $dir/strptime.pl '%Y-%m-%d %H:%M:%S %z' '2014-01-01 01:23:45 +0900'`, "1388507025 32400";

if ($found eq 'Europe/Paris') {
    is `$^X $inc $dir/strptime.pl '%Y-%m-%d %H:%M:%S %Z' '2014-01-01 01:23:45 Europe/Paris'`, "1388535825 3600";
}
if ($found eq 'CET-1CEST') {
    is `$^X $inc $dir/strptime.pl '%Y-%m-%d %H:%M:%S %Z' '2014-01-01 01:23:45 CET-1CEST'`, "1388507025 7200";
}
