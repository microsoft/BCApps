// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Utilities;
using System.Reflection;

codeunit 99001559 "Subc. ProdO. Factbox Mgmt."
{
#if not CLEAN29
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432

#endif
    /// <summary>
    /// Opens the appropriate Production Order page (Released or Finished) for the production order linked to the given variant record.
    /// </summary>
    /// <param name="RecRelatedVariant">A record variant of a purchase or transfer document line.</param>
    procedure ShowProductionOrder(RecRelatedVariant: Variant)
    var
        ProductionOrder: Record "Production Order";
        FinishedProductionOrder: Page "Finished Production Order";
        ReleasedProductionOrder: Page "Released Production Order";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        ProductionOrder.SetFilter(Status, '>=%1', ProductionOrder.Status::Released);
        ProductionOrder.SetRange("No.", ProdOrderNo);
        if not ProductionOrder.FindFirst() then
            exit;
        case ProductionOrder.Status of
            ProductionOrder.Status::Released:
                begin
                    ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
                    ReleasedProductionOrder.SetTableView(ProductionOrder);
                    ReleasedProductionOrder.Editable := false;
                    ReleasedProductionOrder.Run();
                end;
            ProductionOrder.Status::Finished:
                begin
                    ProductionOrder.SetRange(Status, ProductionOrder.Status::Finished);
                    FinishedProductionOrder.SetTableView(ProductionOrder);
                    FinishedProductionOrder.Editable := false;
                    FinishedProductionOrder.Run();
                end;
        end;
    end;

    /// <summary>
    /// Opens the Production Order Routing page for the routing line linked to the given variant record.
    /// </summary>
    /// <param name="RecRelatedVariant">A record variant of a purchase or transfer document line.</param>
    procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRouting: Page "Prod. Order Routing";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        SetFilterProductionOrderRouting(ProdOrderRoutingLine, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo);
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRouting.SetTableView(ProdOrderRoutingLine);
        ProdOrderRouting.Editable := false;
        ProdOrderRouting.Run();
    end;

    /// <summary>
    /// Returns the number of production order routing lines linked to the given variant record.
    /// </summary>
    /// <param name="RecRelatedVariant">A record variant of a purchase or transfer document line.</param>
    /// <returns>The count of matching production order routing lines, or 0 if no production order is found.</returns>
    procedure CalcNoOfProductionOrderRoutings(RecRelatedVariant: Variant): Integer
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(0);

#endif
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        SetFilterProductionOrderRouting(ProdOrderRoutingLine, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo);
        exit(ProdOrderRoutingLine.Count());
    end;

    local procedure SetFilterProductionOrderRouting(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; RoutingNo: Code[20]; OperationNo: Code[10])
    begin
        ProdOrderRoutingLine.SetFilter(Status, '>=%1', ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
    end;

    /// <summary>
    /// Opens the Production Order Components page filtered to the production order linked to the given variant record.
    /// </summary>
    /// <param name="RecRelatedVariant">A record variant of a purchase or transfer document line.</param>
    procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        PageManagement: Codeunit "Page Management";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        SetFilterProductionOrderComponents(ProdOrderComponent, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo);
        PageManagement.PageRun(ProdOrderComponent);
    end;

    /// <summary>
    /// Returns the number of production order components linked to the given variant record.
    /// </summary>
    /// <param name="RecRelatedVariant">A record variant of a purchase or transfer document line.</param>
    /// <returns>The count of matching production order components, or 0 if no production order is found.</returns>
    procedure CalcNoOfProductionOrderComponents(RecRelatedVariant: Variant): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(0);

#endif
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit(0);

        SetFilterProductionOrderComponents(ProdOrderComponent, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo);
        exit(ProdOrderComponent.Count());
    end;

    local procedure SetFilterProductionOrderComponents(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; RoutingNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetLoadFields("Routing Link Code");
        ProdOrderRoutingLine.SetFilter(Status, '>=%1', ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        if ProdOrderRoutingLine.FindFirst() then
            ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");

        ProdOrderComponent.SetFilter(Status, '>=%1', ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLineNo);
    end;

    local procedure SetProdOrderInformationByVariant(RecRelatedVariant: Variant; var ProdOrderNo: Code[20]; var ProdOrderLineNo: Integer; var RoutingNo: Code[20]; var OperationNo: Code[10]): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TransferLine: Record "Transfer Line";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        DataTypeManagement: Codeunit "Data Type Management";
        ResultRecordRef: RecordRef;
        RecId: RecordId;
    begin
        if not RecRelatedVariant.IsRecord() then
            exit(false);

        DataTypeManagement.GetRecordRef(RecRelatedVariant, ResultRecordRef);

        RecId := ResultRecordRef.RecordId();

        if RecId.TableNo() = 0 then
            exit(false);

        case RecId.TableNo() of
            Database::"Purchase Line":
                begin
                    ResultRecordRef.SetTable(PurchaseLine);
                    ProdOrderNo := PurchaseLine."Prod. Order No.";
                    ProdOrderLineNo := PurchaseLine."Prod. Order Line No.";
                    RoutingNo := PurchaseLine."Routing No.";
                    OperationNo := PurchaseLine."Operation No.";
                end;
            Database::"Purch. Rcpt. Line":
                begin
                    ResultRecordRef.SetTable(PurchRcptLine);
                    ProdOrderNo := PurchRcptLine."Prod. Order No.";
                    ProdOrderLineNo := PurchRcptLine."Prod. Order Line No.";
                    RoutingNo := PurchRcptLine."Routing No.";
                    OperationNo := PurchRcptLine."Operation No.";
                end;
            Database::"Purch. Inv. Line":
                begin
                    ResultRecordRef.SetTable(PurchInvLine);
                    ProdOrderNo := PurchInvLine."Prod. Order No.";
                    ProdOrderLineNo := PurchInvLine."Prod. Order Line No.";
                    RoutingNo := PurchInvLine."Routing No.";
                    OperationNo := PurchInvLine."Operation No.";
                end;
            Database::"Transfer Line":
                begin
                    ResultRecordRef.SetTable(TransferLine);
                    ProdOrderNo := TransferLine."Subc. Prod. Order No.";
                    ProdOrderLineNo := TransferLine."Subc. Prod. Order Line No.";
                    RoutingNo := TransferLine."Subc. Routing No.";
                    OperationNo := TransferLine."Subc. Operation No.";
                end;
            Database::"Transfer Shipment Line":
                begin
                    ResultRecordRef.SetTable(TransferShipmentLine);
                    ProdOrderNo := TransferShipmentLine."Subc. Prod. Order No.";
                    ProdOrderLineNo := TransferShipmentLine."Subc. Prod. Order Line No.";
                    RoutingNo := TransferShipmentLine."Subc. Routing No.";
                    OperationNo := TransferShipmentLine."Subc. Operation No.";
                end;
            Database::"Transfer Receipt Line":
                begin
                    ResultRecordRef.SetTable(TransferReceiptLine);
                    ProdOrderNo := TransferReceiptLine."Subc. Prod. Order No.";
                    ProdOrderLineNo := TransferReceiptLine."Subc. Prod. Order Line No.";
                    RoutingNo := TransferReceiptLine."Subc. Routing No.";
                    OperationNo := TransferReceiptLine."Subc. Operation No.";
                end;
            Database::"Item Ledger Entry":
                begin
                    ResultRecordRef.SetTable(ItemLedgerEntry);
                    ProdOrderNo := ItemLedgerEntry."Order No.";
                    ProdOrderLineNo := ItemLedgerEntry."Order Line No.";
                    OperationNo := ItemLedgerEntry."Subc. Operation No.";
                    RoutingNo := GetRoutingNoFromProdOrderRoutingLine(ProdOrderNo, ProdOrderLineNo, OperationNo);
                end;
        end;
        exit((ProdOrderNo <> '') and (ProdOrderLineNo <> 0));
    end;

    local procedure GetRoutingNoFromProdOrderRoutingLine(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; OperationNo: Code[10]): Code[20]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        if ProdOrderRoutingLine.FindFirst() then
            exit(ProdOrderRoutingLine."Routing No.");
    end;
}
