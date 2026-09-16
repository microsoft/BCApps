#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 101897 DevSourceInfo
#pragma warning restore AS0103, PTE0004
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

