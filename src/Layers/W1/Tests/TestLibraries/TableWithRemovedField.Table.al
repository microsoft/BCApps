table 136603 "Table With Removed Field"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Integer)
        {
            DataClassification = SystemMetadata;
        }
#pragma warning disable AS0105
        field(2; "Obsolete Field Removed"; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = "G/L Entry";
            ObsoleteState = Removed;
            ObsoleteReason = 'Test field.';
            ObsoleteTag = '15.0';
        }
        field(3; "Obsolete Field Pending"; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = "Cust. Ledger Entry";
            ObsoleteReason = 'Test field.';
            ObsoleteState = Pending;
            ObsoleteTag = '25.0';
        }
#pragma warning restore AS0105
        field(4; "Normal Field"; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = "Vendor Ledger Entry";
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
#pragma warning disable AS0105
        key(Key2; "Obsolete Field Pending", "Key")
        {
            ObsoleteReason = 'Test key.';
            ObsoleteState = Pending;
            ObsoleteTag = '25.0';
        }
        key(Key3; "Normal Field")
        {
            ObsoleteReason = 'Test key.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
        key(Key4; "Obsolete Field Pending", "Normal Field")
        {
        }
#pragma warning restore AS0105
    }

    fieldgroups
    {
    }
}

