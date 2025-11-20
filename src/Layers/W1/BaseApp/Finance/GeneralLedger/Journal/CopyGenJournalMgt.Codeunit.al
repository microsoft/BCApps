// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 181 "Copy Gen. Journal Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        CopiedLinesTxt: Label '%1 posted general journal lines was copied to General Journal.\\Do you want to open target general journal?', Comment = '%1 - number of lines';
        CanBeCopiedErr: Label 'You cannot copy the posted general journal lines with G/L register number %1 because they contain customer, vendor, or employee ledger entries that were posted and applied in the same G/L register.', Comment = '%1 = "G/L Register" number';

    procedure CopyToGenJournal(var PostedGenJournalLine: Record "Posted Gen. Journal Line")
    var
        CopyGenJournalParameters: Record "Copy Gen. Journal Parameters";
    begin
        if not PostedGenJournalLine.FindSet() then
            exit;

        CheckIfCanBeCopied(PostedGenJournalLine);

        if not GetCopyParameters(CopyGenJournalParameters, PostedGenJournalLine) then
            exit;

        PostedGenJournalLine.FindSet();
        repeat
            InsertGenJournalLine(PostedGenJournalLine, CopyGenJournalParameters);
        until PostedGenJournalLine.Next() = 0;

        ShowFinishMessage(PostedGenJournalLine.Count, CopyGenJournalParameters);
    end;

    procedure CopyGLRegister(var SrcPostedGenJournalLine: Record "Posted Gen. Journal Line")
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        TempPostedGenJournalLine: Record "Posted Gen. Journal Line" temporary;
        TempGLRegister: Record "G/L Register" temporary;
    begin
        if not SrcPostedGenJournalLine.FindSet() then
            exit;

        repeat
            TempGLRegister.Init();
            TempGLRegister."No." := SrcPostedGenJournalLine."G/L Register No.";
            if TempGLRegister.Insert() then;
        until SrcPostedGenJournalLine.Next() = 0;

        if not TempGLRegister.FindSet() then
            exit;

        repeat
            PostedGenJournalLine.SetRange("G/L Register No.", TempGLRegister."No.");
            if PostedGenJournalLine.FindSet() then
                repeat
                    TempPostedGenJournalLine.Init();
                    TempPostedGenJournalLine := PostedGenJournalLine;
                    TempPostedGenJournalLine.Insert();
                until PostedGenJournalLine.Next() = 0;
        until TempGLRegister.Next() = 0;

        CopyToGenJournal(TempPostedGenJournalLine);
    end;

    local procedure InsertGenJournalLine(PostedGenJournalLine: Record "Posted Gen. Journal Line"; CopyGenJournalParameters: Record "Copy Gen. Journal Parameters")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        OnBeforeInsertGenJournalLine(PostedGenJournalLine, CopyGenJournalParameters);

        GenJournalLine.Init();
        GenJournalLine.TransferFields(PostedGenJournalLine, true);
        GenJournalLine."Journal Template Name" := CopyGenJournalParameters."Journal Template Name";
        GenJournalLine."Journal Batch Name" := CopyGenJournalParameters."Journal Batch Name";
        if CopyGenJournalParameters."Replace Posting Date" <> 0D then
            GenJournalLine.Validate("Posting Date", CopyGenJournalParameters."Replace Posting Date");
        if CopyGenJournalParameters."Replace Document No." <> '' then
            GenJournalLine."Document No." := CopyGenJournalParameters."Replace Document No.";
        GenJournalLine."Line No." := GenJournalLine.GetNewLineNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        GenJournalLine."Posting No. Series" := '';
        if CopyGenJournalParameters."Reverse Sign" then begin
            GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
            GenJournalLine.Validate(Amount, -GenJournalLine.Amount);
        end;
        GenJournalLine.Insert(true);

        OnAfterInsertGenJournalLine(PostedGenJournalLine, CopyGenJournalParameters, GenJournalLine);
    end;

    local procedure GetCopyParameters(var CopyGenJournalParameters: Record "Copy Gen. Journal Parameters"; var PostedGenJournalLine: Record "Posted Gen. Journal Line") Result: Boolean
    var
        TempSrcGenJournalBatch: Record "Gen. Journal Batch" temporary;
        CopyGenJournalParametersPage: Page "Copy Gen. Journal Parameters";
    begin
        PrepareCopyGenJournalParameters(CopyGenJournalParameters, PostedGenJournalLine, TempSrcGenJournalBatch);

        CopyGenJournalParametersPage.SetCopyParameters(CopyGenJournalParameters, TempSrcGenJournalBatch);
        if CopyGenJournalParametersPage.RunModal() <> Action::OK then
            exit(false);

        CopyGenJournalParametersPage.GetCopyParameters(CopyGenJournalParameters);

        if CopyGenJournalParameters."Journal Template Name" <> '' then
            CopyGenJournalParameters.TestField("Journal Batch Name");
        Result := true;

        OnAfterGetCopyParameters(CopyGenJournalParameters, Result);
    end;

    local procedure ShowFinishMessage(LineCount: Integer; CopyGenJournalParameters: Record "Copy Gen. Journal Parameters")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ConfirmManagement: Codeunit "Confirm Management";
        GenJnlManagement: Codeunit GenJnlManagement;
    begin
        if ConfirmManagement.GetResponse(StrSubstNo(CopiedLinesTxt, LineCount), false) then begin
            GenJournalBatch.Get(CopyGenJournalParameters."Journal Template Name", CopyGenJournalParameters."Journal Batch Name");
            GenJnlManagement.TemplateSelectionFromBatch(GenJournalBatch);
        end;
    end;

    local procedure CheckIfCanBeCopied(var PostedGenJournalLine: Record "Posted Gen. Journal Line")
    var
        GLRegister: Record "G/L Register";
    begin
        if PostedGenJournalLine.FindSet() then
            repeat
                GLRegister.Get(PostedGenJournalLine."G/L Register No.");
                CheckCustomerEntries(GLRegister);
                CheckVendorEntries(GLRegister);
            until PostedGenJournalLine.Next() = 0;

        OnAfterCheckIfCanBeCopied(PostedGenJournalLine);
    end;

    local procedure CheckCustomerEntries(GLRegister: Record "G/L Register")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        DetailedCustLedgEntry.SetFilter("Entry Type", '<>%1', DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        if not DetailedCustLedgEntry.IsEmpty() then
            ShowCanBeCopiedError(GLRegister."No.");
    end;

    local procedure CheckVendorEntries(GLRegister: Record "G/L Register")
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        DetailedVendorLedgEntry.SetFilter("Entry Type", '<>%1', DetailedVendorLedgEntry."Entry Type"::"Initial Entry");
        if not DetailedVendorLedgEntry.IsEmpty() then
            ShowCanBeCopiedError(GLRegister."No.");
    end;

    local procedure ShowCanBeCopiedError(GLRegisterNo: Integer)
    begin
        Error(CanBeCopiedErr, GLRegisterNo);
    end;

    local procedure PrepareCopyGenJournalParameters(var CopyGenJournalParameters: Record "Copy Gen. Journal Parameters"; var PostedGenJournalLine: Record "Posted Gen. Journal Line"; var SrcGenJournalBatch: Record "Gen. Journal Batch")
    var
        TempGenJournalBatch: Record "Gen. Journal Batch" temporary;
    begin
        if not PostedGenJournalLine.FindSet() then
            exit;

        repeat
            TempGenJournalBatch.Init();
            TempGenJournalBatch."Journal Template Name" := PostedGenJournalLine."Journal Template Name";
            TempGenJournalBatch.Name := PostedGenJournalLine."Journal Batch Name";
            if TempGenJournalBatch.Insert() then;
        until PostedGenJournalLine.Next() = 0;

        if TempGenJournalBatch.Count = 1 then begin
            TempGenJournalBatch.FindFirst();
            SrcGenJournalBatch."Journal Template Name" := TempGenJournalBatch."Journal Template Name";
            SrcGenJournalBatch.Name := TempGenJournalBatch.Name;
            CopyGenJournalParameters."Journal Template Name" := TempGenJournalBatch."Journal Template Name";
            CopyGenJournalParameters."Journal Batch Name" := TempGenJournalBatch.Name;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJournalLine(var PostedGenJournalLine: Record "Posted Gen. Journal Line"; var CopyGenJournalParameters: Record "Copy Gen. Journal Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckIfCanBeCopied(PostedGenJournalLine: Record "Posted Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGenJournalLine(PostedGenJournalLine: Record "Posted Gen. Journal Line"; CopyGenJournalParameters: Record "Copy Gen. Journal Parameters"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCopyParameters(var CopyGenJournalParameters: Record "Copy Gen. Journal Parameters"; var Result: Boolean)
    begin
    end;
}
