#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 103497 "Temp. Reference Data"
#pragma warning restore AS0103, PTE0004
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1;"Table ID";Integer)
        {
        }
        field(2;"Use Case No.";Integer)
        {
        }
        field(3;"Test Case No.";Integer)
        {
        }
        field(4;"Iteration No.";Integer)
        {
        }
        field(5;"Entry No.";Integer)
        {
        }
        field(10;TestString;Text[200])
        {
        }
    }

    keys
    {
        key(Key1;"Table ID","Use Case No.","Test Case No.","Iteration No.","Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

