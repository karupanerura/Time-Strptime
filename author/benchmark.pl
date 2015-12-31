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
        dt: 11 wallclock secs (10.45 usr +  0.01 sys = 10.46 CPU) @ 2313.48/s (n=24199)
dt(cached): 11 wallclock secs (10.55 usr +  0.01 sys = 10.56 CPU) @ 7906.72/s (n=83495)
        pt: 11 wallclock secs (10.48 usr +  0.00 sys = 10.48 CPU) @ 186033.21/s (n=1949628)
        tm: 11 wallclock secs (10.40 usr +  0.00 sys = 10.40 CPU) @ 1927168.46/s (n=20042552)
        tp: 11 wallclock secs (10.53 usr +  0.00 sys = 10.53 CPU) @ 116695.06/s (n=1228799)
tp(cached): 11 wallclock secs (10.60 usr +  0.01 sys = 10.61 CPU) @ 286613.10/s (n=3040965)
        ts: 10 wallclock secs (10.24 usr +  0.35 sys = 10.59 CPU) @ 2846.74/s (n=30147)
ts(cached): 11 wallclock secs (10.37 usr +  0.00 sys = 10.37 CPU) @ 172462.97/s (n=1788441)
                Rate     dt     ts dt(cached)    tp ts(cached)   pt tp(cached)    tm
dt            2313/s     --   -19%       -71%  -98%       -99% -99%       -99% -100%
ts            2847/s    23%     --       -64%  -98%       -98% -98%       -99% -100%
dt(cached)    7907/s   242%   178%         --  -93%       -95% -96%       -97% -100%
tp          116695/s  4944%  3999%      1376%    --       -32% -37%       -59%  -94%
ts(cached)  172463/s  7355%  5958%      2081%   48%         --  -7%       -40%  -91%
pt          186033/s  7941%  6435%      2253%   59%         8%   --       -35%  -90%
tp(cached)  286613/s 12289%  9968%      3525%  146%        66%  54%         --  -85%
tm         1927168/s 83202% 67597%     24274% 1551%      1017% 936%       572%    --
    # Subtest: UTC(+0000)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 2 - UTC(+0000)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 10 wallclock secs (10.66 usr +  0.01 sys = 10.67 CPU) @ 2267.95/s (n=24199)
dt(cached): 10 wallclock secs (10.54 usr +  0.01 sys = 10.55 CPU) @ 7692.32/s (n=81154)
        pt: 11 wallclock secs (10.40 usr +  0.01 sys = 10.41 CPU) @ 185383.19/s (n=1929839)
        tm: 10 wallclock secs (10.48 usr +  0.00 sys = 10.48 CPU) @ 1928506.01/s (n=20210743)
        tp: 10 wallclock secs (10.03 usr +  0.00 sys = 10.03 CPU) @ 130361.62/s (n=1307527)
tp(cached): 11 wallclock secs (10.59 usr +  0.01 sys = 10.60 CPU) @ 286883.49/s (n=3040965)
        ts: 10 wallclock secs ( 9.72 usr +  0.34 sys = 10.06 CPU) @ 2831.01/s (n=28480)
ts(cached): 10 wallclock secs (10.33 usr +  0.00 sys = 10.33 CPU) @ 171433.40/s (n=1770907)
                Rate     dt     ts dt(cached)    tp ts(cached)   pt tp(cached)    tm
dt            2268/s     --   -20%       -71%  -98%       -99% -99%       -99% -100%
ts            2831/s    25%     --       -63%  -98%       -98% -98%       -99% -100%
dt(cached)    7692/s   239%   172%         --  -94%       -96% -96%       -97% -100%
tp          130362/s  5648%  4505%      1595%    --       -24% -30%       -55%  -93%
ts(cached)  171433/s  7459%  5956%      2129%   32%         --  -8%       -40%  -91%
pt          185383/s  8074%  6448%      2310%   42%         8%   --       -35%  -90%
tp(cached)  286883/s 12549% 10034%      3629%  120%        67%  55%         --  -85%
tm         1928506/s 84933% 68021%     24971% 1379%      1025% 940%       572%    --
    # Subtest: Asia/Tokyo(+0900)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 3 - Asia/Tokyo(+0900)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 10 wallclock secs (10.56 usr +  0.01 sys = 10.57 CPU) @ 2159.32/s (n=22824)
