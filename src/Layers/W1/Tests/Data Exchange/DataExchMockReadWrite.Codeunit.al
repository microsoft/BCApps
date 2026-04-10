codeunit 132392 "Data Exch Mock Read Write"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchDef: Record "Data Exch. Def";
        OutputStream: OutStream;
    begin
        // [FEATURE] [Data Exchange] [Mapping]

        DataExchDef.Get("Data Exch. Def Code");
        DataExchDef.TestField("Reading/Writing Codeunit");
        "File Content".CreateOutStream(OutputStream);
        OutputStream.WriteText('DATA');
    end;
}

