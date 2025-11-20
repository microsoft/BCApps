// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.BatchProcessing;
using System.Utilities;

codeunit 234 "Gen. Jnl.-B.Post+Print"
{
    TableNo = "Gen. Journal Batch";

    trigger OnRun()
    begin
        GenJnlBatch.Copy(Rec);
        Code();
        Rec := GenJnlBatch;
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlPostviaJobQueue: Codeunit "Gen. Jnl.-Post via Job Queue";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        RecRefToPrint: RecordRef;
        GenJnlsScheduled: Boolean;
        JnlWithErrors: Boolean;

        JournalsScheduledMsg: Label 'Journals have been scheduled for posting.';
#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        HideDialog: Boolean;
        OrderByDocNoAndLineNo: Boolean;
    begin
        // If simple view is used then order gen. journal lines by doc no. and line no.
        if GenJnlManagement.GetJournalSimplePageModePreference(PAGE::"General Journal") then
            OrderByDocNoAndLineNo := true;

        GenJnlTemplate.Get(GenJnlBatch."Journal Template Name");
        if GenJnlTemplate."Force Posting Report" or
           (GenJnlTemplate."Cust. Receipt Report ID" = 0) and (GenJnlTemplate."Vendor Receipt Report ID" = 0)
        then
            GenJnlTemplate.TestField("Posting Report ID");

        OnBeforePostJournalBatch(GenJnlBatch, HideDialog);

        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                exit;

        GenJnlBatch.Find('-');
        repeat
            GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
            if OrderByDocNoAndLineNo then
                GenJnlLine.SetCurrentKey("Document No.", "Line No.");
            if GenJnlLine.FindFirst() then begin
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
                    GenJnlLine.SetFilter("Document No.", '<>%1', '');
                end else begin
                    Clear(GenJnlPostBatch);
                    if GenJnlPostBatch.Run(GenJnlLine) then begin
                        OnAfterPostJournalBatch(GenJnlBatch);
                        GenJnlBatch.Mark(false);
                        RecRefToPrint.GetTable(GenJnlLine);
                        BatchPostingPrintMgt.PrintJournal(RecRefToPrint);
                    end else begin
                        GenJnlBatch.Mark(true);
                        JnlWithErrors := true;
                    end;
                end;
            end;
        until GenJnlBatch.Next() = 0;

        if GenJnlsScheduled then
            Message(JournalsScheduledMsg);

        if not GeneralLedgerSetup."Post & Print with Job Queue" then
            if not JnlWithErrors then
                Message(Text001)
            else
                Message(
                  Text002 +
                  Text003);

        if not GenJnlBatch.Find('=><') or GeneralLedgerSetup."Post & Print with Job Queue" then begin
            GenJnlBatch.Reset();
            GenJnlBatch.Name := '';
        end;
    end;

    procedure JournalWithPostingErrors(): Boolean
    begin
        exit(JnlWithErrors);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; var HideDialog: Boolean)
    begin
    end;
}

