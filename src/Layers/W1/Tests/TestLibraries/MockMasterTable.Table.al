table 134487 "Mock Master Table"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Name; Text[30])
        {
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

