table 132802 "UPG - CRM Connection Setup"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
        }
        field(5; "Last Update Invoice Entry No."; Integer)
        {
            Caption = 'Last Update Invoice Entry No.';
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