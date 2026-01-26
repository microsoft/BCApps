// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 2000005 "Check Non Euro SEPA Payments"
{
    TableNo = "Payment Journal Line";

    trigger OnRun()
    begin
        CheckPaymJnlLine.Init();

        if Rec.FindSet() then begin
            CheckPaymJnlLine.CheckExportProtocol(Rec."Export Protocol Code");
            repeat
                CheckPaymJnlLine.FillGroupLineAmountBuf(Rec);
                CheckPaymJnlLine.CheckBankForSEPA(Rec);
                CheckPaymJnlLine.CheckBeneficiaryBankForSEPA(Rec, false);
                CheckPaymJnlLine.ErrorIfCurrencyEuro(Rec);
                OnAfterCheckPaymJnlLine(Rec, CheckPaymJnlLine);
            until Rec.Next() = 0;
            CheckPaymJnlLine.CheckTotalLineAmounts();
        end else
            CheckPaymJnlLine.ErrorNoPayments();

        CheckPaymJnlLine.ShowErrorLog();
    end;

    var
        CheckPaymJnlLine: Codeunit CheckPaymJnlLine;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPaymJnlLine(var PaymentJournalLine: Record "Payment Journal Line"; var CheckPaymJnlLine: Codeunit CheckPaymJnlLine)
    begin
    end;
}

