table 103301 "Whse. Test Case"
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

