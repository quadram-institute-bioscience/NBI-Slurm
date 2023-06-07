package NBI::Job;
#ABSTRACT: A class for representing a job for NBI::Slurm

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
use File::Spec::Functions;
$Data::Dumper::Sortkeys = 1;
use File::Basename;

$NBI::Job::VERSION           = $NBI::Slurm::VERSION;
my $DEFAULT_QUEUE               = "nbi-short";
require Exporter;
our @ISA = qw(Exporter);


=head1 SYNOPSIS

A job object supported from C<NBI::Slurm> .

=over 4

=item B<name>

The actual sequence, the only mandatory field (string)
 

=back

  use NBI::Job;
  my $job = new(
    -name => "job-name",
    -command => "ls -l",
  );

  # Multi commands
    my $job = new(
    -name => "job-name",
    -commands => ["ls -l", "echo done"]
  );

=head1 MAIN METHODS 

=head2 new()

Create a new instance of C<NBI::Seq>.
The sequence is the only required field.


=cut

sub new {
    my $class = shift @_;
    my ($job_name, $commands_array, $command, $opts);

    # Descriptive instantiation with parameters -param => value
    if (substr($_[0], 0, 1) eq '-') {
        my %data = @_;
        # Try parsing
        for my $i (keys %data) {
            if ($i =~ /^-name/) {
                $job_name = $data{$i};
            } elsif ($i =~ /^-command$/) {
                $command = $data{$i};
            } elsif ($i =~ /^-opts$/) {
                # Check that $data{$i} is an instance of NBI::Opts
                if ($data{$i}->isa('NBI::Opts')) {
                    # $data{$i} is an instance of NBI::Opts
                    $opts = $data{$i};
                } else {
                    # $data{$i} is not an instance of NBI::Opts
                    confess "ERROR NBI::Job: -opts must be an instance of NBI::Opts\n";
                }
                
            } elsif ($i =~ /^-commands$/) {
                # Check that $data{$i} is an array
                if (ref($data{$i}) eq 'ARRAY') {
                    $commands_array = $data{$i};
                } else {
                    confess "ERROR NBI::Job: -commands must be an array\n";
                }
            } else {
                confess "ERROR NBI::Seq: Unknown parameter $i\n";
            }
        }
    } 
    
    my $self = bless {}, $class;
    

    $self->{name} = defined $job_name ? $job_name : 'job-' . int(rand(1000000));
    $self->{jobid} = 0;
    
    # Commands: if both commands_array and command are defined, append command to commands_array
    if (defined $commands_array) {
        $self->{commands} = $commands_array;
        if (defined $command) {
            push @{$self->{commands}}, $command;
        }
    } elsif (defined $command) {
        $self->{commands} = [$command];
    } 

    # Opts must be an instance of NBI::Opts, check first
    if (defined $opts) {
        # check that $opts is an instance of NBI::Opts
        if ($opts->isa('NBI::Opts')) {
            # $opts is an instance of NBI::Opts
            $self->{opts} = $opts;
        } else {
            # $opts is not an instance of NBI::Opts
            confess "ERROR NBI::Job: -opts must be an instance of NBI::Opts\n";
        }
  
    } else {
        $self->{opts} = NBI::Opts->new($DEFAULT_QUEUE);
    }
    return $self;
 
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
    if (defined $new_val and $new_val !~ /^-?(\d+)$/) {
        confess "ERROR NBI::Job: jobid must be an integer ". $new_val ."\n";
    }
    $self->{jobid} = $new_val if (defined $new_val);
    return $self->{jobid};
}

sub outputfile : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{output_file} = $new_val if (defined $new_val);
    if (not defined $self->{output_file}) {
        $self->{output_file} = catfile( $self->opts->tmpdir , $self->name . ".%j.out");
    } else {
        return $self->{output_file};
    }
}

