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

	$self->{connection_string} = $self->{mqtt}->{host} || 'localhost';

	$self->{connection_string} .=":". $self->{mqtt}->{port} if defined($self->{mqtt}->{port});
	
	$self->{log}->save('d', "mqtt: connection string: ". $self->{connection_string}) if $self->{mqtt}->{'DEBUG'};
	
    $self->{mqtt}->{mqtt} = Net::MQTT::Simple->new($self->{connection_string});
 	# Depending if authentication is required, login to the broker
	if( $self->{mqtt}->{user} and $self->{mqtt}->{password} ) {
		$self->{mqtt}->{mqtt}->login($self->{mqtt}->{user}, $self->{mqtt}->{password}) or die "$!";
	}
	$self->{mqtt}->{error} = 0;
	$self->{log}->save('i', "mqtt: connected ". $self->{connection_string});
  }

  sub publish {
	my($self, $topic, $data) = @_;
    eval{
		$self->{mqtt}->{mqtt}->publish($topic, $data) or die "$!";
	};
	if($@) { $self->{mqtt}->{error} = 1;
			 $self->{log}->save('e', "$@");
	}
  }

  sub retain {
	my($self, $topic, $data) = @_;
    eval{
		$self->{mqtt}->{mqtt}->retain($topic, $data) or die "$!";
	};
	if($@) { $self->{mqtt}->{error} = 1;
			 $self->{log}->save('e', "$@");
	}
  }

  sub disconnect {
	my($self) = @_;
    eval{
		$self->{mqtt}->{mqtt}->disconnect() or die "$!";
	};
	if($@) { $self->{mqtt}->{error} = 1;
			 $self->{log}->save('e', "$@");
	}
	$self->{log}->save('i', "mqtt: disconnected ". $self->{connection_string});
  }
}
1;
