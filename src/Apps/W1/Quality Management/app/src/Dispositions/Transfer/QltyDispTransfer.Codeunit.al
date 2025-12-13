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
    /// Creates a Transfer Order from a Quality Inspection Test
    /// </summary>
    /// <param name="QltyInspectionTestHeader">Quality Inspection Test</param>
    /// <param name="OptionalSpecificQuantity">Optional specified quantity, updated based on chosen Move Behavior</param>
    /// <param name="QltyQuantityBehavior">Transfer a specific quantity, tracked quantity, sample size, or sample pass/fail quantity</param>
    /// <param name="OptionalSourceLocationFilter">Optional additional location filter for item on test</param>
    /// <param name="OptionalSourceBinFilter">Optional additional bin filter for item on test</param>   
    /// <param name="DestinationLocationCode">Destination location for the transfer</param>
    /// <param name="OptionalInTransitLocationCode">The in-transit location to use</param>    
    /// <returns>Returns true if a transfer line was created</returns>
    internal procedure PerformDisposition(QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; OptionalSpecificQuantity: Decimal; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior"; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; DestinationLocationCode: Code[10]; OptionalInTransitLocationCode: Code[10]) DidSomething: Boolean
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
        exit(PerformDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer));
    end;

    /// <summary>
    /// Creates a Transfer Order from a Quality Inspection Test
    /// </summary>
    /// <param name="QltyInspectionTestHeader"></param>
    /// <param name="TempInstructionQltyDispositionBuffer"></param>
    /// <returns></returns>
    procedure PerformDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        TransferHeader: Record "Transfer Header";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        Handled: Boolean;
        IsDirectTransfer: Boolean;
    begin
        OnBeforeProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething, Handled);
        if Handled then
            exit;

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            Clear(TransferHeader);
            Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());
            if TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" = '' then
                if TransferRoute.Get(Location.Code, TempQuantityToActQltyDispositionBuffer."New Location Code") then
                    TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" := TransferRoute."In-Transit Code";

            IsDirectTransfer := (TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" = '');

            CreateTransferHeader(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, IsDirectTransfer, TransferHeader);

            DidSomething := DidSomething or
                CreateTransferLineWithOutboundTracking(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, TransferHeader);

            if DidSomething then
                QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl, TransferHeader."No.", TransferHeader);
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        OnAfterProcessDisposition(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DidSomething);

        if not DidSomething then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionTestHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
    end;

    local procedure CreateTransferHeader(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; DirectTransfer: Boolean; var TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.SetHideValidationDialog(true);
        TransferHeader.Validate("Transfer-from Code", TempQuantityToActQltyDispositionBuffer.GetFromLocationCode());
        TransferHeader.Validate("Transfer-to Code", TempQuantityToActQltyDispositionBuffer."New Location Code");
        if TempQuantityToActQltyDispositionBuffer."In-Transit Location Code" <> '' then
            TransferHeader.Validate("In-Transit Code", TempQuantityToActQltyDispositionBuffer."In-Transit Location Code");

        TransferHeader."Qlty. Inspection Test No." := QltyInspectionTestHeader."No.";
        TransferHeader."Qlty. Inspection Retest No." := QltyInspectionTestHeader."Retest No.";
        TransferHeader.Insert(true);
        TransferHeader.Validate("Direct Transfer", DirectTransfer);
    end;

    local procedure CreateTransferLineWithOutboundTracking(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferHeader: Record "Transfer Header") Created: Boolean
    var
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
    begin
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine.Validate("Item No.", QltyInspectionTestHeader."Source Item No.");
        if QltyInspectionTestHeader."Source Variant Code" <> '' then
            TransferLine.Validate("Variant Code", QltyInspectionTestHeader."Source Variant Code");
        if TempQuantityToActQltyDispositionBuffer."Bin Filter" <> '' then
            if Location.Get(TempQuantityToActQltyDispositionBuffer.GetFromLocationCode()) then
                if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                    TransferLine.Validate("Transfer-from Bin Code", TempQuantityToActQltyDispositionBuffer.GetFromBinCode());

        TransferLine.Validate(Quantity, TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        TransferLine.Validate("Qty. to Ship", TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");
        TransferLine.Insert(false);
        if QltyInspectionTestHeader.IsItemTrackingUsed() then
            QltyItemTrackingMgmt.CreateOutboundTransferLineReservationEntries(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, TransferLine);

        Created := true;
        OnAfterCreateTransferLineWithOutboundTracking(QltyInspectionTestHeader, TempQuantityToActQltyDispositionBuffer, TransferHeader, TransferLine, Created);
    end;

    /// <summary>
    /// Provides an opportunity to modify the create Purchase Return Order behavior or replace it completely.
    /// </summary>
    /// <param name="QltyInspectionTestHeader">Quality Inspection Test</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="prbDidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbDidSomething: Boolean; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the create Purchase Return Order behavior or replace it completely.
    /// </summary>
    /// <param name="QltyInspectionTestHeader">Quality Inspection Test</param>
    /// <param name="TempInstructionQltyDispositionBuffer">The instruction</param>
    /// <param name="prbDidSomething">Provides an opportunity to replace the default boolean success/fail of if it worked.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDisposition(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var prbDidSomething: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the created transfer header and transfer line after the line and optional outbound shipment tracking has been inserted.
    /// </summary>
    /// <param name="QltyInspectionTestHeader">Quality Inspection Test</param>
    /// <param name="TransferHeader">Created Transfer Header</param>
    /// <param name="TransferLine">Created Transfer Line</param>
    /// <param name="Created">Indicator that a transfer was created</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTransferLineWithOutboundTracking(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary; var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var Created: Boolean)
    begin
    end;
}
