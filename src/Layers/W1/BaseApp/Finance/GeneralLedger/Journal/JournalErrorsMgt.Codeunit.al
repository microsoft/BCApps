// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.FixedAssets.Journal;
using Microsoft.Intercompany.Journal;
using Microsoft.Projects.Project.Journal;
using Microsoft.Utilities;
using System.Utilities;

/// <summary>
/// Management codeunit for handling journal validation errors and background error checking for journal lines.
/// Provides centralized error management, validation tracking, and background error handling for journal operations.
/// </summary>
/// <remarks>
/// Centralized error management system for journal validation and background error processing.
/// Key features: Error message collection and management, background validation support, journal line change tracking.
/// Integration: Works with background error handling, validation codeunits, journal check processes.
/// Usage: Validation error collection, background check coordination, error display and management.
/// </remarks>
codeunit 9080 "Journal Errors Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        TempDeletedGenJnlLine: Record "Gen. Journal Line" temporary;
        TempModifiedGenJnlLine: Record "Gen. Journal Line" temporary;
        TempGenJnlLineBeforeModify: Record "Gen. Journal Line" temporary;
        TempGenJnlLineAfterModify: Record "Gen. Journal Line" temporary;
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        FullBatchCheck: Boolean;
        NothingToPostErr: Label 'There is nothing to post because the journal does not contain a quantity or amount.';

    /// <summary>
    /// Retrieves the standardized error message for situations where there are no journal lines to post.
    /// Provides consistent error messaging across journal posting operations.
    /// </summary>
    /// <returns>Text message indicating nothing to post condition.</returns>
    procedure GetNothingToPostErrorMsg(): Text
    begin
        exit(NothingToPostErr);
    end;

    /// <summary>
    /// Sets error messages collection from source error message records for journal validation processing.
    /// Transfers error messages from external validation processes into the journal error management context.
    /// </summary>
    /// <param name="SourceTempErrorMessage">Temporary error message records to copy into journal error management.</param>
    procedure SetErrorMessages(var SourceTempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Copy(SourceTempErrorMessage, true);
    end;

    /// <summary>
    /// Retrieves error messages collection for journal validation and processing.
    /// Returns accumulated error messages from journal validation operations for display or further processing.
    /// </summary>
    /// <param name="NewTempErrorMessage">Temporary error message records to populate with current error collection.</param>
    procedure GetErrorMessages(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

    /// <summary>
    /// Sets record context for journal line modification validation tracking.
    /// Stores previous and current journal line records for change detection and validation during modification operations.
    /// </summary>
    /// <param name="xRec">Previous version of journal line record before modification.</param>
    /// <param name="Rec">Current version of journal line record after modification.</param>
    procedure SetRecXRecOnModify(xRec: Record "Gen. Journal Line"; Rec: Record "Gen. Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then begin
            SaveJournalLineToBuffer(xRec, TempGenJnlLineBeforeModify);
            SaveJournalLineToBuffer(Rec, TempGenJnlLineAfterModify);
        end;
    end;

    local procedure SaveJournalLineToBuffer(GenJournalLine: Record "Gen. Journal Line"; var BufferLine: Record "Gen. Journal Line" temporary)
    begin
        if BufferLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.") then begin
            BufferLine.TransferFields(GenJournalLine);
            BufferLine.Modify();
        end else begin
            BufferLine := GenJournalLine;
            BufferLine.Insert();
        end;
    end;

    /// <summary>
    /// Retrieves record context for journal line modification validation tracking.
    /// Returns stored previous and current journal line records used for change detection during validation.
    /// </summary>
    /// <param name="xRec">Previous version of journal line record to return.</param>
    /// <param name="Rec">Current version of journal line record to return.</param>
    /// <returns>True if record context is available, false if no modification context is stored.</returns>
    procedure GetRecXRecOnModify(var xRec: Record "Gen. Journal Line"; var Rec: Record "Gen. Journal Line"): Boolean
    begin
        if TempGenJnlLineAfterModify.FindFirst() then begin
            xRec := TempGenJnlLineBeforeModify;
            Rec := TempGenJnlLineAfterModify;

            if TempGenJnlLineBeforeModify.Delete() then;
            if TempGenJnlLineAfterModify.Delete() then;
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Sets the full batch check mode for journal validation processing.
    /// Controls whether validation should process entire journal batches or individual lines.
    /// </summary>
    /// <param name="NewFullBatchCheck">True to enable full batch validation, false for individual line validation.</param>
    procedure SetFullBatchCheck(NewFullBatchCheck: Boolean)
    begin
        FullBatchCheck := NewFullBatchCheck;
    end;

    /// <summary>
    /// Retrieves the current full batch check mode setting for journal validation.
    /// Indicates whether validation is configured for full batch or individual line processing.
    /// </summary>
    /// <returns>True if full batch validation is enabled, false if individual line validation is used.</returns>
    procedure GetFullBatchCheck(): Boolean
    begin
        exit(FullBatchCheck);
    end;

    /// <summary>
    /// Retrieves deleted journal lines from the tracking buffer for error management and recovery operations.
    /// Returns journal lines that have been marked as deleted during validation or processing operations.
    /// </summary>
    /// <param name="TempGenJnlLine">Temporary journal line records to populate with deleted line information.</param>
    /// <param name="ClearBuffer">Boolean indicating whether to clear the deleted lines buffer after retrieval.</param>
    /// <returns>True if deleted lines are available, false if no deleted lines exist in buffer.</returns>
    procedure GetDeletedGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; ClearBuffer: Boolean): Boolean
    begin
        if TempDeletedGenJnlLine.FindSet() then begin
            repeat
                TempGenJnlLine := TempDeletedGenJnlLine;
                TempGenJnlLine.Insert();
            until TempDeletedGenJnlLine.Next() = 0;

            if ClearBuffer then
                TempDeletedGenJnlLine.DeleteAll();
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Retrieves modified journal lines from the tracking buffer for change detection and validation.
    /// Returns journal lines that have been tracked as modified during validation operations.
    /// </summary>
    /// <param name="TempGenJnlLine">Temporary journal line records to populate with modified line information.</param>
    /// <returns>True if modified lines are available, false if no modified lines exist in buffer.</returns>
    procedure GetModifiedGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary): Boolean
    begin
        TempGenJnlLine.Reset();
        TempGenJnlLine.DeleteAll();
        if TempModifiedGenJnlLine.FindSet() then begin
            repeat
                TempGenJnlLine := TempModifiedGenJnlLine;
                TempGenJnlLine.Insert();
            until TempModifiedGenJnlLine.Next() = 0;

            TempModifiedGenJnlLine.DeleteAll();
            exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Inserts a deleted journal line into the tracking buffer for audit and recovery purposes.
    /// Stores journal lines that have been deleted during validation or posting operations.
    /// </summary>
    /// <param name="GenJnlLine">The journal line record to track as deleted.</param>
    procedure InsertDeletedLine(GenJnlLine: Record "Gen. Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then begin
            TempDeletedGenJnlLine := GenJnlLine;
            if TempDeletedGenJnlLine.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"General Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventGeneralJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"General Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"General Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventSalesJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Sales Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventSalesJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventPurchaseJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventPurchaseJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Cash Receipt Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventCashReceiptJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Cash Receipt Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventCashReceiptJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Cash Receipt Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventCashReceiptJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventPaymentJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPaymentJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Payment Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventPaymentJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"IC General Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job G/L Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventJobGLJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job G/L Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventJobGLJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job G/L Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventJobJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Fixed Asset G/L Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventFixedAssetGLJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Fixed Asset G/L Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventFixedAssetGLJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Fixed Asset G/L Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventFixedAssetGLJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Recurring General Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventRecurringGenJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Recurring General Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventRecurringGenJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Recurring General Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventRecurringGenJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;
}
