table 132564 "Master Data Setup Sample"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Guid)
        {
        }
        field(2; Name; Text[250])
        {
        }
        field(3; Path; Text[250])
        {
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

