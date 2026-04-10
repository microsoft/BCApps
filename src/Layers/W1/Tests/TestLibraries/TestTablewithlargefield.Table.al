table 139173 "Test Table with large field"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Integer)
        {
        }
        field(2; Description; Text[2048])
        {
        }
    }

    keys
    {
        key(Key1; PK)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

