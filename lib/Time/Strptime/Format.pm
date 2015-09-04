package Time::Strptime::Format;
use strict;
use warnings;
use utf8;
use integer;

use B;
use Carp ();
use Time::Local qw/timelocal_nocheck timegm_nocheck/;
use Encode qw/decode is_utf8/;
use Encode::Locale;
use Locale::Scope qw/locale_scope/;
use List::MoreUtils qw/uniq/;
use POSIX qw/tzset strftime LC_ALL/;

use constant DEBUG => exists $ENV{PERL_TIME_STRPTIME_DEBUG} && $ENV{PERL_TIME_STRPTIME_DEBUG};

our $VERSION = 0.02_01;

BEGIN {
    local $@;
    eval "use Time::TZOffset 0.04 qw/tzoffset_as_seconds/";
    *tzoffset_as_seconds = sub { timegm_nocheck(@_) - timelocal_nocheck(@_) } if $@;
}

our %DEFAULT_HANDLER = (
    '%' => [char          => '%' ],
    A   => [SKIP          => sub {
        map quotemeta, map { ($_, substr $_, 0, 3) } map { is_utf8($_) ? $_ : decode(locale => $_) } map {
            strftime('%a', 0, 0, 0, $_, 0, 0),
            strftime('%A', 0, 0, 0, $_, 0, 0)
        } 1..7
    }],
    a   => [extend        => q{%A} ],
    B   => [localed_month => sub {
        my $self = shift;

        unless (exists $self->{format_table}{localed_month}) {
            my %format_table;
            for my $month (1..12) {
                my $b = strftime('%b', 0, 0, 0, 1, $month-1, 0);
                my $B = strftime('%B', 0, 0, 0, 1, $month-1, 0);
                $format_table{is_utf8($b) ? $b : decode(locale => $b) } = $month;
                $format_table{is_utf8($B) ? $B : decode(locale => $B) } = $month;
            }
            $format_table{substr($_, 0, 3)} = $format_table{$_} for keys %format_table;
            $self->{format_table}{localed_month} = \%format_table;
        }

        return [map quotemeta, keys %{ $self->{format_table}{localed_month} }];
    } ],
    b   => [extend      => q{%B}],
    C   => ['UNSUPPORTED'],
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

our %FIXED_OFFSET = (
    GMT => 0,
    UTC => 0,
    Z   => 0,
);

sub new {
    my ($class, $format, $options) = @_;
    $options ||= +{};

    my $self = bless +{
        format    => $format,
        time_zone => $options->{time_zone},
        locale    => $options->{locale} || 'C',
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
    goto &{ $self->_parser };
}

sub _parser {
    my $self = shift;
    return $self->{_parser} ||= $self->_compile_format;
}

sub _compile_format {
    my $self = shift;
    my $format = $self->{format};

    my $parser = do {
        # setlocale and tzset
        my $locale = locale_scope(LC_ALL, $self->{locale});
        local $ENV{TZ} = $ENV{TZ} || $self->{time_zone} || strftime('%Z', localtime);
        tzset();

        # assemble format to regexp
        my $handlers = join '', keys %{ $self->{_handler} };
        my @types;
        $format =~ s{([^%]*)?%([${handlers}])([^%]*)?}{
            my $prefix = quotemeta($1||'');
            my $suffix = quotemeta($3||'');
            $prefix.$self->_assemble_format($2, \@types).$suffix
        }geo;
        my %types_table = map { $_ => 1 } map {
            my $t = $_;
            $t =~ s/^localed_//;
            $t;
        } @types;

        # define vars
        my $vars = join ', ', uniq map { '$'.$_ } map {
            my $t = $_;
            $t =~ s/^localed_// ? ($_, $t) : $_;
        } @types, 'offset', 'epoch';
        my $captures = join ', ', map { '$'.$_ }  @types;

        # generate base src
        local $" = ' ';
        my $parser_src = <<EOD;
my ($vars);
\$offset = 0;
sub {
    ($captures) = \$_[0] =~ m{^$format\$}
        or Carp::croak 'cannot parse datetime. text: "'.\$_[0].'", format: '.\%s;
\%s
    (\$epoch, \$offset);
};
EOD

        # generate formatter src
        my $formatter_src = '';
        for my $type (@types) {
            $formatter_src .= $self->_gen_stash_initialize_src($type);
        }
        $formatter_src .= $self->_gen_calc_epoch_src(\%types_table);
        $formatter_src .= $self->_gen_calc_offset_src(\%types_table);

        my $combined_src = sprintf $parser_src, B::perlstring(B::perlstring($self->{format})), $formatter_src;
        $self->{parser_src} = $combined_src;
        warn Encode::encode_utf8 "[DEBUG] src: $combined_src" if DEBUG;

        my $format_table = $self->{format_table} || {};
        eval $combined_src; ## no critic
    };
    tzset();
    die $@ if $@;

    return $parser;
}

sub _assemble_format {
    my ($self, $c, $types) = @_;
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
        $val =~ s{([^%]*)?%([${handlers}])([^%]*)?}{
            my $prefix = quotemeta($1||'');
            my $suffix = quotemeta($3||'');
            $prefix.$self->_assemble_format($2, $types).$suffix
        }ge;
        return $val;
    }
    else {
        return ''             if $type eq 'TODO' and warn "SKIP(TODO): \%$c. patches welcome :)";
        return quotemeta $val if $type eq 'SKIP';
        return quotemeta $val if $type eq 'char';

        push @$types => $type;
        return "($val)";
    }
}

sub _gen_stash_initialize_src {
    my ($self, $type) = @_;

    if ($type eq 'timezone') {
        return <<'EOD';
    local $ENV{TZ} = $timezone;
    tzset();
EOD
    }
    elsif ($type =~ /^localed_([a-z]+)$/) {
        return <<EOD;
    \$${1} = \$format_table->{localed_${1}}->{\$localed_${1}};
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
    my $second        = $types_table->{second} ? '$second' : 0;
    my $minute        = $types_table->{minute} ? '$minute' : 0;
    my $hour          = $self->_gen_calc_hour_src($types_table);
    if ($types_table->{epoch}) {
        # nothing to do
    }
    elsif ($types_table->{year} && $types_table->{month} && $types_table->{day}) {
        $src .= <<EOD;
    \$epoch = timegm_nocheck($second, $minute, $hour, \$day, \$month - 1, \$year - 1900);
EOD
    }
    elsif ($types_table->{year} && $types_table->{day365}) {
        $src .= <<EOD;
    \$epoch = timegm_nocheck($second, $minute, $hour, 1, 0, \$year - 1900) + \$day365 * 60 * 60 * 24;
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

    my $fixed_offset = $self->_fixed_offset($types_table, $ENV{TZ});

    my $second = $types_table->{second} ? '$second' : 0;
    my $minute = $types_table->{minute} ? '$minute' : 0;
    my $hour   = $self->_gen_calc_hour_src($types_table);
    if (defined $fixed_offset) {
        if ($fixed_offset != 0) {
            $src .= sprintf <<'EOD', $fixed_offset;
    $offset -= %d;
EOD
        }
    }
    elsif ($types_table->{offset}) {
        $src .= <<'EOD';
    $offset = (abs($offset) == $offset ? 1 : -1) * (60 * 60 * substr($offset, 1, 2) + 60 * substr($offset, 3, 2));
EOD
    }
    elsif ($types_table->{year} && $types_table->{month} && $types_table->{day}) {
        $src .= <<EOD;
    \$offset = tzoffset_as_seconds($second, $minute, $hour, \$day, \$month - 1, \$year - 1900);
EOD
    }
    elsif ($types_table->{year} && $types_table->{day365}) {
        $src .= <<EOD;
    \$offset = tzoffset_as_seconds($second, $minute, $hour, 1, 0, \$year - 1900);
EOD
    }
    else {
        die 'unknown case. types: '. join ', ', keys %$types_table;
    }

    $src .= <<'EOD' unless $types_table->{epoch} || defined $fixed_offset;
    $epoch -= $offset;
EOD

    return $src;
}

sub _gen_calc_hour_src {
    my ($self, $types_table) = @_;

    if ($types_table->{hour24}) {
        return '$hour24';
    }
    elsif ($types_table->{hour12} && $types_table->{ampm}) {
        return <<'EOD';
($hour12 == 12 ? (uc $ampm eq q{AM} ? 0 : 12) : ($hour12 + (uc $ampm eq q{PM} ? 12 : 0)))
EOD
    } else {
        return 0;
    }
}

sub _fixed_offset {
    my ($self, $types_table, $time_zone) = @_;
    return if $types_table->{offset};
    return if $types_table->{timezone};
    return if not defined $time_zone;
    return if not exists $FIXED_OFFSET{$time_zone};
    return $FIXED_OFFSET{$time_zone};
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
