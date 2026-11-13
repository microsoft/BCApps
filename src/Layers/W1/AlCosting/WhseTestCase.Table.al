#pragma warning disable AS0103, PTE0004 // Accepted: this test-only table is intentionally not exposed through production permission sets. Tracked by AB#640773.
table 103301 "Whse. Test Case"
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
        field(2;"Use Case No.";Integer)
        {
            TableRelation = "Whse. Use Case"."Use Case No.";
        }
        field(3;"Test Case No.";Integer)
        {
            MinValue = 1;
        }
        field(4;Description;Text[100])
        {
        }
        field(5;"Testscript Completed";Boolean)
        {
        }
        field(6;"Entry No.";Integer)
        {
            FieldClass = Normal;
            InitValue = 0;
        }
    }

    keys
    {
        key(Key1;"Project Code","Use Case No.","Test Case No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

