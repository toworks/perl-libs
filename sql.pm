package sql;{ 
  use strict;
  use warnings;
  use utf8;
  use DBI;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use DBI qw(:sql_types);
  use Data::Dumper;  

  sub new {
    my($class, $log) = @_;
    my $self = bless {	'sql' => {'error' => 1},
                        'log' => $log,
    }, $class;

    return $self;
  }
 
  sub set_con {
    my($self, $driver, $host, $database) = @_;
    $self->{sql}->{host} = $host;
    $self->{sql}->{database} = $database;
	$self->{sql}->{dsn} = "Driver={$driver};Server=$self->{sql}->{host};Database=$self->{sql}->{database};Trusted_Connection=yes" if $self->{sql}->{type} eq "mssql";
  }

  sub conn {
    my($self) = @_;
    eval{ $self->{sql}->{dbh} = DBI->connect("dbi:ODBC:$self->{sql}->{dsn}") || die "$DBI::errstr" if $self->{sql}->{type} eq "mssql";
          $self->{sql}->{dbh}->{RaiseError} = 0; # при 1 eval игнорируется, для диагностики полезно
          $self->{sql}->{dbh}->{LongReadLen} = 512 * 1024 || die "$DBI::errstr"; # We are interested in the first 512 KB of data
          $self->{sql}->{dbh}->{LongTruncOk} = 1 || die "$DBI::errstr"; # We're happy to truncate any excess
    };
    if($@) { $self->{log}->save('e', "$@"); $self->{sql}->{error} = 1; } else { $self->{sql}->{error} = 0; }
  }

  sub get {
    my($self, $name) = @_;
    return $self->{sql}->{$name};
  }

  sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{sql}->{$key} = $set{$key};
    }
  }
}
1;
