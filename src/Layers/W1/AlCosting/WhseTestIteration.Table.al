table 103302 "Whse. Test Iteration"
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
            TableRelation = "Whse. Use Case"."Use Case No.";
        }
        field(3;"Test Case No.";Integer)
        {
            MinValue = 1;
            TableRelation = "Whse. Test Case"."Test Case No.";
        }
        field(4;"Iteration No.";Integer)
        {
        }
        field(5;"Stop After";Boolean)
        {

            trigger OnValidate()
            begin
                if "Stop After" then begin
                  SetFilter("Project Code","Project Code");
                  ModifyAll("Stop After",false);
                  "Stop After" := true;
                end;
            end;
        }
        field(6;"Step No.";Integer)
        {
        }
        field(7;Description;Text[50])
        {
        }
    }

    keys
    {
        key(Key1;"Project Code","Use Case No.","Test Case No.","Iteration No.","Step No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

