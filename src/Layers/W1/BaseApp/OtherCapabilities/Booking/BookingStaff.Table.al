namespace Microsoft.Booking;

table 6705 "Booking Staff"
{
    Caption = 'Booking Staff';
    ExternalName = 'BookingStaff';
    TableType = Exchange;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "SMTP Address"; Text[250])
        {
            Caption = 'SMTP Address';
            ExternalName = 'SmtpAddress';
        }
        field(2; "Display Name"; Text[250])
        {
            Caption = 'Display Name';
            ExternalName = 'DisplayName';
        }
        field(3; Permission; Option)
        {
            Caption = 'Permission';
            ExternalName = 'Permission';
            OptionCaption = 'Invalid,Administrator,Viewer,Guest';
            OptionMembers = Invalid,Administrator,Viewer,Guest;
        }
    }

    keys
    {
        key(Key1; "SMTP Address")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

