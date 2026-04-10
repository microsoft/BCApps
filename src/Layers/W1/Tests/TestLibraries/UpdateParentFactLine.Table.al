table 139144 "Update Parent Fact Line"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header Id"; Code[10])
        {
        }
        field(2; "Line Id"; Integer)
        {
        }
        field(3; Name; Text[30])
        {
        }
    }

    keys
    {
        key(Key1; "Header Id")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

