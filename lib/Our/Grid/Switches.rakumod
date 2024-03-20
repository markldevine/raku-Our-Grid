unit class Our::Grid::Switches:api<1>:auth<Mark Devine (mark@markdevine.com)>;

has Bool    $.csv;
has Bool    $.html;
has Bool    $.json;
has Str     $.grid-proxy-host;
has Uint    $.grid-proxy-port;
has Bool    $.gui;
has Bool    $.mailing;
has         @.mail-attachment-formats;
has         @.mail-bcc;
has         @.mail-cc;
has Str     $.mail-from;
has         @.mail-to;
has         $.mail-body-format;
has Bool    $.text;
has Bool    $.tui;
has Bool    $.xml;

method bundle {
    my %bundle                          = ();
    %bundle<csv>                        = self.csv;
    %bundle<html>                       = self.html;
    %bundle<json>                       = self.json;
    %bundle<grid-proxy-host>            = self.grid-proxy-host;
    %bundle<grid-proxy-port>            = self.grid-proxy-port;
    %bundle<gui>                        = self.gui;
    %bundle<mailing>                    = self.mailing;
    %bundle<mail-attachment-formats>    = self.mail-attachment-formats;
    %bundle<mail-bcc>                   = self.mail-bcc;
    %bundle<mail-cc>                    = self.mail-cc;
    %bundle<mail-from>                  = self.mail-from;
    %bundle<mail-to>                    = self.mail-to;
    %bundle<mail-body-format>           = self.mail-body-format;
    %bundle<text>                       = self.text;
    %bundle<tui>                        = self.tui;
    return(%bundle);
}
