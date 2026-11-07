table 130204 "Test Coverage Map"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test Codeunit ID"; Integer)
        {
        }
        field(2; "Object Type"; Integer)
        {
        }
        field(3; "Object ID"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Test Codeunit ID", "Object Type", "Object ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

