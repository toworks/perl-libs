package ssh;{
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use Net::SSH2;
  use Data::Dumper;

  sub new {
    my($class, $log) = @_;
    my $self = bless {	'obj' => {'error' => 1},
                        'log' => $log,
    }, $class;

    return $self;
  }

  sub connect {
    my($self) = @_; # ссылка на объект
	eval{ $self->{obj}->{ssh} = undef;
		  $self->{obj}->{ssh} = Net::SSH2->new() || die "cannot create ssh: $!";
		  #$self->{obj}->{ssh}->debug(1) || die "cannot enable debug ssh: $!";
		  $self->{obj}->{ssh}->connect($self->get('host'), $self->get('port')) || die "cannot connect: ". $self->get('host'). ":". $self->get('port') .": $!";
		  $self->{obj}->{ssh}->auth_password($self->get('user'), $self->get('password')) || die "cannot login check username or password: $!";
		  $self->{obj}->{channel} = $self->{obj}->{ssh}->channel() || die "cannot create channel: $!";
		  $self->{obj}->{channel}->shell() || die "cannot create shell: $!";
		  $self->{log}->save('i', "ssh connect: ". $self->get('host'). ":". $self->get('port'));
	};
	if($@) { $self->{obj}->{error} = 1;
			 $self->{log}->save('e', "$@");
	} else { $self->{obj}->{error} = 0; }
  }

  sub disconnect {
    my($self) = @_; # ссылка на объект
	eval{ $self->{obj}->{channel}->close() || die "cannot close channel: $!";
		  $self->{obj}->{ssh}->disconnect() || die "cannot disconnect ssh: $!";
		  $self->{obj}->{ssh} = undef;
		  $self->{log}->save('i', "ssh disconnect: ".  $self->get('host'));
	};
	if($@) { $self->{log}->save('e', "$@"); };
  }

  sub get {
    my($self, $name) = @_;
    return $self->{obj}->{$name};
  }

  sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{obj}->{$key} = $set{$key};
    }
  }
}
1;
