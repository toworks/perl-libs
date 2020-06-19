package mqtt;{
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use Net::MQTT::Simple;
  use Data::Dumper;
  
  sub new {
    my($class, $log) = @_;
    my $self = bless {	'mqtt' => {'error' => 1},
                        'log' => $log,
    }, $class;

    return $self;
  }

  sub get {
    my($self, $name) = @_;
    return $self->{mqtt}->{$name};
  }

  sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{mqtt}->{$key} = $set{$key};
    }
  }

  sub connect {
	my($self) = @_;

	# Allow unencrypted connection with credentials
	$ENV{MQTT_SIMPLE_ALLOW_INSECURE_LOGIN} = 1;

	my $connection_string = $self->{mqtt}->{host} || 'localhost';

	$connection_string .= $self->{mqtt}->{port} || 1883;
	
	$self->{log}->save('d', "$connection_string") if $self->{mqtt}->{'DEBUG'};
	
    eval{ 	$self->{mqtt}->{mqtt} = Net::MQTT::Simple->new($connection_string) or die "$!";
 			# Depending if authentication is required, login to the broker
			if( $self->{mqtt}->{user} and $self->{mqtt}->{password} ) {
				$self->{mqtt}->{mqtt}->login($$self->{mqtt}->{user}, $self->{mqtt}->{password});
			}
	};
	if($@) { $self->{mqtt}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

  sub disconnect {
	my($self) = @_;
    eval{
		$self->{mqtt}->{mqtt}->disconnect() or die "$!";
	};
	if($@) { $self->{mqtt}->{error} = 1;
			 $self->{log}->save('e', "$@");
	}
  }
}
1;
