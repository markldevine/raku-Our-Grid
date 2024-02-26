use Cro::HTTP::Log::File;
use Cro::HTTP::Server;

use Repository;

$*OUT.out-buffer = 0;

my $repository = Repository.new;

%*ENV<REPOSITORY_HOST> = <CTUNIXVMADMINPv.wmata.local>;
%*ENV<REPOSITORY_PORT> = 20000;

my Cro::Service $http = Cro::HTTP::Server.new(
#   http => <1.1 2>,
    http => <1.1>,
#   host => %*ENV<REPOSITORY_HOST> || die("Missing REPOSITORY_HOST in environment"),
#   port => %*ENV<REPOSITORY_PORT> || die("Missing REPOSITORY_PORT in environment"),
    host => 'localhost',
    port => 8888,
#   tls => %(
#       private-key-file => %*ENV<REPOSITORY_TLS_KEY>  || %?RESOURCES<fake-tls/server-key.pem> || "resources/fake-tls/server-key.pem",
#       certificate-file => %*ENV<REPOSITORY_TLS_CERT> || %?RESOURCES<fake-tls/server-crt.pem> || "resources/fake-tls/server-crt.pem",
#   ),
    application => $repository.routes,
    after => [ Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR) ],
);

$http.start;

#say "Listening at https://%*ENV<REPOSITORY_HOST>:%*ENV<REPOSITORY_PORT>";
put 'Listening at http://localhost:8888';

react {
    whenever signal(SIGHUP) {
        say "Hanging up...";
        $http.stop;
        done;
    }
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
