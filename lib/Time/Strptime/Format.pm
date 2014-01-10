package Time::Strptime::Format;
use strict;
use warnings;
use utf8;

use Carp ();
use Time::Local ();
use POSIX ();

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

    my $self = bless +{
        format   => $format,
        _handler => +{
            %DEFAULT_HANDLER,
            %$handler,
        },
    } => $class;

    # compile and cache
    $self->_parser();

    return $self;
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

    # generate anon package
    my $parser_package;
    $self->{_parser_package}{$format}->cleanup if $self->{_parser_package}{$format};
    $parser_package = $self->{_parser_package}{$format}
        ||= __PACKAGE__ . '::__ANON__::Parser' . (0+$self) . time . $$ . int rand . 0+{};

    # assemble format to regexp
    my @types;
    $format =~ s{%(.)}{$self->_assemble_format($1, \@types)}ge;
    my %types_table = map { $_ => 1 } @types;

    # generate base src
    my $parser_src = <<EOD;
package $parser_package;
use strict;
use warnings;
use utf8;

use Carp ();
use Time::Local ();
use POSIX qw/tzset/;

\*__TIME_STRPTIME_FORMAT_TO_EPOCH__ = @{[ $types_table{offset} ? 1 : 0 ]} ? \\\*Time::Local::timegm : \\\*Time::Local::timelocal;

my (\$epoch, \@matches, \%%stash, \$register);

sub cleanup {
    undef \$epoch;
    undef \@matches;
    undef \%%stash;
    undef \$register;
}

sub {
    if (\@matches = (\$_[0] =~ m{\\A$format\\z}o)) {
        \$epoch = 0;
        \%s;
    }
    else {
        Carp::croak "cannot parse datetime. text: \$_[0], format: \%s";
    }
};
EOD

    # generate formatter src
    my $formatter_src = '';
    for my $type (@types) {
        $formatter_src .= sprintf <<EOD, $self->_gen_stash_src($type);
\$register = shift \@matches;
%s
EOD
    }
    $formatter_src .= $self->_gen_calc_epoch_src(\%types_table);

    my $combined_src = sprintf $parser_src, $formatter_src, $self->{format};
    # warn $combined_src;

    my $parser = eval $combined_src; ## no critic
    die $@ if $@;
    return $parser;
}

sub _assemble_format {
    my ($self, $c, $types) = @_;
    die "unknwon: \%$c" unless exists $self->{_handler}->{$c};

    my ($type, $val) = @{ $self->{_handler}->{$c} };
    die "unsupported: \%$c" if $type eq 'UNSUPPORTED';

    return ''   if $type eq 'TODO' and die "SKIP(TODO): \%$c";
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

sub _gen_stash_src {
    my ($self, $type) = @_;
    return '$stash{epoch} = $register;' if $type eq 'epoch';
    return "\$stash{$type} = \$register;";
}

sub _gen_calc_epoch_src {
    my ($self, $types_table) = @_;
    return 'return $stash{epoch};' if $types_table->{epoch};

    my $src = '';

    # timezone
    $src .= <<EOD if $types_table->{timezone};
local \$ENV{TZ} = \$stash{timezone};
tzset();
EOD

    # offset
    $src .= <<EOD if $types_table->{offset};
\$epoch += \$stash{offset} * 60 * 60 / 100;
EOD

    # hour24&minute&second
    # year&day365 or year&month&day
    if ($types_table->{year} && $types_table->{month} && $types_table->{day}) {
        $src .= <<EOD;
\$epoch += __TIME_STRPTIME_FORMAT_TO_EPOCH__(@{[ $types_table->{second} ? '$stash{second}' : 0 ]}, @{[ $types_table->{minute} ? '$stash{minute}' : 0 ]}, @{[ $types_table->{hour24} ? '$stash{hour24}' : 0 ]}, \$stash{day}, \$stash{month} - 1, \$stash{year} - 1900);
EOD
    }
    elsif ($types_table->{year} && $types_table->{day365}) {
        $src .= <<EOD;
\$epoch += \$timelocal->(@{[ $types_table->{second} ? '$stash{second}' : 0 ]}, @{[ $types_table->{minute} ? '$stash{minute}' : 0 ]}, @{[ $types_table->{hour24} ? '$stash{hour24}' : 0 ]}, 1, 0, \$stash{year} - 1900);
\$epoch += \$stash{day365} * 60 * 60 * 24;
EOD
    }
    else {
        require Data::Dumper;

        no warnings 'once';
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Indent   = 0;
        local $Data::Dumper::SortKeys = 1;
        use warnings 'once';

        die 'unknown case. types: '.Data::Dumper->Dump([[ keys %$types_table ]]);
    }

    return $src;
}

sub DESTROY {
    my $self = shift;
    if ($self->{_parser_package}) {
        for my $format (keys %{ $self->{_parser_package} }) {
            $self->{_parser_package}->{$format}->cleanup;
        }
    }
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
