package NBI::Opts;
#ABSTRACT: A class for representing a the SLURM options for NBI::Slurm

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;

$NBI::Opts::VERSION           = $NBI::Slurm::VERSION;

my $SYSTEM_TEMPDIR = $ENV{'TMPDIR'} || $ENV{'TEMP'} || "/tmp";
require Exporter;
our @ISA = qw(Exporter);


=head1 SYNOPSIS

SLURM Options for C<NBI::Slurm> .

=over 4

=item B<name>

The actual sequence, the only mandatory field (string)
 

=back

  use NBI::Job;
  my $opts = new(
     -queue => "short",
     -threads => 4,
     -memory => 8,
     -opts  => ["--output=TestJob.out", "--mail-user user@nmsu.edu"],
  );


=head1 MAIN METHODS 

=head2 new()

Create a new instance of C<NBI::Seq>.
The sequence is the only required field.


=cut

sub new {
    my $class = shift @_;
    my ($queue, $memory, $threads, $opts_array, $tmpdir, $hours, $email_address, $email_when) = (undef, undef, undef, undef, undef, undef, undef);

    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        my %data = @_;
        # Try parsing
        for my $i (keys %data) {
            if ($i =~ /^-queue/) {
                $queue = $data{$i};
            } elsif ($i =~ /^-threads/) {
                # Check it's an integer 
                if ($data{$i} =~ /^\d+$/) {
                    $threads = $data{$i};
                } else {
                    confess "ERROR NBI::Seq: -threads expects an integer\n";
                }
            } elsif ($i =~ /^-memory/) {
                $memory = _mem_parse_mb($data{$i});
            } elsif ($i =~ /^-tmpdir/) {
                $memory = $data{$i};
            } elsif ($i =~ /^-mail/) {
                $email_address = $data{$i};
            } elsif ($i =~ /^-when/) {
                $email_when = $data{$i};
            } elsif ($i =~ /^-opts/) {
                # in this case we expect an array
                if (ref($data{$i}) ne "ARRAY") {
                    confess "ERROR NBI::Seq: -opts expects an array\n";
                }
                $opts_array = $data{$i};
            } elsif ($i =~ /^-time/) {
                $hours = _time_to_hour($data{$i});
            } else {
                confess "ERROR NBI::Seq: Unknown parameter $i\n";
            }
        }
    } 
    
    my $self = bless {}, $class;
    
    # Set attributes
    $self->queue = defined $queue ? $queue : "nbi-short";
    $self->threads = defined $threads ? $threads : 1;
    $self->memory = defined $memory ? $memory : 100;
    $self->hours = defined $hours ? $hours : 1;
    $self->tmpdir = defined $tmpdir ? $tmpdir : $SYSTEM_TEMPDIR;
    $self->email_address = defined $email_address ? $email_address : undef;
    $self->email_type = defined $email_when ? $email_when : "none";
    # Set options
    $self->opts = defined $opts_array ? $opts_array : [];
    return $self;
 
}


sub queue : lvalue {
    # Update queue
    my ($self, $new_val) = @_;
    $self->{queue} = $new_val if (defined $new_val);
    return $self->{queue};
}

sub threads : lvalue {
    # Update threads
    my ($self, $new_val) = @_;
    $self->{threads} = $new_val if (defined $new_val);
    return $self->{threads};
}

sub memory : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{memory} = _mem_parse_mb($new_val) if (defined $new_val);
    return $self->{memory};
}

sub email_address : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{email_address} = $new_val if (defined $new_val);
    return $self->{email_address};
}

sub email_type : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{email_type} = $new_val if (defined $new_val);
    return $self->{email_type};
}

sub hours : lvalue {
    # Update memory
    my ($self, $new_val) = @_;
    $self->{hours} = _time_to_hour($new_val) if (defined $new_val);
    return $self->{hours};
}

sub tmpdir : lvalue {
    # Update tmpdir
    my ($self, $new_val) = @_;
    $self->{tmpdir} = $new_val if (defined $new_val);
    return $self->{tmpdir};
}

