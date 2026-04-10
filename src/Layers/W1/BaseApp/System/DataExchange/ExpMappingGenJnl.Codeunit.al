namespace System.IO;

using Microsoft.Bank.Payment;

codeunit 1274 "Exp. Mapping Gen. Jnl."
{
    Permissions = TableData "Data Exch." = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        PaymentExportData: Record "Payment Export Data";
        DataExch: Record "Data Exch.";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
        PaymentExportDataRecRef: RecordRef;
        Window: Dialog;
        LineNo: Integer;
    begin
        PaymentExportData.SetRange("Data Exch Entry No.", Rec."Entry No.");
        PaymentExportData.FindSet();

        Window.Open(ProgressMsg);

        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            DataExch.Get(PaymentExportData."Data Exch Entry No.");
            DataExch.Validate("Data Exch. Line Def Code", PaymentExportData."Data Exch. Line Def Code");
            DataExch.Modify(true);

            PaymentExportDataRecRef.GetTable(PaymentExportData);
            PaymentExportMgt.ProcessColumnMapping(DataExch, PaymentExportDataRecRef,
              PaymentExportData."Line No.", PaymentExportData."Data Exch. Line Def Code", PaymentExportDataRecRef.Number);
        until PaymentExportData.Next() = 0;

        Window.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Processing line no. #1######.';
#pragma warning restore AA0470
}

