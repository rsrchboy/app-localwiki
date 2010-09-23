#!/usr/bin/env perl

use strict;
use Test::UseAllModules;

BEGIN { all_uses_ok(); }

__END__

# other varieties, if they make more sense

# if you also want to test modules under t/lib
use strict;
use Test::UseAllModules under => qw(lib t/lib);

BEGIN { all_uses_ok(); }

# if you have modules that'll fail use_ok() for themselves
use strict;
use Test::UseAllModules;

BEGIN {
  all_uses_ok except => qw(
    Some::Dependent::Module
    Another::Dependent::Module
    ^Yet::Another::Dependent::.*   # you can use regex
  )
}
