use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More tests => 3;

# This test checks the loadability of the module
# and that the object is correctly blessed as FASTX::Reader

use_ok 'NBI::Slurm';
use_ok 'NBI::Job';
use_ok 'NBI::Opts';
