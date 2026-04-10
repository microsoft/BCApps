namespace Microsoft.Booking;

table 6704 "Booking Mailbox"
{
    Caption = 'Booking Mailbox';
    ExternalName = 'BookingMailbox';
    TableType = Exchange;
    DataClassification = CustomerContent;

    fields
    {
        field(1; SmtpAddress; Text[80])
        {
            Caption = 'SmtpAddress';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(3; "Display Name"; Text[250])
        {
            Caption = 'Display Name';
            ExternalName = 'DisplayName';
        }
    }

    keys
    {
        key(Key1; SmtpAddress)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure LookupMailbox(var BookingMailbox: Record "Booking Mailbox"): Boolean
    var
        BookingMailboxList: Page "Booking Mailbox List";
    begin
        BookingMailboxList.SetRecord(Rec);
        BookingMailboxList.SetTableView(Rec);
        BookingMailboxList.LookupMode(true);
        if BookingMailboxList.RunModal() in [ACTION::OK, ACTION::LookupOK] then begin
            BookingMailboxList.GetRecord(BookingMailbox);
            exit(true);
        end;
    end;
}

