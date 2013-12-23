package Time::Strptime::Format;
use strict;
use warnings;
use utf8;
use 5.10.0;

use Carp ();
use Time::Local ();
use POSIX qw/tzset/;

our $VERSION = 0.01;

our %DEFAULT_HANDLER = (
    '%' => [char        => '%' ],
    A   => ['UNSUPPORTED'],
    a   => ['UNSUPPORTED'],
    B   => ['UNSUPPORTED'],
    b   => ['UNSUPPORTED'],
    C   => [SKIP        => q{[0-9]{2}} ],
    c   => ['UNSUPPORTED'],
    D   => [extend      => q{%m/%d/%Y}                    ],
    d   => [day         => ['0[1-9]','[12][0-9]','3[01]'] ],
    e   => [day         => [' [1-9]','[12][0-9]','3[01]'] ],
    F   => [extend      => q{%Y-%m-%d} ],
    G   => ['UNSUPPORTED'],
    g   => ['UNSUPPORTED'],
    H   => [hour24      => ['[01][0-9]','2[0-3]'] ],
    h   => [extend      => q{%b}                     ],
    I   => ['UNSUPPORTED'],
    j   => [day365      => ['00[1-9]','[12][0-9][0-9]','3[0-5][0-9]','36[0-6]'] ],
    k   => [hour24      => ['[ 1][0-9]','2[0-3]'] ],
    l   => ['UNSUPPORTED'],
    M   => [minute      => q{[0-5][0-9]}          ],
    m   => [month       => ['0[1-9]','1[0-2]']    ],
    n   => [char        => "\n"                   ],
    p   => ['UNSUPPORTED'],
    R   => [extend      => q{%H:%M}               ],
    r   => [extend      => q{%I:%M:%S %p}         ],
    S   => [second      => ['[0-5][0-9]','60']    ],
    s   => [epoch       => q{[0-9]+}              ],
    T   => [extend      => q{%H:%M:%S}            ],
    t   => [char        => "\t"                   ],
    U   => ['UNSUPPORTED'],
    u   => ['UNSUPPORTED'],
    V   => ['UNSUPPORTED'],
    v   => [extend      => q{%e-%b-%Y} ],
    W   => ['UNSUPPORTED'],
    w   => ['UNSUPPORTED'],
    X   => ['UNSUPPORTED'],
    x   => ['UNSUPPORTED'],
    Y   => [year        => q{[0-9]{4}}],
    y   => ['UNSUPPORTED'],
    Z   => [timezone    => q{[A-Z]+}],
    z   => [offset      => q{[-+][0-9]{4}}],
);

use Class::Accessor::Lite rw => [qw/format/];

sub new {
    my ($class, $format, $handler) = @_;
    $handler ||= +{};

    return bless +{
        format   => $format,
        _handler => +{
            %DEFAULT_HANDLER,
            %$handler,
        },
    } => $class;
}

sub parse {
    my $self = shift;
    return $self->_parser->(@_);
}

sub _parser {
    my $self = shift;
    return $self->{_parser}{$self->{format}} ||= $self->_compile_format;
}

sub _compile_format {
    my $self = shift;
    my $format = $self->{format};
    warn $format;

    my @types;
    $format =~ s{%(.)}{$self->_assemble_format($1, \@types)}ge;
    use Data::Dumper;
    warn Dumper +{
        format => $format,
        types  => \@types,
    };

    my $parser_src = <<EOD;
sub {
    my \$text = shift;
    if (my \@matches = \$text =~ m{$format}) {
        my \%%stash;
        \%s;
    }
    else {
        Carp::croak "cannot parse datetime. text: \$text, format: \%s";
    }
}
EOD

    my $formatter_src = '';
    for my $type (@types) {
        $formatter_src .= sprintf <<EOD, $self->_stash_src($type);
{
    local \$_ = shift \@matches;
    tr/ //d; # trim
    \%s
}
EOD
    }

    {
        my %types_table = map { $_ => 1 } @types;

        # epoch
        $formatter_src .= <<EOD if $types_table{epoch};
return \$stash{epoch};
EOD

        # start
        $formatter_src .= <<EOD;
my \$epoch     = 0;
my \$timelocal = \\\&Time::Local::timelocal;
EOD
        {
            # timezone
            $formatter_src .= <<EOD if $types_table{timezone};
local \$ENV{TZ} = \$stash{timezone};
tzset();
EOD

            # offset
            $formatter_src .= <<EOD if $types_table{offset};
\$epoch     += \$stash{offset} * 60 * 60;
\$timelocal  = \&Time::Local::timegm;
EOD

            # hour24&minute&second
            # year&day365 or year&month&day
            $formatter_src .= <<EOD;
{
    my \$second = \$stash{second} || 0;
    my \$minute = \$stash{minute} || 0;
    my \$hour   = \$stash{hour24} || 0;
    if (exists \$stash{year} && exists \$stash{day365}) {
        \$epoch += \$timelocal->(\$second, \$minute, \$hour, 1, 0, \$stash{year} - 1900);
        \$epoch += \$stash{day365} * 60 * 60 * 24;
    }
    elsif (exists \$stash{year} && exists \$stash{month} && exists \$stash{day}) {
        \$epoch += \$timelocal->(\$second, \$minute, \$hour, \$stash{day}, \$stash{month} - 1, \$stash{year} - 1900);
    }
    else {
        require Data::Dumper;
        local \$Data::Dumper::Terse    = 1;
        local \$Data::Dumper::Indent   = 0;
        local \$Data::Dumper::SortKeys = 1;
        die 'unknown case. stash: '.Data::Dumper->Dump([\\\%stash]);
    }
}
EOD
}
        # finish
        $formatter_src .= <<EOD;
return \$epoch;
EOD
    }

    my $combined_src = sprintf $parser_src, $formatter_src, $self->{format};
    warn $combined_src;

    my $parser = eval $combined_src; ## no critic
    die $@ if $@;
    return $parser;
}

sub _assemble_format {
    my ($self, $c, $types) = @_;
    die "unknwon: \%$c" unless exists $self->{_handler}->{$c};

    my ($type, $val) = @{ $self->{_handler}->{$c} };
    die "unsupported: \%$c" if $type eq 'UNSUPPORTED';

    return ''   if $type eq 'TODO' and warn "SKIP(TODO): \%$c";
    return $val if $type eq 'SKIP';
    return $val if $type eq 'char';
    if ($type eq 'extend') {
        $val =~ s{%(.)}{$self->_assemble_format($1, $types)}ge;
        return $val;
    }
    else {
        push @$types => $type;

        if (ref $val) {
            $val = $self->$val($type) if ref $val eq 'CODE';
            $val = join '|', @$val    if ref $val eq 'ARRAY';
        }

        return "($val)";
    }
}

sub _stash_src {
    my ($self, $type) = @_;
    return '$stash{epoch} = $_;' if $type eq 'epoch';
    return "\$stash{$type} = \$_;";
}

1;
__END__

=pod
 
=head1 NAME

Time::Strptime::Format - TODO

=head1 VERSION

This document describes Time::Strptime::Format version 0.01.

=head1 DESCRIPTION

TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
