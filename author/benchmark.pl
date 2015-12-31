use strict;
use warnings;
use utf8;
use feature qw/say/;

use Benchmark qw/cmpthese timethese/;

use Time::Strptime;
use Time::Strptime::Format;
use Time::Piece;
use DateTime::Format::Strptime;
use POSIX qw/tzset/;
use Time::Local qw/timelocal/;
use Time::TZOffset qw/tzoffset tzoffset_as_seconds/;
use Time::Moment;
use POSIX::strptime;
use Test::More;

my $pattern = '%Y-%m-%d %H:%M:%S';
my $text    = '2014-01-01 01:23:45';

say "================ Perl5 info  ==============";
system $^X, '-V';
say "================ Module info ==============";
say "$_:\t",$_->VERSION for qw/DateTime DateTime::TimeZone DateTime::Locale DateTime::Format::Strptime Time::Local Time::TZOffset Time::Moment Time::Piece Time::Strptime/;
say "===========================================";

for my $time_zone (qw|GMT UTC Asia/Tokyo America/Whitehorse|) {
    local $ENV{TZ} = $time_zone;
    tzset();

    my $ts_parser = Time::Strptime::Format->new($pattern);
    my $dt_parser = DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone);
    my $tp_parser = tzoffset(CORE::localtime) eq '+0000' ? Time::Piece->gmtime : Time::Piece->localtime;

    subtest "${time_zone}(@{[ tzoffset(CORE::localtime) ]})" => sub {
        my $dt = $dt_parser->parse_datetime($text);
        my $tp = $tp_parser->strptime($text, $pattern);
        my $tm = Time::Moment->from_string($text.tzoffset(CORE::localtime), lenient => 1);
        is_deeply(($ts_parser->parse($text))[0], timelocal(POSIX::strptime($text, $pattern)));
        is_deeply([$ts_parser->parse($text)],    [$dt->epoch, $dt->offset]);
        is_deeply([$ts_parser->parse($text)],    [$tp->epoch, $tp->tzoffset->seconds]);
        is_deeply([$ts_parser->parse($text)],    [$tm->epoch, $tm->offset * 60]);
    };

    my $tzoffset = tzoffset(CORE::localtime);
    cmpthese timethese -10 => +{
        'dt(cached)' => sub { $dt_parser->parse_datetime($text) },
        'pt'         => sub { timelocal(POSIX::strptime($text, $pattern)) },
        'ts(cached)' => sub { $ts_parser->parse($text) },
        'tp(cached)' => sub { $tp_parser->strptime($text, $pattern) },
        'dt'         => sub { DateTime::Format::Strptime->new(pattern => $pattern, time_zone => $time_zone)->parse_datetime($text) },
        'ts'         => sub { Time::Strptime::Format->new($pattern)->parse($text)                                                  },
        'tp'         => sub { Time::Piece->localtime->strptime($text, $pattern) },
        'tm'         => sub { Time::Moment->from_string($text.$tzoffset, lenient => 1) },
    };
}

done_testing;
__END__
================ Perl5 info  ==============
Summary of my perl5 (revision 5 version 22 subversion 1) configuration:
   
  Platform:
    osname=darwin, osvers=14.5.0, archname=darwin-2level
    uname='darwin karupanerura-mbp.local 14.5.0 darwin kernel version 14.5.0: tue sep 1 21:23:09 pdt 2015; root:xnu-2782.50.1~1release_x86_64 x86_64 '
    config_args='-Dprefix=/Users/karupanerura/.anyenv/envs/plenv/versions/5.22 -de -Dusedevel -A'eval:scriptdir=/Users/karupanerura/.anyenv/envs/plenv/versions/5.22/bin''
    hint=recommended, useposix=true, d_sigaction=define
    useithreads=undef, usemultiplicity=undef
    use64bitint=define, use64bitall=define, uselongdouble=undef
    usemymalloc=n, bincompat5005=undef
  Compiler:
    cc='cc', ccflags ='-fno-common -DPERL_DARWIN -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include',
    optimize='-O3',
    cppflags='-fno-common -DPERL_DARWIN -fno-strict-aliasing -pipe -fstack-protector-strong -I/usr/local/include'
    ccversion='', gccversion='4.2.1 Compatible Apple LLVM 7.0.2 (clang-700.1.81)', gccosandvers=''
    intsize=4, longsize=8, ptrsize=8, doublesize=8, byteorder=12345678, doublekind=3
    d_longlong=define, longlongsize=8, d_longdbl=define, longdblsize=16, longdblkind=3
    ivtype='long', ivsize=8, nvtype='double', nvsize=8, Off_t='off_t', lseeksize=8
    alignbytes=8, prototype=define
  Linker and Libraries:
    ld='env MACOSX_DEPLOYMENT_TARGET=10.3 cc', ldflags =' -fstack-protector-strong -L/usr/local/lib'
    libpth=/usr/local/lib /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/../lib/clang/7.0.2/lib /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib /usr/lib
    libs=-lpthread -lgdbm -ldbm -ldl -lm -lutil -lc
    perllibs=-lpthread -ldl -lm -lutil -lc
    libc=, so=dylib, useshrplib=false, libperl=libperl.a
    gnulibc_version=''
  Dynamic Linking:
    dlsrc=dl_dlopen.xs, dlext=bundle, d_dlsymun=undef, ccdlflags=' '
    cccdlflags=' ', lddlflags=' -bundle -undefined dynamic_lookup -L/usr/local/lib -fstack-protector-strong'


