package configuration;{
  use strict;
  use warnings;
  use utf8;
  binmode(STDOUT,':utf8');
  use open(':encoding(utf8)');
  use YAML::XS qw/LoadFile/;
  use Data::Dumper;

  sub new {
    # получаем имя класса
    my($class, $log) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
        'log' => $log,
    };

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент
    
    $self->set;

    return $self;
  }

  sub set {
    my($self) = @_;
    eval{ $self->{'config'} = LoadFile($self->{log}->get_name().'.conf.yml') || die $!; };
    if($@) { $self->{log}->save('e', "$@"); exit 1; }
  }

  sub get {
    my($self, $name) = @_;

    my $value;

    if ( ! defined($name) ) {
        $value = $self->{'config'};
    } else {
        $value = $self->{'config'}->{$name} || undef;
    }
    return $value;
  }
}
1;
