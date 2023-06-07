
#!/usr/bin/env perl
use v5.12;
use Data::Dumper;
# add to library ../lib/
use FindBin qw($RealBin);

use lib "$RealBin/../lib";
use NBI::Slurm;

my $opt = NBI::Opts->new(
    -queue => "nbi-short",
    -threads => 1,
    -memory => "12Gb",
    -time   => "0d 1h",
    -tmpdir => "/tmp"
);

my $job = NBI::Job->new(
    -name => "my-job",
    -command => "ls -l > temporary-example-list.txt",
    -opts => $opt
);

say Dumper $job;    

say $job->script();
if (my $j = $job->run()) {
    say "Job submitted: $j";
} else {
    say "Job not submitted: $j";
}