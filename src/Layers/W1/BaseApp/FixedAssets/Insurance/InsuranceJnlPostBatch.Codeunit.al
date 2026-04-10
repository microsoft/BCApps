// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.Finance.Analysis;
using Microsoft.FixedAssets.Journal;
using Microsoft.Foundation.NoSeries;

codeunit 5653 "Insurance Jnl.-Post Batch"
{
    Permissions = TableData "Insurance Journal Batch" = rimd;
    TableNo = "Insurance Journal Line";

    trigger OnRun()
    begin
        InsuranceJnlLine.Copy(Rec);
        Code();
        Rec := InsuranceJnlLine;
    end;

    var
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        InsuranceReg: Record "Insurance Register";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        InsuranceJnlLine2: Record "Insurance Journal Line";
        InsuranceJnlLine3: Record "Insurance Journal Line";
        FAJnlSetup: Record "FA Journal Setup";
        InsuranceJnlPostLine: Codeunit "Insurance Jnl.-Post Line";
        InsuranceJnlCheckLine: Codeunit "Insurance Jnl.-Check Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        Window: Dialog;
        LineCount: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        InsuranceRegNo: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        InsuranceJnlLine.SetRange("Journal Template Name", InsuranceJnlLine."Journal Template Name");
        InsuranceJnlLine.SetRange("Journal Batch Name", InsuranceJnlLine."Journal Batch Name");
        InsuranceJnlLine.LockTable();

        InsuranceJnlTempl.Get(InsuranceJnlLine."Journal Template Name");
        InsuranceJnlBatch.Get(InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name");

        if not InsuranceJnlLine.Find('=><') then begin
            Commit();
            InsuranceJnlLine."Line No." := 0;
            exit;
        end;

        Window.Open(
          Text001 +
          Text002 +
          Text003);
        Window.Update(1, InsuranceJnlLine."Journal Batch Name");
        // Check lines
        LineCount := 0;
        StartLineNo := InsuranceJnlLine."Line No.";
        repeat
            LineCount := LineCount + 1;
            Window.Update(2, LineCount);
            InsuranceJnlCheckLine.RunCheck(InsuranceJnlLine);
            if InsuranceJnlLine.Next() = 0 then
                InsuranceJnlLine.Find('-');
        until InsuranceJnlLine."Line No." = StartLineNo;
        NoOfRecords := LineCount;

        InsCoverageLedgEntry.LockTable();
        if InsCoverageLedgEntry.FindLast() then;
        InsuranceReg.LockTable();
        if InsuranceReg.FindLast() then
            InsuranceRegNo := InsuranceReg."No." + 1
        else
            InsuranceRegNo := 1;
        // Post lines
        LineCount := 0;
        LastDocNo := '';
        LastDocNo2 := '';
        LastPostedDocNo := '';
        InsuranceJnlLine.Find('-');
        repeat
            LineCount := LineCount + 1;
            Window.Update(3, LineCount);
            Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            if not (InsuranceJnlLine."Insurance No." = '') and
               (InsuranceJnlBatch."No. Series" <> '') and
               (InsuranceJnlLine."Document No." <> LastDocNo2)
            then
                InsuranceJnlLine.TestField("Document No.", NoSeriesBatch.GetNextNo(InsuranceJnlBatch."No. Series", InsuranceJnlLine."Posting Date"));
            if not (InsuranceJnlLine."Insurance No." = '') then
                LastDocNo2 := InsuranceJnlLine."Document No.";
            if InsuranceJnlLine."Posting No. Series" = '' then
                InsuranceJnlLine."Posting No. Series" := InsuranceJnlBatch."No. Series"
            else
                if not (InsuranceJnlLine."Insurance No." = '') then
                    if InsuranceJnlLine."Document No." = LastDocNo then
                        InsuranceJnlLine."Document No." := LastPostedDocNo
                    else begin
                        LastDocNo := InsuranceJnlLine."Document No.";
                        InsuranceJnlLine."Document No." := NoSeriesBatch.GetNextNo(InsuranceJnlLine."Posting No. Series", InsuranceJnlLine."Posting Date");
                        LastPostedDocNo := InsuranceJnlLine."Document No.";
                    end;
            InsuranceJnlPostLine.RunWithOutCheck(InsuranceJnlLine);
            OnCodeOnAfterInsuranceJnlPostLineRunWithOutCheck(InsuranceJnlLine);
        until InsuranceJnlLine.Next() = 0;

        if InsuranceReg.FindLast() then;
        if InsuranceReg."No." <> InsuranceRegNo then
            InsuranceRegNo := 0;

        InsuranceJnlLine.Init();
        InsuranceJnlLine."Line No." := InsuranceRegNo;
        // Update/delete lines
        if InsuranceRegNo <> 0 then begin
            InsuranceJnlLine2.CopyFilters(InsuranceJnlLine);
            InsuranceJnlLine2.SetFilter("Insurance No.", '<>%1', '');
            if InsuranceJnlLine2.FindLast() then;
            // Remember the last line
            InsuranceJnlLine3.Copy(InsuranceJnlLine);
            OnCodeOnBeforeInsuranceJnlLine3DeleteAll(InsuranceJnlLine3, InsuranceJnlLine);
            InsuranceJnlLine3.DeleteAll();
            InsuranceJnlLine3.Reset();
            InsuranceJnlLine3.SetRange("Journal Template Name", InsuranceJnlLine."Journal Template Name");
            InsuranceJnlLine3.SetRange("Journal Batch Name", InsuranceJnlLine."Journal Batch Name");
            if InsuranceJnlTempl."Increment Batch Name" then
                if not InsuranceJnlLine3.FindLast() then
                    if IncStr(InsuranceJnlLine."Journal Batch Name") <> '' then begin
                        InsuranceJnlBatch.Get(InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name");
                        InsuranceJnlBatch.Delete();
                        FAJnlSetup.IncInsuranceJnlBatchName(InsuranceJnlBatch);
                        InsuranceJnlBatch.Name := IncStr(InsuranceJnlLine."Journal Batch Name");
                        if InsuranceJnlBatch.Insert() then;
                        InsuranceJnlLine."Journal Batch Name" := InsuranceJnlBatch.Name;
                    end;

            InsuranceJnlLine3.SetRange("Journal Batch Name", InsuranceJnlLine."Journal Batch Name");
            if (InsuranceJnlBatch."No. Series" = '') and not InsuranceJnlLine3.FindLast() then begin
                InsuranceJnlLine3.Init();
                InsuranceJnlLine3."Journal Template Name" := InsuranceJnlLine."Journal Template Name";
                InsuranceJnlLine3."Journal Batch Name" := InsuranceJnlLine."Journal Batch Name";
                InsuranceJnlLine3."Line No." := 10000;
                InsuranceJnlLine3.Insert();
                InsuranceJnlLine3.SetUpNewLine(InsuranceJnlLine2);
                InsuranceJnlLine3.Modify();
            end;
        end;
        NoSeriesBatch.SaveState();

        Commit();
        Clear(InsuranceJnlCheckLine);
        Clear(InsuranceJnlPostLine);
        UpdateAnalysisView.UpdateAll(0, true);
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterInsuranceJnlPostLineRunWithOutCheck(var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeInsuranceJnlLine3DeleteAll(var InsuranceJnlLine3: Record "Insurance Journal Line"; var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
    end;
}

