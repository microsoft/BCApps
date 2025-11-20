// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Foundation.NoSeries;

codeunit 5469 "Library API - General Journal"
{

    trigger OnRun()
    begin
    end;

    var
        GenJnlManagement: Codeunit GenJnlManagement;

    procedure InitializeLine(var GenJournalLine: Record "Gen. Journal Line"; LineNo: Integer; DocumentNo: Code[20]; ExternalDocumentNo: Code[35])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        CopyValuesFromGenJnlLine: Record "Gen. Journal Line";
        CopyValuesFromGenJnlLineSpecified: Boolean;
        BottomLine: Boolean;
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        GenJournalLine."Line No." := LineNo;
        GetCopyValuesFromLine(GenJournalLine, CopyValuesFromGenJnlLine, CopyValuesFromGenJnlLineSpecified, BottomLine);

        if BottomLine and
           (LineNo <> 0)
        then begin
            GenJournalLine."Line No." := 0;
            SetUpNewLine(GenJournalLine, CopyValuesFromGenJnlLine, CopyValuesFromGenJnlLineSpecified, BottomLine);
            GenJournalLine."Line No." := LineNo;
        end else
            SetUpNewLine(GenJournalLine, CopyValuesFromGenJnlLine, CopyValuesFromGenJnlLineSpecified, BottomLine);

        GenJournalLine."External Document No." := ExternalDocumentNo;
        if DocumentNo <> '' then
            GenJournalLine."Document No." := DocumentNo
        else
            AlterDocNoBasedOnExternalDocNo(GenJournalLine, CopyValuesFromGenJnlLine, GenJournalBatch, CopyValuesFromGenJnlLineSpecified);
    end;

    procedure EnsureGenJnlBatchExists(TemplateNameTxt: Text[10]; BatchNameTxt: Text[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.Get(TemplateNameTxt, BatchNameTxt) then begin
            GenJournalBatch.Validate("Journal Template Name", TemplateNameTxt);
            GenJournalBatch.SetupNewBatch();
            GenJournalBatch.Validate(Name, BatchNameTxt);
            GenJournalBatch.Validate(Description, GenJournalBatch.Name);
            GenJournalBatch.Insert(true);
            Commit();
        end;
    end;

    local procedure GetCopyValuesFromLine(var GenJournalLine: Record "Gen. Journal Line"; var CopyValuesFromGenJnlLine: Record "Gen. Journal Line"; var CopyValuesFromGenJnlLineSpecified: Boolean; var BottomLine: Boolean)
    begin
        // This function is replicating the behavior of the page
        // If line is at the bottom, we will copy values from previous line
        // If line is in the middle, we will copy values from next line
        BottomLine := true;
        CopyValuesFromGenJnlLineSpecified := false;

        if GenJournalLine."Line No." <> 0 then begin
            CopyValuesFromGenJnlLine.Reset();
            CopyValuesFromGenJnlLine.CopyFilters(GenJournalLine);
            CopyValuesFromGenJnlLine.SetFilter("Line No.", '>%1', GenJournalLine."Line No.");
            if CopyValuesFromGenJnlLine.FindFirst() then begin
                CopyValuesFromGenJnlLineSpecified := true;
                BottomLine := false;
                exit;
            end;
        end;

        if not CopyValuesFromGenJnlLineSpecified then begin
            CopyValuesFromGenJnlLine.Reset();
            CopyValuesFromGenJnlLine.CopyFilters(GenJournalLine);
            if CopyValuesFromGenJnlLine.FindLast() then
                CopyValuesFromGenJnlLineSpecified := true;
        end;
    end;

    local procedure SetUpNewLine(var GenJournalLine: Record "Gen. Journal Line"; CopyValuesFromGenJnlLine: Record "Gen. Journal Line"; CopyValuesFromGenJnlLineSpecified: Boolean; BottomLine: Boolean)
    var
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
    begin
        if CopyValuesFromGenJnlLineSpecified then
            GenJnlManagement.CalcBalance(
              GenJournalLine, CopyValuesFromGenJnlLine, Balance, TotalBalance, ShowBalance, ShowTotalBalance);

        GenJournalLine.SetUpNewLine(CopyValuesFromGenJnlLine, Balance, BottomLine);

        if GenJournalLine."Line No." = 0 then
            GenJournalLine.Validate(
              "Line No.", GenJournalLine.GetNewLineNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name"));
    end;

    local procedure AlterDocNoBasedOnExternalDocNo(var GenJournalLine: Record "Gen. Journal Line"; CopyValuesFromGenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; CopyValuesFromGenJnlLineSpecified: Boolean)
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        if CopyValuesFromGenJnlLineSpecified and
           (CopyValuesFromGenJnlLine."Document No." = GenJournalLine."Document No.") and
           (CopyValuesFromGenJnlLine."External Document No." <> GenJournalLine."External Document No.")
        then
            GenJournalLine."Document No." := NoSeriesBatch.SimulateGetNextNo(GenJnlBatch."No. Series", GenJournalLine."Posting Date", GenJournalLine."Document No.");
    end;

    procedure GetBatchNameFromId(JournalBatchId: Guid): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.GetBySystemId(JournalBatchId);

        exit(GenJournalBatch.Name);
    end;
}

