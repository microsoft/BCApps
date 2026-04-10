table 132805 "Table State Obsolete Removed"
{
    ReplicateData = false;
    DataClassification = CustomerContent;
    ObsoleteState = Removed;
    ObsoleteReason = 'Test table used to test that Change Log is not considering deprecated tables.';
    ObsoleteTag = '15.0';

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
        }
        field(2; "Test No."; Integer)
        {
            Caption = 'Test No.';
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