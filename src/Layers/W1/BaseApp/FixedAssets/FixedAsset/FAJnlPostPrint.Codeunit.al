// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;

codeunit 5670 "FA. Jnl.-Post+Print"
{
    TableNo = "FA Journal Line";

    trigger OnRun()
    begin
        FAJnlLine.Copy(Rec);
        Code();
        Rec.Copy(FAJnlLine);
    end;

    var
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlLine: Record "FA Journal Line";
        FAReg: Record "FA Register";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];

#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the posting report?';
        Text003: Label 'The journal lines were successfully posted.';
#pragma warning disable AA0470
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        FAJnlTemplate.Get(FAJnlLine."Journal Template Name");
        FAJnlTemplate.TestField("Posting Report ID");
        FAJnlTemplate.TestField("Maint. Posting Report ID");
        if FAJnlTemplate.Recurring and (FAJnlLine.GetFilter("FA Posting Date") <> '') then
            FAJnlLine.FieldError("FA Posting Date", Text000);

        HideDialog := false;
        OnBeforePostJournalBatch(FAJnlLine, HideDialog);
        if not HideDialog then
            if not Confirm(Text001, false) then
                exit;

        TempJnlBatchName := FAJnlLine."Journal Batch Name";

        CODEUNIT.Run(CODEUNIT::"FA Jnl.-Post Batch", FAJnlLine);

        if FAReg.Get(FAJnlLine."Line No.") then begin
            FAReg.SetRecFilter();
            if FAReg."From Entry No." > 0 then
                REPORT.Run(FAJnlTemplate."Posting Report ID", false, false, FAReg);
            if FAReg."From Maintenance Entry No." > 0 then
                REPORT.Run(FAJnlTemplate."Maint. Posting Report ID", false, false, FAReg);
        end;

        if FAJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = FAJnlLine."Journal Batch Name" then
                Message(Text003)
            else
                Message(
                  Text004,
                  FAJnlLine."Journal Batch Name");

        if not FAJnlLine.Find('=><') or (TempJnlBatchName <> FAJnlLine."Journal Batch Name") then begin
            FAJnlLine.Reset();
            FAJnlLine.FilterGroup := 2;
            FAJnlLine.SetRange("Journal Template Name", FAJnlLine."Journal Template Name");
            FAJnlLine.SetRange("Journal Batch Name", FAJnlLine."Journal Batch Name");
            FAJnlLine.FilterGroup := 0;
            FAJnlLine."Line No." := 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var FAJournalLine: Record "FA Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

