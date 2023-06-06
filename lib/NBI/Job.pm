package NBI::Job;
#ABSTRACT: A class for representing a job for NBI::Slurm

use 5.012;
use warnings;
use Carp qw(confess);
use Data::Dumper;
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
    '#!/bin/bash',
    '#SBATCH -p NBI_SLURM_QUEUE',
    '#SBATCH -t NBI_SLURM_DAYS-NBI_SLURM_HOURS:00',
    '#SBATCH -c NBI_SLURM_CORES',
    '#SBATCH --mem=NBI_SLURM_MEMMB',
    '#SBATCH -N NBI_SLURM_NODES',
    '#SBATCH -J NBI_SLURM_JOBNAME',
    '#SBATCH --mail-type=NBI_SLURM_MAILTYPE',
    '#SBATCH --mail-user=NBI_SLURM_MAILADDR',
    '#SBATCH -o NBI_SLURM_OUT',
    '#SBATCH -e NBI_SLURM_ERR'
    ];

    # Replace the template
    my $script = join("\n", @{$template});
    # Replace the values
    $script =~ s/NBI_SLURM_QUEUE/$self->opts->queue/g;
    $script =~ s/NBI_SLURM_DAYS/$self->opts->days/g;
    $script =~ s/NBI_SLURM_HOURS/$self->opts->hours/g;
    $script =~ s/NBI_SLURM_CORES/$self->opts->threads/g;
    $script =~ s/NBI_SLURM_MEMMB/$self->opts->memory/g;
    $script =~ s/NBI_SLURM_NODES/1/g;
    $script =~ s/NBI_SLURM_JOBNAME/$self->name/g;
    $script =~ s/NBI_SLURM_MAILTYPE/$self->opts->mail_type/g;
    $script =~ s/NBI_SLURM_MAILADDR/$self->opts->mail_user/g;
    $script =~ s/NBI_SLURM_OUT/$self->outputfile/g;
    $script =~ s/NBI_SLURM_ERR/$self->errorfile/g;

    # Add the commands
    $script .= join("\n", @{$self->{commands}});
    return $script;
END_SCRIPT
    # Add the commands
    $script .= join("\n", @{$self->{commands}});
    return $script;

}
sub run {
    my $self = shift @_;
    # Check it has some commands
    if ($self->commands_count == 0) {
        confess "ERROR NBI::Job: No commands defined for job " . $self->name . "\n";
    }
    # Check it has some opts
    if (not defined $self->opts) {
        confess "ERROR NBI::Job: No opts defined for job " . $self->name . "\n";
    }
    # Check it has a queue
    if (not defined $self->opts->queue) {
        confess "ERROR NBI::Job: No queue defined for job " . $self->name . "\n";
    }
    
    # Create the script
    
}
1;