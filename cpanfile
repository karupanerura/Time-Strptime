requires 'Encode';
requires 'Encode::Locale';
requires 'Locale::Scope';
requires 'Time::Local';
requires 'parent';
requires 'perl', '5.022000';

recommends 'Time::TZOffset', '0.04';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'Test::More';
};

on develop => sub {
    requires 'Time::Piece';
    requires 'Time::TZOffset';
    requires 'DateTime::Format::Strptime';
};
