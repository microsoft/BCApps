#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 103405 "Required Input Data"
#pragma warning restore AS0103, PTE0004
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1;"Object Name";Text[30])
        {
        }
        field(2;"Tab Name";Text[30])
        {
        }
        field(3;"Field Name";Text[30])
        {
        }
        field(4;"Field Value";Text[30])
        {
        }
        field(5;"No.";Integer)
        {
        }
        field(6;"Control Name";Text[30])
        {
        }
        field(7;"Control Type";Text[30])
        {
        }
        field(8;Shortcut;Text[30])
        {
        }
    }

    keys
    {
        key(Key1;"Object Name","No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

