// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.InventoryAdjustment;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Tracking;

/// <summary>
/// The purpose of this reaction is to do inventory adjustments such as negative adjustments for the purposes of disposing inventory.
/// </summary>
codeunit 20446 "Qlty. Disp. Neg. Adjust Inv." implements "Qlty. Disposition"
{
    var
        WarehouseJournalLineDescriptionTemplateLbl: Label 'Inspection [%1] negative adjusted quantity', Comment = '%1 = Quality Inspection';
        MissingBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the adjustment batch.';
        WriteOffEntireItemTrackingErr: Label 'Reducing inventory using the item tracked quantity for inspection %1 was requested, however the item associated with this inspection does not require tracking.', Comment = '%1=the inspection';
        CannotGetJournalBatchErr: Label 'Could not get journal batch %1,%2%3. Check the adjustment batch on the Quality Management Setup page.', Comment = '%1=template,%2=batch name,%3=location';
        LocationLbl: Label ' Location: %1', Comment = '%1=location';
        DocumentTypeLbl: Label 'Negative Adjustment';
        NoAdjTemplateErr: Label 'No Adjustment Journal Template found. Ensure a valid adjustment template exists.';
        DescriptionTxt: Label 'Inspection [%1] reduce inventory', Comment = '%1 = Quality Inspection';

    /// <summary>
    /// Creates a negative adjustment using the information from a given Quality Inspection.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to adjust.</param>
    /// <param name="OptionalSpecificQuantity">The specific base quantity to adjust when required by the quantity behavior.</param>
    /// <param name="QltyQuantityBehavior">The rule used to determine the adjustment quantity.</param>
    /// <param name="OptionalSourceLocationFilter">An optional source location filter.</param>
    /// <param name="OptionalSourceBinFilter">An optional source bin filter.</param>
    /// <param name="PostingBehavior">Specifies whether to prepare or post the adjustment.</param>
    /// <param name="Reason">The reason code assigned to the adjustment line.</param>
    /// <returns>True if an adjustment line was created or posted; otherwise, false.</returns>
    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; PostingBehavior: Enum "Qlty. Item Adj. Post Behavior"; Reason: Code[10]) DidSomething: Boolean
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Dispose with Negative Inventory Adjustment";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := OptionalSpecificQuantity;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := QltyQuantityBehavior;
        TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(OptionalSourceLocationFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
        TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(OptionalSourceBinFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
        TempInstructionQltyDispositionBuffer."Entry Behavior" := PostingBehavior;
        TempInstructionQltyDispositionBuffer."Reason Code" := Reason;
        exit(PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    /// <summary>
    /// Creates a negative adjustment using the information from a given Quality Inspection.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to adjust.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions that define the quantity, source filters, posting behavior, and reason code.</param>
    /// <returns>True if an adjustment line was created or posted; otherwise, false.</returns>
    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Location: Record Location;
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        ItemJournalLine: Record "Item Journal Line";
        ItemReservationEntry: Record "Reservation Entry";
        WhseWarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseJnlWarehouseJournalTemplate: Record "Warehouse Journal Template";
        JnlItemJournalTemplate: Record "Item Journal Template";
        WhseJnlWarehouseJournalBatch: Record "Warehouse Journal Batch";
        NegativeAdjustItemJournalBatch: Record "Item Journal Batch";
        ItmItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        IsHandled: Boolean;
        CreatedLine: Boolean;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Dispose with Negative Inventory Adjustment";

        OnBeforeProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DidSomething, IsHandled);
        if IsHandled then
            exit;

        if TempInstructionQltyDispositionBuffer."Quantity Behavior" = TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity" then
            if not QltyInspectionHeader.IsItemTrackingUsed() then
                Error(WriteOffEntireItemTrackingErr, QltyInspectionHeader.GetFriendlyIdentifier());

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        QltyManagementSetup.Get();

        if IsHandled then
            exit;

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            Clear(Location);
            if TempQuantityToActQltyDispositionBuffer."Location Filter" <> '' then
                Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());
            if Location."Directed Put-away and Pick" then begin
                if QltyManagementSetup."Whse. Item Journal Batch Name" = '' then
                    Error(MissingBatchErr);
                if not WhseJnlWarehouseJournalBatch.Get(QltyManagementSetup.GetWarehouseInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Whse. Item Journal Batch Name", Location.Code) then
                    Error(CannotGetJournalBatchErr, QltyManagementSetup.GetWarehouseInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Whse. Item Journal Batch Name", StrSubstNo(LocationLbl, Location.Code));

                Clear(WhseWarehouseJournalLine);
                CreateNegativeWarehouseAdjustmentLine(
                   QltyInspectionHeader,
                   TempQuantityToActQltyDispositionBuffer,
                   WhseJnlWarehouseJournalBatch.Name,
                   WhseWarehouseJournalLine,
                   WhseItemTrackingLine);
                CreatedLine := WhseWarehouseJournalLine."Line No." <> 0;
                if CreatedLine then begin
                    if TempQuantityToActQltyDispositionBuffer."Entry Behavior" = TempQuantityToActQltyDispositionBuffer."Entry Behavior"::Post then begin
                        DidSomething := false;
                        WhseJnlWarehouseJournalTemplate.Get(WhseWarehouseJournalLine."Journal Template Name");
                        WhseJnlWarehouseJournalTemplate.TestField("Force Registering Report", false);
                        WhseWarehouseJournalLine.SetRecFilter();
                        Codeunit.Run(Codeunit::"Whse. Jnl.-Register Batch", WhseWarehouseJournalLine);
                        DidSomething := true;
                    end else
                        DidSomething := true;

                    QltyNotificationMgmt.NotifyNegativeAdjustmentOccurred(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Whse. Item Journal Batch Name");
                end;
            end else begin
                if QltyManagementSetup."Item Journal Batch Name" = '' then
                    Error(MissingBatchErr);
                NegativeAdjustItemJournalBatch.SetAutoCalcFields("Template Type");
                if not NegativeAdjustItemJournalBatch.Get(QltyManagementSetup.GetInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Item Journal Batch Name") then
                    Error(CannotGetJournalBatchErr, QltyManagementSetup.GetInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Item Journal Batch Name", '');
                Clear(ItemJournalLine);
                CreateNegativeItemAdjustmentLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, NegativeAdjustItemJournalBatch, ItemJournalLine, ItemReservationEntry);
                CreatedLine := ItemJournalLine."Line No." <> 0;

                if CreatedLine then begin
                    if TempQuantityToActQltyDispositionBuffer."Entry Behavior" = TempQuantityToActQltyDispositionBuffer."Entry Behavior"::Post then begin
                        DidSomething := false;
                        JnlItemJournalTemplate.Get(ItemJournalLine."Journal Template Name");
                        JnlItemJournalTemplate.TestField("Force Posting Report", false);
                        ItmItemJnlPostBatch.SetSuppressCommit(true);
                        ItemJournalLine.SetRange("Line No.", ItemJournalLine."Line No.");
                        ItmItemJnlPostBatch.Run(ItemJournalLine);
                        DidSomething := true;
                    end else
                        DidSomething := true;

                    QltyNotificationMgmt.NotifyNegativeAdjustmentOccurred(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Item Journal Batch Name");
                end;
            end;

        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if not DidSomething then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);

        OnAfterProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DidSomething);
    end;

    /// <summary>
    /// Creates a negative warehouse adjustment line and its warehouse item tracking line.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the item and tracking values.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The source filters and quantity to adjust; the quantity is converted to a negative value.</param>
    /// <param name="WarehouseNegativeAdjustmentBatch">The warehouse journal batch name.</param>
    /// <param name="WarehouseJournalLine">The created warehouse journal line.</param>
    /// <param name="WhseItemTrackingLine">The created warehouse item tracking line.</param>
    local procedure CreateNegativeWarehouseAdjustmentLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; WarehouseNegativeAdjustmentBatch: Code[10]; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        WhseJnlWarehouseJournalBatch: Record "Warehouse Journal Batch";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        IsHandled: Boolean;
    begin
        Clear(WarehouseJournalLine);
        WarehouseJournalLine.Reset();
        OnBeforeCreateNegativeWarehouseAdjustmentLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, WarehouseNegativeAdjustmentBatch, WarehouseJournalLine, WhseItemTrackingLine, IsHandled);
        if IsHandled then
            exit;

        QltyManagementSetup.Get();
        WhseJnlWarehouseJournalBatch.Get(QltyManagementSetup.GetWarehouseInventoryAdjustmentJournalTemplate(), WarehouseNegativeAdjustmentBatch, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

        TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" := -1 *
            Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");

        QltyItemJournalManagement.CreateWarehouseJournalLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, WhseJnlWarehouseJournalBatch, WarehouseJournalLine, WhseItemTrackingLine);

        WarehouseJournalLine.Description := StrSubstNo(WarehouseJournalLineDescriptionTemplateLbl, QltyInspectionHeader.GetFriendlyIdentifier());
        WarehouseJournalLine.Modify();
    end;

    /// <summary>
    /// Creates a negative item journal adjustment line and its reservation entry.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the item and tracking values.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The source filters and quantity to adjust; the quantity is converted to a negative value.</param>
    /// <param name="ItemJournalBatch">The item journal batch in which to create the line.</param>
    /// <param name="ItemJournalLine">The created item journal line.</param>
    /// <param name="ReservationEntry">The reservation entry created for item tracking.</param>
    local procedure CreateNegativeItemAdjustmentLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        ItemJournalTemplate: Code[10];
        IsHandled: Boolean;
    begin
        Clear(ItemJournalLine);

        OnBeforeCreateNegativeItemAdjustmentLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch.Name, ItemJournalLine, ReservationEntry, IsHandled);
        if IsHandled then
            exit;

        ItemJournalTemplate := QltyManagementSetup.GetInventoryAdjustmentJournalTemplate();
        if ItemJournalTemplate = '' then
            Error(NoAdjTemplateErr);

        ItemJournalBatch.CalcFields("Template Type");

        TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" := -1 * Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        QltyItemJournalManagement.CreateItemJournalLine(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry);
        ItemJournalLine.Description := CopyStr(StrSubstNo(DescriptionTxt, QltyInspectionHeader.GetFriendlyIdentifier()), 1, MaxStrLen(ItemJournalLine.Description));
        ItemJournalLine.Modify();
    end;

    /// <summary>
    /// Occurs before a negative item adjustment line is created and can replace the default creation.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to adjust.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The quantity and source filters for the adjustment.</param>
    /// <param name="AdjustmentBatchName">The item journal batch name.</param>
    /// <param name="ItemJournalLine">The item journal line being prepared.</param>
    /// <param name="ReservationEntry">The reservation entry used for item tracking.</param>
    /// <param name="IsHandled">Set to true to skip the default line creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNegativeItemAdjustmentLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var AdjustmentBatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before a negative warehouse adjustment line is created and can replace the default creation.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to adjust.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The quantity and source filters for the adjustment.</param>
    /// <param name="WarehouseNegativeAdjustmentBatch">The warehouse journal batch name.</param>
    /// <param name="WarehouseJournalLine">The warehouse journal line being prepared.</param>
    /// <param name="WhseItemTrackingLine">The warehouse item tracking line being prepared.</param>
    /// <param name="IsHandled">Set to true to skip the default line creation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNegativeWarehouseAdjustmentLine(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseNegativeAdjustmentBatch: Code[10]; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before the disposition has taken place, allowing the opportunity to extend or replace the functionality.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection being processed.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions.</param>
    /// <param name="Changed">Indicates whether an adjustment was created or posted.</param>
    /// <param name="IsHandled">Set to true to skip the default disposition processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var Changed: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after the disposition has taken place.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that was processed.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions.</param>
    /// <param name="Changed">Indicates whether an adjustment was created or posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var Changed: Boolean)
    begin
    end;
}
