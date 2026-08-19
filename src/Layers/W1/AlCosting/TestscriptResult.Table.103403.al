#pragma warning disable AA0215
table 103403 "_Testscript Result"
#pragma warning restore AA0215
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
        }
        field(2; Name; Text[250])
        {
        }
        field(3; Value; Text[250])
        {
        }
        field(4; "Expected Value"; Text[250])
        {
        }
        field(5; "Is Equal"; Boolean)
        {
        }
        field(6; "Codeunit ID"; Integer)
        {
        }
        field(7; Date; Date)
        {
        }
        field(8; Time; Time)
        {
        }
        field(9; "Use Case No."; Integer)
        {
        }
        field(10; "Test Case No."; Integer)
        {
        }
        field(11; "Entry No."; Integer)
        {
        }
        field(13; TableID; Integer)
        {
            TableRelation = AllObj."Object ID" where("Object Type" = FILTER(Table));
        }
        field(14; "Iteration No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Use Case No.", "Test Case No.", "Iteration No.", TableID)
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Caption(): Text[30]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, "Codeunit ID") then
            exit(AllObjWithCaption."Object Caption");
    end;
}

