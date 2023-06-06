#ABSTRACT: NBI Slurm module
use strict;
use warnings;
package NBI::Slurm;

$NBI::Slurm::VERSION = '0.1.0';

use NBI::Job;
use NBI::Opts;

# Export both classes
use base qw(Exporter);
our @EXPORT_OK = qw(NBI::Job NBI::Opts);
1;
