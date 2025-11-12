table 103404 "Test Iteration"
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
        field(3;"Iteration No.";Integer)
        {
        }
        field(4;"Stop After";Boolean)
        {

            trigger OnValidate()
            begin
                if "Stop After" then begin
                  ModifyAll("Stop After",false);
                  "Stop After" := true;
                end;
            end;
        }
        field(5;"Step No.";Integer)
        {
        }
        field(6;Description;Text[50])
        {
        }
    }

    keys
    {
        key(Key1;"Use Case No.","Test Case No.","Iteration No.","Step No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

