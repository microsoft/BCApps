table 103303 "Whse. Testscript Result"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    LookupPageID = "Whse. Testscript Results";
    DataClassification = CustomerContent;

    fields
    {
        field(1;"Project Code";Code[10])
        {
        }
        field(2;"No.";Integer)
        {
        }
        field(3;Name;Text[250])
        {
        }
        field(4;Value;Text[250])
        {
        }
        field(5;"Expected Value";Text[250])
        {
        }
        field(6;"Is Equal";Boolean)
        {
        }
        field(7;"Codeunit ID";Integer)
        {
        }
        field(8;Date;Date)
        {
        }
        field(9;Time;Time)
        {
        }
        field(10;"Use Case No.";Integer)
        {
        }
        field(11;"Test Case No.";Integer)
        {
        }
        field(12;"Entry No.";Integer)
        {
        }
        field(13;TableID;Integer)
        {
            TableRelation = AllObj."Object ID" WHERE ("Object Type"=FILTER(Table));
        }
        field(14;"Iteration No.";Integer)
        {
        }
    }

    keys
    {
        key(Key1;"Project Code","No.")
        {
            Clustered = true;
        }
        key(Key2;"Use Case No.","Test Case No.","Iteration No.",TableID)
        {
        }
        key(Key3;"Is Equal")
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
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit,"Codeunit ID") then
          exit(AllObjWithCaption."Object Caption");
    end;
}

