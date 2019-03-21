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
			$self->{opc}->{opcintf} = Win32::OLE::OPC->new('OPC.Automation',
												  $self->{opc}->{name},
												  $self->{opc}->{host} or die "failure to connect to opc");
	};
	if($@) { $self->{opc}->{error} = 1;
			 $self->{log}->save('e', "$@"); }
  }
}
1;
