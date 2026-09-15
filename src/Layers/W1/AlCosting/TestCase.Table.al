table 103402 "Test Case"
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
            TableRelation = "Use Case";
        }
        field(2;"Test Case No.";Integer)
        {
            MinValue = 1;
        }
        field(3;Description;Text[100])
        {
        }
        field(4;"Testscript Completed";Boolean)
        {
        }
        field(5;"Project Code";Code[10])
        {
        }
        field(6;"Entry No.";Integer)
        {
            InitValue = 0;
        }
    }

    keys
    {
        key(Key1;"Use Case No.","Test Case No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