sub errorfile : lvalue {
    # Update name
    my ($self, $new_val) = @_;
    $self->{error_file} = $new_val if (defined $new_val);
    if (not defined $self->{error_file}) {
        $self->{error_file} =  catfile($self->opts->tmpdir, $self->name . ".%j.err");
    } else {
        return $self->{error_file};
    }
    
}
sub append_command {
    my ($self, $new_command) = @_;
    push @{$self->{commands}}, $new_command;
}

sub prepend_command {
    my ($self, $new_command) = @_;
    unshift @{$self->{commands}}, $new_command;
}

sub commands {
    my ($self) = @_;
    return $self->{commands};
}

sub commands_count {
    my ($self) = @_;
    return 0 + scalar @{$self->{commands}};
}

sub set_opts {
    my ($self, $opts) = @_;
    # Check that $opts is an instance of NBI::Opts
    if ($opts->isa('NBI::Opts')) {
        # $opts is an instance of NBI::Opts
        $self->{opts} = $opts;
    } else {
        # $opts is not an instance of NBI::Opts
        confess "ERROR NBI::Job: -opts must be an instance of NBI::Opts\n";
    }
}

sub get_opts {
    my ($self) = @_;
    return $self->{opts};
}

sub opts {
    my ($self) = @_;
    return $self->{opts};
}

## Run job

sub script {
    # Generate the sbatch script
    my ($self) = @_;
    
    my $template = [
    '#SBATCH -J NBI_SLURM_JOBNAME',
    '#SBATCH -o NBI_SLURM_OUT',
    '#SBATCH -e NBI_SLURM_ERR',
    ''
    ];
    my $header = $self->opts->header();
    # Replace the template
    my $script = join("\n", @{$template});
    # Replace the values
    
    my $name = $self->name;
    my $file_out = $self->outputfile;
    my $file_err = $self->errorfile;
    $script =~ s/NBI_SLURM_JOBNAME/$name/g;
    $script =~ s/NBI_SLURM_OUT/$file_out/g;
    $script =~ s/NBI_SLURM_ERR/$file_err/g;

    # Add the commands
    $script .= join("\n", @{$self->{commands}});
    
    
    # Add the commands
    $script .= join("\n", @{$self->{commands}});
    return $header . $script;

}

sub run {
    my $self = shift @_;
        # Check it has some commands
    
 
    # Check it has a queue
    if (not defined $self->opts->queue) {
        confess "ERROR NBI::Job: No queue defined for job " . $self->name . "\n";
    }
    # Check it has some opts
    if (not defined $self->opts) {
        confess "ERROR NBI::Job: No opts defined for job " . $self->name . "\n";
    }
    # Check it has some commands
    if ($self->commands_count == 0) {
        confess "ERROR NBI::Job: No commands defined for job " . $self->name . "\n";
    }

    # Create the script
    my $script = $self->script();

    # Create the script file
    my $script_file = catfile($self->opts->tmpdir, $self->name . ".sh");
    open(my $fh, ">", $script_file) or confess "ERROR NBI::Job: Cannot open file $script_file for writing\n";
    print $fh $script;
    close($fh);

    # Run the script

    if (_has_command('sbatch') == 0) {
        $self->jobid = -1;
        return 0;
    }
    my $job_output = `sbatch "$script_file"`;

    # Check the output
    if ($job_output =~ /Submitted batch job (\d+)/) {
        # Job submitted
        my $job_id = $1;
        # Update the job id
        $self->{job_id} = $job_id;
        return $job_id;
    } else {
        # Job not submitted
        confess "ERROR NBI::Job: Job " . $self->name . " not submitted\n";
    }
    return $self->jobid;
}


sub _has_command {
    my $command = shift;
    my $is_available = 0;
    
    if ($^O eq 'MSWin32') {
        # Windows system
        $is_available = system("where $command >nul 2>nul") == 0;
    } else {
        # Unix-like system
        $is_available = system("command -v $command >/dev/null 2>&1") == 0;
    }
    
    return $is_available;
}

sub _to_string {
    # Convert string to a sanitized string with alphanumeric chars and dashes
    my ($self, $string) = @_;
    return $string =~ s/[^a-zA-Z0-9\-]//gr; 
}
1;