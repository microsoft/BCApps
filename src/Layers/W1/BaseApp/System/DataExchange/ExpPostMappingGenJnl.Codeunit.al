namespace System.IO;

using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Utilities;

codeunit 1275 "Exp. Post-Mapping Gen. Jnl."
{
    Permissions = TableData "Credit Transfer Entry" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        CreditTransferEntry: Record "Credit Transfer Entry";
        GenJnlLine: Record "Gen. Journal Line";
        TempInteger: Record "Integer" temporary;
        SEPACTFillExportBuffer: Codeunit "SEPA CT-Fill Export Buffer";
        Window: Dialog;
        LineNo: Integer;
    begin
        GenJnlLine.SetRange("Data Exch. Entry No.", Rec."Entry No.");
        GenJnlLine.FindSet();

        CreditTransferRegister.SetRange("From Bank Account No.", GenJnlLine."Bal. Account No.");
        CreditTransferRegister.FindLast();

        Window.Open(ProgressMsg);

        repeat
            LineNo += 1;
            Window.Update(1, LineNo);

            TempInteger.DeleteAll();
            SEPACTFillExportBuffer.GetAppliesToDocEntryNumbers(GenJnlLine, TempInteger);
            if TempInteger.FindSet() then
                repeat
                    CreditTransferEntry.CreateNew(
                      CreditTransferRegister."No.", 0,
                      GenJnlLine."Account Type", GenJnlLine."Account No.", TempInteger.Number,
                      GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount, '',
                      GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
                until TempInteger.Next() = 0
            else
                CreditTransferEntry.CreateNew(
                  CreditTransferRegister."No.", LineNo,
                  GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.GetAppliesToDocEntryNo(),
                  GenJnlLine."Posting Date", GenJnlLine."Currency Code", GenJnlLine.Amount, '',
                  GenJnlLine."Recipient Bank Account", GenJnlLine."Message to Recipient");
        until GenJnlLine.Next() = 0;
        LineNo += TempInteger.Count();

        Window.Close();
    end;

    var
#pragma warning disable AA0470
        ProgressMsg: Label 'Post-processing line no. #1######.';
#pragma warning restore AA0470
}

