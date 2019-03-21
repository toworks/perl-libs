package opc;{
  use strict;
  use warnings;
  use utf8;
#  binmode(STDOUT,':utf8');
#  use open(':encoding(utf8)');
  use Win32::OLE::OPC qw($OPCCache $OPCDevice);
  use Data::Dumper;

  sub new {
    # получаем имя класса
    my($class, $log, $opc_name, $opc_ip, $group, $tags) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
		'opc_name' => $opc_name,
		'opc_ip' => $opc_ip,
		'group' => $group,
		'error' => 1,
		'log' => $log,
		'tags' => $tags,
	};

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент

    return $self;
  }

  sub connect {
	my($self) = @_; # ссылка на объект
    eval{ 	$self->{opcintf} = undef;
			$self->{opcintf} = Win32::OLE::OPC->new('OPC.Automation',
												  $self->{opc_name},
												  $self->{opc_ip}) or die $self->{log}->save('i', "failure to connect to opc");
	};
	#if($@) { $self->{log}->save('e', "$@"); $self->{error} = 1; } else { $self->{log}->save('i', "connected opc"); $self->{error} = 0; }

	unless($@) {
		eval{ 	$self->{opcintf}->MoveToRoot;
				$self->{group} = $self->{opcintf}->OPCGroups->Add($self->{group});
				$self->{items} = $self->{group}->OPCItems;
				$self->{error} = 0;
				$self->set_tags();
		}
	} else { $self->{error} = 1; }
  }

  sub set_tags {
	my($self) = @_; # ссылка на объект

	if ( $self->{error} == 0 ) {
		eval{
			foreach my $type ( keys %{$self->{tags}} ) {
				foreach my $id_measuring ( keys %{$self->{tags}->{$type}} ) {
					my $tag = $self->{tags}->{$type}->{$id_measuring}->{tag};
					$self->{items}->AddItem($tag, $self->{opcintf});
					#$self->{tag}->{$id_measuring}->{$type} = $tag;
					#print $self->{tags}->{$type}->{$id_measuring}->{tag}."\n";
				}
			}
		}
	}
  }

  sub get_values {
	my($self) = @_; # ссылка на объект
	my %values;

	eval{
		$self->{opcintf}->Leafs;
		my $i = 1;
		foreach my $type ( keys %{$self->{tags}} ) {
			foreach my $id_measuring ( keys %{$self->{tags}->{$type}} ) {
				my $tag = $self->{tags}->{$type}->{$id_measuring}->{tag};
				#$self->{tag}->{$id_measuring}->{$type} = $tag;
				#print $self->{tags}->{$type}->{$id_measuring}->{tag}."\n";
				my $name = $self->{tags}->{$type}->{$id_measuring}->{name};
				#print (join "\t", $type, $name, $id_measuring, $tag, "\n");
				
				my $item = $self->{items}->Item($i);
				my $timestamp = $item->Read($OPCCache)->{'TimeStamp'};
				my $datetime = $timestamp->Date("yyyy-MM-dd"). " " .$timestamp->Time("HH:mm:ss");
				my $value = $item->Read($OPCCache)->{'Value'};
				#print(join "\t", $item->Read($OPCCache)->{'TimeStamp'}, $item->Read($OPCCache)->{'Value'}, "\n");
				#print(join "\t", $datetime, $value, "\n");
				#print $timestamp."\t".local_timestamp()."\n";
				#$values{$type}{$id_measuring} = [ $name, $id_measuring, sprintf("%.4f", $value), $datetime ];
				$values{$type}{$id_measuring} = [ $name, $id_measuring, sprintf("%.4f", $value), local_timestamp() ];
				$i++;
				#print "count $i\n";
			}
		}

		undef $i;

			#for (my $i = 1; $i < $self->{opcintf}->{count}+1; $i++) {
#			for (my $i = 1; $i < $#tags+2; $i++) {
#			for (my $i = 1; $i < $self->{tag_count}+2; $i++) {
#				my $item = $self->{items}->Item($i);
#				my $timestamp = $item->Read($OPCCache)->{'TimeStamp'};
#				my $datetime = $timestamp->Date("yyyy-MM-dd"). " " .$timestamp->Time("HH:mm:ss");
#				my $value = $item->Read($OPCCache)->{'Value'};
#				print(join "\t", $item->Read($OPCCache)->{'TimeStamp'}, $item->Read($OPCCache)->{'Value'}, "\n");
#				$values{$type}{$id} = [ $name, $id, int($ref->{$tag}), $datetime ];
				#%item_handles = ( $tags[$i-1] => { 'timestamp' => $datetime, 'value' => $value } );
#				$item_handles{ $tags[$i-1] } = {
#												'timestamp' => $datetime,
#												'value' => $value,
#											};
#			}
	};
	
	if($@) {
		$self->{error} = 1;
		$self->{log}->save('e', "$@");
		$self->connect();
	}

=comm		
		my @tags = @{$self->{tags}};
		eval{ $self->{opcintf}->Leafs; };
		if($@) { $self->{log}->save('e', "$@"); $self->{error} = 1; } else { $self->{error} = 0; }

		eval{
		#		for (my $i = 1; $i < $self->{opcintf}->{count}+1; $i++) {
				for (my $i = 1; $i < $#tags+2; $i++) {
					my $item = $self->{items}->Item($i);
					my $timestamp = $item->Read($OPCCache)->{'TimeStamp'};
					my $datetime = $timestamp->Date("yyyy-MM-dd"). " " .$timestamp->Time("HH:mm:ss");
					my $value = $item->Read($OPCCache)->{'Value'};
					#print(join "\t", $item->Read($OPCCache)->{'TimeStamp'}, $item->Read($OPCCache)->{'Value'}, "\n");
					#%item_handles = ( $tags[$i-1] => { 'timestamp' => $datetime, 'value' => $value } );
					$item_handles{ $tags[$i-1] } = {
													'timestamp' => $datetime,
													'value' => $value,
												};
				}
		};
		if ($@) {
			$self->{error} = 1;
			$self->{log}->save(2, "failure to get values to opc");
		}
=cut
	return(\%values);
  }
  
	sub local_timestamp {
		my $t = time;
		my @time = (localtime $t);
		my $date = DateTime->new( 	year 		=> $time[5]+1900,
									month 		=> $time[4]+1,
									day 		=> $time[3],
									hour 		=> $time[2],
									minute 		=> $time[1],
									second 		=> $time[0],
									time_zone 	=> "Europe/Kiev" );
		my $dt = $date->strftime("%Y-%m-%d %H:%M:%S");
		$dt .= sprintf ".%03d", ($t-int($t))*1000;
		return $dt;
	}
  
   sub get_error {
		my($self) = @_; # ссылка на объект
		return $self->{error};
   }
}
1;