sub opts : lvalue {
    # Update opts
    my ($self, $new_val) = @_;
    if (not defined $self->{opts}) {
        $self->{opts} = [];
        return $self->{opts};
    }
    # check newval is an array
    confess "ERROR NBI::Opts: opts must be an array, got $new_val\n" if (ref($new_val) ne "ARRAY");
    $self->{opts} = $new_val if (defined $new_val);
    return $self->{opts};
}
sub add_option {
    # Add an option
    my ($self, $new_val) = @_;
    push @{$self->{opts}}, $new_val;
    return $self->{opts};
}

sub opts_count {
    # Return the number of options
    my $self = shift @_;
    return defined $self->{opts} ? scalar @{$self->{opts}} : 0;
}

sub view {
    # Return a string representation of the object
    my $self = shift @_;
    my $str = " --- NBI::Opts object ---\n";
    $str .= " queue:\t$self->{queue}\n";
    $str .= " threads:\t$self->{threads}\n";
    $str .= " memory MB:\t$self->{memory}\n";
    $str .= " time (h):\t$self->{hours}\n";
    $str .= " tmpdir:\t$self->{tmpdir}\n";
    $str .= " ---------------------------\n";
    for my $o (@{$self->{opts}}) {
        $str .= "#SBATCH $o\n";
    }
    return $str;
}

sub header {
    # Return a header for the script based on the options
    my $self = shift @_;
    my $str = "#!/bin/bash\n";
    # Queue
    $str .= "#SBATCH -p " . $self->{queue} . "\n";
    # Nodes: 1
    $str .= "#SBATCH -N 1\n";
    # Time
    $str .= "#SBATCH -t " . $self->timestring() . "\n";
    # Memory
    $str .= "#SBATCH --mem=" . $self->{memory} . "\n";
    # Threads
    $str .= "#SBATCH -c " . $self->{threads} . "\n";
    # Mail
    if (defined $self->{email_address}) {
        $str .= "#SBATCH --mail-user=" . $self->{email_address} . "\n";
        $str .= "#SBATCH --mail-type=" . $self->{email_type} . "\n";
    }
    return $str;
}

sub timestring {
    my $self = shift @_;
    my $hours = $self->{hours};
    my $days = 0+ int($hours / 24);
    $hours = $hours % 24;
    # Format hours to be 2 digits
    $hours = sprintf("%02d", $hours);
    return "${days}-${hours}:00:00";
}

sub _mem_parse_mb {
    my $mem = shift @_;
    if ($mem=~/^(\d+)$/) {
        # bare number: interpret as MB
        return $mem;
    } elsif ($mem=~/^(\d+)\.?(MB?|GB?|TB?|KB?)$/i) {
        if (substr(uc($2), 0, 1) eq "G") {
            $mem = $1 * 1024;
        } elsif (substr(uc($2), 0, 1) eq "T") {
            $mem = $1 * 1024 * 1024;
        } elsif (substr(uc($2), 0, 1) eq "M") {
            $mem = $1;
        } elsif (substr(uc($2), 0, 1) eq "K") {
            continue;
        } else {
            # Consider MB
            $mem = $1;
        }
    } else {
        confess "ERROR NBI::Opts: Cannot parse memory value $mem\n";
    }
    return $mem;
}

sub _time_to_hour {
    # Get an integer (hours) or a string in the format \d+D \d+H \d+M
    my $time = shift @_;
    $time = uc($time);
    if ($time =~/^(\d+)$/) {
        # Got an integer
        return $1;
    } else {
        my $hours = 0;
        while ($time =~/(\d+)([DHM])/g) {
            my $val = $1;
            my $unit = $2;
            if ($unit eq "D") {
                
                $hours += $val * 24;
          
            } elsif ($unit eq "M") {
                $val /= 60;
                $hours += $val;

            } elsif ($unit eq "H") {
                $hours += $val;
    
            } elsif ($unit eq "S") {
                continue;
            } else {
                confess "ERROR NBI::Opts: Cannot parse time value $time\n";
            }
            
        }
        return $hours;
    }
}


1;