dt(cached): 11 wallclock secs (10.55 usr +  0.01 sys = 10.56 CPU) @ 6756.91/s (n=71353)
        pt: 11 wallclock secs (10.51 usr +  0.00 sys = 10.51 CPU) @ 113668.51/s (n=1194656)
        tm: 12 wallclock secs (10.58 usr + -0.01 sys = 10.57 CPU) @ 1933722.33/s (n=20439445)
        tp: 10 wallclock secs (10.30 usr +  0.01 sys = 10.31 CPU) @ 116956.45/s (n=1205821)
tp(cached):  9 wallclock secs (10.48 usr +  0.01 sys = 10.49 CPU) @ 287232.22/s (n=3013066)
        ts: 11 wallclock secs (10.19 usr +  0.33 sys = 10.52 CPU) @ 2614.45/s (n=27504)
ts(cached):  9 wallclock secs (10.37 usr +  0.01 sys = 10.38 CPU) @ 84805.30/s (n=880279)
                Rate     dt     ts dt(cached) ts(cached)    pt    tp tp(cached)    tm
dt            2159/s     --   -17%       -68%       -97%  -98%  -98%       -99% -100%
ts            2614/s    21%     --       -61%       -97%  -98%  -98%       -99% -100%
dt(cached)    6757/s   213%   158%         --       -92%  -94%  -94%       -98% -100%
ts(cached)   84805/s  3827%  3144%      1155%         --  -25%  -27%       -70%  -96%
pt          113669/s  5164%  4248%      1582%        34%    --   -3%       -60%  -94%
tp          116956/s  5316%  4373%      1631%        38%    3%    --       -59%  -94%
tp(cached)  287232/s 13202% 10886%      4151%       239%  153%  146%         --  -85%
tm         1933722/s 89452% 73863%     28518%      2180% 1601% 1553%       573%    --
    # Subtest: America/Whitehorse(-0800)
    ok 1
    ok 2
    ok 3
    ok 4
    1..4
ok 4 - America/Whitehorse(-0800)
Benchmark: running dt, dt(cached), pt, tm, tp, tp(cached), ts, ts(cached) for at least 10 CPU seconds...
        dt: 10 wallclock secs (10.56 usr +  0.01 sys = 10.57 CPU) @ 2147.59/s (n=22700)
dt(cached): 10 wallclock secs (10.55 usr +  0.00 sys = 10.55 CPU) @ 6794.22/s (n=71679)
        pt: 11 wallclock secs (10.46 usr +  0.00 sys = 10.46 CPU) @ 94936.42/s (n=993035)
        tm: 11 wallclock secs (10.65 usr +  0.01 sys = 10.66 CPU) @ 1917396.34/s (n=20439445)
        tp: 10 wallclock secs (10.50 usr +  0.01 sys = 10.51 CPU) @ 116441.10/s (n=1223796)
tp(cached):  9 wallclock secs (10.42 usr +  0.00 sys = 10.42 CPU) @ 286533.01/s (n=2985674)
        ts: 11 wallclock secs (10.17 usr +  0.33 sys = 10.50 CPU) @ 2609.62/s (n=27401)
ts(cached):  9 wallclock secs (10.56 usr +  0.01 sys = 10.57 CPU) @ 87907.38/s (n=929181)
                Rate     dt     ts dt(cached) ts(cached)    pt    tp tp(cached)    tm
dt            2148/s     --   -18%       -68%       -98%  -98%  -98%       -99% -100%
ts            2610/s    22%     --       -62%       -97%  -97%  -98%       -99% -100%
dt(cached)    6794/s   216%   160%         --       -92%  -93%  -94%       -98% -100%
ts(cached)   87907/s  3993%  3269%      1194%         --   -7%  -25%       -69%  -95%
pt           94936/s  4321%  3538%      1297%         8%    --  -18%       -67%  -95%
tp          116441/s  5322%  4362%      1614%        32%   23%    --       -59%  -94%
tp(cached)  286533/s 13242% 10880%      4117%       226%  202%  146%         --  -85%
tm         1917396/s 89181% 73374%     28121%      2081% 1920% 1547%       569%    --
1..4
