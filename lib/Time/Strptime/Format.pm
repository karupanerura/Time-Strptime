package Time::Strptime::Format;
use strict;
use warnings;
use utf8;

use Carp ();
use Time::Local qw/timelocal timegm/;
use Encode qw/decode/;
use Encode::Locale;
use Locale::Scope qw/locale_scope/;
use POSIX qw/tzset strftime LC_ALL/;

our $VERSION = 0.01;

BEGIN {
    if (eval { require Time::TZOffset; 1 }) {
        *tzoffset_as_epoch = sub {
            my $offset = Time::TZOffset::tzoffset(@_);
            return (abs($offset) == $offset ? 1 : -1) * (60 * 60 * substr($offset, 1, 2) + 60 * substr($offset, 3, 2));
        };
    }
    else {
        *tzoffset_as_epoch = sub {
            return timelocal(@_) - timegm(@_);
        };
    }
}

our %DEFAULT_HANDLER = (
    '%' => [char          => '%' ],
    A   => [SKIP          => sub { map { decode(locale => $_) } map { strftime('%a', 0, 0, 0, $_, 0, 0), strftime('%A', 0, 0, 0, $_, 0, 0) } 1..7 } ],
    a   => [extend        => q{%A} ],
    B   => [localed_month => sub {
        my $self = shift;

        unless (exists $self->{format_table}{localed_month}) {
            my %format_table;
            for my $month (1..12) {
                $format_table{decode(locale => strftime('%b', 0, 0, 0, 1, $_-1, 0))} = $month;
                $format_table{decode(locale => strftime('%B', 0, 0, 0, 1, $_-1, 0))} = $month;
            }
            $self->{format_table}{localed_month} = \%format_table;
        }

        return [keys %{ $self->{format_table}{localed_month} }];
    } ],
    b   => [extend      => q{%B}],
    C   => [SKIP        => q{[0-9]{2}} ],
    c   => ['UNSUPPORTED'],
    D   => [extend      => q{%m/%d/%Y}                    ],
    d   => [day         => ['0[1-9]','[12][0-9]','3[01]'] ],
    e   => [day         => [' [1-9]','[12][0-9]','3[01]'] ],
    F   => [extend      => q{%Y-%m-%d} ],
    G   => [year        => q{%Y} ], ## It's realy OK?
    g   => [SKIP        => q{[0-9]{2}} ],
    H   => [hour24      => ['[01][0-9]','2[0-3]'] ],
    h   => [extend      => q{%b}                     ],
    I   => [hour12      => ['0[1-9]', '1[0-2]'] ],
    j   => [day365      => ['00[1-9]','[12][0-9][0-9]','3[0-5][0-9]','36[0-6]'] ],
    k   => [hour24      => ['[ 1][0-9]','2[0-3]'] ],
    l   => [hour12      => [' [1-9]', '1[0-2]'] ],
    M   => [minute      => q{[0-5][0-9]}          ],
    m   => [month       => ['0[1-9]','1[0-2]']    ],
    n   => [SKIP        => q{\s+}                 ],
    p   => [ampm        => q{[AP]M}],
    P   => [ampm        => q{[ap]m}],
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
    Z   => [timezone    => ['[-A-Z]+', '[A-Z][a-z]+(?:/[A-Z][a-z]+)+']],
    z   => [offset      => q{[-+][0-9]{4}}],
);

