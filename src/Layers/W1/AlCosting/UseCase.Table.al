table 103401 "Use Case"
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
            MinValue = 1;
        }
        field(2;Description;Text[100])
        {
        }
    }

    keys
    {
        key(Key1;"Use Case No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

