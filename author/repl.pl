use strict;
use warnings;
use utf8;
use feature qw/say/;

use Time::Strptime::Format;
use Time::Piece;

my $format = Time::Strptime::Format->new($ARGV[0]);

while (1) {
    print '> ';
    chomp(my $line = <STDIN>);
    my ($epoch, $offset) = eval { $format->parse($line) };
    if ($@) {
        print "ERROR: $@";
        next;
    }
    print "epoch     = $epoch\n";
    print "offset    = $offset\n";
    print "localtime = @{[ scalar localtime $epoch ]}\n";
    print "gmtime    = @{[ scalar gmtime $epoch ]}\n";
}
__END__
