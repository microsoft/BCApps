// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

/// <summary>
/// Management codeunit for copying posted general journal lines back to active general journal batches.
/// Provides functionality to recreate journal entries from posted transactions for corrections or recurring entries.
/// </summary>
/// <remarks>
/// Core functionality for copying posted journal transactions back to active journals for reprocessing.
/// Supports copying individual posted lines or complete G/L registers with validation and parameter configuration.
/// Key features: Posted line copying, G/L register recreation, parameter-based configuration, validation checks.
/// Integration: Works with Copy Gen. Journal Parameters for configuration, validates against applied entries.
/// </remarks>
codeunit 181 "Copy Gen. Journal Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        CopiedLinesTxt: Label '%1 posted general journal lines was copied to General Journal.\\Do you want to open target general journal?', Comment = '%1 - number of lines';
        CanBeCopiedErr: Label 'You cannot copy the posted general journal lines with G/L register number %1 because they contain customer, vendor, or employee ledger entries that were posted and applied in the same G/L register.', Comment = '%1 = "G/L Register" number';
        SkipValidationConfirmQst: Label 'No GL Register found with no. %1, do you still want to copy and skip validation?', Comment = 'Confirmation message when no GL Register is found for the posted lines being copied.';

    /// <summary>
    /// Copies posted general journal lines to an active general journal batch for reprocessing or correction.
    /// Validates posted lines can be copied and prompts user for copy parameters before creating new journal lines.
    /// </summary>
    /// <param name="PostedGenJournalLine">Posted journal lines to copy (multiple lines supported via filters)</param>
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

    /// <summary>
    /// Copies complete G/L registers (all posted lines from specific register numbers) to active general journal batches.
    /// Handles bulk copying of entire posting transactions organized by G/L register with validation and parameter setup.
    /// </summary>
    /// <param name="SrcPostedGenJournalLine">Source posted journal lines filtered by G/L register numbers to copy</param>
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
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmHandled: Boolean;
        ConfirmResponse: Boolean;
    begin
        if not PostedGenJournalLine.FindSet() then
            exit;

        repeat
            if GLRegister.Get(PostedGenJournalLine."G/L Register No.") then begin
                CheckCustomerEntries(GLRegister);
                CheckVendorEntries(GLRegister);
            end else begin
                ConfirmHandled := false;
                ConfirmResponse := false;
                OnCheckIfCanBeCopiedOnBeforeSkipValidationOrError(PostedGenJournalLine, ConfirmHandled, ConfirmResponse);
                if ConfirmHandled then begin
                    if not ConfirmResponse then
                        Error('');
                end else
                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(SkipValidationConfirmQst, PostedGenJournalLine."G/L Register No."), false) then
                        Error('');
            end;
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

    /// <summary>
    /// Integration event raised before inserting a copied general journal line from posted transaction.
    /// Allows modification of posted data or copy parameters before creating the new journal line.
    /// </summary>
    /// <param name="PostedGenJournalLine">Posted journal line being copied to active journal</param>
    /// <param name="CopyGenJournalParameters">Copy parameters controlling destination batch and processing options</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGenJournalLine(var PostedGenJournalLine: Record "Posted Gen. Journal Line"; var CopyGenJournalParameters: Record "Copy Gen. Journal Parameters")
    begin
    end;

    /// <summary>
    /// Integration event raised after validating that posted general journal lines can be copied.
    /// Provides extensibility for additional validation rules or custom copy eligibility checks.
    /// </summary>
    /// <param name="PostedGenJournalLine">Posted journal line that passed standard copy validation checks</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckIfCanBeCopied(PostedGenJournalLine: Record "Posted Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully inserting a copied general journal line into the active batch.
    /// Enables post-processing of the newly created journal line or additional field updates.
    /// </summary>
    /// <param name="PostedGenJournalLine">Source posted journal line that was copied</param>
    /// <param name="CopyGenJournalParameters">Copy parameters used during the insertion process</param>
    /// <param name="GenJournalLine">Newly created general journal line in the active batch</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertGenJournalLine(PostedGenJournalLine: Record "Posted Gen. Journal Line"; CopyGenJournalParameters: Record "Copy Gen. Journal Parameters"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after retrieving copy parameters from the user interface.
    /// Allows modification of copy parameters or overriding the user's parameter selection result.
    /// </summary>
    /// <param name="CopyGenJournalParameters">Copy parameters obtained from user input or defaults</param>
    /// <param name="Result">Boolean result indicating whether copy parameters were successfully obtained</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCopyParameters(var CopyGenJournalParameters: Record "Copy Gen. Journal Parameters"; var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before confirming whether to skip validation when no G/L Register is found.
    /// Provides extensibility for handling the confirmation or overriding the default behavior.
    /// </summary>
    /// <param name="PostedGenJournalLine">Posted journal line being evaluated for copy eligibility</param>
    /// <param name="ConfirmHandled">Boolean flag indicating whether the confirmation was handled by the event subscriber</param>
    /// <param name="ConfirmResponse">Boolean response to return as the confirm action if confirm dialog is skipped</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckIfCanBeCopiedOnBeforeSkipValidationOrError(PostedGenJournalLine: Record "Posted Gen. Journal Line"; var ConfirmHandled: Boolean; var ConfirmResponse: Boolean)
    begin
    end;
}
