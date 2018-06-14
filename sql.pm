package sql;{ 
  use DBI;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use DBI qw(:sql_types);
  use Data::Dumper;  

  sub new {
    my($class, $log) = @_;
    my $self = bless {	'error' => 1,
                        'log' => $log,
    }, $class;

    return $self;
  }
 
  sub set_con {
    my($self, $host, $database) = @_; # ссылка на объект
    $self->{sql}->{host} = $host;
    $self->{sql}->{database} = $database;
#    $self->{dsn} = "Driver={ODBC Driver 13 for SQL Server};Server=$self->{sql}->{host};Database=$self->{sql}->{database};Trusted_Connection=yes" if $self->{sql}->{type} eq "mssql";
	$self->{dsn} = "Driver={SQL Server Native Client 11.0};Server=$self->{sql}->{host};Database=$self->{sql}->{database};Trusted_Connection=yes" if $self->{sql}->{type} eq "mssql";
  }

  sub conn {
    my($self) = @_; # ссылка на объект
    eval{ $self->{dbh} = DBI->connect("dbi:ODBC:$self->{dsn}") || die "$DBI::errstr" if $self->{sql}->{type} eq "mssql";
          $self->{dbh}->{RaiseError} = 0; # при 1 eval игнорируется, для диагностики полезно
          $self->{dbh}->{LongReadLen} = 512 * 1024 || die "$DBI::errstr"; # We are interested in the first 512 KB of data
          $self->{dbh}->{LongTruncOk} = 1 || die "$DBI::errstr"; # We're happy to truncate any excess
    };# обработка ошибки
    if($@) { $self->{log}->save('e', "$@"); $self->{error} = 1; } else { $self->{log}->save('i', "connected sql"); $self->{error} = 0; }
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

  sub debug {
    my($self, $debug) = @_;
    $self->{'DEBUG'} = $debug;
  }

  sub get_data {
    my($self) = @_;
    my($sth, $ref, $query, @values);

    $self->conn() if ( $self->{error} == 1 or ! $self->{dbh}->ping );

#    $query = "SELECT *, datediff(s, '1970', getdate()) as [current_timestamp] FROM [$self->{sql}->{database}]..$self->{sql}->{table} with(nolock) ";
#	$query = "SELECT * FROM [$self->{sql}->{database}]..process_operations with(nolock) ";
#	$query .= "where enable = 1 ";
	$query = "exec([$self->{sql}->{database}]..get_process_operations_query())";

    eval{ $self->{dbh}->{RaiseError} = 1;
          $sth = $self->{dbh}->prepare($query) || die "$DBI::errstr";
          $sth->execute() || die "$DBI::errstr";
    };
    if ($@) {   $self->{error} = 1;
                $self->{log}->save('e', "$DBI::errstr");
    };

    unless($@) {
        eval{
                my $count = 0;
                while ($ref = $sth->fetchrow_hashref()) {
                    #print Dumper($ref), "\n";
                    $values[$count] = $ref;
                    $count++;
                }
        }
    }
    eval{ $sth->finish() || die "$DBI::errstr";	};# обработка ошибки
    if ($@) {   $self->{error} = 1;
                $self->{log}->save('e', "$DBI::errstr");
				$self->{log}->save('d', "$query");
    };

    #$self->{log}->save('d', "\n".Dumper(\@values)."\n") if $self->{'DEBUG'};
    
    return(\@values);
  }

  sub set_data {
    my($self, $id_measuring) = @_;
    my($sth, $ref, $query);

    $self->conn() if ( $self->{error} == 1 or ! $self->{dbh}->ping );

	$query = "exec [$self->{sql}->{database}]..[ins_process_operations_metadata] " . $id_measuring;
	
    eval{ $self->{dbh}->{RaiseError} = 1;
          $sth = $self->{dbh}->prepare($query) || die "$DBI::errstr";
          $sth->execute() || die "$DBI::errstr";
    };
    if ($@) {   $self->{error} = 1;
                $self->{log}->save('e', "$DBI::errstr");
				$self->{log}->save('d', "$query");
    };
  }

  sub response {
    my($self, $mid, $status, $type) = @_;
    my($sth, $ref, $query);

    $self->conn() if ( $self->{error} == 1 );
    
    $query  = "update [$self->{sql}->{database}]..$self->{sql}->{table}_response ";
#	$query  = "update [$self->{sql}->{database}]..stage_response ";
    $query .= "set response = ? ";
    $query .= "where mid = ? and type = ?";

    eval{	$self->{dbh}->{RaiseError} = 1;
            $self->{dbh}->{AutoCommit} = 0;
            $sth = $self->{dbh}->prepare_cached($query) || die "$DBI::errstr";
            $sth->bind_param(1, $status) || die "$DBI::errstr";
            $sth->bind_param(2, $mid) || die "$DBI::errstr";
            $sth->bind_param(3, $type) || die "$DBI::errstr";
            $sth->execute() || die "$DBI::errstr";
            $self->{dbh}->{AutoCommit} = 1;
    };
    if ($@) {
        $self->{log}->save('e', "$@");
        $self->{error} = 1;
    }
    undef $values;
  }
}
1;
