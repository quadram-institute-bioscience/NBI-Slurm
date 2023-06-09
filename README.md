# NBI-Slurm

<a href="https://metacpan.org/dist/NBI-Slurm"><img align="right" src="docs/one-mouse.svg"  width="128"></a>

[![.github/workflows/main.yml](https://github.com/quadram-institute-bioscience/NBI-Slurm/actions/workflows/main.yml/badge.svg)](https://github.com/quadram-institute-bioscience/NBI-Slurm/actions/workflows/main.yml)
[![MetaCpan](https://img.shields.io/cpan/v/NBI-Slurm)](https://metacpan.org/dist/NBI-Slurm)
[![testers](https://img.shields.io/badge/CPAN%20Testers-status-brightgreen)](http://matrix.cpantesters.org/?dist=NBI-Slurm;maxver=1)

## New Batch Interface for SLURM

[`NBI::Slurm`](https://metacpan.org/dist/NBI-Slurm) is a Perl package that provides a convenient interface for submitting jobs to SLURM, 
a workload manager for *High-Performance Computing* (HPC) clusters. 
It includes two main classes to submit jobs to SLURM: 

* `NBI::Job`, which represents a job to be submitted to SLURM, and 
* `NBI::Opts`, which represents the SLURM options for a job.

And two classes to manage the output of the jobs:

* `NBI::Queue`, which represents the content of the SLURM queue, and
* `NBI::QueuedJob`, which represents a single job in the queue.

Features

* Very experimental, very alpha, very buggy.
* Easily create and configure SLURM jobs using the NBI::Job class.
* Comes with binaries to submit jobs, list jobs, wait for jobs, etc.
  
## Installation

To use [NBI::Slurm](https://metacpan.org/dist/NBI-Slurm), you need Perl 5.12 or higher installed on your system. 
You can install the package using CPAN or manually by copying the NBI/Slurm.pm file to your Perl library directory.

cpanm is a command line utility for installing Perl modules from CPAN.

To install cpanm, run the following command:

```bash
# If you dont have cpanm installed:
curl -L https://cpanmin.us | perl - --sudo App::cpanminus

# Install with cpanm
cpanm NBI::Slurm
```

## Scripts

* List or cancel your jobs in the queue with **lsjobs**

```bash
lsjobs [options] [jobid.. | pattern ]
```

* Submit a job to the queue (with cores, memory, time, etc) with **runjob**

```bash
runjob -n "my-job" -t 2 -r -c 18 -m 32 --after "python script.py --threads 18"
```

* Wait for all jobs matching a pattern to finish (to be used to run a second job when they are all finished), with **waitjobs**

```bash
waitjobs [-u $USER] [pattern]
```

* Who is using the cluster: list usernames and number of jobs in ascending order with **whojobs**

```bash
whojobs [--min-jobs INT]
```

## Library Usage

Here's a simple example demonstrating how to use NBI::Slurm to submit a job to SLURM:

```perl
use NBI::Job;
use NBI::Opts;

# Create a job
my $job = NBI::Job->new(
    -name    => "job-name",
    -command => "ls -l",
);

# Create options
my $opts = NBI::Opts->new(
    -queue   => "short",
    -threads => 4,
    -memory  => 8,
    -opts    => ["-m afterok:1234"],
);

# Set options for the job
$job->set_opts($opts);

# Submit the job to SLURM
my $jobid = $job->run;
```

For more detailed information on the available methods and options, please refer to the individual documentation of the NBI::Job and NBI::Opts classes.

## Author

[NBI::Slurm](https://metacpan.org/dist/NBI-Slurm) is written by [Andrea Telatin](https://telatin.github.io)

## License

This module is released under the [MIT License](https://mit-license.org/).
