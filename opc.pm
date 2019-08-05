package opc;{
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use Win32::OLE::OPC qw($OPCCache $OPCDevice);
  use Data::Dumper;
  
  sub new {
    my($class, $log) = @_;
    my $self = bless {	'opc' => {'error' => 1},
                        'log' => $log,
    }, $class;

    return $self;
  }

  sub get {
    my($self, $name) = @_;
    return $self->{opc}->{$name};
  }

  sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{opc}->{$key} = $set{$key};
    }
  }

  sub connect {
	my($self) = @_;
    eval{ 	$self->{opc}->{opcintf} = undef;
			$self->{opc}->{tags} = undef;
			$self->{opc}->{opcintf} = Win32::OLE::OPC->new($self->{opc}->{progid} || 'OPC.Automation',
												  $self->{opc}->{name},
												  $self->{opc}->{host}
												  )	or die "$!";
#			$self->{opc}->{opcintf}->MoveToRoot	or die "$!";
			$self->add_group( $_ ) for keys %{$self->{opc}->{groups}};
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }

  sub add_group {
	my($self, $name) = @_;
    eval{ 	$self->{opc}->{$name}->{group} = $self->{opc}->{opcintf}->OPCGroups->Add($name)	or die "$!";
			$self->{opc}->{$name}->{group}->SetProperty('UpdateRate', 100);
			$self->{opc}->{$name}->{group}->SetProperty('IsActive', 1);
			$self->{opc}->{$name}->{group}->SetProperty('IsSubscribed', 1);
			$self->{opc}->{$name}->{items} = $self->{opc}->{$name}->{group}->OPCItems or die "$!";
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@");
	} else {
		$self->{log}->save('i', "added opc group: " . $name);
	}
  }
}
1;
