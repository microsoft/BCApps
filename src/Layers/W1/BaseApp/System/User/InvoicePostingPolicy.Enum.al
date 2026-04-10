namespace System.Security.User;

enum 80 "Invoice Posting Policy"
{
    Extensible = true;

    value(0; Allowed) { Caption = 'Allowed'; }
    value(1; Prohibited) { Caption = 'Prohibited'; }
    value(2; Mandatory) { Caption = 'Mandatory'; }
}