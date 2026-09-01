// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.PutAway;

using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Ledger;

/// <summary>
/// This codeunit is responsible for the reaction of creating internal put-aways.
/// </summary>
codeunit 20447 "Qlty. Disp. Internal Put-away" implements "Qlty. Disposition"
{
    var
        TempCreatedBufferWhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header" temporary;
        ShouldSuppressNotification: Boolean;
        PutAwayEntireItemTrackingErr: Label 'Creating an Internal Put-away the entire item tracking for inspection %1 was requested, however the item associated with this inspection does not require item tracking.', Comment = '%1=the inspection';
        DocumentTypeLbl: Label 'Internal Put-Away';

    ///<summary>
    /// Create a warehouse internal put-away(s) from the supplied inspection.
    /// It's possible that multiple put-away's could be created if the item tracking is in multiple bins, but the typical scenario would be
    /// one internal put-away.
    /// You must be in a directed pick and put location, and you must be using item tracking warehouse tracking to use this feature.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection to create the internal put-away from</param>
    /// <param name="OptionalSpecificQuantity">Optional quantity. Leave blank to use the entire item tracking or the quantity from the inspection.</param>
    /// <param name="OptionalSourceLocationFilter">Optional limitations on the source location.</param>
    /// <param name="OptionalSourceBinFilter">Optional limitations on the source bin.</param>
    /// <param name="ReleaseImmediately">if true it will release the document, if false it will keep it open.</param>
    /// <param name="QltyQuantityBehavior">The quantity behavior</param>
    /// <returns>Confirming internal putaway lines created.</returns>
    internal procedure PerformDisposition(QltyInspectionHeader: Record "Qlty. Inspection Header"; OptionalSpecificQuantity: Decimal; OptionalSourceLocationFilter: Text; OptionalSourceBinFilter: Text; ReleaseImmediately: Boolean; QltyQuantityBehavior: Enum "Qlty. Quantity Behavior") DidSomething: Boolean
    var
        TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Create Internal Put-away";
        TempInstructionQltyDispositionBuffer."Qty. To Handle (Base)" := OptionalSpecificQuantity;
        TempInstructionQltyDispositionBuffer."Quantity Behavior" := QltyQuantityBehavior;
        TempInstructionQltyDispositionBuffer."Location Filter" := CopyStr(OptionalSourceLocationFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Location Filter"));
        TempInstructionQltyDispositionBuffer."Bin Filter" := CopyStr(OptionalSourceBinFilter, 1, MaxStrLen(TempInstructionQltyDispositionBuffer."Bin Filter"));
        if ReleaseImmediately then
            TempInstructionQltyDispositionBuffer."Entry Behavior" := TempInstructionQltyDispositionBuffer."Entry Behavior"::Post;
        exit(PerformDisposition(QltyInspectionHeader, TempInstructionQltyDispositionBuffer));
    end;

    procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseIntPutAwayRelease: Codeunit "Whse. Int. Put-away Release";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Create Internal Put-away";
        QltyManagementSetup.Get();
        if TempInstructionQltyDispositionBuffer."Quantity Behavior" = TempInstructionQltyDispositionBuffer."Quantity Behavior"::"Item Tracked Quantity" then
            if not QltyInspectionHeader.IsItemTrackingUsed() then
                Error(PutAwayEntireItemTrackingErr, QltyInspectionHeader.GetFriendlyIdentifier());

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then begin
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
            exit;
        end;

        repeat
            if (WhseInternalPutAwayHeader."Location Code" <> TempQuantityToActQltyDispositionBuffer."Location Filter") or (WhseInternalPutAwayHeader."From Bin Code" <> TempQuantityToActQltyDispositionBuffer."Bin Filter") then begin
                CreateInternalPutawayHeader(WhseInternalPutAwayHeader, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode(), TempQuantityToActQltyDispositionBuffer.GetFromBinCode());

                TempCreatedBufferWhseInternalPutAwayHeader := WhseInternalPutAwayHeader;
                TempCreatedBufferWhseInternalPutAwayHeader.Insert();

                if not ShouldSuppressNotification then
                    QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl, WhseInternalPutAwayHeader."No.", WhseInternalPutAwayHeader);
            end;

            CreateInternalPutawayLine(QltyInspectionHeader, WhseInternalPutAwayHeader, TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)");

            DidSomething := true;

        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if DidSomething and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post) then begin
            TempCreatedBufferWhseInternalPutAwayHeader.Reset();
            TempCreatedBufferWhseInternalPutAwayHeader.FindSet();
            repeat
                WhseInternalPutAwayHeader.Reset();
                WhseInternalPutAwayHeader.Get(TempCreatedBufferWhseInternalPutAwayHeader."No.");
                WhseInternalPutAwayHeader.SetHideValidationDialog(true);
                if WhseInternalPutAwayHeader.Status = WhseInternalPutAwayHeader.Status::Open then
                    WhseIntPutAwayRelease.Release(WhseInternalPutAwayHeader);
            until TempCreatedBufferWhseInternalPutAwayHeader.Next() = 0;
        end;

        if not DidSomething then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeLbl);
    end;

    local procedure CreateInternalPutawayHeader(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; FromLocationCode: Code[10]; FromBinCode: Code[20])
    begin
        Clear(WhseInternalPutAwayHeader);
        WhseInternalPutAwayHeader.Init();
        WhseInternalPutAwayHeader.Validate("Location Code", FromLocationCode);
        WhseInternalPutAwayHeader.Validate("From Bin Code", FromBinCode);
        WhseInternalPutAwayHeader.Insert(true);
    end;

    local procedure CreateInternalPutawayLine(QltyInspectionHeader: Record "Qlty. Inspection Header"; var InWhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; Quantity: Decimal)
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        TempWarehouseEntry: Record "Warehouse Entry" temporary;
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        NextLineNumber: Integer;
    begin
        WhseInternalPutAwayLine.SetRange("No.", InWhseInternalPutAwayHeader."No.");
        if WhseInternalPutAwayLine.FindLast() then;
        NextLineNumber := WhseInternalPutAwayLine."Line No." + 10000;
        WhseInternalPutAwayLine.Init();
        WhseInternalPutAwayLine.Validate("No.", InWhseInternalPutAwayHeader."No.");
        WhseInternalPutAwayLine."Line No." := NextLineNumber;
        WhseInternalPutAwayLine.Validate("Location Code", InWhseInternalPutAwayHeader."Location Code");
        WhseInternalPutAwayLine.Validate("From Zone Code", InWhseInternalPutAwayHeader."From Zone Code");
        WhseInternalPutAwayLine.Validate("From Bin Code", InWhseInternalPutAwayHeader."From Bin Code");
        WhseInternalPutAwayLine.Validate("Item No.", QltyInspectionHeader."Source Item No.");
        WhseInternalPutAwayLine.Validate("Variant Code", QltyInspectionHeader."Source Variant Code");
        WhseInternalPutAwayLine.Validate(Quantity, Quantity);
        WhseInternalPutAwayLine.Insert(true);
        TempWarehouseEntry."Item No." := QltyInspectionHeader."Source Item No.";
        TempWarehouseEntry."Variant Code" := QltyInspectionHeader."Source Variant Code";
        TempWarehouseEntry."Lot No." := QltyInspectionHeader."Source Lot No.";
        TempWarehouseEntry."Serial No." := QltyInspectionHeader."Source Serial No.";
        TempWarehouseEntry."Expiration Date" := QltyItemTrackingMgmt.GetExpirationDate(QltyInspectionHeader, InWhseInternalPutAwayHeader."Location Code");
        TempWarehouseEntry."Package No." := QltyInspectionHeader."Source Package No.";
        if (TempWarehouseEntry."Lot No." <> '') or (TempWarehouseEntry."Serial No." <> '') or (TempWarehouseEntry."Package No." <> '') then
            WhseInternalPutAwayLine.SetItemTrackingLines(TempWarehouseEntry, Quantity);

        WhseInternalPutAwayLine.Modify();
    end;

    /// <summary>
    /// Gets the created warehouse internal putaways that were created as buffer tables.
    /// </summary>
    /// <param name="TempCreatedBufferWhseInternalPutAwayHeader2"></param>
    internal procedure GetCreatedWarehouseInternalPutAwayHeaderBuffer(var TempCreatedBufferWhseInternalPutAwayHeader2: Record "Whse. Internal Put-away Header" temporary)
    begin
        TempCreatedBufferWhseInternalPutAwayHeader2.Copy(TempCreatedBufferWhseInternalPutAwayHeader, true);
    end;

    /// <summary>
    /// Set to true to suppress that a notification should be made.
    /// </summary>
    /// <param name="SuppressNotification"></param>
    internal procedure SetSuppressNotifications(SuppressNotification: Boolean)
    begin
        ShouldSuppressNotification := SuppressNotification;
    end;
}