sub new {
    my ($class, $format, $options) = @_;
    $options ||= +{};

    my $self = bless +{
        format    => $format,
        time_zone => $options->{time_zone} || $ENV{TZ} || strftime('%Z', localtime) || 'GMT',
        locale    => $options->{locale}    || 'C',
        _handler  => +{
            %DEFAULT_HANDLER,
            %{ $options->{handler} || {} },
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

    # setlocale and tzset
    my $locale = locale_scope(LC_ALL, $self->{locale});
    local $ENV{TZ} = $self->{time_zone};
    tzset();

    # assemble format to regexp
    my $handlers = join '', keys %{ $self->{_handler} };
    my @types;
    $format =~ s{([^%]*)?%([${handlers}])([^%]*)?}{quotemeta($1||'') .$self->_assemble_format($2, \@types) . quotemeta($3||'')}geo;
    my %types_table = map { $_ => 1 } map {
        my $t = $_;
        $t =~ s/^localized_//;
        $t;
    } @types;

    # generate base src
    local $" = ' ';
    my $parser_src = <<EOD;
my (\$epoch, \$offset, \%%stash);
sub {
    if (\@stash{qw/@types/} = (\$_[0] =~ m{\\A$format\\z}mso)) {
        \%s;
        return (\$epoch, \$offset);
    }
    else {
        Carp::croak "cannot parse datetime. text: '\$_[0]', format: '\%s'";
    }
};
EOD

    # generate formatter src
    my $formatter_src = '';
    for my $type (@types) {
        $formatter_src .= $self->_gen_stash_initialize_src($type);
    }
    $formatter_src .= $self->_gen_calc_epoch_src(\%types_table);
    $formatter_src .= $self->_gen_calc_offset_src(\%types_table);

    my $combined_src = sprintf $parser_src, $formatter_src, $self->{format};
    # warn $combined_src;

    my $format_table = $self->{format_table} || {};
    my $parser = eval $combined_src; ## no critic
    die $@ if $@;
    return $parser;
}

sub _assemble_format {
    my ($self, $c, $types) = @_;
    die "unknwon: \%$c" unless exists $self->{_handler}->{$c};

    my ($type, $val) = @{ $self->{_handler}->{$c} };
    die "unsupported: \%$c. patches welcome :)" if $type eq 'UNSUPPORTED';

    # normalize
    if (ref $val) {
        $val = $self->$val($type) if ref $val eq 'CODE';
        $val = join '|', @$val    if ref $val eq 'ARRAY';
    }

    # assemble to regexp
    if ($type eq 'extend') {
        my $handlers = join '', keys %{ $self->{_handler} };
        $val =~ s{([^%]*)?%([${handlers}])([^%]*)?}{quotemeta($1||'') .$self->_assemble_format($2, $types) . quotemeta($3||'')}geo;
        return $val;
    }
    else {
        return ''   if $type eq 'TODO' and warn "SKIP(TODO): \%$c. patches welcome :)";
        return $val if $type eq 'SKIP';
        return $val if $type eq 'char';

        push @$types => $type;
        return "($val)";
    }
}

sub _gen_stash_initialize_src {
    my ($self, $type) = @_;

    if ($type eq 'timezone') {
        return <<'EOD';
local $ENV{TZ} = $stash{timezone};
tzset();
EOD
    }
    elsif ($type =~ /^localed_([a-z]+)$/) {
        return <<EOD;
\$stash{${1}} = \$format_table->{localed_${1}}->{\$stash{localed_${1}}};
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
    my $second        = $types_table->{second} ? '$stash{second}' : 0;
    my $minute        = $types_table->{minute} ? '$stash{minute}' : 0;
    my $hour          = $self->_gen_calc_hour_src($types_table);
    if ($types_table->{epoch}) {
        $src .= <<'EOD';
$epoch = $stash{epoch};
EOD
    }
    elsif ($types_table->{year} && $types_table->{month} && $types_table->{day}) {
        $src .= <<EOD;
\$epoch = timegm($second, $minute, $hour, \$stash{day}, \$stash{month} - 1, \$stash{year} - 1900);
EOD
    }
    elsif ($types_table->{year} && $types_table->{day365}) {
        $src .= <<EOD;
\$epoch = timegm($second, $minute, $hour, 1, 0, \$stash{year} - 1900) + \$stash{day365} * 60 * 60 * 24;
EOD
    }
    else {
        die 'unknown case. types: '. join ', ', keys %$types_table;
    }

    return $src;
}

sub _gen_calc_offset_src {
    my ($self, $types_table) = @_;

    my $src = '';

    my $fix_offset = $self->_can_use_fixed_offset($types_table);

    my $second = $types_table->{second} ? '$stash{second}' : 0;
    my $minute = $types_table->{minute} ? '$stash{minute}' : 0;
    my $hour   = $self->_gen_calc_hour_src($types_table);
    if ($fix_offset) {
        my $offset = tzoffset_as_epoch(localtime);
        $src .= sprintf <<'EOD', $offset;
$offset = %d;
EOD
    }
    elsif ($types_table->{offset}) {
        $src .= <<'EOD';
$offset = (abs($stash{offset}) == $stash{offset} ? 1 : -1) * (60 * 60 * substr($stash{offset}, 1, 2) + 60 * substr($stash{offset}, 3, 2));
EOD
    }
    elsif ($types_table->{year} && $types_table->{month} && $types_table->{day}) {
        $src .= <<EOD;
\$offset = tzoffset_as_epoch($second, $minute, $hour, \$stash{day}, \$stash{month} - 1, \$stash{year} - 1900);
EOD
    }
    elsif ($types_table->{year} && $types_table->{day365}) {
        $src .= <<EOD;
\$offset = tzoffset_as_epoch($second, $minute, $hour, 1, 0, \$stash{year} - 1900);
EOD
    }
    else {
        die 'unknown case. types: '. join ', ', keys %$types_table;
    }

    $src .= <<'EOD' unless $types_table->{epoch} || $fix_offset;
$epoch -= $offset;
EOD

    return $src;
}

sub _gen_calc_hour_src {
    my ($self, $types_table) = @_;

    if ($types_table->{hour24}) {
        return '$stash{hour24}';
    }
    elsif ($types_table->{hour12} && $types_table->{ampm}) {
        return <<'EOD';
($stash{hour12} == 12 ? (uc $stash{ampm} eq q{AM} ? 0 : 12) : ($stash{hour12} + (uc $stash{ampm} eq q{PM} ? 12 : 0)))
EOD
    } else {
        return 0;
    }
}

sub _can_use_fixed_offset {
    my ($self, $types_table) = @_;
    return if $types_table->{offset};
    return if $types_table->{timezone};
    return $ENV{TZ} eq 'GMT';
}

1;
__END__


=encoding utf-8

=head1 NAME

Time::Strptime::Format - L<strptime(3)> format compiler and parser.

=head1 SYNOPSIS

    use Time::Strptime::Format;

    # OO style
    my $fmt = Time::Strptime::Format->new('%Y-%m-%d %H:%M:%S');
    my ($epoch_o, $offset_o) = $fmt->parse('2014-01-01 00:00:00');

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
