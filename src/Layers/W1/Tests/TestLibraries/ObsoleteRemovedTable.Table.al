table 136604 "Obsolete Removed Table"
{
    ObsoleteReason = 'Removed table';
    ObsoleteState = Removed;
    ObsoleteTag = '15.0';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Integer)
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
