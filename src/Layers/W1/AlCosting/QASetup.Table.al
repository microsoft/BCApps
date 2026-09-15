table 103498 "QA Setup"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1;"Primary Key";Code[10])
        {
        }
        field(2;"Use Hardcoded Reference";Boolean)
        {
            InitValue = true;
        }
        field(3;"Test Results Path";Text[250])
        {
        }
        field(4;"Run Test Log";Boolean)
        {
        }
    }

    keys
    {
        key(Key1;"Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

