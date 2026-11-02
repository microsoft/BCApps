#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 101903 "G/L Account Map Buffer"
#pragma warning restore AS0103, PTE0004
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
        field(2; Value; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Key")
        {
        }
    }

    fieldgroups
    {
    }
}

