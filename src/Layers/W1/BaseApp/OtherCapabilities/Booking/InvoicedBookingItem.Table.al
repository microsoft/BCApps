namespace Microsoft.Booking;

table 1638 "Invoiced Booking Item"
{
    Caption = 'Invoiced Booking Item';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Booking Item ID"; Text[250])
        {
            Caption = 'Booking Item ID';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; Posted; Boolean)
        {
            Caption = 'Posted';
        }
    }

    keys
    {
        key(Key1; "Booking Item ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

