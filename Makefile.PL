use inc::Module::Install;
use Module::Install::AuthorTests;

name 'WWW-Google-C2DM';
all_from 'lib/WWW/Google/C2DM.pm';

#requires '';

test_requires 'Test::More', 0.98;

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

repository 'http://github.com/xaicron/p5-WWW-Google-C2DM/';
bugtracker 'http://github.com/xaicron/p5-WWW-Google-C2DM/issues';

WriteAll;
