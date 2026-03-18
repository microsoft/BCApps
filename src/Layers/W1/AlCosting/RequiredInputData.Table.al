table 103405 "Required Input Data"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1;"Object Name";Text[30])
        {
        }
        field(2;"Tab Name";Text[30])
        {
        }
        field(3;"Field Name";Text[30])
        {
        }
        field(4;"Field Value";Text[30])
        {
        }
        field(5;"No.";Integer)
        {
        }
        field(6;"Control Name";Text[30])
        {
        }
        field(7;"Control Type";Text[30])
        {
        }
        field(8;Shortcut;Text[30])
        {
        }
    }

    keys
    {
        key(Key1;"Object Name","No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

