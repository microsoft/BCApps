// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions.Move;

using Microsoft.QualityManagement.Dispositions;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;

/// <summary>
/// Creates an internal movement. When the 'post' option is used, it will create a movement document from the internal movement.
/// </summary>
codeunit 20450 "Qlty. Disp. Internal Move" implements "Qlty. Disposition"
{
    var
        InternalMovementLineDescriptionTemplateLbl: Label 'Inspection [%3] changed bin from [%1] to [%2]', Comment = '%1 = From Bin Code; %2 = To Bin Code; %3 = the inspection';
        DocumentTypeInternalMovementLbl: Label 'Internal Movement';
        DocumentTypeWarehouseInventoryMovementLbl: Label 'Inventory Movement';

    internal procedure PerformDisposition(var QltyInspectionHeader: Record "Qlty. Inspection Header"; var TempInstructionQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary) DidSomething: Boolean
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        TempQuantityToActQltyDispositionBuffer: Record "Qlty. Disposition Buffer" temporary;
        CreatedWarehouseActivityHeader: Record "Warehouse Activity Header";
        QltyInventoryAvailability: Codeunit "Qlty. Inventory Availability";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        MovementLineCreated: Boolean;
    begin
        TempInstructionQltyDispositionBuffer."Disposition Action" := TempInstructionQltyDispositionBuffer."Disposition Action"::"Move with Internal Movement";
        QltyManagementSetup.Get();

        QltyInventoryAvailability.PopulateQuantityBuffer(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, TempQuantityToActQltyDispositionBuffer);

        if not TempQuantityToActQltyDispositionBuffer.FindSet() then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeInternalMovementLbl);

        repeat
            if InternalMovementHeader."No." = '' then
                CreateInternalMovementHeader(InternalMovementHeader, TempQuantityToActQltyDispositionBuffer.GetFromLocationCode(), TempQuantityToActQltyDispositionBuffer."New Bin Code");

            CreateInternalMovementLine(
                QltyInspectionHeader,
                InternalMovementHeader,
                InternalMovementLine,
                TempQuantityToActQltyDispositionBuffer.GetFromBinCode(),
                TempQuantityToActQltyDispositionBuffer."Qty. To Handle (Base)",
                MovementLineCreated);

            DidSomething := DidSomething or MovementLineCreated;

            if (MovementLineCreated and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::"Prepare only")) then
                QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeInternalMovementLbl, InternalMovementHeader."No.", InternalMovementHeader);
        until TempQuantityToActQltyDispositionBuffer.Next() = 0;

        if (DidSomething and (TempInstructionQltyDispositionBuffer."Entry Behavior" = TempInstructionQltyDispositionBuffer."Entry Behavior"::Post)) then
            CreateInventoryMovementFromInternalMovement(InternalMovementHeader, CreatedWarehouseActivityHeader);

        if CreatedWarehouseActivityHeader."No." <> '' then
            QltyNotificationMgmt.NotifyDocumentCreated(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeWarehouseInventoryMovementLbl, CreatedWarehouseActivityHeader."No.", CreatedWarehouseActivityHeader);

        if not DidSomething then
            QltyNotificationMgmt.NotifyDocumentCreationFailed(QltyInspectionHeader, TempInstructionQltyDispositionBuffer, DocumentTypeInternalMovementLbl);
    end;

    local procedure CreateInventoryMovementFromInternalMovement(InternalMovementHeader: Record "Internal Movement Header"; var CreatedWarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        TempDummyWhseWarehouseRequest: Record "Warehouse Request" temporary;
        InvtCreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
    begin
        InvtCreateInventoryPickMovement.SetWhseRequest(TempDummyWhseWarehouseRequest, true);
        InvtCreateInventoryPickMovement.CreateInvtMvntWithoutSource(InternalMovementHeader);

        InvtCreateInventoryPickMovement.GetWhseActivHeader(CreatedWarehouseActivityHeader);
    end;

    local procedure CreateInternalMovementHeader(var InternalMovementHeader: Record "Internal Movement Header"; FromLocationCode: Code[10]; ToBinCode: Code[20])
    begin
        Clear(InternalMovementHeader);
        InternalMovementHeader.Init();
        InternalMovementHeader.Validate("Location Code", FromLocationCode);
        InternalMovementHeader.Validate("To Bin Code", ToBinCode);
        InternalMovementHeader.Insert(true)
    end;

    local procedure CreateInternalMovementLine(QltyInspectionHeader: Record "Qlty. Inspection Header"; InternalMovementHeader: Record "Internal Movement Header"; var PrevInternalMovementLine: Record "Internal Movement Line"; FromBinCode: Code[20]; Quantity: Decimal; var MovementLineCreated: Boolean)
    var
        InternalMovementLine: Record "Internal Movement Line";
        TempWarehouseEntry: Record "Warehouse Entry" temporary;
        QltyItemTrackingMgmt: Codeunit "Qlty. Item Tracking Mgmt.";
        IsHandled: Boolean;
    begin
        InternalMovementLine.Validate("No.", InternalMovementHeader."No.");
        InternalMovementLine.SetUpNewLine(PrevInternalMovementLine);
        InternalMovementLine.Validate("From Bin Code", FromBinCode);
        InternalMovementLine.Validate("Item No.", QltyInspectionHeader."Source Item No.");
        InternalMovementLine.Validate(Quantity, Quantity);
        InternalMovementLine.Validate("Variant Code", QltyInspectionHeader."Source Variant Code");
        InternalMovementLine.Description := CopyStr(StrSubstNo(
            InternalMovementLineDescriptionTemplateLbl,
            FromBinCode,
            InternalMovementHeader."To Bin Code",
            QltyInspectionHeader.GetFriendlyIdentifier()), 1, MaxStrLen(InternalMovementLine.Description));
        InternalMovementLine.Insert();

        if QltyInspectionHeader.IsItemTrackingUsed() then begin
            TempWarehouseEntry."Item No." := QltyInspectionHeader."Source Item No.";
            TempWarehouseEntry."Variant Code" := QltyInspectionHeader."Source Variant Code";
            TempWarehouseEntry."Lot No." := QltyInspectionHeader."Source Lot No.";
            TempWarehouseEntry."Serial No." := QltyInspectionHeader."Source Serial No.";
            TempWarehouseEntry."Package No." := QltyInspectionHeader."Source Package No.";
            TempWarehouseEntry."Expiration Date" := QltyItemTrackingMgmt.GetExpirationDate(QltyInspectionHeader, InternalMovementHeader."Location Code");
            TempWarehouseEntry."Location Code" := InternalMovementHeader."Location Code";
            OnBeforeSetInternalMovementTrackingLines(QltyInspectionHeader, InternalMovementHeader, PrevInternalMovementLine, InternalMovementLine, FromBinCode, Quantity, TempWarehouseEntry, IsHandled);
            if not IsHandled then
                if (TempWarehouseEntry."Lot No." <> '') or (TempWarehouseEntry."Serial No." <> '') or (TempWarehouseEntry."Package No." <> '') then
                    InternalMovementLine.SetItemTrackingLines(TempWarehouseEntry, Quantity);
        end;
        PrevInternalMovementLine := InternalMovementLine;
        MovementLineCreated := true;
        OnAfterCreateInternalMovementLine(QltyInspectionHeader, InternalMovementHeader, PrevInternalMovementLine, FromBinCode, Quantity);
    end;

    /// <summary>
    /// Provides an opportunity to alter the internal movement tracking lines that were made with MoveInventory
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="InternalMovementHeader"></param>
    /// <param name="PrevInternalMovementLine"></param>
    /// <param name="InternalMovementLine"></param>
    /// <param name="FromBinCode"></param>
    /// <param name="Quantity"></param>
    /// <param name="TempWarehouseEntry"></param>
    /// <param name="IsHandled"></param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetInternalMovementTrackingLines(QltyInspectionHeader: Record "Qlty. Inspection Header"; InternalMovementHeader: Record "Internal Movement Header"; var PrevInternalMovementLine: Record "Internal Movement Line"; var InternalMovementLine: Record "Internal Movement Line"; FromBinCode: Code[20]; var Quantity: Decimal; var TempWarehouseEntry: Record "Warehouse Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Provides an opportunity to alter the internal movement line that was made with MoveInventory
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    /// <param name="InternalMovementHeader"></param>
    /// <param name="InternalMovementLine"></param>
    /// <param name="FromBinCode"></param>
    /// <param name="Quantity"></param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInternalMovementLine(QltyInspectionHeader: Record "Qlty. Inspection Header"; InternalMovementHeader: Record "Internal Movement Header"; var InternalMovementLine: Record "Internal Movement Line"; FromBinCode: Code[20]; var Quantity: Decimal)
    begin
    end;
}
