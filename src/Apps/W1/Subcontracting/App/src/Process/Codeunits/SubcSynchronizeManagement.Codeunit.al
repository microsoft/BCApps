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
    procedure SynchronizeExpectedReceiptDate(var PurchaseLine: Record "Purchase Line"; xRecPurchaseLine: Record "Purchase Line")
    var
        ProductionOrder: Record "Production Order";
    begin
        if not IsSubcontractingLine(PurchaseLine) then
            exit;

        if PurchaseLine."Expected Receipt Date" = xRecPurchaseLine."Expected Receipt Date" then
            exit;
        if PurchaseLine."Qty. Received (Base)" <> 0 then
            exit;

        if ProductionOrder.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.") then begin
            if not ProductionOrder."Created from Purch. Order" then
                exit;
            if ProductionOrder."Due Date" <> PurchaseLine."Expected Receipt Date" then begin
                ProductionOrder.SetUpdateEndDate();
                ProductionOrder.Validate("Due Date", PurchaseLine."Expected Receipt Date");
                ProductionOrder.Modify();
            end;
        end;
    end;

    procedure SynchronizeQuantity(var PurchaseLine: Record "Purchase Line"; xRecPurchaseLine: Record "Purchase Line")
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        PurchLineBaseQuantity: Decimal;
    begin
        if not IsSubcontractingLine(PurchaseLine) then
            exit;

        if (PurchaseLine.Quantity = xRecPurchaseLine.Quantity) and (PurchaseLine."Unit of Measure Code" = xRecPurchaseLine."Unit of Measure Code") then
            exit;

        if PurchaseLine."Qty. Received (Base)" <> 0 then
            exit;

        if ProductionOrder.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.") then begin
            if not ProductionOrder."Created from Purch. Order" then
                exit;

            ItemUnitofMeasure.Get(PurchaseLine."No.", PurchaseLine."Unit of Measure Code");
            PurchLineBaseQuantity :=
                UnitofMeasureManagement.CalcBaseQty(PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Unit of Measure Code", PurchaseLine.Quantity, ItemUnitofMeasure."Qty. per Unit of Measure", ItemUnitofMeasure."Qty. Rounding Precision", PurchaseLine.FieldCaption("Qty. Rounding Precision"), PurchaseLine.FieldCaption(Quantity), PurchaseLine.FieldCaption("Quantity (Base)"));

            if ProductionOrder.Quantity <> PurchLineBaseQuantity then begin
                ProductionOrder.Quantity := PurchLineBaseQuantity;
                ProductionOrder.Modify();
            end;

            if ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
                if ProdOrderLine.Quantity <> PurchLineBaseQuantity then begin
                    ProdOrderLine.Validate(Quantity, PurchLineBaseQuantity);
                    ProdOrderLine.Modify();
                    ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
                    ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
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

    procedure DeleteEnhancedDocumentsByChangeOfVendorNo(var PurchaseHeader: Record "Purchase Header"; var xPurchaseHeader: Record "Purchase Header")
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry, ItemLedgerEntry2 : Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchaseLine, PurchaseLine2, PurchaseLineModify : Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchaseLine.SetRange("Qty. Received (Base)", 0);

        PurchaseLine2.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine2.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine2.SetFilter("No.", '<>%1', '');
        PurchaseLine2.SetRange("Prod. Order No.", '');
        PurchaseLine2.SetRange("Qty. Received (Base)", 0);

        if not PurchaseLine.IsEmpty() then begin
            PurchaseLine.FindSet();
            repeat
                if ProductionOrder.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.") then
                    if ProductionOrder."Created from Purch. Order" then begin
                        ItemLedgerEntry.SetRange("Order Type", "Inventory Order Type"::Production);
                        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
                        if ItemLedgerEntry.IsEmpty() then begin
                            CapacityLedgerEntry.SetRange("Order Type", "Inventory Order Type"::Production);
                            CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
                            if CapacityLedgerEntry.IsEmpty() then begin
                                ProductionOrder.DeleteProdOrderRelations();

                                // Delete References to Production Order to delete
                                PurchaseLineModify.SetRange("Document Type", PurchaseHeader."Document Type");
                                PurchaseLineModify.SetRange("Document No.", PurchaseHeader."No.");
                                PurchaseLineModify.SetRange(Type, "Purchase Line Type"::Item);
                                PurchaseLineModify.SetFilter("No.", '<>%1', '');
                                PurchaseLineModify.SetRange("Prod. Order No.", ProductionOrder."No.");
                                if not PurchaseLineModify.IsEmpty() then begin
                                    PurchaseLineModify.ModifyAll("Prod. Order Line No.", 0);
                                    PurchaseLineModify.ModifyAll("Operation No.", '');
                                    PurchaseLineModify.ModifyAll("Routing No.", '');
                                    PurchaseLineModify.ModifyAll("Routing Reference No.", 0);
                                    PurchaseLineModify.ModifyAll("Prod. Order No.", '');
                                end;

                                // Delete Subcontracting dependent Purchase Lines
                                PurchaseLine2.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
                                if not PurchaseLine2.IsEmpty() then
                                    PurchaseLine2.DeleteAll(true);

                                TransferHeader.SetCurrentKey("Source ID", "Source Type", "Source Subtype");
                                TransferHeader.SetRange("Source ID", PurchaseHeader."Buy-from Vendor No.");
                                TransferHeader.SetRange("Source Type", "Transfer Source Type"::Subcontracting);
                                TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
                                TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
                                if not TransferHeader.IsEmpty() then begin
                                    TransferHeader.FindFirst();
                                    ItemLedgerEntry2.SetRange("Order Type", "Inventory Order Type"::Production);
                                    ItemLedgerEntry2.SetRange("Order No.", ProductionOrder."No.");
                                    if ItemLedgerEntry.IsEmpty() then
                                        TransferHeader.Delete(true);
                                end;
                                ProductionOrder.Delete();
                            end;
                        end;
                    end;
            until PurchaseLine.Next() = 0;
        end;
    end;

    procedure DeleteEnhancedDocumentsByDeletePurchLine(var PurchaseLine: Record "Purchase Line")
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry, ItemLedgerEntry2 : Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchaseLine2: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
    begin
        if not IsSubcontractingLine(PurchaseLine) then
            exit;

        if PurchaseLine."Qty. Received (Base)" <> 0 then
            exit;

        if ProductionOrder.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.") then begin
            if not ProductionOrder."Created from Purch. Order" then
                exit;
            ItemLedgerEntry.SetRange("Order Type", "Inventory Order Type"::Production);
            ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
            if ItemLedgerEntry.IsEmpty() then begin
                CapacityLedgerEntry.SetRange("Order Type", "Inventory Order Type"::Production);
                CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
                if CapacityLedgerEntry.IsEmpty() then begin
                    ProductionOrder.DeleteProdOrderRelations();

                    // Delete Subcontracting dependent Purchase Lines
                    PurchaseLine2.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
                    if PurchaseLine2.FindSet() then
                        PurchaseLine2.DeleteAll(true);

                    TransferHeader.SetCurrentKey("Source ID", "Source Type", "Source Subtype");
                    TransferHeader.SetRange("Source ID", PurchaseLine."Buy-from Vendor No.");
                    TransferHeader.SetRange("Source Type", "Transfer Source Type"::Subcontracting);
                    TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
                    TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
                    if not TransferHeader.IsEmpty() then begin
                        TransferHeader.FindFirst();
                        ItemLedgerEntry2.SetRange("Order Type", "Inventory Order Type"::Production);
                        ItemLedgerEntry2.SetRange("Order No.", ProductionOrder."No.");
                        if ItemLedgerEntry.IsEmpty() then
                            TransferHeader.Delete(true);
                    end;
                    ProductionOrder.Delete();
                end
            end;
        end;
    end;

    local procedure IsSubcontractingLine(var PurchaseLine: Record "Purchase Line") IsSubcontracting: Boolean
    begin
        if PurchaseLine.Type <> "Purchase Line Type"::Item then
            exit(IsSubcontracting);

        if PurchaseLine."No." = '' then
            exit(IsSubcontracting);

        if PurchaseLine."Prod. Order No." = '' then
            exit(IsSubcontracting);

        IsSubcontracting := true;
        exit(IsSubcontracting);
    end;
}