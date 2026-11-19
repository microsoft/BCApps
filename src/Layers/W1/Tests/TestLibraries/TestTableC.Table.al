#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 132512 TestTableC
#pragma warning restore AS0103, PTE0004
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; IntegerField; Integer)
        {
            AutoIncrement = true;
        }
    }

    keys
    {
        key(Key1; IntegerField)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

