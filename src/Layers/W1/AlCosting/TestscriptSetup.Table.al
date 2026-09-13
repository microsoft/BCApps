#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 103002 "Testscript Setup"
#pragma warning restore AS0103, PTE0004
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1;"Primary Key";Code[10])
        {
            Editable = false;
        }
        field(2;"Postpone Show Test Result";Boolean)
        {
        }
    }

    keys
    {
        key(Key1;"Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

