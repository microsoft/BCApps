// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Setup;
using System.Utilities;

codeunit 213 "Res. Jnl.-Post Batch"
{
    Permissions = TableData "Res. Journal Batch" = rimd;
    TableNo = "Res. Journal Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        ResJnlLine.Copy(Rec);
        Code();
        Rec := ResJnlLine;
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlLine: Record "Res. Journal Line";
        ResJnlLine2: Record "Res. Journal Line";
        ResJnlLine3: Record "Res. Journal Line";
        ResLedgEntry: Record "Res. Ledger Entry";
        ResReg: Record "Resource Register";
        ResSetup: Record "Resources Setup";
        ResJnlCheckLine: Codeunit "Res. Jnl.-Check Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Window: Dialog;
        ResRegNo: Integer;
        StartLineNo: Integer;
        LineCount: Integer;
        NoOfRecords: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        OnBeforeCode(ResJnlLine);

        ResJnlLine.ReadIsolation(IsolationLevel::UpdLock);
        ResJnlLine.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
        ResJnlLine.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");

        ResJnlTemplate.Get(ResJnlLine."Journal Template Name");
        ResJnlBatch.Get(ResJnlLine."Journal Template Name", ResJnlLine."Journal Batch Name");

        if ResJnlTemplate.Recurring then begin
            ResJnlLine.SetRange("Posting Date", 0D, WorkDate());
            ResJnlLine.SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
        end;

        if not ResJnlLine.Find('=><') then begin
            ResJnlLine."Line No." := 0;
            Commit();
            exit;
        end;

        if ResJnlTemplate.Recurring then
            Window.Open(
                Text001 +
                Text002 +
                Text003 +
                Text004)
        else
            Window.Open(
                Text001 +
                Text002 +
                Text005);
        Window.Update(1, ResJnlLine."Journal Batch Name");

        // Check lines
        LineCount := 0;
        StartLineNo := ResJnlLine."Line No.";
        repeat
            LineCount := LineCount + 1;
            Window.Update(2, LineCount);
            CheckRecurringLine(ResJnlLine);
            ResJnlCheckLine.RunCheck(ResJnlLine);
            if ResJnlLine.Next() = 0 then
                ResJnlLine.Find('-');
        until ResJnlLine."Line No." = StartLineNo;
        NoOfRecords := LineCount;

        // Find next register no.
        if ResSetup.UseLegacyPosting() then begin
            ResLedgEntry.LockTable();
            if ResLedgEntry.FindLast() then;
            ResReg.LockTable();
            if ResReg.FindLast() and (ResReg."To Entry No." = 0) then
                ResRegNo := ResReg."No."
            else
                ResRegNo := ResReg."No." + 1;
        end;

        BindSubscription(this);

        // Post lines
        LineCount := 0;
        LastDocNo := '';
        LastDocNo2 := '';
        LastPostedDocNo := '';
        ResJnlLine.Find('-');
        repeat
            LineCount := LineCount + 1;
            Window.Update(3, LineCount);
            Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            if not ResJnlLine.EmptyLine() and
                (ResJnlBatch."No. Series" <> '') and
                (ResJnlLine."Document No." <> LastDocNo2)
            then
                ResJnlLine.TestField("Document No.", NoSeriesBatch.GetNextNo(ResJnlBatch."No. Series", ResJnlLine."Posting Date"));
            if not ResJnlLine.EmptyLine() then
                LastDocNo2 := ResJnlLine."Document No.";
            MakeRecurringTexts(ResJnlLine);
            if ResJnlLine."Posting No. Series" = '' then begin
                ResJnlLine."Posting No. Series" := ResJnlBatch."No. Series";
                ResJnlLine.TestField("Document No.");
            end else
                if not ResJnlLine.EmptyLine() then
                    if (ResJnlLine."Document No." = LastDocNo) and (ResJnlLine."Document No." <> '') then
                        ResJnlLine."Document No." := LastPostedDocNo
                    else begin
                        LastDocNo := ResJnlLine."Document No.";
                        ResJnlLine."Document No." := NoSeriesBatch.GetNextNo(ResJnlLine."Posting No. Series", ResJnlLine."Posting Date");
                        LastPostedDocNo := ResJnlLine."Document No.";
                    end;
            ResJnlPostLine.RunWithCheck(ResJnlLine);
        until ResJnlLine.Next() = 0;

        OnCodeOnAfterPostJnlLines(ResJnlBatch, ResJnlLine, ResRegNo);

        // Copy register no. and current journal batch name to the res. journal
        if ResSetup.UseLegacyPosting() then
            if not ResReg.FindLast() or (ResReg."No." <> ResRegNo) then
                ResRegNo := 0;

        ResJnlLine.Init();
        ResJnlLine."Line No." := ResRegNo;

        // Update/delete lines
        if ResRegNo <> 0 then
            if ResJnlTemplate.Recurring then begin
                // Recurring journal
                LineCount := 0;
                ResJnlLine2.CopyFilters(ResJnlLine);
                ResJnlLine2.Find('-');
                repeat
                    LineCount := LineCount + 1;
                    Window.Update(5, LineCount);
                    Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
                    if ResJnlLine2."Posting Date" <> 0D then
                        ResJnlLine2.Validate("Posting Date", CalcDate(ResJnlLine2."Recurring Frequency", ResJnlLine2."Posting Date"));
                    if (ResJnlLine2."Recurring Method" = ResJnlLine2."Recurring Method"::Variable) and
                        (ResJnlLine2."Resource No." <> '')
                    then begin
                        ResJnlLine2.Quantity := 0;
                        ResJnlLine2."Total Cost" := 0;
                        ResJnlLine2."Total Price" := 0;
                    end;
                    ResJnlLine2.Modify();
                until ResJnlLine2.Next() = 0;
            end else begin
                // Not a recurring journal
                ResJnlLine2.CopyFilters(ResJnlLine);
                ResJnlLine2.SetFilter("Resource No.", '<>%1', '');
                if ResJnlLine2.Find('+') then; // Remember the last line
                ResJnlLine3.Copy(ResJnlLine);
                RecordLinkManagement.RemoveLinks(ResJnlLine3);
                ResJnlLine3.DeleteAll();
                ResJnlLine3.Reset();
                ResJnlLine3.SetRange("Journal Template Name", ResJnlLine."Journal Template Name");
                ResJnlLine3.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
                if ResJnlTemplate."Increment Batch Name" then
                    if not ResJnlLine3.FindLast() then
                        if IncStr(ResJnlLine."Journal Batch Name") <> '' then begin
                            ResJnlBatch.Delete();
                            ResJnlBatch.Name := IncStr(ResJnlLine."Journal Batch Name");
                            if ResJnlBatch.Insert() then;
                            ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
                        end;

                ResJnlLine3.SetRange("Journal Batch Name", ResJnlLine."Journal Batch Name");
                if (ResJnlBatch."No. Series" = '') and not ResJnlLine3.FindLast() then begin
                    ResJnlLine3.Init();
                    ResJnlLine3."Journal Template Name" := ResJnlLine."Journal Template Name";
                    ResJnlLine3."Journal Batch Name" := ResJnlLine."Journal Batch Name";
                    ResJnlLine3."Line No." := 10000;
                    ResJnlLine3.Insert();
                    ResJnlLine3.SetUpNewLine(ResJnlLine2);
                    ResJnlLine3.Modify();
                end;
            end;
        NoSeriesBatch.SaveState();

        Commit();

        RunUpdateAnalysisView();
        Commit();
    end;

    local procedure RunUpdateAnalysisView()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunUpdateAnalysisView(IsHandled);
        if IsHandled then
            exit;

        UpdateAnalysisView.UpdateAll(0, true);
    end;

    local procedure CheckRecurringLine(var ResJnlLine2: Record "Res. Journal Line")
    var
        DummyDateFormula: DateFormula;
    begin
        if ResJnlLine2."Resource No." <> '' then
            if ResJnlTemplate.Recurring then begin
                ResJnlLine2.TestField("Recurring Method");
                ResJnlLine2.TestField("Recurring Frequency");
                if ResJnlLine2."Recurring Method" = ResJnlLine2."Recurring Method"::Variable then
                    ResJnlLine2.TestField(Quantity);
            end else begin
                ResJnlLine2.TestField("Recurring Method", 0);
                ResJnlLine2.TestField("Recurring Frequency", DummyDateFormula);
            end;
    end;

    local procedure MakeRecurringTexts(var ResJnlLine2: Record "Res. Journal Line")
    begin
        if (ResJnlLine2."Resource No." <> '') and (ResJnlLine2."Recurring Method" <> 0) then
            AccountingPeriod.MakeRecurringTexts(ResJnlLine2."Posting Date", ResJnlLine2."Document No.", ResJnlLine2.Description);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Res. Jnl.-Post Line", 'OnAfterResLedgEntryInsert', '', false, false)]
    local procedure OnAfterInsertResLedgEntry(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
        if ResLedgerEntry."Resource Register No." > ResRegNo then
            ResRegNo := ResLedgerEntry."Resource Register No.";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterPostJnlLines(var ResJnlBatch: Record "Res. Journal Batch"; var ResJnlLine: Record "Res. Journal Line"; ResRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ResJnlLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunUpdateAnalysisView(var IsHandled: Boolean)
    begin
    end;
}

