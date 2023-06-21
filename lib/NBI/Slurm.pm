#ABSTRACT: NBI Slurm module
use strict;
use warnings;

package NBI::Slurm;
use NBI::Job;
use NBI::Opts;
use base qw(Exporter);
our @ISA = qw(Exporter);
our @EXPORT = qw(Job Opts %FORMAT_STRINGS);
$NBI::Slurm::VERSION = '0.4.1';




our %FORMAT_STRINGS = (
 'account'    => '%a',
 'jobid'      => '%A',
 'jobname'    => '%j',
 'cpus'       => '%C',
 'end_time'   => '%E',
 'start_time' => '%S',
 'total_time' => '%l',
 'time_left'  => '%L',
 'memory'     => '%m',
 'command'    => '%o',
 'queue'      => '%P',
 'reason'     => '%r',
 'status'     => '%T', # short: %t
 'workdir'    => '%Z',
 'user'       => '%u',
);





1;

__END__

=pod

=head1 SYNOPSIS

Submit jobs to SLURM using the CNBI::Job and CNBI::Opts classes.

  use NBI::Slurm;

Create options for the job:

my $opts = NBI::Opts->new(
  -queue => "short",
  -threads => 4,
  -memory => 8,
  
);

Create a job, using the options:

  my $job = NBI::Job->new(
    -name => "job-name",
    -command => "ls -l", 
    -opts => $opts,
  );


Submit the job to SLURM

  my $jobid = $job->run;

=head1 INTRODUCTION

=head2 HPC

I<High-Performance Computing> (HPC) refers to the use of powerful computing systems to solve complex problems that require significant computational resources. 
An B<HPC cluster> typically consists of multiple interconnected computers, referred to as nodes, which work together to perform computational tasks efficiently. The cluster includes a head node, which serves as the central control point for managing the cluster and handling job submissions. 

The I<head node> is responsible for coordinating the execution of jobs, scheduling resources, and distributing them among the execution nodes. Execution nodes, also known as compute nodes, are the workhorses of the cluster, performing the actual computations requested by users' jobs. These nodes are equipped with high-performance processors, large amounts of memory, and fast interconnects to ensure rapid data transfer and efficient parallel processing. 

By leveraging the combined power of the head node and execution nodes, HPC systems provide researchers and scientists with the capability to tackle computationally demanding tasks, such as large-scale simulations, data analysis, and modeling, to accelerate scientific discoveries and innovation.

=head2 SCHEDULERS

I<Schedulers> are an integral component of High-Performance Computing (HPC) systems, responsible for managing and allocating computing resources efficiently among multiple users and their jobs. 

HPC schedulers optimize resource utilization, minimize job waiting times, and ensure fair access to the available resources. 

One popular scheduler used in HPC environments is B<SLURM> (Simple Linux Utility for Resource Management). SLURM is an open-source, highly scalable, and flexible job scheduler that provides a comprehensive set of features for job submission, resource allocation, job prioritization, and job accounting. It offers a powerful command-line interface and extensive configuration options, making it suitable for a wide range of HPC clusters and workload management scenarios. 

SLURM's design philosophy focuses on scalability, fault-tolerance, and extensibility, making it a popular choice for many research institutions and supercomputing centers.

=head1 DESCRIPTION

The C<NBI::Slurm> package provides a set of classes and methods for submitting jobs to SLURM, a workload manager for high-performance computing (HPC) clusters. It includes the L<NBI::Job> and C<NBI::Opts> classes, which allow you to define and configure jobs to be submitted to SLURM.

The L<NBI::Job> class represents a job to be submitted to SLURM. 
It provides methods for setting the job name, defining the commands to be executed, setting the output and error file paths, and submitting the job to SLURM. 

The L<NBI::Opts> class represents the SLURM options for the job, such as the queue, number of threads, allocated memory, and execution time. It allows you to configure these options and generate the SLURM header for the job script.

By combining the NBI::Job and NBI::Opts classes, you can easily create and submit jobs to SLURM. 
The C<NBI::Slurm> package provides a convenient interface for interacting with SLURM and managing HPC jobs.

=head1 CLASSES

The C<NBI::Slurm> package includes the following classes:

=over 4

=item * L<NBI::Job>: Represents a job to be submitted to SLURM.

=item * L<NBI::Opts>: Represents the SLURM options for a job.

=back

Please refer to the documentation for each class for more information on their methods and usage.
