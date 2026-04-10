// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Inventory.Counting.Journal;
using Microsoft.Utilities;
using System.Utilities;

codeunit 9077 "Item Journal Errors Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        TempItemJnlLineModified: Record "Item Journal Line" temporary;
        TempDeletedItemJnlLine: Record "Item Journal Line" temporary;
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        FullBatchCheck: Boolean;

    procedure SetErrorMessages(var SourceTempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Copy(SourceTempErrorMessage, true);
    end;

    procedure GetErrorMessages(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

    procedure SetItemJnlLineOnModify(Rec: Record "Item Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then
            SaveItemJournalLineToBuffer(Rec, TempItemJnlLineModified);
    end;

    local procedure SaveItemJournalLineToBuffer(ItemJournalLine: Record "Item Journal Line"; var BufferLine: Record "Item Journal Line" temporary)
    begin
        if BufferLine.Get(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemJournalLine."Line No.") then begin
            BufferLine.TransferFields(ItemJournalLine);
            BufferLine.Modify();
        end else begin
            BufferLine := ItemJournalLine;
            BufferLine.Insert();
        end;
    end;

    procedure GetItemJnlLinePreviousLineNo() PrevLineNo: Integer
    begin
        if TempItemJnlLineModified.FindFirst() then begin
            PrevLineNo := TempItemJnlLineModified."Line No.";
            if TempItemJnlLineModified.Delete() then;
        end;
    end;

    procedure SetFullBatchCheck(NewFullBatchCheck: Boolean)
    begin
        FullBatchCheck := NewFullBatchCheck;
    end;

    procedure GetFullBatchCheck(): Boolean
    begin
        exit(FullBatchCheck);
    end;

    procedure GetDeletedItemJnlLine(var TempItemJnlLine: Record "Item Journal Line" temporary; ClearBuffer: Boolean): Boolean
    begin
        if TempDeletedItemJnlLine.FindSet() then begin
            repeat
                TempItemJnlLine := TempDeletedItemJnlLine;
                TempItemJnlLine.Insert();
            until TempDeletedItemJnlLine.Next() = 0;

            if ClearBuffer then
                TempDeletedItemJnlLine.DeleteAll();
            exit(true);
        end;

        exit(false);
    end;

    procedure InsertDeletedItemJnlLine(ItemJnlLine: Record "Item Journal Line")
    begin
        if BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled() then begin
            TempDeletedItemJnlLine := ItemJnlLine;
            if TempDeletedItemJnlLine.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventItemJournal(var Rec: Record "Item Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedItemJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventItemJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowModify: Boolean)
    begin
        SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventItemJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowInsert: Boolean)
    begin
        SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Reclass. Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventItemReclassJournal(var Rec: Record "Item Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedItemJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Reclass. Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventItemReclassJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowModify: Boolean)
    begin
        SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Reclass. Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventItemReclassJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowInsert: Boolean)
    begin
        SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Phys. Inventory Journal", 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventPhysInventoryJournal(var Rec: Record "Item Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedItemJnlLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Phys. Inventory Journal", 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPhysInventoryJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowModify: Boolean)
    begin
        SetItemJnlLineOnModify(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Phys. Inventory Journal", 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventPhysInventoryJournal(var Rec: Record "Item Journal Line"; var xRec: Record "Item Journal Line"; var AllowInsert: Boolean)
    begin
        SetItemJnlLineOnModify(Rec);
    end;
}
