package LOG;{
  use strict;
  use warnings;
  use utf8;
  binmode(STDOUT,':utf8');
  use open(':encoding(utf8)');
  use File::Basename;
  use Data::Dumper;
  use Time::HiRes qw(time);
  use POSIX qw(strftime);

  sub new {
    # получаем имя класса
    my($class) = @_;
    # создаем хэш, содержащий свойства объекта
    my $self = {
                filename => get_name().".log",
    };

    # хэш превращается, превращается хэш...
    bless $self, $class;
    # ... в элегантный объект!

    # эта строчка - просто для ясности кода
    # bless и так возвращает свой первый аргумент

    return $self;
  }

  sub get_name {
    my ( $name, $path, $suffix ) = fileparse( $0, qr{\.[^.]*$} );
#	print "NAME=$name\n";
#	print "PATH=$path\n";
#	print "SFFX=$suffix\n";
    return $name;
  }

=pod
Type    Level    Description
'a'     ALL      All levels including custom levels.
'd'     DEBUG    Designates fine-grained informational events that are most useful to debug an application.
'e'     ERROR    Designates error events that might still allow the application to continue running.
'f'     FATAL    Designates very severe error events that will presumably lead the application to abort.
'i'     INFO     Designates informational messages that highlight the progress of the application at coarse-grained level.
'o'     OFF      The highest possible rank and is intended to turn off logging.
't'     TRACE    Designates finer-grained informational events than the DEBUG.
'w'     WARN     Designates potentially harmful situations.
=cut

  sub save {
    my($self, $type, $log) = @_; # ссылка на объект

    my $level;
    
    if ($type =~ /a/) {
        $level = 'ALL';
    } elsif ($type =~ /d/) {
        $level = 'DEBUG';
    } elsif ($type =~ /e/) {
        $level = 'ERROR';
    } elsif ($type =~ /f/) {
        $level = 'FATAL';
    } elsif ($type =~ /i/) {
        $level = 'INFO';
    } elsif ($type =~ /o/) {
        $level = 'OFF';
    } elsif ($type =~ /t/) {
        $level = 'TRACE';
    } elsif ($type =~ /w/) {
        $level = 'WARN';
    } else {
        $level = 'INFO';
    }

    # trim both ends
    $log =~ s/^\s+|\s+$//g if $log;

    unless($log) { $log = ''; }

    my $t = time;
    my $date = strftime "%Y-%m-%d %H:%M:%S", localtime $t;
    $date .= sprintf ".%03d", ($t-int($t))*1000;

    my $date_to_file = strftime "%Y%m%d_", localtime $t;
    my $log_file = $date_to_file.$self->{'filename'};
    
    eval {	open(my $fh, '>>', $log_file) or die "Не могу открыть файл: '$log_file' $!";
            print $fh "$date $level\t$log\n";
            close $fh;
    };
    print STDERR "$date $@" if ($@);
  }
}
1;
