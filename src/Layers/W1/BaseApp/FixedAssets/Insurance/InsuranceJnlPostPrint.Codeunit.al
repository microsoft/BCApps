// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 5672 "Insurance Jnl.-Post+Print"
{
    TableNo = "Insurance Journal Line";

    trigger OnRun()
    begin
        InsuranceJnlLine.Copy(Rec);
        Code();
        Rec.Copy(InsuranceJnlLine);
    end;

    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsuranceReg: Record "Insurance Register";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journal lines and print the posting report?';
        Text002: Label 'The journal lines were successfully posted.';
#pragma warning disable AA0470
        Text003: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        InsuranceJnlTempl.Get(InsuranceJnlLine."Journal Template Name");
        InsuranceJnlTempl.TestField("Posting Report ID");

        HideDialog := false;
        OnBeforePostJournalBatch(InsuranceJnlLine, HideDialog);
        if not HideDialog then
            if not Confirm(Text000, false) then
                exit;

        TempJnlBatchName := InsuranceJnlLine."Journal Batch Name";

        CODEUNIT.Run(CODEUNIT::"Insurance Jnl.-Post Batch", InsuranceJnlLine);

        if InsuranceReg.Get(InsuranceJnlLine."Line No.") then begin
            InsuranceReg.SetRecFilter();
            REPORT.Run(InsuranceJnlTempl."Posting Report ID", false, false, InsuranceReg);
        end;

        if InsuranceJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = InsuranceJnlLine."Journal Batch Name" then
                Message(Text002)
            else
                Message(
                  Text003,
                  InsuranceJnlLine."Journal Batch Name");

        if not InsuranceJnlLine.Find('=><') or (TempJnlBatchName <> InsuranceJnlLine."Journal Batch Name") then begin
            InsuranceJnlLine.Reset();
            InsuranceJnlLine.FilterGroup := 2;
            InsuranceJnlLine.SetRange("Journal Template Name", InsuranceJnlLine."Journal Template Name");
            InsuranceJnlLine.SetRange("Journal Batch Name", InsuranceJnlLine."Journal Batch Name");
            InsuranceJnlLine.FilterGroup := 0;
            InsuranceJnlLine."Line No." := 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var InsuranceJournalLine: Record "Insurance Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

