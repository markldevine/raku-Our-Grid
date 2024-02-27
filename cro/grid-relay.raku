#!/usr/bin/env raku

use lib </home/mdevine/github.com/raku-Our-Grid/lib>;

use Cro::HTTP::Router;
use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Our::Grid;

#use Data::Dump::Tree;

my Cro::Service $grid-relay;

$*OUT.out-buffer        = 0;

%*ENV<REPOSITORY_HOST>  = <127.0.0.1>;
%*ENV<REPOSITORY_PORT>  = 22151;

my $application         = route {
#   get     -> 'proxy-mail-via-redis', *%params,  {
#   get     -> 'proxy-mail-via-redis', $redis-key {
    get     -> 'proxy-mail-via-redis', *$redis-key {
        my Our::Grid $grid .= new;
        $grid.receive-proxy-mail-via-redis(:$redis-key);
$grid.ANSI-print;
$grid.html-print;
#       content 'text/plain', $grid.html-print;
    },
};

$grid-relay             = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<REPOSITORY_HOST> || die("Missing REPOSITORY_HOST in environment"),
    port => %*ENV<REPOSITORY_PORT> || die("Missing REPOSITORY_PORT in environment"),
#   tls => %(
#       private-key-file => %*ENV<REPOSITORY_TLS_KEY>  || %?RESOURCES<fake-tls/server-key.pem> || "resources/fake-tls/server-key.pem",
#       certificate-file => %*ENV<REPOSITORY_TLS_CERT> || %?RESOURCES<fake-tls/server-crt.pem> || "resources/fake-tls/server-crt.pem",
#   ),
    application => $application,
#   after => [ Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR) ],
);

$grid-relay.start;

#say "Listening at https://%*ENV<REPOSITORY_HOST>:%*ENV<REPOSITORY_PORT>";
put 'Listening at http://' ~ %*ENV<REPOSITORY_HOST> ~ ':' ~ %*ENV<REPOSITORY_PORT>;

react {
    whenever signal(SIGHUP) {
        say "Hanging up...";
        $grid-relay.stop;
        done;
    }
    whenever signal(SIGINT) {
        say "Shutting down...";
        $grid-relay.stop;
        done;
    }
}
