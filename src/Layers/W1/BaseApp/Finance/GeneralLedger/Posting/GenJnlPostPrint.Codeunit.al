// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.BatchProcessing;
using System.Utilities;

codeunit 232 "Gen. Jnl.-Post+Print"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        GenJnlLine.Copy(Rec);
        Code();
        Rec.Copy(GenJnlLine);

        OnAfterOnRun(Rec);
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlPostviaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        RecRefToPrint: RecordRef;
        GenJnlsScheduled: Boolean;
        TempJnlBatchName: Code[10];

        JournalsScheduledMsg: Label 'Journal lines have been scheduled for posting.';
#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the report(s)?';
        Text003: Label 'The journal lines were successfully posted.';
#pragma warning disable AA0470
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        if GenJnlTemplate."Force Posting Report" or
           (GenJnlTemplate."Cust. Receipt Report ID" = 0) and (GenJnlTemplate."Vendor Receipt Report ID" = 0)
        then
            GenJnlTemplate.TestField("Posting Report ID");
        if GenJnlTemplate.Recurring and (GenJnlLine.GetFilter("Posting Date") <> '') then
            GenJnlLine.FieldError("Posting Date", Text000);

        OnBeforePostJournalBatch(GenJnlLine, HideDialog);

        if not HideDialog then begin
            if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                exit;
            if not GenJnlPostBatch.ConfirmPostingUnvoidableChecks(GenJnlLine."Journal Batch Name", GenJnlLine."Journal Template Name") then
                exit;
        end;

        TempJnlBatchName := GenJnlLine."Journal Batch Name";

        IsHandled := false;
        OnAfterConfirmPostJournalBatch(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Post & Print with Job Queue" then begin
            // Add job queue entry for each document no.
            GenJnlLine.SetCurrentKey("Document No.");
            while GenJnlLine.FindFirst() do begin
                GenJnlsScheduled := true;
                GenJnlLine."Print Posted Documents" := true;
                GenJnlLine.Modify();
                GenJnlPostviaJobQueue.EnqueueGenJrnlLineWithUI(GenJnlLine, false);
                GenJnlLine.SetFilter("Document No.", '>%1', GenJnlLine."Document No.");
            end;

            if GenJnlsScheduled then
                Message(JournalsScheduledMsg);
        end else begin
            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);
            OnAfterPostJournalBatch(GenJnlLine);

            PrintJournal();

            if not HideDialog then
                if GenJnlLine."Line No." = 0 then
                    Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
                else begin
                    IsHandled := false;
                    OnCodeOnBeforeLinesSuccessfullyPostedMessage(GenJnlLine, IsHandled);
                    if not IsHandled then
                        if TempJnlBatchName = GenJnlLine."Journal Batch Name" then
                            Message(Text003)
                        else
                            Message(Text004, GenJnlLine."Journal Batch Name");
                end;
        end;

        if not GenJnlLine.Find('=><') or (TempJnlBatchName <> GenJnlLine."Journal Batch Name") or GeneralLedgerSetup."Post & Print with Job Queue" then begin
            GenJnlLine.Reset();
            GenJnlLine.FilterGroup(2);
            GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
            OnGenJnlLineSetFilter(GenJnlLine);
            GenJnlLine.FilterGroup(0);
            GenJnlLine."Line No." := 1;
        end;
    end;

    local procedure PrintJournal()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintJournalBatch(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        RecRefToPrint.GetTable(GenJnlLine);
        BatchPostingPrintMgt.PrintJournal(RecRefToPrint);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var GenJournalLine: Record "Gen. Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPostJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenJnlLineSetFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeLinesSuccessfullyPostedMessage(GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintJournalBatch(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

