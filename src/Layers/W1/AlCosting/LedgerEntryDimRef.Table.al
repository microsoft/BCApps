#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 103410 "Ledger Entry Dim. Ref."
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
        field(2;"Entry No.";Integer)
        {
        }
        field(3;"Dimension Set ID";Integer)
        {
            NotBlank = false;
        }
        field(103001;"Use Case No.";Integer)
        {
        }
        field(103002;"Test Case No.";Integer)
        {
            TableRelation = "Test Case"."Test Case No." WHERE ("Use Case No."=FIELD("Use Case No."));
        }
        field(103003;"Iteration No.";Integer)
        {
        }
    }

    keys
    {
        key(Key1;"Use Case No.","Test Case No.","Iteration No.","Table ID","Entry No.","Dimension Set ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

