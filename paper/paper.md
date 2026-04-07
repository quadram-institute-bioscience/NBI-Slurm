---
title: 'NBI-Slurm: Simplified submission of Slurm jobs with energy saving mode'
tags:
  - slurm
  - hpc
  - energy-saving
  - perl
  - bioinformatics
authors:
  - name: Andrea Telatin
    affiliation: "1, 2"
    orcid: 0000-0001-7619-281X
affiliations:
  - name: Quadram Institute Bioscience, Norwich, NR4 7UQ, UK
    ror: "04td3ys19"
    index: 1
  - name: Center for Microbial Interactions, Norwich Research Park, Norwich, NR4 7UG, UK
    index: 2
date: "18 March 2026"
bibliography: paper.bib
---

# Summary

NBI-Slurm is a Perl package that provides a simplified, user-friendly interface for submitting and managing jobs on SLURM [@jette2002slurm] high-performance computing (HPC) clusters.
It offers both a library of Perl modules for programmatic job management and a suite of command-line tools designed to reduce the cognitive overhead of SLURM's native interface.
Distinctive features of NBI-Slurm are (a) TUI applications to view and cancel jobs, (b) the possibility to generate tool specific wrappers for (bioinformatic) tools and (c) an energy-aware scheduling mode — "eco mode" — that automatically defers flexible jobs
to off-peak periods, helping research institutions reduce their computational carbon footprint without requiring users to manually plan submission times.

# Statement of Need

HPC clusters are indispensable in modern research, particularly in the life sciences where large-scale sequence analyses, genome assemblies,
and statistical models demand resources beyond a desktop workstation. 
SLURM has become the dominant workload manager in this space [@slurm_adoption], yet its interface presents a steep learning curve.
Users must learn a verbose `sbatch` scripting syntax, understand resource unit conventions (memory in megabytes, time in `D-HH:MM:SS` format),
manage job dependencies manually, and repeat boilerplate directives across every submission script.

Workflow managers such as Snakemake [@molder2021snakemake] and Nextflow [@di2017nextflow] address this at the pipeline level by abstracting SLURM as an execution backend,
but they require users to rewrite their analysis logic inside a domain-specific language. 
Many researchers have existing shell scripts or one-off analyses that do not warrant a full pipeline refactor. 
NBI-Slurm occupies a complementary niche: it wraps SLURM's interface without imposing a workflow model, 
making it straightforward to submit individual commands or small batches while retaining access to all SLURM features through pass-through options.

The `lsjobs` utility prints a colour-coded, human-readable table of queued jobs as a static snapshot, offering a more ergonomic alternative to the raw output of `squeue`.
Its companion tool `viewjobs` provides a fully interactive terminal user interface (TUI) that allows users to browse the live job queue without leaving the terminal (\autoref{fig:viewjobs}).
Users can scroll through jobs with arrow or Vim keys, sort columns, inspect per-job details, toggle column visibility, and adjust column widths interactively.
Individual jobs can be selected with `Space` and multiple selected jobs can be cancelled in bulk with a single keypress, removing the need to copy-paste job IDs into `scancel`.

![Interactive TUI of `viewjobs`, showing job navigation, multi-column display, and bulk-cancel workflow. The image is AI generated from a real screenshot (Google NanoBanana) \label{fig:viewjobs}](viewjobs.png)

Energy consumption in research computing is a growing concern [@lannelongue2021green]. Most researchers have no practical mechanism to shift flexible jobs to periods when grid electricity is cheaper or cleaner. NBI-Slurm addresses this directly with a configurable scheduling module that calculates the next available low-energy window and injects a `--begin` directive into the submission, requiring no change to the underlying command.

# NBI::Slurm package

## Availability and Installation

NBI-Slurm is distributed under the MIT licence and is available from CPAN as `NBI::Slurm`. 
Installation requires Perl 5.16 or later and can be performed with:

```bash
cpanm NBI::Slurm
```

The source code is hosted at <https://github.com/quadram-institute-bioscience/NBI-Slurm> under continuous integration.
Development has been active since June 2023, and the module is published to the MetaCPAN repository at <https://metacpan.org/dist/NBI-Slurm>.

## Code Structure and Dependencies

The package is organised into two layers.

**Perl module library (`lib/NBI/`):** Five classes model the key abstractions:

- `NBI::Opts` — encapsulates SLURM resource directives (queue, threads, memory, wall-time, email, job arrays, start time). It accepts human-friendly inputs such as `"8GB"` or `"2h30m"` and converts them to SLURM's expected formats.
- `NBI::Job` — represents a job to be submitted, holding a command (or list of commands) and an `NBI::Opts` object. The `script()` method generates a complete `sbatch` script; `run()` submits it and returns the job identifier.
- `NBI::Queue` — queries the live SLURM queue via `squeue` and returns a list of `NBI::QueuedJob` objects, optionally filtered by user, status, name, or queue.
- `NBI::QueuedJob` — a lightweight data object representing one queued job, used by the queue-management tools.
- `NBI::EcoScheduler` — implements the energy-aware scheduling logic. Given a job's expected duration and a set of configurable windows, it finds the next period satisfying a three-tier preference: (1) job completes within an eco window and avoids peak hours; (2) job starts in an eco window and avoids peak hours but may overrun; (3) job starts in an eco window and partially overlaps peak hours. Default windows target weekday nights (00:00–06:00) and weekend off-peak periods (00:00–07:00, 11:00–16:00), avoiding evening peaks (17:00–20:00), all of which are fully configurable with a settings file (by default `~/.nbislurm.config`).

**Command-line tools (`bin/`):**

