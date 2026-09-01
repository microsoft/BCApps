// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Move;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;

codeunit 20452 "Qlty. Disp. Move Item Reclass." implements "Qlty. Disposition"
{
    var
        ItemJournalLineDescriptionTemplateLbl: Label 'Inspection [%3] changed bin from [%1] to [%2]', Comment = '%1 = From Bin code; %2 = To Bin code; %3 = the inspection';
        MissingBinMoveBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the movement batches.';
        OpenSetupActionLbl: Label 'Open Quality Management Setup';
        DocumentTypeLbl: Label 'Item Reclassification';

    /// <summary>
    /// Creates and optionally posts item reclassification lines to move inspection inventory.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to move.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions containing source, destination, quantity, and posting behavior.</param>
    /// <returns>True if a reclassification line was created or posted; otherwise, false.</returns>
    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ItemJournalLine: Record "Item Journal Line";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        CreatedLineNo: Integer;
        IsHandled: Boolean;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Item Reclassification";

        OnBeforeProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DidSomething, IsHandled);
        if IsHandled then
            exit;

        QltyManagementSetup.Get();
        if QltyManagementSetup."Item Reclass. Batch Name" = '' then
            ThrowMissingSetupError();

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            Clear(CreatedLineNo);
            CreateItemReclassificationLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Item Reclass. Batch Name", CreatedLineNo);

            if CreatedLineNo <> 0 then begin
                DidSomething := true;
                if TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post then begin
                    ItemJournalLine.SetRange("Journal Template Name", QltyManagementSetup.GetItemReclassJournalTemplate());
                    ItemJournalLine.SetRange("Journal Batch Name", QltyManagementSetup."Item Reclass. Batch Name");
                    ItemJournalLine.SetRange("Line No.", CreatedLineNo);
                    DidSomething := QltyItemJournalManagement.PostItemJournal(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, ItemJournalLine);
                    if DidSomething then
                        QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Item Reclass. Batch Name")
                    else begin
                        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only";

                        QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Item Reclass. Batch Name");

                        TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;
                    end;
                end else
                    QltyNotificationMgmt.NotifyMovementOccurred(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, QltyManagementSetup."Item Reclass. Batch Name");
            end;
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if not DidSomething and (TempInstructionQltyDispositionBuffer."Entry Behavior" <> TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);

        OnAfterProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DidSomething);
    end;

    /// <summary>
    /// Creates an item reclassification journal line for the requested movement.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the item and tracking values.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The movement source, destination, and quantity.</param>
    /// <param name="BatchName">The item reclassification journal batch name.</param>
    /// <param name="CreatedLineNo">The line number of the created journal line.</param>
    local procedure CreateItemReclassificationLine(QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; BatchName: Code[10]; var CreatedLineNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJournalBatch: Record "Item Journal Batch";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        IsHandled: Boolean;
    begin
        QltyManagementSetup.Get();
        OnBeforeCreateItemReclassificationLine(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, BatchName, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        ItemJournalBatch.SetAutoCalcFields("Template Type");
        ItemJournalBatch.Get(QltyManagementSetup.GetItemReclassJournalTemplate(), BatchName);

        QltyItemJournalManagement.CreateItemJournalLine(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry);
        ItemJournalLine.Description := CopyStr(StrSubstNo(ItemJournalLineDescriptionTemplateLbl, TempInstructionQltyDispositionBuffer.GetFromBinCode(), TempInstructionQltyDispositionBuffer."New Bin Code", QltyInspectionHeader.GetFriendlyIdentifier()), 1, MaxStrLen(ItemJournalLine.Description));
        ItemJournalLine.Modify(false);

        CreatedLineNo := ItemJournalLine."Line No.";
    end;

    /// <summary>
    /// This allows extensions to override or replace the item reclassification event.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to move.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The movement source, destination, and quantity.</param>
    /// <param name="BatchName">The item reclassification journal batch name.</param>
    /// <param name="ItemJournalLine">The item journal line being prepared.</param>
    /// <param name="IsHandled">Set to true to skip the default line creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemReclassificationLine(QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var BatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before the disposition has taken place, allowing the opportunity to extend or replace the functionality.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection being processed.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions.</param>
    /// <param name="Changed">Indicates whether a reclassification line was created or posted.</param>
    /// <param name="IsHandled">Set to true to skip the default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var Changed: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after the disposition has taken place.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that was processed.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions.</param>
    /// <param name="Changed">Indicates whether a reclassification line was created or posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var Changed: Boolean)
    begin
    end;

    /// <summary>
    /// Raises an actionable error when the item reclassification batch is not configured.
    /// </summary>
    local procedure ThrowMissingSetupError()
    var
        ErrorInfo: ErrorInfo;
    begin
        ErrorInfo.Message := MissingBinMoveBatchErr;
        ErrorInfo.PageNo := Page::"Qlty. Management Setup";
        ErrorInfo.AddAction(OpenSetupActionLbl, Codeunit::"Qlty. Disp. Move Item Reclass.", 'OpenQualityManagementSetup');
        Error(ErrorInfo);
    end;

    /// <summary>
    /// Opens Quality Management Setup from the missing-setup error action.
    /// </summary>
    /// <param name="ErrorInfo">The error context supplied to the action callback.</param>
    procedure OpenQualityManagementSetup(ErrorInfo: ErrorInfo)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        if not QltyManagementSetup.Get() then
            QltyManagementSetup.Insert(true);
        Page.Run(Page::"Qlty. Management Setup", QltyManagementSetup);
    end;
}