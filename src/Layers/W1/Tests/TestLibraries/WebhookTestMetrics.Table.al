table 130641 "Webhook Test Metrics"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Code[10])
        {
        }
        field(2; CreatedCount; Integer)
        {
        }
        field(3; UpdatedCount; Integer)
        {
        }
        field(4; DeletedCount; Integer)
        {
        }
        field(5; MissedCount; Integer)
        {
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

