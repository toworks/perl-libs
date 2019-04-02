package serial;{ 
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use Data::Dumper;
# Win32::SerialPort  - Win32
# Device::SerialPort - Linux
  BEGIN
  {
	my $OS_win = ($^O eq "MSWin32") ? 1 : 0;
	if ($OS_win) 
	{
	  eval "use Win32::SerialPort";
	  die "$@\n" if ($@);
	}
	else 
	{
	  eval "use Device::SerialPort";
	  die "$@\n" if ($@);
	}
  }

  sub new {
    my($class, $log) = @_;
    my $self = bless {	'serial' => {'error' => 1},
                        'log' => $log,
    }, $class;

    return $self;
  }

  sub get {
    my($self, $name) = @_;
    return $self->{serial}->{$name};
  }

  sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{serial}->{$key} = $set{$key};
    }
  }

  sub connect {
	my($self) = @_;
	eval{
			my $OS_win = ($^O eq "MSWin32") ? 1 : 0;
			if ($OS_win) 
			{
				$self->{fh} = new Win32::SerialPort($self->{serial}->{comport}) or die "$^E";
			}
			else 
			{
				$self->{fh} = new Device::SerialPort($self->{serial}->{comport}) or die "$^E";
			}

			$self->{fh}->databits($self->{serial}->{databits}) or die "$^E";
			$self->{fh}->baudrate($self->{serial}->{baud}) or die "$^E";
			$self->{fh}->parity($self->{serial}->{parity}) or die "$^E";
			$self->{fh}->stopbits($self->{serial}->{stopbits}) or die "$^E";
			$self->{fh}->handshake($self->{serial}->{handshake} || 'none') or die "$^E";
			$self->{fh}->read_interval(100) or die "$^E";
			$self->{fh}->read_const_time(100) or die "$^E";
			$self->{fh}->buffers(4096, 4096) or die "$^E"; # read, write returns current in list context
			$self->{fh}->error_msg(1) or die "$^E";
			$self->{fh}->user_msg(1) or die "$^E";
			$self->{fh}->write_settings or die "$^E";
			$self->{serial}->{error} = 0;
	};
	if($@) { $self->{serial}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

}
1;
