#ABSTRACT: NBI::QueuedJob, to describe a job from the SLURM queue (squeue)
use strict;
use warnings;
package NBI::QueuedJob;
use Carp qw(confess croak);
require Exporter;
our @ISA = qw(Exporter);


$NBI::QueuedJob::VERSION = $NBI::Slurm::VERSION;
our $VALID_ATTR_STR="ACCOUNT|GRES|MIN_CPUS|MIN_TMP_DISK|END_TIME|FEATURES|GROUP|OVER_SUBSCRIBE|JOBID|NAME|COMMENT|TIME_LIMIT|MIN_MEMORY|REQ_NODES|COMMAND|PRIORITY|QOS|REASON|ST|USER|RESERVATION|WCKEY|EXC_NODES|NICE|S:C:T|JOBID|EXEC_HOST|CPUS|NODES|DEPENDENCY|ARRAY_JOB_ID|GROUP|SOCKETS_PER_NODE|CORES_PER_SOCKET|THREADS_PER_CORE|ARRAY_TASK_ID|TIME_LEFT|TIME|NODELIST|CONTIGUOUS|PARTITION|PRIORITY|NODELIST(REASON)|START_TIME|STATE|USER|SUBMIT_TIME|LICENSES|CORE_SPEC|SCHEDNODES|WORK_DIR";
our $VALID_STATUS_STR="PENDING,RUNNING,SUSPENDED,COMPLETED,CANCELLED,FAILED,TIMEOUT,NODE_FAIL,PREEMPTED,BOOT_FAIL,DEADLINE,OUT_OF_MEMORY,COMPLETING,CONFIGURING,RESIZING,REVOKED,SPECIAL_EXIT";
our @VALID_ATTR=split(/\|/,$VALID_ATTR_STR);
our @VALID_STATUS=split(/,/,$VALID_STATUS_STR);

# Append to @VALID_STATUS also @FORMAT_STRINGS
@VALID_ATTR = (@VALID_ATTR, keys %NBI::Slurm::FORMAT_STRINGS);
# make uc all VALID_ATTR
@VALID_ATTR = map {uc($_)} @VALID_ATTR;
sub new {
    my $class = shift @_;
    my $username;
    my $queue;
    my $name;
    my $jobid;
    my $status;
    my $attrs = {};
    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        my %data = @_;
        # Try parsing
        for my $i (keys %data) {
            if ($i =~ /^-user/) {
                $username = $data{$i};
            } elsif ($i =~ /^-jobid/) {
                # Check it's an integer 
                if ($data{$i} =~ /^\d+$/) {
                    $jobid = $data{$i};
                } else {
                    confess "ERROR NBI: -threads expects an integer\n";
                }
            } elsif ($i =~ /^-queue/) {
                $queue = $data{$i};
            } elsif ($i =~ /^-status/) {
                # Check it's a valid status
                if (grep {$_ eq uc($data{$i})} @VALID_STATUS) {
                    $status = uc($data{$i});
                } else {
                    confess "ERROR NBI: -status expects one of the following values: $VALID_STATUS_STR\n";
                }
            
            } elsif ($i =~ /^-name/) {
                $name = $data{$i};
            } elsif ($i =~ /^-(\w+)/) {
                if (grep {$_ eq uc($1)} @VALID_ATTR) {
                    if (defined $data{$i}) {
                        $attrs->{uc($1)} = $data{$i};
                    } else {
                        croak "ERROR NBI: -$1 expects a value\n";
                    }
                } else {
                    confess "ERROR NBI: Unknown parameter -$1\nValid parameters are:  ",
                    join("\n -",@VALID_ATTR), "\n";
                }
            } else {
                confess "ERROR NBI: Unknown option/parameter $i\n";
            }
        }
    } 
    
    my $self = bless {}, $class;
    
    # Set attributes
    $self->username    = defined $username ? $username : undef;
    $self->queue       = defined $queue ? $queue : undef;
    $self->name        = defined $name ? $name : undef;
    $self->jobid       = defined $jobid ? $jobid : undef;
    $self->status      = defined $status ? $status : undef;
    $self->{attrs}     = $attrs;
    return $self;
}

sub username : lvalue {
    # Update threads
    my ($self, $new_val) = @_;
    $self->{username} = $new_val if (defined $new_val);
    return $self->{username};
}

sub queue : lvalue {
    # Update queue
    my ($self, $new_val) = @_;
    $self->{queue} = $new_val if (defined $new_val);
    return $self->{queue};
}

sub name : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{name} = $new_val if (defined $new_val);
    return $self->{name};
}

sub jobid : lvalue {
    # Update jobid
    my ($self, $new_val) = @_;
    confess "ERROR NBI::Queue: jobid must be an integer\n" if (defined $new_val && $new_val !~ /^\d+$/);
    $self->{jobid} = $new_val if (defined $new_val);
    return $self->{jobid};
}

sub status : lvalue {
    # Update status
    my ($self, $new_val) = @_;
    confess "ERROR NBI::Queue: status must be one of the following values: $VALID_STATUS_STR\n" if (defined $new_val && !grep {$_ eq uc($new_val)} @VALID_STATUS);
    $self->{status} = $new_val if (defined $new_val);
    return $self->{status};
}
1;
