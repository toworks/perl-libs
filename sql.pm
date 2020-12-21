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
    my $self = bless {  'sql' => {'error' => 1},
                        'log' => $log,
    }, $class;

    return $self;
  }
 
  sub set_con {
    my($self, $driver, $host, $database) = @_;
    $self->{sql}->{host} = $host;
    $self->{sql}->{database} = $database;
    $self->{sql}->{dsn} = "Driver={$driver};Server=$self->{sql}->{host};Database=$self->{sql}->{database}" if $self->{sql}->{type} eq "mssql";
    $self->{sql}->{dsn} = "dbi:$driver:hostname=$self->{sql}->{host};db=$self->{sql}->{database}" if $self->{sql}->{type} eq "fbsql";
	$self->{sql}->{dsn} = "dbi:$driver:host=$self->{sql}->{host};dbname=$self->{sql}->{database}" if $self->{sql}->{type} eq "pgsql";
	$self->{sql}->{dsn} = "Driver={$driver};DBQ=$self->{sql}->{database}" if $self->{sql}->{type} eq "access";
  }

  sub conn {
    my($self) = @_;
    eval{ if ( defined($self->{sql}->{user}) ) {
			$self->{sql}->{dbh} = DBI->connect("dbi:ODBC:$self->{sql}->{dsn};Uid=$self->{sql}->{user};Pwd=$self->{sql}->{password};") || die "$DBI::errstr" if $self->{sql}->{type} eq "mssql";
		  } else {
			$self->{sql}->{dbh} = DBI->connect("dbi:ODBC:$self->{sql}->{dsn};Trusted_Connection=yes") || die "$DBI::errstr" if $self->{sql}->{type} eq "mssql";
		  }
		  $self->{sql}->{dbh} = DBI->connect("dbi:ODBC:$self->{sql}->{dsn}") || die "$DBI::errstr" if $self->{sql}->{type} eq "mssql";
          $self->{sql}->{dbh} = DBI->connect("$self->{sql}->{dsn};ib_dialect=$self->{sql}->{dialect}", $self->{sql}->{user}, $self->{sql}->{password}) || die "$DBI::errstr" if $self->{sql}->{type} eq "fbsql";
		  $self->{sql}->{dbh} = DBI->connect("$self->{sql}->{dsn}", $self->{sql}->{user}, $self->{sql}->{password}) || die "$DBI::errstr" if $self->{sql}->{type} eq "pgsql";
		  $self->{sql}->{dbh} = DBI->connect("dbi:ODBC:$self->{sql}->{dsn}", $self->{sql}->{user}, $self->{sql}->{password}) || die "$DBI::errstr" if $self->{sql}->{type} eq "access";
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