| Tool | Purpose |
|------|---------|
| `runjob` | Submit a command as a SLURM job with resource flags |
| `lsjobs` | List, filter, and cancel user jobs with coloured tabular output |
| `viewjobs` | Interactive terminal UI for job management |
| `waitjobs` | Block until jobs matching a pattern complete |
| `whojobs` | Show cluster utilisation grouped by user |
| `session` | Launch an interactive SLURM session |

Runtime dependencies are deliberately minimal: `Capture::Tiny` (>=0.40), `JSON::PP`, `Text::ASCIITable` (>=0.22), `Term::ANSIColor`, `Storable`, and `POSIX`—all either part of the Perl core or widely available on CPAN.


## Documentation

Each module is documented with embedded POD (Plain Old Documentation), rendered on CPAN at <https://metacpan.org/dist/NBI-Slurm>.
Each command-line tool provides a `--help` flag and a manual page generated from its POD. 
A user guide with annotated examples is maintained in the repository's `README.md`. 
The test suite (`t/`) covers unit behaviour of every module and integration behaviour of the command-line tools; author-facing tests (`xt/`) verify POD completeness and coverage.
All tests will be able to check functions even without Slurm. To check the ability to interact with Slurm, there are optional tests that can be executed with `prove -lv xt/hpc-*.t`.


## Wrappers

NBI-Slurm includes a declarative wrapper framework built around three classes: `NBI::Launcher`, `NBI::Manifest`, and `NBI::Pipeline`.
A wrapper is a small Perl module that subclasses `NBI::Launcher` and describes a bioinformatics tool — its inputs, parameters, outputs, activation method (HPC module, conda environment, or Singularity image), and SLURM resource defaults — in a single constructor call.
The only method that subclasses typically need to override is `make_command()`, which returns the tool invocation string; the base class handles input validation, scratch-directory setup, shell script generation, and job submission.
`NBI::Manifest` serialises all resolved inputs, parameters, outputs, and SLURM resources to a JSON provenance file written alongside the results at submission time, then patched in-place by the job script itself upon completion or failure — with no dependency on external tools such as `jq`.
Multi-step analyses can be expressed as `NBI::Pipeline` objects that wire `afterok` SLURM dependencies between `NBI::Job` instances automatically.
The bundled `NBI::Launcher::Kraken2` module illustrates the pattern: it declares paired- or single-end FASTQ inputs, a database directory that defaults to the `KRAKEN2_DB` environment variable, and a `threads` parameter that is automatically synchronised from the `--cpus` SLURM flag; its `build()` override measures the database folder size at submission time and inflates the memory request accordingly (40% headroom plus a 100 GB fixed overhead), ensuring the job is unlikely to be killed by the out-of-memory handler without requiring the user to perform any calculation.
Third-party wrappers can be placed in `~/.nbi/launchers/` and are discovered automatically by the `nbilaunch` command-line tool.

## Example commands

**Submitting a parallel job.** A researcher wishing to run a genome assembler with 18 cores, 64 GB RAM, and a 12-hour wall-time can write:

```bash
runjob -n "assembly" -c 18 -m 64 -t 12 -w ./logs/ \
  "flye --nano-raw reads.fastq --out-dir asm"
```

**Processing a file list as a job array.** To align 200 FASTQ files, one job per file:

```bash
runjob -n "align" -c 8 -m 16 --files samples.txt \
  "bwa mem ref.fa #FILE# > #FILE#.bam"
```

**Energy-aware deferral.** A long-running but flexible annotation job can be scheduled for the next eco window automatically. Note that by default the *eco mode*
is enabled, and can be overridden with `--no-eco` or setting the economy_mode=0 in the configuration file.

```bash
runjob --eco -n "annotate" -t 6 "prokka genome.fa"
```

NBI-Slurm calculates the next suitable window (e.g., the following night) and adds `--begin=2026-03-19T00:00:00` to the submission without any further user action.

**Programmatic job chaining.** In a Perl analysis script:

```perl
use NBI::Job;
use NBI::Opts;

my $opts = NBI::Opts->new(
    -queue => "long", 
    -threads => 16, 
    -memory => 32, 
    -time => "4h");
my $job  = NBI::Job->new(
    -name => "step1", 
    -command => "python align.py", 
    -opts => $opts);
my $id   = $job->run();

my $opts2 = NBI::Opts->new(
    -queue => "short", 
    -threads => 4, 
    -memory => 8, 
    -time => "1h");
my $job2  = NBI::Job->new(
    -name => "step2", 
    -command => "python report.py --input results/", 
    -opts => $opts2);
$job2->opts->dependencies([$id]);
$job2->run();
```


# Acknowledgements

The author gratefully acknowledges the support of the Biotechnology and Biological Sciences Research Council (BBSRC);
this research was funded by the BBSRC Institute Strategic Programme Food Microbiome and Health BB/X011054/1 and its constituent project(s) BBS/E/QU/230001B;
the BBSRC Institute Strategic Programme Microbes and Food Safety BB/X011011/1 and its constituent project(s) BBS/E/QU/230002C; the BBSRC Core Capability Grant BB/CCG2260/1.
This research was also supported by the infrastructure provided by the CLIMB-BIG-DATA grant MR/T030062/1. 
The author thanks colleagues at the Quadram Institute Bioscience for feedback and field-testing during development,
and the GreenDISC working group and NBI Research Computing for support and discussions.

# AI Usage Disclosure

Claude Code (Anthropic) was used during development of NBI-Slurm from version 0.10.0 onwards, assisting with code generation, refactoring, test scaffolding, and documentation drafting.
It was also used to assist with drafting and editing this paper.
All AI-assisted outputs were reviewed, edited, and validated by the author,
who made all core design decisions and retains full responsibility for the accuracy, originality,
and correctness of the submitted materials.

# References
