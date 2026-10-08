#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 103401 "Use Case"
#pragma warning restore AS0103, PTE0004
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1;"Use Case No.";Integer)
        {
            MinValue = 1;
        }
        field(2;Description;Text[100])
        {
        }
    }

    keys
    {
        key(Key1;"Use Case No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

