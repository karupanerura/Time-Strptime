package Time::Strptime;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use Carp ();
use Time::Strptime::Format;

sub strptime {
    my ($format, $text) = @_;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    return Time::Strptime::Format->new($format)->parse($text);
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Strptime - It's new $module

=head1 SYNOPSIS

    use Time::Strptime qw/strptime/;

    # function
    my $epoch_f = strptime('%Y-%m-%d %H:%M:%S', '2014-01-01 00:00:00');

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my $epoch_o = $fmt->parse('2014-01-01 00:00:00');

=head1 DESCRIPTION

Time::Strptime is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

