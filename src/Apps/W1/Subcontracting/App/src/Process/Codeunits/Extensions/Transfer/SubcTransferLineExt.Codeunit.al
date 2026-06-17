// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;

codeunit 99001544 "Subc. Transfer Line Ext."
{
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432

#endif
    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterGetTransHeader, '', false, false)]
    local procedure OnAfterGetTransHeader(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        TransferLine."Subc. Return Order" := TransferHeader."Subc. Return Order";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    var
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        SubcTransferManagement.UpdateLocationCodeInProdOrderCompAfterDeleteTransferLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeValidateEvent, "Item No.", false, false)]
    local procedure OnBeforeValidateItemNo(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; CurrFieldNo: Integer)
    var
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary() then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Item No.") then
            exit;

        if Rec."Item No." = xRec."Item No." then
            exit;

        SubcTransferManagement.CheckSubcTransferLineCanBeModified(Rec, Rec.FieldCaption("Item No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeValidateEvent, "Variant Code", false, false)]
    local procedure OnBeforeValidateVariantCode(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; CurrFieldNo: Integer)
    var
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary() then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Variant Code") then
            exit;

        if Rec."Variant Code" = xRec."Variant Code" then
            exit;

        SubcTransferManagement.CheckSubcTransferLineCanBeModified(Rec, Rec.FieldCaption("Variant Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnBeforeValidateEvent, Quantity, false, false)]
    local procedure OnBeforeValidateQuantity(var Rec: Record "Transfer Line"; var xRec: Record "Transfer Line"; CurrFieldNo: Integer)
    var
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if Rec.IsTemporary() then
            exit;

        if CurrFieldNo <> Rec.FieldNo(Quantity) then
            exit;

        if Rec.Quantity = xRec.Quantity then
            exit;

        SubcTransferManagement.CheckSubcTransferLineCanBeModified(Rec, Rec.FieldCaption(Quantity));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnValidateItemNoOnCopyFromTempTransLine, '', false, false)]
    local procedure OnValidateItemNoOnCopyFromTempTransLine_TransferLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        CopySubFieldsFromTempTransferLineToTransferLine(TransferLine, TempTransferLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnValidateUnitofMeasureCodeOnBeforeValidateQuantity, '', false, false)]
    local procedure OnValidateUnitofMeasureCodeOnBeforeValidateQuantity(var TransferLine: Record "Transfer Line"; Item: Record Item; xTransferLine: Record "Transfer Line")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if TransferLine."Transfer WIP Item" then
            TransferLine."Qty. per Unit of Measure" := 0;
    end;

    local procedure CopySubFieldsFromTempTransferLineToTransferLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line")
    begin
        TransferLine."Subc. Purch. Order No." := TempTransferLine."Subc. Purch. Order No.";
        TransferLine."Subc. Purch. Order Line No." := TempTransferLine."Subc. Purch. Order Line No.";
        TransferLine."Subc. Prod. Order No." := TempTransferLine."Subc. Prod. Order No.";
        TransferLine."Subc. Prod. Order Line No." := TempTransferLine."Subc. Prod. Order Line No.";
        TransferLine."Subc. Prod. Ord. Comp Line No." := TempTransferLine."Subc. Prod. Ord. Comp Line No.";
        TransferLine."Subc. Routing No." := TempTransferLine."Subc. Routing No.";
        TransferLine."Subc. Routing Reference No." := TempTransferLine."Subc. Routing Reference No.";
        TransferLine."Subc. Work Center No." := TempTransferLine."Subc. Work Center No.";
        TransferLine."Subc. Operation No." := TempTransferLine."Subc. Operation No.";
        TransferLine."Subc. Return Order" := TempTransferLine."Subc. Return Order";
    end;
}