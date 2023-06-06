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
    my ($queue, $memory, $threads, $opts_array, $tmpdir) = (undef, undef, undef, undef, undef);

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
            } elsif ($i =~ /^-opts/) {
                # in this case we expect an array
                if (ref($data{$i}) ne "ARRAY") {
                    confess "ERROR NBI::Seq: -opts expects an array\n";
                }
                $opts_array = $data{$i};
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
    $self->tmpdir = defined $tmpdir ? $tmpdir : $SYSTEM_TEMPDIR;

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
    $str .= " tmpdir:\t$self->{tmpdir}\n";
    $str .= " ---------------------------\n";
    for my $o (@{$self->{opts}}) {
        $str .= "#SBATCH $o\n";
    }
    return $str;
}


sub _mem_parse_mb {
    my $mem = shift @_;
    if ($mem=~/^(\d+)$/) {
        # bare number: interpret as MB
        return $mem;
    } elsif ($mem=~/^(\d+)\.?(MB|GB|TB)$/i) {
        if (uc($2) == "GB") {
            $mem = $1 * 1024;
        } elsif (uc($2) == "TB") {
            $mem = $1 * 1024 * 1024;
        } else {
            $mem = $1;
        }
    } else {
        confess "ERROR NBI::Opts: Cannot parse memory value $mem\n";
    }
    return $mem;
}



1;