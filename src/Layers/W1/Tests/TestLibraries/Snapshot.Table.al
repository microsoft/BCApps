table 130013 Snapshot
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Snapshot No."; Integer)
        {
        }
        field(2; "Snapshot Name"; Text[30])
        {
        }
        field(3; Description; Text[250])
        {
        }
        field(4; Incremental; Boolean)
        {
        }
        field(5; "Incremental Index"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Snapshot No.")
        {
            Clustered = true;
        }
        key(Key2; "Incremental Index")
        {
        }
    }

    fieldgroups
    {
    }
}

