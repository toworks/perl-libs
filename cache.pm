package cache;{
  use strict;
  use warnings;
  use utf8;
  binmode(STDOUT,':utf8');
  use open(':encoding(utf8)');
  use YAML::XS qw/LoadFile DumpFile/;
  use Data::Dumper;

  sub new {
    my($class, $log, $filename) = @_;
    my $self = bless {  'log' => $log,
                        'filename' => $filename,
                    }, $class;

    $self->read;

    return $self;
  }

  sub read {
    my($self) = @_;
    if ( -e $self->{filename} ) {
        eval{ $self->{'cache'} = LoadFile( $self->{filename} ) || die $!; };
        if($@) { $self->{log}->save('e', "$@"); }
    } else {
        $self->{'cache'};
    }
  }
  
  sub get {
    my($self, $name) = @_;
    return $self->{'cache'}->{$name} || undef;
  }

  sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{'cache'}->{$key} = $set{$key};
    }
  }

  sub save {
    my($self) = @_;
    eval{ DumpFile( $self->{filename}, $self->{'cache'} ); };
    if($@) { $self->{log}->save('e', "$@") };
  }
}
1;
