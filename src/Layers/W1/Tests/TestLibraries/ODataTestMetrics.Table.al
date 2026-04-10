table 130640 "OData Test Metrics"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Code[10])
        {
        }
        field(2; GetCount; Integer)
        {
        }
        field(3; InsertCount; Integer)
        {
        }
        field(4; ModifyCount; Integer)
        {
        }
        field(5; DeleteCount; Integer)
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

