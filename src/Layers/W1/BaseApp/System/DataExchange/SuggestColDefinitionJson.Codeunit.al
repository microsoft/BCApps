namespace System.IO;

codeunit 1238 "Suggest Col. Definition - Json"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure GenerateDataExchColDef(URLPath: Text; DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GetJsonStructure: Codeunit "Get Json Structure";
        ColumnNo: Integer;
    begin
        GetJsonStructure.GenerateStructure(URLPath, TempXMLBuffer);

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.DeleteAll();
        ColumnNo := 0;

        TempXMLBuffer.Reset();
        if TempXMLBuffer.FindSet() then
            repeat
                ColumnNo += 10000;

                DataExchColumnDef.Init();
                DataExchColumnDef.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
                DataExchColumnDef.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
                DataExchColumnDef.Validate("Column No.", ColumnNo);

                DataExchColumnDef.Validate(Name, TempXMLBuffer.Name);
                DataExchColumnDef.Validate(Path, TempXMLBuffer.Path);
                DataExchColumnDef.Insert(true);
            until TempXMLBuffer.Next() = 0;
    end;
}

