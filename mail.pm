package mail;{
 use strict;
 use warnings;
 use utf8;
 binmode(STDOUT,':utf8');
 use open(':encoding(utf8)');
 use Net::SMTP;
 use Data::Dumper;

 sub new {
    my($class, $conf, $log) = @_;
    my $self = bless {	'mail' => $conf,
						'log' => $log,
    }, $class;

    return $self;
 }

 sub get {
	my($self, $name) = @_;
    return $self->{mail}->{$name};
 }

 sub set {
    my($self, %set) = @_;
    foreach my $key ( keys %set ) {
        $self->{mail}->{$key} = $set{$key};
    }
 }

 sub setup {
    my($self) = @_;

    eval{ $self->{mailer} = new Net::SMTP(  $self->{mail}->{smtp_server},
                                            Hello => 'arcelormittal.com',
                                            Port  => $self->{mail}->{port}#,
                                            #Debug => 1
                                        ) || die $self->{mailer}->message();
  };
  if($@) { $self->{log}->save('e', "$@"); }
 }

 sub send {
    my($self, $subject, $message) = @_;
    
    use Encode;
    $subject = encode('utf8', $subject);
	$message = encode('utf8', $message);
    no Encode;
    
    $self->setup();

	$self->{log}->save('d', "send message: ".$message) if $self->{mail}->{'DEBUG'};

    # remove whitespaces from array elements
    my @recipient = grep(s/\s*//g, split ',', $self->{mail}->{send_to} );
#	print $_.";" for @recipient;
#	exit;
    eval {	$self->{mailer}->auth( $self->{mail}->{auth_user}, $self->{mail}->{auth_password}) || die $self->{mailer}->message();
            $self->{mailer}->mail( $self->{mail}->{auth_user} ) || die $self->{mailer}->message();
            #$self->{mailer}->to($self->{mail}->{send_to}) || die $self->{mailer}->message();
            $self->{mailer}->to($_) || die $self->{mailer}->message() for @recipient;
            $self->{mailer}->data() || die $self->{mailer}->message();
#			$self->{mailer}->datasend("To: $_\n") || die $self->{mailer}->message() for @recipient;
#			$self->{mailer}->datasend("To: Sergey.Arhipov\@arcelormittal.com\n") || die $self->{mailer}->message();
#			$self->{mailer}->datasend("To: Ruslan.Vishnevyy\@arcelormittal.com\n") || die $self->{mailer}->message();
            #$self->{mailer}->datasend("From: Krr-Svc-Pa_Redmine <krr-svc-pa_redmine\@arcelormittal.com>\n") || die $self->{mailer}->message();
#			$self->{mailer}->datasend("To: Sergey.Arhipov\@arcelormittal.com; Ruslan.Vishnevyy\@arcelormittal.com\n") || die $self->{mailer}->message();
            $self->{mailer}->datasend("To: $_; \n") || die $self->{mailer}->message() for @recipient;
            $self->{mailer}->datasend("Subject: $subject\n") || die $self->{mailer}->message();
            $self->{mailer}->datasend("\n") || die $self->{mailer}->message();
            $self->{mailer}->datasend("$message\n") || die $self->{mailer}->message();
            $self->{mailer}->dataend() || die $self->{mailer}->message();
            $self->{mailer}->quit || die $self->{mailer}->message();
    };
    if($@) { $self->{log}->save('e', "$@"); }
 }
}
1;
