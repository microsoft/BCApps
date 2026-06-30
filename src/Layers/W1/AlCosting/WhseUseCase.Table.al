table 103300 "Whse. Use Case"
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
            MinValue = 1;
        }
        field(3;Description;Text[100])
        {
        }
    }

    keys
    {
        key(Key1;"Project Code","Use Case No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

