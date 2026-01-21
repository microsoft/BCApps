// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

codeunit 99001511 "Subc. Synchronize Management"
{
    procedure SynchronizeExpectedReceiptDate(var PurchLine: Record "Purchase Line"; xRecPurchLine: Record "Purchase Line")
    var
        ProdOrder: Record "Production Order";
    begin
        if not IsSubcontractingLine(PurchLine) then
            exit;

        if PurchLine."Expected Receipt Date" = xRecPurchLine."Expected Receipt Date" then
            exit;
        if PurchLine."Qty. Received (Base)" <> 0 then
            exit;

        if ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.") then begin
            if not ProdOrder."Created from Purch. Order" then
                exit;
            if ProdOrder."Due Date" <> PurchLine."Expected Receipt Date" then begin
                ProdOrder.SetUpdateEndDate();
                ProdOrder.Validate("Due Date", PurchLine."Expected Receipt Date");
                ProdOrder.Modify();
            end;
        end;
    end;

    procedure SynchronizeQuantity(var PurchLine: Record "Purchase Line"; xRecPurchLine: Record "Purchase Line")
    var
        ItemUoM: Record "Item Unit of Measure";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrder: Record "Production Order";
        UOMMgt: Codeunit "Unit of Measure Management";
        PurchLineBaseQuantity: Decimal;
    begin
        if not IsSubcontractingLine(PurchLine) then
            exit;

        if (PurchLine.Quantity = xRecPurchLine.Quantity) and (PurchLine."Unit of Measure Code" = xRecPurchLine."Unit of Measure Code") then
            exit;

        if PurchLine."Qty. Received (Base)" <> 0 then
            exit;

        if ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.") then begin
            if not ProdOrder."Created from Purch. Order" then
                exit;

            ItemUoM.Get(PurchLine."No.", PurchLine."Unit of Measure Code");
            PurchLineBaseQuantity :=
                UOMMgt.CalcBaseQty(PurchLine."No.", PurchLine."Variant Code", PurchLine."Unit of Measure Code", PurchLine.Quantity, ItemUoM."Qty. per Unit of Measure", ItemUoM."Qty. Rounding Precision", PurchLine.FieldCaption("Qty. Rounding Precision"), PurchLine.FieldCaption(Quantity), PurchLine.FieldCaption("Quantity (Base)"));

            if ProdOrder.Quantity <> PurchLineBaseQuantity then begin
                ProdOrder.Quantity := PurchLineBaseQuantity;
                ProdOrder.Modify();
            end;

            if ProdOrderLine.Get("Production Order Status"::Released, PurchLine."Prod. Order No.", PurchLine."Prod. Order Line No.") then
                if ProdOrderLine.Quantity <> PurchLineBaseQuantity then begin
                    ProdOrderLine.Validate(Quantity, PurchLineBaseQuantity);
                    ProdOrderLine.Modify();
                    ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
                    ProdOrderComponent.SetRange("Prod. Order No.", PurchLine."Prod. Order No.");
                    ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                    if not ProdOrderComponent.IsEmpty() then begin
                        ProdOrderComponent.FindSet();
                        repeat
                            ProdOrderComponent.Validate("Quantity per");
                            ProdOrderComponent.Modify();
                        until ProdOrderComponent.Next() = 0;
                    end;
                end;
        end;
    end;

    procedure DeleteEnhancedDocumentsByChangeOfVendorNo(var PurchHeader: Record "Purchase Header"; var xPurchHeader: Record "Purchase Header")
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        ItemLedgEntry, ItemLedgEntry2 : Record "Item Ledger Entry";
        ProdOrder: Record "Production Order";
        PurchLine, PurchLine2, PurchLineModify : Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchLine.SetFilter("No.", '<>%1', '');
        PurchLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchLine.SetRange("Qty. Received (Base)", 0);

        PurchLine2.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine2.SetRange("Document No.", PurchHeader."No.");
        PurchLine2.SetRange(Type, "Purchase Line Type"::Item);
        PurchLine2.SetFilter("No.", '<>%1', '');
        PurchLine2.SetRange("Prod. Order No.", '');
        PurchLine2.SetRange("Qty. Received (Base)", 0);

        if not PurchLine.IsEmpty() then begin
            PurchLine.FindSet();
            repeat
                if ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.") then
                    if ProdOrder."Created from Purch. Order" then begin
                        ItemLedgEntry.SetRange("Order Type", "Inventory Order Type"::Production);
                        ItemLedgEntry.SetRange("Order No.", ProdOrder."No.");
                        if ItemLedgEntry.IsEmpty() then begin
                            CapLedgEntry.SetRange("Order Type", "Inventory Order Type"::Production);
                            CapLedgEntry.SetRange("Order No.", ProdOrder."No.");
                            if CapLedgEntry.IsEmpty() then begin
                                ProdOrder.DeleteProdOrderRelations();

                                // Delete References to Production Order to delete
                                PurchLineModify.SetRange("Document Type", PurchHeader."Document Type");
                                PurchLineModify.SetRange("Document No.", PurchHeader."No.");
                                PurchLineModify.SetRange(Type, "Purchase Line Type"::Item);
                                PurchLineModify.SetFilter("No.", '<>%1', '');
                                PurchLineModify.SetRange("Prod. Order No.", ProdOrder."No.");
                                if not PurchLineModify.IsEmpty() then begin
                                    PurchLineModify.ModifyAll("Prod. Order Line No.", 0);
                                    PurchLineModify.ModifyAll("Operation No.", '');
                                    PurchLineModify.ModifyAll("Routing No.", '');
                                    PurchLineModify.ModifyAll("Routing Reference No.", 0);
                                    PurchLineModify.ModifyAll("Prod. Order No.", '');
                                end;

                                // Delete Subcontracting dependent Purchase Lines
                                PurchLine2.SetRange("Subc. Prod. Order No.", ProdOrder."No.");
                                if not PurchLine2.IsEmpty() then
                                    PurchLine2.DeleteAll(true);

                                TransferHeader.SetCurrentKey("Source ID", "Source Type", "Source Subtype");
                                TransferHeader.SetRange("Source ID", PurchHeader."Buy-from Vendor No.");
                                TransferHeader.SetRange("Source Type", "Transfer Source Type"::Subcontracting);
                                TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
                                TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchHeader."No.");
                                if not TransferHeader.IsEmpty() then begin
                                    TransferHeader.FindFirst();
                                    ItemLedgEntry2.SetRange("Order Type", "Inventory Order Type"::Production);
                                    ItemLedgEntry2.SetRange("Order No.", ProdOrder."No.");
                                    if ItemLedgEntry.IsEmpty() then
                                        TransferHeader.Delete(true);
                                end;
                                ProdOrder.Delete();
                            end;
                        end;
                    end;
            until PurchLine.Next() = 0;
        end;
    end;

    procedure DeleteEnhancedDocumentsByDeletePurchLine(var PurchLine: Record "Purchase Line")
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        ItemLedgEntry, ItemLedgEntry2 : Record "Item Ledger Entry";
        ProdOrder: Record "Production Order";
        PurchLine2: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
    begin
        if not IsSubcontractingLine(PurchLine) then
            exit;

        if PurchLine."Qty. Received (Base)" <> 0 then
            exit;

        if ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.") then begin
            if not ProdOrder."Created from Purch. Order" then
                exit;
            ItemLedgEntry.SetRange("Order Type", "Inventory Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", ProdOrder."No.");
            if ItemLedgEntry.IsEmpty() then begin
                CapLedgEntry.SetRange("Order Type", "Inventory Order Type"::Production);
                CapLedgEntry.SetRange("Order No.", ProdOrder."No.");
                if CapLedgEntry.IsEmpty() then begin
                    ProdOrder.DeleteProdOrderRelations();

                    // Delete Subcontracting dependent Purchase Lines
                    PurchLine2.SetRange("Subc. Prod. Order No.", ProdOrder."No.");
                    if PurchLine2.FindSet() then
                        PurchLine2.DeleteAll(true);

                    TransferHeader.SetCurrentKey("Source ID", "Source Type", "Source Subtype");
                    TransferHeader.SetRange("Source ID", PurchLine."Buy-from Vendor No.");
                    TransferHeader.SetRange("Source Type", "Transfer Source Type"::Subcontracting);
                    TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
                    TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchLine."Document No.");
                    if not TransferHeader.IsEmpty() then begin
                        TransferHeader.FindFirst();
                        ItemLedgEntry2.SetRange("Order Type", "Inventory Order Type"::Production);
                        ItemLedgEntry2.SetRange("Order No.", ProdOrder."No.");
                        if ItemLedgEntry.IsEmpty() then
                            TransferHeader.Delete(true);
                    end;
                    ProdOrder.Delete();
                end
            end;
        end;
    end;

    local procedure IsSubcontractingLine(var PurchLine: Record "Purchase Line") IsSubcontracting: Boolean
    begin
        if PurchLine.Type <> "Purchase Line Type"::Item then
            exit(IsSubcontracting);

        if PurchLine."No." = '' then
            exit(IsSubcontracting);

        if PurchLine."Prod. Order No." = '' then
            exit(IsSubcontracting);

        IsSubcontracting := true;
        exit(IsSubcontracting);
    end;
}