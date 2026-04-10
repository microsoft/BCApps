table 132908 "Table AutoIncrement Out Of PK"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
        }
        field(2; Category; Option)
        {
            OptionMembers = "0","1","2";
        }
        field(3; "Setup ID"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Setup ID", Category)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
