namespace System.IO;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 1272 "Exp. Validation Gen. Jnl."
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Rec.DeletePaymentFileBatchErrors();
        Rec.DeletePaymentFileErrors();

        GenJnlLine.CopyFilters(Rec);
        if GenJnlLine.FindSet() then
            repeat
                CODEUNIT.Run(CODEUNIT::"Payment Export Gen. Jnl Check", GenJnlLine);
            until GenJnlLine.Next() = 0;

        if GenJnlLine.HasPaymentFileErrorsInBatch() then begin
            Commit();
            Error(HasErrorsErr);
        end;
    end;

    var
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
}

