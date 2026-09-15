namespace Microsoft.Booking;

table 6721 "Booking Mgr. Setup"
{
    Caption = 'Booking Mgr. Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Booking Mgr. Codeunit"; Integer)
        {
            Caption = 'Booking Mgr. Codeunit';
            InitValue = 6722;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

