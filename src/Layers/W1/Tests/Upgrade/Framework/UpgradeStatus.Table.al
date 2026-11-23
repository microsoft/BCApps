#pragma warning disable AS0103, PTE0004 // Accepted: this internal table is intentionally accessed only by its owning infrastructure and is not exposed through user permission sets. Tracked by AB#640773.
table 132800 "Upgrade Status"
#pragma warning restore AS0103, PTE0004
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; PrimaryKey; Code[10])
        {
            DataClassification = SystemMetadata;
        }

        field(2; UpgradeTriggered; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; PrimaryKey)
        {
            Clustered = true;
        }
    }
}