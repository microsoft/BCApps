table 139141 "Update Parent Header"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Code[10])
        {
        }
        field(2; Description; Text[100])
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

