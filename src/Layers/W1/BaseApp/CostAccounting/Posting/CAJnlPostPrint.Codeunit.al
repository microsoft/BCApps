// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Posting;

using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 1113 "CA Jnl.-Post+Print"
{
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        CostJnlLine.Copy(Rec);
        Code();
        Rec.Copy(CostJnlLine);
    end;

    var
        CostJnlLine: Record "Cost Journal Line";
        CostReg: Record "Cost Register";
        CostJnlTemplate: Record "Cost Journal Template";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
#pragma warning disable AA0074
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
#pragma warning disable AA0470
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        TempJnlBatchName: Code[10];
        HideDialog: Boolean;
    begin
        CostJnlTemplate.Get(CostJnlLine."Journal Template Name");
        CostJnlTemplate.TestField("Posting Report ID");

        HideDialog := false;
        OnBeforePostJournalBatch(CostJnlLine, HideDialog);
        if not HideDialog then
            if not Confirm(Text001) then
                exit;

        TempJnlBatchName := CostJnlLine."Journal Batch Name";
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJnlLine);
        CostReg.Get(CostJnlLine."Line No.");
        CostReg.SetRecFilter();
        REPORT.Run(CostJnlTemplate."Posting Report ID", false, false, CostReg);

        if CostJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = CostJnlLine."Journal Batch Name" then
                Message(Text003)
            else
                Message(Text004, CostJnlLine."Journal Batch Name");

        if not CostJnlLine.Find('=><') or (TempJnlBatchName <> CostJnlLine."Journal Batch Name") then begin
            CostJnlLine.Reset();
            CostJnlLine.FilterGroup(2);
            CostJnlLine.SetRange("Journal Template Name", CostJnlLine."Journal Template Name");
            CostJnlLine.SetRange("Journal Batch Name", CostJnlLine."Journal Batch Name");
            CostJnlLine.FilterGroup(0);
            CostJnlLine."Line No." := 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var CostJournalLine: Record "Cost Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

