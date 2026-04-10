table 132800 "Upgrade Status"
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