Characteristics of this binary (from libperl): 
  Compile-time options: HAS_TIMES PERLIO_LAYERS PERL_DONT_CREATE_GVSV
                        PERL_HASH_FUNC_ONE_AT_A_TIME_HARD PERL_MALLOC_WRAP
                        PERL_NEW_COPY_ON_WRITE PERL_PRESERVE_IVUV
                        PERL_USE_DEVEL USE_64_BIT_ALL USE_64_BIT_INT
                        USE_LARGE_FILES USE_LOCALE USE_LOCALE_COLLATE
                        USE_LOCALE_CTYPE USE_LOCALE_NUMERIC USE_LOCALE_TIME
                        USE_PERLIO USE_PERL_ATOF
  Locally applied patches:
	Devel::PatchPerl 1.38
  Built under darwin
  Compiled at Dec 14 2015 13:05:08
  @INC:
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/site_perl/5.22.1/darwin-2level
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/site_perl/5.22.1
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/5.22.1/darwin-2level
    /Users/karupanerura/.anyenv/envs/plenv/versions/5.22/lib/perl5/5.22.1
    .
================ Module info ==============
DateTime:	1.21
DateTime::TimeZone:	1.94
DateTime::Locale:	1.02
DateTime::Format::Strptime:	1.62
Time::Local:	1.2300
Time::TZOffset:	0.04
Time::Moment:	0.37
Time::Piece:	1.29
Time::Strptime:	0.03
===========================================
    # Subtest: GMT(+0000)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 1 - GMT(+0000)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 10 wallclock secs (10.36 usr +  0.00 sys = 10.36 CPU) @ 2347.59/s (n=24321)
dt(cached): 11 wallclock secs (10.42 usr +  0.00 sys = 10.42 CPU) @ 8207.97/s (n=85527)
        pt:  9 wallclock secs (10.01 usr +  0.01 sys = 10.02 CPU) @ 207161.78/s (n=2075761)
        tm: 11 wallclock secs (10.50 usr +  0.01 sys = 10.51 CPU) @ 1925694.39/s (n=20239048)
        tp: 11 wallclock secs (10.64 usr +  0.00 sys = 10.64 CPU) @ 115487.69/s (n=1228789)
tp(cached): 11 wallclock secs (10.50 usr +  0.00 sys = 10.50 CPU) @ 284349.90/s (n=2985674)
        ts: 10 wallclock secs (10.39 usr +  0.01 sys = 10.40 CPU) @ 4217.02/s (n=43857)
ts(cached): 11 wallclock secs (10.55 usr +  0.00 sys = 10.55 CPU) @ 174978.39/s (n=1846022)
                Rate     dt     ts dt(cached)    tp ts(cached)   pt tp(cached)    tm
dt            2348/s     --   -44%       -71%  -98%       -99% -99%       -99% -100%
ts            4217/s    80%     --       -49%  -96%       -98% -98%       -99% -100%
dt(cached)    8208/s   250%    95%         --  -93%       -95% -96%       -97% -100%
tp          115488/s  4819%  2639%      1307%    --       -34% -44%       -59%  -94%
ts(cached)  174978/s  7354%  4049%      2032%   52%         -- -16%       -38%  -91%
pt          207162/s  8724%  4813%      2424%   79%        18%   --       -27%  -89%
tp(cached)  284350/s 12012%  6643%      3364%  146%        63%  37%         --  -85%
tm         1925694/s 81929% 45565%     23361% 1567%      1001% 830%       577%    --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 2 - UTC(+0000)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 10 wallclock secs (10.00 usr +  0.00 sys = 10.00 CPU) @ 2330.80/s (n=23308)
dt(cached): 11 wallclock secs (10.47 usr +  0.01 sys = 10.48 CPU) @ 7943.42/s (n=83247)
        pt: 11 wallclock secs (10.48 usr +  0.00 sys = 10.48 CPU) @ 209175.10/s (n=2192155)
        tm: 10 wallclock secs (10.36 usr +  0.00 sys = 10.36 CPU) @ 1934610.33/s (n=20042563)
        tp: 11 wallclock secs (10.44 usr +  0.01 sys = 10.45 CPU) @ 115621.82/s (n=1208248)
tp(cached): 10 wallclock secs (10.71 usr +  0.00 sys = 10.71 CPU) @ 281097.01/s (n=3010549)
        ts: 10 wallclock secs (10.64 usr +  0.00 sys = 10.64 CPU) @ 4209.59/s (n=44790)
