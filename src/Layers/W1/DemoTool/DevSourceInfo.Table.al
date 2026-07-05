table 101897 DevSourceInfo
{
    Caption = 'DevSourceInfo';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Locked = true;
        }
        field(2; sdTimestamp; Text[19])
        {
            Caption = 'Timestamp', Locked = true;
        }
        field(3; gitHash; Text[40])
        {
            Caption = 'Hash', Locked = true;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
        }
    }

    fieldgroups
    {
    }
}

