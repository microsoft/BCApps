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

    procedure GetNothingToPostErrorMsg(): Text
    begin
        exit(NothingToPostErr);
    end;

    procedure SetErrorMessages(var SourceTempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Copy(SourceTempErrorMessage, true);
    end;

    procedure GetErrorMessages(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

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

    procedure SetFullBatchCheck(NewFullBatchCheck: Boolean)
    begin
        FullBatchCheck := NewFullBatchCheck;
    end;

    procedure GetFullBatchCheck(): Boolean
    begin
        exit(FullBatchCheck);
    end;

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
