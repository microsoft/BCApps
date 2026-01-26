// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 15000031 "Export Remittance"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        RemAgreement: Record "Remittance Agreement";
        ExportTelepay: Report "Remittance - export (bank)";
        ExportBBS: Report "Remittance - export (BBS)";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportRemittance(Rec, IsHandled);
        if IsHandled then
            exit;

        RemAgreement.Get(Rec."Remittance Agreement Code");
        if RemAgreement."Payment System" = RemAgreement."Payment System"::BBS then begin
            ExportBBS.SetJournalLine(Rec);
            ExportBBS.RunModal();
        end else begin
            ExportTelepay.SetJournalLine(Rec);
            ExportTelepay.RunModal();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportRemittance(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

