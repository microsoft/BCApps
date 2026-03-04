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
    /// Creates a Transfer Order from a Quality Inspection
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="OptionalSpecificQuantity">Optional specified quantity, updated based on chosen Move Behavior</param>
    /// <param name="QltyQuantityBehavior">Transfer a specific quantity, tracked quantity, sample size, or sample pass/fail quantity</param>
    /// <param name="OptionalSourceLocationFilter">Optional additional location filter for item on inspection</param>
    /// <param name="OptionalSourceBinFilter">Optional additional bin filter for item on inspection</param>   
    /// <param name="DestinationLocationCode">Destination location for the transfer</param>
    /// <param name="OptionalInTransitLocationCode">The in-transit location to use</param>    
    /// <returns>Returns true if a transfer line was created</returns>
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
    /// Creates a Transfer Order from a Quality Inspection
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <returns></returns>
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
        TransferHeader.Validate("Direct Transfer", DirectTransfer);
    end;

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
        if TempQuantityToActQltyDispositionBuffer."Bin Filter" <> '' then
            if Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode()) then
                if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                    TransferLine.Validate("Transfer-from Bin Code", TempQuantityToActQltyDispositionBuffer.GetFromBinCode());

        TransferLine.Validate(Quantity, TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        TransferLine.Validate("Qty. to Ship", TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        TransferLine.Insert(false);
        if QltyInspectionHeader.IsItemTrackingUsed() then
            QltyItemTrackingMgmt.CreateOutboundTransferLineReservationEntries(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, TransferLine);

        Created := true;
        OnAfterCreateTransferLineWithOutboundTracking(QltyInspectionHeader, TempQuantityToActQltyDispositionBuffer, TransferHeader, TransferLine, Created);
    end;

    /// <summary>
    /// Provides an opportunity to modify the create Purchase Return Order behavior or replace it completely.
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="DidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    /// <param name="IsHandled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var DidSomething: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the create Purchase Return Order behavior or replace it completely.
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="DidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var DidSomething: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the created transfer header and transfer line after the line and optional outbound shipment tracking has been inserted.
    /// </summary>
    /// <param name="QltyInspectionHeader">Quality Inspection</param>
    /// <param name="TransferHeader">Created Transfer Header</param>
    /// <param name="TransferLine">Created Transfer Line</param>
    /// <param name="Created">Indicator that a transfer was created</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTransferLineWithOutboundTracking(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var Created: Boolean)
    begin
    end;
}
