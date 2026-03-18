namespace System.Diagnostics;

table 402 "Change Log Setup"
{
    Caption = 'Change Log Setup';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Change Log Activated"; Boolean)
        {
            Caption = 'Change Log Activated';
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

