// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Projects.Resources.Ledger;

codeunit 272 "Res. Jnl.-Post+Print"
{
    TableNo = "Res. Journal Line";

    trigger OnRun()
    begin
        ResJnlLine.Copy(Rec);
        Code();
        Rec.Copy(ResJnlLine);
    end;

    var
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlLine: Record "Res. Journal Line";
        ResReg: Record "Resource Register";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];

#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the posting report?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
#pragma warning disable AA0470
        Text005: Label 'You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        ResJnlTemplate.Get(ResJnlLine."Journal Template Name");
        ResJnlTemplate.TestField("Posting Report ID");
        if ResJnlTemplate.Recurring and (ResJnlLine.GetFilter("Posting Date") <> '') then
            ResJnlLine.FieldError("Posting Date", Text000);

        HideDialog := false;
        OnBeforePostJournalBatch(ResJnlLine, HideDialog);
        if not HideDialog then
            if not Confirm(Text001) then
                exit;

        TempJnlBatchName := ResJnlLine."Journal Batch Name";

        CODEUNIT.Run(CODEUNIT::"Res. Jnl.-Post Batch", ResJnlLine);

        OnAfterPostJournalBatch(ResJnlLine);

        if ResReg.Get(ResJnlLine."Line No.") then begin
            ResReg.SetRecFilter();
            REPORT.Run(ResJnlTemplate."Posting Report ID", false, false, ResReg);
        end;

        if ResJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = ResJnlLine."Journal Batch Name" then
                Message(Text003)
            else
                Message(
                  Text004 +
                  Text005,
                  ResJnlLine."Journal Batch Name");

        if not ResJnlLine.Find('=><') or (TempJnlBatchName <> ResJnlLine."Journal Batch Name") then begin
            ResJnlLine.Reset();
            ResJnlLine.FilterGroup(2);
            ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
            ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
            ResJnlLine.FilterGroup(0);
            ResJnlLine."Line No." := 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var ResJournalLine: Record "Res. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var ResJournalLine: Record "Res. Journal Line"; var HideDialog: Boolean)
    begin
    end;
}

