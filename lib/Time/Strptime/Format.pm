package Time::Strptime::Format;
use strict;
use warnings;
use utf8;

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
    return $self->{_parser} ||= $self->_compile_format;
}

sub _compile_format {
    my $self = shift;
    my $format = $self->{format};

    # assemble format to regexp
    my @types;
    $format =~ s{%(.)}{$self->_assemble_format($1, \@types)}ge;
    my %types_table = map { $_ => 1 } @types;

    # generate base src
    my $parser_src = <<EOD;
my (\$epoch, \%%stash);
sub {
    if (\@stash{qw/@types/} = (\$_[0] =~ m{\\A$format\\z}o)) {
        \$epoch = 0;
        \%s;
    }
    else {
        Carp::croak "cannot parse datetime. text: \$_[0], format: $self->{format}";
    }
};
EOD

    # generate formatter src
    my $formatter_src = '';
    for my $type (@types) {
        $formatter_src .= $self->_gen_stash_finalize_src($type);
    }
    $formatter_src .= $self->_gen_calc_epoch_src(\%types_table);

    my $combined_src = sprintf $parser_src, $formatter_src;
    # warn $combined_src;

    my $parser = eval $combined_src; ## no critic
    die $@ if $@;
    return $parser;
}

sub _assemble_format {
    my ($self, $c, $types) = @_;
    die "unknwon: \%$c" unless exists $self->{_handler}->{$c};

    my ($type, $val) = @{ $self->{_handler}->{$c} };
    die "unsupported: \%$c. patches welcome :)" if $type eq 'UNSUPPORTED';

    return ''   if $type eq 'TODO' and warn "SKIP(TODO): \%$c. patches welcome :)";
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

sub _gen_stash_finalize_src {
    my ($self, $type) = @_;

    if ($type eq 'timezone') {
        return <<'EOD';
local $ENV{TZ} = $stash{timezone};
tzset();
EOD
    }
    elsif ($type eq 'epoch') {
        return <<'EOD';
return $stash{epoch};
EOD
    }
    elsif ($type eq 'offset') {
        return <<'EOD';
$epoch += $stash{offset} 60 * 60 / -100;
EOD
    }
    else {
        return ''; # default: none
    }
}

sub _gen_calc_epoch_src {
    my ($self, $types_table) = @_;


    my $src = '';

    # hour24&minute&second
    # year&day365 or year&month&day
    my $timelocal_sub = "Time::Local::time@{[ $types_table->{offset} ? 'gm' : 'local' ]}";
    if ($types_table->{year} && $types_table->{month} && $types_table->{day}) {
        $src .= <<EOD;
\$epoch += ${timelocal_sub}(@{[ $types_table->{second} ? '$stash{second}' : 0 ]}, @{[ $types_table->{minute} ? '$stash{minute}' : 0 ]}, @{[ $types_table->{hour24} ? '$stash{hour24}' : 0 ]}, \$stash{day}, \$stash{month} - 1, \$stash{year} - 1900);
EOD
    }
    elsif ($types_table->{year} && $types_table->{day365}) {
        $src .= <<EOD;
\$epoch += ${timelocal_sub}(@{[ $types_table->{second} ? '$stash{second}' : 0 ]}, @{[ $types_table->{minute} ? '$stash{minute}' : 0 ]}, @{[ $types_table->{hour24} ? '$stash{hour24}' : 0 ]}, 1, 0, \$stash{year} - 1900);
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

1;
__END__


=encoding utf-8

=head1 NAME

Time::Strptime::Format - strptime format compiler and parser.

=head1 SYNOPSIS

    use Time::Strptime::Format;

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my $epoch_o = $fmt->parse('2014-01-01 00:00:00');

=head1 DESCRIPTION

B<THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

This is L<Time::Strptime> engine.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
