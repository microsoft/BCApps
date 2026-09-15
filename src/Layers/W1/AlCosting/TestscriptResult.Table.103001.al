#pragma warning disable AA0215
table 103001 "Testscript Result"
#pragma warning restore AA0215
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    LookupPageID = "Testscript Results";
    DataClassification = CustomerContent;

    fields
    {
        field(1;"Entry No.";Integer)
        {
        }
        field(2;Name;Text[250])
        {
        }
        field(3;Value;Text[250])
        {
        }
        field(4;"Expected Value";Text[250])
        {
        }
        field(5;"Is Equal";Boolean)
        {
        }
        field(6;"Codeunit ID";Integer)
        {
        }
    }

    keys
    {
        key(Key1;"Entry No.")
        {
            Clustered = true;
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
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit,"Codeunit ID") then
          exit(AllObjWithCaption."Object Caption");
    end;
}