ts(cached): 11 wallclock secs (10.42 usr +  0.01 sys = 10.43 CPU) @ 175289.74/s (n=1828272)
                Rate     dt     ts dt(cached)    tp ts(cached)   pt tp(cached)    tm
dt            2331/s     --   -45%       -71%  -98%       -99% -99%       -99% -100%
ts            4210/s    81%     --       -47%  -96%       -98% -98%       -99% -100%
dt(cached)    7943/s   241%    89%         --  -93%       -95% -96%       -97% -100%
tp          115622/s  4861%  2647%      1356%    --       -34% -45%       -59%  -94%
ts(cached)  175290/s  7421%  4064%      2107%   52%         -- -16%       -38%  -91%
pt          209175/s  8874%  4869%      2533%   81%        19%   --       -26%  -89%
tp(cached)  281097/s 11960%  6578%      3439%  143%        60%  34%         --  -85%
tm         1934610/s 82902% 45857%     24255% 1573%      1004% 825%       588%    --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 3 - Asia/Tokyo(+0900)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 11 wallclock secs (10.73 usr +  0.01 sys = 10.74 CPU) @ 2171.23/s (n=23319)
dt(cached): 10 wallclock secs (10.53 usr +  0.00 sys = 10.53 CPU) @ 6961.92/s (n=73309)
        pt: 11 wallclock secs (10.40 usr +  0.00 sys = 10.40 CPU) @ 113817.88/s (n=1183706)
        tm: 11 wallclock secs (10.68 usr +  0.01 sys = 10.69 CPU) @ 1893269.22/s (n=20239048)
        tp:  9 wallclock secs (10.51 usr +  0.00 sys = 10.51 CPU) @ 114731.78/s (n=1205831)
tp(cached): 11 wallclock secs (10.62 usr +  0.00 sys = 10.62 CPU) @ 277921.75/s (n=2951529)
        ts: 11 wallclock secs (10.67 usr +  0.01 sys = 10.68 CPU) @ 3799.34/s (n=40577)
ts(cached):  9 wallclock secs (10.48 usr +  0.00 sys = 10.48 CPU) @ 110487.12/s (n=1157905)
                Rate     dt     ts dt(cached) ts(cached)    pt    tp tp(cached)    tm
dt            2171/s     --   -43%       -69%       -98%  -98%  -98%       -99% -100%
ts            3799/s    75%     --       -45%       -97%  -97%  -97%       -99% -100%
dt(cached)    6962/s   221%    83%         --       -94%  -94%  -94%       -97% -100%
ts(cached)  110487/s  4989%  2808%      1487%         --   -3%   -4%       -60%  -94%
pt          113818/s  5142%  2896%      1535%         3%    --   -1%       -59%  -94%
tp          114732/s  5184%  2920%      1548%         4%    1%    --       -59%  -94%
tp(cached)  277922/s 12700%  7215%      3892%       152%  144%  142%         --  -85%
tm         1893269/s 87098% 49731%     27095%      1614% 1563% 1550%       581%    --
    # Subtest: America/Whitehorse(-0800)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 4 - America/Whitehorse(-0800)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 10 wallclock secs (10.44 usr +  0.00 sys = 10.44 CPU) @ 2193.77/s (n=22903)
dt(cached): 10 wallclock secs (10.48 usr +  0.01 sys = 10.49 CPU) @ 7034.13/s (n=73788)
        pt: 11 wallclock secs (10.60 usr +  0.00 sys = 10.60 CPU) @ 106504.62/s (n=1128949)
        tm: 11 wallclock secs (10.60 usr +  0.00 sys = 10.60 CPU) @ 1909344.15/s (n=20239048)
        tp: 11 wallclock secs (10.49 usr +  0.01 sys = 10.50 CPU) @ 127242.29/s (n=1336044)
tp(cached): 11 wallclock secs (10.56 usr +  0.00 sys = 10.56 CPU) @ 279499.91/s (n=2951519)
        ts: 10 wallclock secs (10.45 usr +  0.00 sys = 10.45 CPU) @ 3777.03/s (n=39470)
ts(cached): 10 wallclock secs (10.14 usr +  0.01 sys = 10.15 CPU) @ 96040.79/s (n=974814)
                Rate     dt     ts dt(cached) ts(cached)    pt    tp tp(cached)    tm
dt            2194/s     --   -42%       -69%       -98%  -98%  -98%       -99% -100%
ts            3777/s    72%     --       -46%       -96%  -96%  -97%       -99% -100%
dt(cached)    7034/s   221%    86%         --       -93%  -93%  -94%       -97% -100%
ts(cached)   96041/s  4278%  2443%      1265%         --  -10%  -25%       -66%  -95%
pt          106505/s  4755%  2720%      1414%        11%    --  -16%       -62%  -94%
tp          127242/s  5700%  3269%      1709%        32%   19%    --       -54%  -93%
tp(cached)  279500/s 12641%  7300%      3873%       191%  162%  120%         --  -85%
tm         1909344/s 86935% 50451%     27044%      1888% 1693% 1401%       583%    --
1..4
