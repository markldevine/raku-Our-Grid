unit class Our::Grid::Switches:api<1>:auth<Mark Devine (mark@markdevine.com)>;

has Bool    $.text;
has Bool    $.html;
has Bool    $.csv;
has Bool    $.json;
has Str     $.grid-proxy-host;
has Uint    $.grid-proxy-port;
has Bool    $.mailing;
has Str     $.mail-from;
has         @.mail-to;
has         @.mail-cc;
has         @.mail-bcc;
has         $.mail-body-format;
has         @.mail-attachment-formats;
has Bool    $.xml;
has Bool    $.tui;
has Bool    $.gui;

method dispatch {
}
