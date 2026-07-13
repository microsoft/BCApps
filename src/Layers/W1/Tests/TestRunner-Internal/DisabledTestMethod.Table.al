table 130206 "Disabled Test Method"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test Codeunit ID"; Integer)
        {
        }
        field(2; "Test Method Name"; Text[128])
        {
        }
    }

    keys
    {
        key(Key1; "Test Codeunit ID", "Test Method Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}