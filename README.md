# NBI-Slurm

<img align="right" src="docs/one-mouse.svg"  width="128">

[![Ubuntu_18](https://github.com/quadram-institute-bioscience/NBI-Slurm/actions/workflows/main.yml/badge.svg)](https://github.com/quadram-institute-bioscience/NBI-Slurm/actions/workflows/main.yml)



## New Batch Interface for SLURM

`NBI::Slurm` is a Perl package that provides a convenient interface for submitting jobs to SLURM, 
a workload manager for *High-Performance Computing* (HPC) clusters. 
It includes two main classes: 

 * `NBI::Job`, which represents a job to be submitted to SLURM, and 
 * `NBI::Opts`, which represents the SLURM options for a job.

Features

 * Very experimental, very alpha, very buggy.
 * Easily create and configure SLURM jobs using the NBI::Job class.
 * Set job name, commands to execute, output and error file paths, and more.
 * Define SLURM options, such as queue, number of threads, allocated memory, and execution time, using the NBI::Opts class.
 * Generate the SLURM header for the job script.
 * Submit jobs to SLURM with just a few lines of code.


## Installation

To use NBI::Slurm, you need Perl 5.12 or higher installed on your system. 
You can install the package using CPAN or manually by copying the NBI/Slurm.pm file to your Perl library directory.


cpanm is a command line utility for installing Perl modules from CPAN.

To install cpanm, run the following command:
```bash
# If you dont have cpanm installed:
curl -L https://cpanmin.us | perl - --sudo App::cpanminus

# Install with cpanm
cpanm NBI::Slurm
```


## Usage

Here's a simple example demonstrating how to use NBI::Slurm to submit a job to SLURM:

```perl
use NBI::Job;
use NBI::Opts;

# Create a job
my $job = NBI::Job->new(
    -name => "job-name",
    -command => "ls -l",
);

# Create options
my $opts = NBI::Opts->new(
    -queue => "short",
    -threads => 4,
    -memory => 8,
    -opts  => ["--output=TestJob.out", "--mail-user user@nmsu.edu"],
);

# Set options for the job
$job->set_opts($opts);

# Submit the job to SLURM
my $jobid = $job->run;
```

For more detailed information on the available methods and options, please refer to the individual documentation of the NBI::Job and NBI::Opts classes.

## Author

NBI::Slurm is written by Andrea Telatin

## License

This module is released under the MIT License.
