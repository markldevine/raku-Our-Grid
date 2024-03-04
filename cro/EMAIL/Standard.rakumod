unit class Mail::Standard;

#
#   Intention:  Drop-in email capability to any Rakudo Perl 6 script
#
#   - read in defaults from user's ~/.email.perl6 file
#   - allow values via new()
#   - return start { $client.send }

use Net::SMTP;
use Email::MIME;
use Mail::Exceptions;

has $!SMTPRelay     = 'smtp.office365.com';
has $!Port          = 587;
has $!UserName      = 'mark@markdevine.com';
has $!Password      = 'XXXXXXXXX';
has $!From          = 'mark@markdevine.com';
has @!To;
has @!CC;
has @!BCC;
has $!Subject;
has @!Attach;

has $!Email;

sub new (:@To!, :@CC, :@BCC, :$Subject, :@Body!, :@Attach) {
    
    $Subject        = 'Subject: ' ~ $Subject unless $Subject ~~ /^Subject:/;

    my @parts.push: Email::MIME.create(
                        header      => [ content-transfer-encoding => "quoted-printable", ],
                        attributes  => [ content-type => "text/plain", charset => "utf8", ],
                        body-str    => @Body.join: "\n",
                    );

    for @Attach -> $attachment {
        X::Mail::Standard::Attachment::NSF.new(source => $attachment).throw unless "$attachment".IE.e;
        my $image   = "$attachment".IO.slurp(:bin);
        given "$attachment".IO.basename {
            when /\.[Zz][Ii][Pp]$/ {
                @parts.push(Email::MIME.create(
                                header     => [ "Content-Transfer-Encoding" => "base64" ],
                                attributes => [ content-type => "application/zip; name=$_", disposition => "attachment" ],
                                body       => $image,
                           )
                );
            }
            default { X::Mail::Standard::UnsupportedAttachment.new(source => $attachment).throw }
        }
    }

    my $self        = self.bless(
                        :$!SMTPRelay,
                        :$!Port,
                        :$!UserName,
                        :$!Password,
                        :$!From,
                        :@To,
                        :@!CC,
                        :@!BCC,
                        :$!Subject,
                        :@!Attach,
                        :$!Email
                      );

    my $!Email      = Email::MIME.create(
                        header-str  => [ from => $!From, to => @To, cc => @CC, bcc => @BCC, subject => $Subject, ],
                        parts       => @parts,
                      );

    return $self;
}

sub Send () {
    my $client;
    if ( not $client = Net::SMTP.new(:server( $SMTPRelay ), :port( $Port ), :debug( 0 ) ) ) {
        note "SMTP Error: Failed to initialize";
        return;
    }
    if ( not $client.auth( $UserName, $Password ) ) {
        note "SMTP AUTH Error: user name <$UserName> / password <$Password> failed";
        return;
    }
    if ( not $client.send( $From, @To, $email.as-string, :keep-going ) ) {
        note "SMTP Error: Failed to send";
    }
    $client.quit;
}
