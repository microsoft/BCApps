// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.ItemTracking;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Tracking;

/// <summary>
/// The purpose of this reaction is to change lot, change serial, change package, change expiration date.
/// </summary>
codeunit 20443 "Qlty. Disp. Change Tracking" implements "Qlty. Disposition"
{
    var
        WarehouseJournalLineDescriptionTemplateLbl: Label 'Inspection [%1] changed item tracking', Comment = '%1 = Quality Inspection';
        DescriptionTxt: Label 'Inspection [%1] changed item tracking', Comment = '%1 = Quality Inspection';
        NoJournalBatchErr: Label 'Cannot open the Reclassification Journal Batch. Check the Move/Reclassify batches on the Quality Management Setup page.';
        MissingBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the Reclassification Journal Batch or Warehouse Reclassification Batch';
        NoItemTrackingChangesErr: Label 'No changes to item tracking information were provided.';
        DocumentTypeLbl: Label 'item tracking change';

    /// <summary>
    /// Performs the change item tracking disposition.
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <returns></returns>
    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) Changed: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        ItemReservationEntry: Record "Reservation Entry";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        IsHandled: Boolean;
        LoopSuccess: Boolean;
        LineCreated: Boolean;
        DocumentOrBatch: Text;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Change Item Tracking";

        OnBeforeProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, Changed, IsHandled);
        if IsHandled then
            exit;

        if ((TempInstructionQltyDispositionBuffer."New Lot No." = '') and (TempInstructionQltyDispositionBuffer."New Serial No." = '') and (TempInstructionQltyDispositionBuffer."New Package No." = '') and
           (TempInstructionQltyDispositionBuffer."New Expiration Date" = 0D))
        then
            Error(NoItemTrackingChangesErr);

        QltyManagementSetup.Get();

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);

        repeat
            Clear(Location);
            LoopSuccess := false;
            if TempQuantityToActQltyDispositionBuffer."Location Filter" <> '' then
                Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());
            if Location."Directed Put-away and Pick" then begin
                if QltyManagementSetup."Whse. Reclass. Batch Name" = '' then
                    Error(MissingBatchErr);

                DocumentOrBatch := QltyManagementSetup."Whse. Reclass. Batch Name";
                Clear(WarehouseJournalLine);
                CreateTrackingWarehouseReclassLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Whse. Reclass. Batch Name", WarehouseJournalLine, WhseItemTrackingLine);
                LineCreated := WarehouseJournalLine."Line No." <> 0;
                if TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only" then
                    Changed := LineCreated;
                if LineCreated and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) then
                    Changed := QltyItemJournalManagement.PostWarehouseJournal(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, WarehouseJournalLine);
                LoopSuccess := true;
            end else begin
                if QltyManagementSetup."Item Reclass. Batch Name" = '' then
                    Error(MissingBatchErr);
                DocumentOrBatch := QltyManagementSetup."Item Reclass. Batch Name";
                Clear(ItemJournalLine);
                CreateTrackingItemReclassLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Item Reclass. Batch Name", ItemJournalLine, ItemReservationEntry);
                LineCreated := ItemJournalLine."Line No." <> 0;
                if TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only" then
                    Changed := LineCreated;
                if LineCreated and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) then
                    Changed := QltyItemJournalManagement.PostItemJournal(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, ItemJournalLine);
                LoopSuccess := true;
            end;

            if LoopSuccess then
                if Location."Directed Put-away and Pick" then
                    QltyNotificationMgmt.NotifyItemTrackingChanged(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, LineCreated, Changed, TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)", DocumentOrBatch, WhseItemTrackingLine."Expiration Date")
                else
                    QltyNotificationMgmt.NotifyItemTrackingChanged(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, LineCreated, Changed, TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)", DocumentOrBatch, ItemReservationEntry."Expiration Date")
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        OnAfterProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, Changed);

        if not Changed then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
    end;

    local procedure CreateTrackingItemReclassLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; ReclassBatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        JournalTemplate: Code[10];
        IsHandled: Boolean;
    begin
        Clear(ItemJournalLine);
        QltyManagementSetup.Get();
        JournalTemplate := QltyManagementSetup.GetItemReclassJournalTemplate();

        ItemJournalBatch.SetAutoCalcFields("Template Type");
        if not ItemJournalBatch.Get(JournalTemplate, ReclassBatchName) then
            Error(NoJournalBatchErr);

        OnBeforeInsertCreateTrackingItemReclassLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, ReclassBatchName, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if TempQuantityToActQltyDispositionBuffer."New Location Code" = '' then
            TempQuantityToActQltyDispositionBuffer."New Location Code" := TempQuantityToActQltyDispositionBuffer.GetFromLocationCode();

        if TempQuantityToActQltyDispositionBuffer."New Bin Code" = '' then
            TempQuantityToActQltyDispositionBuffer."New Bin Code" := TempQuantityToActQltyDispositionBuffer.GetFromBinCode();

        QltyItemJournalManagement.CreateItemJournalLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry);

        ItemJournalLine.Description := CopyStr(StrSubstNo(DescriptionTxt, QltyInspectionHeader.GetFriendlyIdentifier()), 1, MaxStrLen(ItemJournalLine.Description));

        ItemJournalLine.Modify();

        OnAfterCreateTrackingItemReclassLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, ReclassBatchName, ItemJournalLine, ReservationEntry);
    end;

    local procedure CreateTrackingWarehouseReclassLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; ReclassBatchName: Code[10]; var WhseWarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        ChangeTrackingWarehouseJournalBatch: Record "Warehouse Journal Batch";

        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        JournalTemplate: Code[10];
    begin
        JournalTemplate := QltyManagementSetup.GetWarehouseReclassificationJournalTemplate();
        if not ChangeTrackingWarehouseJournalBatch.Get(JournalTemplate, ReclassBatchName, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode()) then
            Error(NoJournalBatchErr);

        TempQuantityToActQltyDispositionBuffer."New Location Code" := TempQuantityToActQltyDispositionBuffer.GetFromLocationCode();
        TempQuantityToActQltyDispositionBuffer."New Bin Code" := TempQuantityToActQltyDispositionBuffer.GetFromBinCode();

        QltyItemJournalManagement.CreateWarehouseJournalLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, ChangeTrackingWarehouseJournalBatch, WhseWarehouseJournalLine, WhseItemTrackingLine);
        WhseWarehouseJournalLine.Description := CopyStr(StrSubstNo(WarehouseJournalLineDescriptionTemplateLbl, QltyInspectionHeader.GetFriendlyIdentifier()), 1, MaxStrLen(WhseWarehouseJournalLine.Description));

        WhseWarehouseJournalLine.Modify();
    end;

    /// <summary>
    /// Occurs before change tracking has taken place, allowing the opportunity to extend or replace the functionality.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var Changed: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after change tracking has taken place.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var Changed: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to adjust the item reclassification line created to change item tracking information before it is inserted.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnBeforeInsertCreateTrackingItemReclassLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ReclassBatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to adjust the warehouse reclassification line and whse. tracking line created to change item tracking information.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnAfterCreateTrackingItemReclassLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ReclassBatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;
}
