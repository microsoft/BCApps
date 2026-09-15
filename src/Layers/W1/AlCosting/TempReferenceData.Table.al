table 103497 "Temp. Reference Data"
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

