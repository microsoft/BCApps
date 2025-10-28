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
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Tracking;

/// <summary>
/// The purpose of this reaction is to do inventory adjustments such as negative adjustments for the purposes of disposing inventory.
/// </summary>
codeunit 20446 "Qlty. Disp. Neg. Adjust Inv." implements "Qlty. Disposition"
{
    Description = 'Negative Adjust inventory.';

    var
        WarehouseJournalLineDescriptionTemplateLbl: Label 'Test [%1] negative adjusted quantity', Comment = '%1 = Quality Inspection Test';
        MissingBatchErr: Label 'There is missing setup on the Quality Management Setup Card defining the adjustment batch.';
        WriteOffEntireLotErr: Label 'Reducing inventory using the item tracked quantity for test %1 was requested, however the item associated with this test does not require tracking.', Comment = '%1=the test';
        CannotGetJournalBatchErr: Label 'Could not get journal batch %1,%2%3. Check the adjustment batch on the Quality Management Setup page.', Comment = '%1=template,%2=batch name,%3=location';
        LocationLbl: Label ' Location: %1', Comment = '%1=location';
        DocumentTypeLbl: Label 'Negative Adjustment';
        NoAdjTemplateErr: Label 'No Adjustment Journal Template found. Ensure a valid adjustment template exists.';
        DescriptionTxt: Label 'Test [%1] reduce inventory', Comment = '%1 = Quality Inspection Test';

    /// <summary>
    /// Creates a negative adjustment using the information from a given Quality Inspection Test.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="OptionalSpecificQuantity"></param>
    /// <param name="QltyQuantityBehavior"></param>
    /// <param name="OptionalSourceLocationFilter"></param>
    /// <param name="OptionalSourceBinFilter"></param>
    /// <param name="PostingBehavior"></param>
    /// <param name="Reason"></param>
    /// <returns></returns>
    internal procedure PerformDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; OptionalSpecificQuantity: Decimal; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; PostingBehavior: Enum "Qlty. Item Adj. Post Behavior"; Reason: Code[10]) DidSomething: Boolean
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
        exit(PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer));
    end;

    /// <summary>
    /// Creates a negative adjustment using the information from a given Quality Inspection Test.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <returns></returns>
    procedure PerformDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
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
        Handled: Boolean;
        CreatedLine: Boolean;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Dispose with Negative Inventory Adjustment";

        OnBeforeProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething, Handled);
        if Handled then
            exit;

        if (not QltyInspectionTestHeader.IsLotTracked()) and (not QltyInspectionTestHeader.IsSerialTracked() and (not QltyInspectionTestHeader.IsPackageTracked())) and
           (TempInstructionQltyDispositionBuffer."Quantity Behavior" = TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity")
        then
            Error(WriteOffEntireLotErr, QltyInspectionTestHeader.GetFriendlyIdentifier());

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        QltyManagementSetup.Get();

        if Handled then
            exit;

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            Clear(Location);
            if TempQuantityToActQltyDispositionBuffer."Location Filter" <> '' then
                Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());
            if Location."Directed Put-away and Pick" then begin
                if QltyManagementSetup."Whse. Adjustment Batch Name" = '' then
                    Error(MissingBatchErr);
                if not WhseJnlWarehouseJournalBatch.Get(QltyManagementSetup.GetWarehouseInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Whse. Adjustment Batch Name", Location.Code) then
                    Error(CannotGetJournalBatchErr, QltyManagementSetup.GetWarehouseInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Whse. Adjustment Batch Name", StrSubstNo(LocationLbl, Location.Code));

                Clear(WhseWarehouseJournalLine);
                CreateNegativeWarehouseAdjustmentLine(
                   QltyInspectionTestHeader,
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

                    QltyNotificationMgmt.NotifyNegativeAdjustmentOccurred(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Whse. Adjustment Batch Name");
                end;
            end else begin
                if QltyManagementSetup."Adjustment Batch Name" = '' then
                    Error(MissingBatchErr);
                NegativeAdjustItemJournalBatch.SetAutoCalcFields("Template Type");
                if not NegativeAdjustItemJournalBatch.Get(QltyManagementSetup.GetInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Adjustment Batch Name") then
                    Error(CannotGetJournalBatchErr, QltyManagementSetup.GetInventoryAdjustmentJournalTemplate(), QltyManagementSetup."Adjustment Batch Name", '');
                Clear(ItemJournalLine);
                CreateNegativeItemAdjustmentLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, NegativeAdjustItemJournalBatch, ItemJournalLine, ItemReservationEntry);
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

                    QltyNotificationMgmt.NotifyNegativeAdjustmentOccurred(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, QltyManagementSetup."Adjustment Batch Name");
                end;
            end;

        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if not DidSomething then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);

        OnAfterProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething);
    end;

    /// <summary>
    /// To create a negative adjustment make sure that pdQuantity is negative.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <returns></returns>
    local procedure CreateNegativeWarehouseAdjustmentLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; WarehouseNegativeAdjustmentBatch: Code[10]; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        WhseJnlWarehouseJournalBatch: Record "Warehouse Journal Batch";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        Handled: Boolean;
    begin
        Clear(WarehouseJournalLine);
        WarehouseJournalLine.Reset();
        OnBeforeCreateNegativeWarehouseAdjustmentLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WarehouseNegativeAdjustmentBatch, WarehouseJournalLine, WhseItemTrackingLine, Handled);
        if Handled then
            exit;

        QltyManagementSetup.Get();
        WhseJnlWarehouseJournalBatch.Get(QltyManagementSetup.GetWarehouseInventoryAdjustmentJournalTemplate(), WarehouseNegativeAdjustmentBatch, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());

        TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" := -1 *
            Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");

        QltyItemJournalManagement.CreateWarehouseJournalLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, WhseJnlWarehouseJournalBatch, WarehouseJournalLine, WhseItemTrackingLine);

        WarehouseJournalLine.Description := StrSubstNo(WarehouseJournalLineDescriptionTemplateLbl, QltyInspectionTestHeader.GetFriendlyIdentifier());
        WarehouseJournalLine.Modify();
    end;

    /// <summary>
    /// To do a negative adjustment, make sure to use a negative quantity here.
    /// </summary>
    local procedure CreateNegativeItemAdjustmentLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry")
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyItemJournalManagement: Codeunit "Qlty. Item Journal Management";
        ItemJournalTemplate: Code[10];
        Handled: Boolean;
    begin
        Clear(ItemJournalLine);

        OnBeforeCreateNegativeItemAdjustmentLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch.Name, ItemJournalLine, ReservationEntry, Handled);
        if Handled then
            exit;

        ItemJournalTemplate := QltyManagementSetup.GetInventoryAdjustmentJournalTemplate();
        if ItemJournalTemplate = '' then
            Error(NoAdjTemplateErr);

        ItemJournalBatch.CalcFields("Template Type");

        TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)" := -1 * Abs(TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        QltyItemJournalManagement.CreateItemJournalLine(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, ItemJournalBatch, ItemJournalLine, ReservationEntry);
        ItemJournalLine.Description := CopyStr(StrSubstNo(DescriptionTxt, QltyInspectionTestHeader.GetFriendlyIdentifier()), 1, MaxStrLen(ItemJournalLine.Description));
        ItemJournalLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNegativeItemAdjustmentLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var AdjustmentBatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNegativeWarehouseAdjustmentLine(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var WarehouseNegativeAdjustmentBatch: Code[10]; var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs before the disposition has taken place, allowing the opportunity to extend or replace the functionality.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="prbChanged"></param>
    /// <param name="Handled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbChanged: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after the disposition has taken place.
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <param name="prbChanged"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbChanged: Boolean)
    begin
    end;
}
