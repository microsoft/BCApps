// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Transfer;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// The purpose of this disposition is to create a transfer document 
/// </summary>
codeunit 20444 "Qlty. Disp. Transfer" implements "Qlty. Disposition"
{
    var

        DocumentTypeLbl: Label 'Transfer Order';

    /// <summary>
    /// Creates a transfer order from a quality inspection and explicit disposition options.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to transfer.</param>
    /// <param name="OptionalSpecificQuantity">The specific base quantity to transfer when required by the quantity behavior.</param>
    /// <param name="QltyQuantityBehavior">The rule used to determine the transfer quantity.</param>
    /// <param name="OptionalSourceLocationFilter">An optional source location filter.</param>
    /// <param name="OptionalSourceBinFilter">An optional source bin filter.</param>
    /// <param name="DestinationLocationCode">The destination location code.</param>
    /// <param name="OptionalInTransitLocationCode">The optional in-transit location code.</param>
    /// <returns>True if a transfer line was created; otherwise, false.</returns>
    internal procedure PerformDisposition(QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; DestinationLocationCode: Code[10]; OptionalInTransitLocationCode: Code[10]) DidSomething: Boolean
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Create Transfer Order";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := OptionalSpecificQuantity;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := QltyQuantityBehavior;
        TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(OptionalSourceLocationFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
        TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(OptionalSourceBinFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
        TempInstructionQltyDispositionBuffer."New Location Code" := DestinationLocationCode;
        TempInstructionQltyDispositionBuffer."In-Transit Location Code" := OptionalInTransitLocationCode;
        exit(PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    /// <summary>
    /// Creates transfer orders and outbound tracking for inspection inventory.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the inventory to transfer.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions containing source, destination, in-transit location, and quantity.</param>
    /// <returns>True if at least one transfer line was created; otherwise, false.</returns>
    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        TransferHeader: Record "Transfer Header";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        IsHandled: Boolean;
        IsDirectTransfer: Boolean;
    begin
        OnBeforeProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DidSomething, IsHandled);
        if IsHandled then
            exit;

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            Clear(TransferHeader);
            Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());
            if TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" = '' then
                if TransferRoute.Get(Location.Code, TempQuantityToActQltyDispositionBuffer."New Location Code") then
                    TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" := TransferRoute."In-Transit Code";

            IsDirectTransfer := (TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" = '');

            CreateTransferHeader(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, IsDirectTransfer, TransferHeader);

            DidSomething := DidSomething or
                CreateTransferLineWithOutboundTracking(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, TransferHeader);

            if DidSomething then
                QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl, TransferHeader."No.", TransferHeader);
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        OnAfterProcessDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DidSomething);

        if not DidSomething then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
    end;

    /// <summary>
    /// Creates a transfer header for the requested source and destination locations.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection linked to the transfer order.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The source, destination, and in-transit location values.</param>
    /// <param name="DirectTransfer">Specifies whether the transfer is direct.</param>
    /// <param name="TransferHeader">The created transfer header.</param>
    local procedure CreateTransferHeader(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; DirectTransfer: Boolean; var TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.SetHideValidationDialog(true);
        TransferHeader.Validate("Transfer-from Code", TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());
        TransferHeader.Validate("Transfer-to Code", TempQuantityToActQltyDispositionBuffer."New Location Code");
        if TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" <> '' then
            TransferHeader.Validate("In-Transit Code", TempQuantityToActQltyDispositionBuffer."In-Transit Location Code");

        TransferHeader."Qlty. Inspection No." := QltyInspectionHeader."No.";
        TransferHeader."Qlty. Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        TransferHeader.Insert(true);
        if DirectTransfer then
            TransferHeader.Validate("Direct Transfer", true);
    end;

    /// <summary>
    /// Creates a transfer line and outbound reservation entries for inspection item tracking.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the item, variant, and tracking values.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The source bin and quantity to transfer.</param>
    /// <param name="TransferHeader">The transfer header receiving the line.</param>
    /// <returns>True after the transfer line is created unless changed by an event subscriber.</returns>
    local procedure CreateTransferLineWithOutboundTracking(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferHeader: Record "Transfer Header") Created: Boolean
    var
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
    begin
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine.Validate("Item No.", QltyInspectionHeader."Source Item No.");
        if QltyInspectionHeader."Source Variant Code" <> '' then
            TransferLine.Validate("Variant Code", QltyInspectionHeader."Source Variant Code");

        Location.SetLoadFields("Bin Mandatory", "Directed Put-away and Pick");
        if TempQuantityToActQltyDispositionBuffer."Bin Filter" <> '' then
            if Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode()) then
                if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                    TransferLine.Validate("Transfer-from Bin Code", TempQuantityToActQltyDispositionBuffer.GetFromBinCode());
        if TempQuantityToActQltyDispositionBuffer."New Bin Code" <> '' then
            if Location.Get(TempQuantityToActQltyDispositionBuffer."New Location Code") then
                if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                    TransferLine.Validate("Transfer-To Bin Code", TempQuantityToActQltyDispositionBuffer."New Bin Code");

        TransferLine.Validate(Quantity, TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        TransferLine.Validate("Qty. to Ship", TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        TransferLine.Insert(false);
        if QltyInspectionHeader.IsItemTrackingUsed() then
            QltyItemTrackingMgmt.CreateOutboundTransferLineReservationEntries(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, TransferLine);

        Created := true;
        OnAfterCreateTransferLineWithOutboundTracking(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, TransferHeader, TransferLine, Created);
    end;

    /// <summary>
    /// Occurs before transfer order processing and can replace the default behavior.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection being processed.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions.</param>
    /// <param name="DidSomething">Indicates whether a transfer line was created.</param>
    /// <param name="IsHandled">Set to true to skip the default transfer processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var DidSomething: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Occurs after transfer order processing.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that was processed.</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The disposition instructions.</param>
    /// <param name="DidSomething">Indicates whether a transfer line was created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var DidSomething: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the created transfer header and transfer line after the line and optional outbound shipment tracking has been inserted.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection that identifies the transferred inventory.</param>
    /// <param name="TempQuantityToActQltyDispositionBuffer">The source, destination, and quantity used for the transfer line.</param>
    /// <param name="TransferHeader">The created transfer header.</param>
    /// <param name="TransferLine">The created transfer line.</param>
    /// <param name="Created">Indicates whether the transfer line should be treated as created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTransferLineWithOutboundTracking(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var Created: Boolean)
    begin
    end;
}
