use v6;

class X::Mail::Standard::Attachment::NSF is Exception {
    has $.source;
    method message { "Mail attachment input source ($.source): No such file!" }
}

class X::Mail::Standard::Attachment::Unsupported is Exception {
    has $.source;
    method message { "Mail attachment type ($.source) unimplemented at this time." }
}

=finish
