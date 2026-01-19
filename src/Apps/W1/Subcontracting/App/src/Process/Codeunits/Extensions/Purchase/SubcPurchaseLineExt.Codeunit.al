// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

codeunit 99001534 "Subc. Purchase Line Ext"
{
    var
        SynchMgmt: Codeunit "Subc. Synchronize Management";

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            if not Rec.IsTemporary() then
                SynchMgmt.DeleteEnhancedDocumentsByDeletePurchLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Expected Receipt Date", false, false)]
    local procedure OnAfterValidateExpectedReceiptDate(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        if CurrFieldNo <> 0 then
            SynchMgmt.SynchronizeExpectedReceiptDate(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, Quantity, false, false)]
    local procedure OnAfterValidateQuantity(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        if CurrFieldNo <> 0 then
            SynchMgmt.SynchronizeQuantity(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Unit of Measure Code", false, false)]
    local procedure OnAfterValidateUnitOfMeasureCode(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        if CurrFieldNo <> 0 then
            SynchMgmt.SynchronizeQuantity(Rec, xRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeUpdateDirectUnitCost, '', false, false)]
    local procedure OnBeforeUpdateDirectUnitCost(var PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; CalledByFieldNo: Integer; CurrFieldNo: Integer; var Handled: Boolean)
    begin
        if PurchLine."Prod. Order No." <> '' then begin
            Handled := true;
            PurchLine.UpdateAmounts();

            GetSubcontractingPrice(PurchLine);
            PurchLine.Validate("Line Discount %");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnValidateVariantCodeOnBeforeDropShipmentError, '', false, false)]
    local procedure OnValidateVariantCodeOnBeforeDropShipmentError(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    var
        ChangeVariantNoNotAllowedErr: Label 'You cannot change %1 because the order line is associated with production order %2.', Comment = '%1=Field Caption, %2=Production Order No.';
    begin
        if PurchaseLine."Prod. Order No." <> '' then
            Error(ChangeVariantNoNotAllowedErr, PurchaseLine.FieldCaption(PurchaseLine."Variant Code"), PurchaseLine."Prod. Order No.");
    end;

    local procedure GetSubcontractingPrice(var PurchLine: Record "Purchase Line")
    var
        SubcontractingPriceMgt: Codeunit "Subc. Price Management";
    begin
        if (PurchLine.Type = PurchLine.Type::Item) and (PurchLine."No." <> '') and (PurchLine."Prod. Order No." <> '') and (PurchLine."Operation No." <> '') then
            SubcontractingPriceMgt.GetSubcPriceForPurchLine(PurchLine);
    end;
}