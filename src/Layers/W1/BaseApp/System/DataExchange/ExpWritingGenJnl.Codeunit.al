namespace System.IO;

codeunit 1276 "Exp. Writing Gen. Jnl."
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        OutputStream: OutStream;
    begin
        DataExchDef.Get(Rec."Data Exch. Def Code");
        DataExchDef.TestField("Reading/Writing XMLport");

        Rec."File Content".CreateOutStream(OutputStream);
        DataExchField.SetRange("Data Exch. No.", Rec."Entry No.");
        XMLPORT.Export(DataExchDef."Reading/Writing XMLport", OutputStream, DataExchField);

        DataExchField.DeleteAll(true);
    end;
}

