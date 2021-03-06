package Miniqlo::RunningFile;
use Miniqlo::Base;
use Miniqlo::Util 'with_timeout';
use Fcntl ();

sub new ($class, $path) {
    bless { path => $path, fh => undef }, $class;
}

sub path ($self) { $self->{path} }
sub fh ($self) {
    $self->{fh} ||= do {
        sysopen my $fh, $self->path, Fcntl::O_RDWR() | Fcntl::O_CREAT()
            or die "Cannot open @{[$self->path]}: $!";
        $fh;
    };
}

sub is_running ($self) {
    return 0 unless -f $self->path;
    if ($self->lock) {
        $self->unlock;
        0;
    } else {
        sysseek $self->fh, 0, 0;
        sysread $self->fh, my $buffer, 10, 0;
        if (length($buffer) != 10) {
            warn "oops";
            return -1;
        } else {
            return 0+$buffer
        }
    }
}

sub lock ($self, $timeout = 0) :method {
    my $fh = $self->fh;
    if ($timeout) {
        my $ok = with_timeout $timeout, sub {
            flock $fh, Fcntl::LOCK_EX;
        };
        return $ok;
    } else {
        return flock $fh, Fcntl::LOCK_EX | Fcntl::LOCK_NB;
    }
}

sub write_pid ($self, $pid) {
    sysseek $self->fh, 0, 0;
    syswrite $self->fh, sprintf "%010d", $pid;
}

sub unlock ($self) {
    flock $self->fh, Fcntl::LOCK_UN;
}

sub unlink ($self) :method {
    unlink $self->path if -f $self->path;
    close $self->fh if $self->fh;
}

1;
