#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 103305 "Whse. Temp. Reference Data"
#pragma warning restore AS0103, PTE0004
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1;"Project Code";Code[10])
        {
        }
        field(2;"Table ID";Integer)
        {
        }
        field(3;"Use Case No.";Integer)
        {
        }
        field(4;"Test Case No.";Integer)
        {
        }
        field(5;"Iteration No.";Integer)
        {
        }
        field(6;"Entry No.";Integer)
        {
        }
        field(10;TestString;Text[250])
        {
        }
    }

    keys
    {
        key(Key1;"Project Code","Table ID","Use Case No.","Test Case No.","Iteration No.","Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

