// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Reflection;

codeunit 99001507 "Subc. Factbox Mgmt."
{
    procedure ShowProductionOrder(RecRelatedVariant: Variant)
    var
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: Page "Released Production Order";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("No.", ProdOrderNo);
        ReleasedProductionOrder.SetTableView(ProductionOrder);
        ReleasedProductionOrder.Editable := false;
        ReleasedProductionOrder.Run();
    end;

    procedure ShowProductionOrderRouting(RecRelatedVariant: Variant)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRouting: Page "Prod. Order Routing";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRouting.SetTableView(ProdOrderRoutingLine);
        ProdOrderRouting.Editable := false;
        ProdOrderRouting.Run();
    end;

    procedure CalcNoOfProductionOrderRoutings(RecRelatedVariant: Variant): Integer
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo);
        exit(ProdOrderRoutingLine.Count());
    end;

    procedure ShowProductionOrderComponents(RecRelatedVariant: Variant)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PageManagement: Codeunit "Page Management";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        if ProdOrderRoutingLine.FindFirst() then
            ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");

        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLineNo);
        PageManagement.PageRun(ProdOrderComponent);
    end;

    procedure CalcNoOfProductionOrderComponents(RecRelatedVariant: Variant): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
        OperationNo: Code[10];
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
        ProdOrderLineNo: Integer;
    begin
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit(0);

        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLineNo);
        exit(ProdOrderComponent.Count());
    end;

    procedure ShowPurchaseOrder(RecRelatedVariant: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PageManagement: Codeunit "Page Management";
        PurchOrderNo: Code[20];
        PurchOrderLineNo: Integer;
    begin
        if not GetPurchaseOrderNoByVariant(RecRelatedVariant, PurchOrderNo, PurchOrderLineNo) then
            exit;
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchOrderNo);
        PageManagement.PageRun(PurchaseHeader);
    end;

    procedure CalcNoOfTransferOrders(RecRelatedVariant: Variant): Integer
    var
        TransferLine: Record "Transfer Line";
        PurchOrderNo: Code[20];
        PurchOrderLineNo: Integer;
    begin
        if not GetPurchaseOrderNoByVariant(RecRelatedVariant, PurchOrderNo, PurchOrderLineNo) then
            exit(0);

        TransferLine.SetCurrentKey("Subcontr. Purch. Order No.");
        TransferLine.SetRange("Subcontr. Purch. Order No.", PurchOrderNo);
        TransferLine.SetRange("Subcontr. PO Line No.", PurchOrderLineNo);
        exit(TransferLine.Count());
    end;

    procedure GetTransferOrderNo(RecRelatedVariant: Variant): Code[20]
    var
        TransferLine: Record "Transfer Line";
        PurchOrderNo: Code[20];
        NoOfTransferOrders: Integer;
        PurchOrderLineNo: Integer;
        MultipleLbl: Label 'Multiple', MaxLength = 20;
    begin
        if not GetPurchaseOrderNoByVariant(RecRelatedVariant, PurchOrderNo, PurchOrderLineNo) then
            exit('');

        NoOfTransferOrders := GetNoOfTransferOrders(RecRelatedVariant);
        case NoOfTransferOrders of
            0:
                exit('');
            1:
                begin
                    FilterTransferLineToSubcontractorPurchaseOrder(PurchOrderNo, PurchOrderLineNo, TransferLine);
                    TransferLine.SetLoadFields(SystemId);
                    TransferLine.FindFirst();
                    exit(TransferLine."Document No.");
                end;
            else
                exit(MultipleLbl);
        end;
    end;

    procedure GetReturnTransferOrderNo(RecRelatedVariant: Variant): Code[20]
    var
        TransferLine: Record "Transfer Line";
        PurchOrderNo: Code[20];
        PurchOrderLineNo: Integer;
    begin
        if not GetPurchaseOrderNoByVariant(RecRelatedVariant, PurchOrderNo, PurchOrderLineNo) then
            exit('');

        TransferLine.SetCurrentKey("Subcontr. Purch. Order No.");
        TransferLine.SetRange("Subcontr. Purch. Order No.", PurchOrderNo);
        TransferLine.SetRange("Subcontr. PO Line No.", PurchOrderLineNo);
        TransferLine.SetFilter("Operation No.", '%1', '');
        TransferLine.SetFilter("Routing No.", '%1', '');
        TransferLine.SetLoadFields(SystemId);
        if TransferLine.IsEmpty() then
            exit('');
        TransferLine.FindFirst();
        exit(TransferLine."Document No.");
    end;

    procedure GetConsumptionQtyFromProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        ItemLedgerEntry.SetCurrentKey(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order No.", ItemLedgerEntry."Order Line No.", ItemLedgerEntry."Entry Type", ItemLedgerEntry."Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Operation No.", ProdOrderRoutingLine."Operation No.");
        ItemLedgerEntry.CalcSums(ItemLedgerEntry.Quantity);

        exit(Abs(ItemLedgerEntry.Quantity));
    end;

    procedure ShowConsumptionQtyFromProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        ItemLedgerEntry.SetCurrentKey(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order No.", ItemLedgerEntry."Order Line No.", ItemLedgerEntry."Entry Type", ItemLedgerEntry."Prod. Order Comp. Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange(ItemLedgerEntry."Operation No.", ProdOrderRoutingLine."Operation No.");
        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
    end;

    local procedure SetProdOrderInformationByVariant(RecRelatedVariant: Variant; var ProdOrderNo: Code[20]; var ProdOrderLineNo: Integer; var RoutingNo: Code[20]; var OperationNo: Code[10]): Boolean
    var
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
                    ProdOrderNo := TransferLine."Prod. Order No.";
                    ProdOrderLineNo := TransferLine."Prod. Order Line No.";
                    RoutingNo := TransferLine."Routing No.";
                    OperationNo := TransferLine."Operation No.";
                end;
            Database::"Transfer Shipment Line":
                begin
                    ResultRecordRef.SetTable(TransferShipmentLine);
                    ProdOrderNo := TransferShipmentLine."Prod. Order No.";
                    ProdOrderLineNo := TransferShipmentLine."Prod. Order Line No.";
                    RoutingNo := TransferShipmentLine."Routing No.";
                    OperationNo := TransferShipmentLine."Operation No.";
                end;
            Database::"Transfer Receipt Line":
                begin
                    ResultRecordRef.SetTable(TransferReceiptLine);
                    ProdOrderNo := TransferReceiptLine."Prod. Order No.";
                    ProdOrderLineNo := TransferReceiptLine."Prod. Order Line No.";
                    RoutingNo := TransferReceiptLine."Routing No.";
                    OperationNo := TransferReceiptLine."Operation No.";
                end;
        end;
        exit((ProdOrderNo <> '') and (ProdOrderLineNo <> 0));
    end;

    local procedure GetPurchaseOrderNoByVariant(RecRelatedVariant: Variant; var PurchOrderNo: Code[20]; var PurchOrderLineNo: Integer): Boolean
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
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
                    PurchOrderNo := PurchaseLine."Document No.";
                    PurchOrderLineNo := PurchaseLine."Line No.";
                end;
            Database::"Purch. Rcpt. Line":
                begin
                    ResultRecordRef.SetTable(PurchRcptLine);
                    PurchOrderNo := PurchRcptLine."Order No.";
                    PurchOrderLineNo := PurchRcptLine."Order Line No.";
                end;
            Database::"Purch. Inv. Line":
                begin
                    ResultRecordRef.SetTable(PurchInvLine);
                    PurchOrderNo := PurchInvLine."Order No.";
                    PurchOrderLineNo := PurchInvLine."Order Line No.";
                end;
            Database::"Transfer Line":
                begin
                    ResultRecordRef.SetTable(TransferLine);
                    PurchOrderNo := TransferLine."Subcontr. Purch. Order No.";
                    PurchOrderLineNo := TransferLine."Subcontr. PO Line No.";
                end;
            Database::"Transfer Shipment Line":
                begin
                    ResultRecordRef.SetTable(TransferShipmentLine);
                    PurchOrderNo := TransferShipmentLine."Subcontr. Purch. Order No.";
                    PurchOrderLineNo := TransferShipmentLine."Subcontr. PO Line No.";
                end;
            Database::"Transfer Receipt Line":
                begin
                    ResultRecordRef.SetTable(TransferReceiptLine);
                    PurchOrderNo := TransferReceiptLine."Subcontr. Purch. Order No.";
                    PurchOrderLineNo := TransferReceiptLine."Subcontr. PO Line No.";
                end;
            Database::"Item Ledger Entry":
                begin
                    ResultRecordRef.SetTable(ItemLedgerEntry);
                    PurchOrderNo := ItemLedgerEntry."Subcontr. Purch. Order No.";
                    PurchOrderLineNo := ItemLedgerEntry."Subcontr. PO Line No.";
                end;
            Database::"Capacity Ledger Entry":
                begin
                    ResultRecordRef.SetTable(CapacityLedgerEntry);
                    PurchOrderNo := CapacityLedgerEntry."Subcontr. Purch. Order No.";
                    PurchOrderLineNo := CapacityLedgerEntry."Subcontr. PO Line No.";
                end;
            Database::"Prod. Order Routing Line":
                begin
                    ResultRecordRef.SetTable(ProdOrderRoutingLine);
                    GetPurchOrderFromProdOrderRtngLine(ProdOrderRoutingLine, PurchOrderNo, PurchOrderLineNo);
                end;
            Database::"Prod. Order Component":
                begin
                    ResultRecordRef.SetTable(ProdOrderComponent);
                    if ProdOrderComponent."Routing Link Code" <> '' then
                        GetPurchOrderFromProdOrderComp(ProdOrderComponent, PurchOrderNo, PurchOrderLineNo);
                end;
        end;
        exit(PurchOrderNo <> '');
    end;

    local procedure GetPurchOrderFromProdOrderRtngLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var PurchOrderNo: Code[20]; var PurchOrderLineNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        if PurchaseLine.IsEmpty() then
            exit;

        PurchaseLine.FindFirst();
        PurchOrderNo := PurchaseLine."Document No.";
        PurchOrderLineNo := PurchaseLine."Line No.";
    end;

    local procedure GetPurchOrderFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"; var PurchOrderNo: Code[20]; var PurchOrderLineNo: Integer)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        if PurchaseLine.IsEmpty() then
            exit;

        PurchaseLine.FindFirst();
        PurchOrderNo := PurchaseLine."Document No.";
        PurchOrderLineNo := PurchaseLine."Line No.";
    end;

    local procedure GetProdOrderRtngLineFromProdOrderComp(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.") then
            exit;

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing Link Code", ProdOrderComponent."Routing Link Code");
        if ProdOrderRoutingLine.IsEmpty() then
            exit;

        ProdOrderRoutingLine.FindFirst();
    end;

    procedure GetPurchOrderOutstandingQtyBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit(0);
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit(0);

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        PurchaseLine.CalcSums(PurchaseLine."Outstanding Qty. (Base)");
        exit(PurchaseLine."Outstanding Qty. (Base)");
    end;

    procedure ShowPurchOrderOutstandingQtyBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit;

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    procedure GetPurchOrderQtyReceivedBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit(0);
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit(0);

        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        PurchaseLine.CalcSums(PurchaseLine."Qty. Received (Base)");
        exit(PurchaseLine."Qty. Received (Base)");
    end;

    procedure ShowPurchOrderQtyReceivedBaseFromProdOrderComp(ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ProdOrderComponent."Routing Link Code" = '' then
            exit;
        if ProdOrderComponent."Subcontracting Type" <> ProdOrderComponent."Subcontracting Type"::Purchase then
            exit;
        GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);

        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange(PurchaseLine."Subc. Work Center No.", ProdOrderRoutingLine."Work Center No.");
        PurchaseLine.SetRange(PurchaseLine."No.", ProdOrderComponent."Item No.");
        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    procedure GetTransferOrderNoByVariant(RecRelatedVariant: Variant; var TransferOrderNo: Code[20]): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TransferLine: Record "Transfer Line";
        DataTypeManagement: Codeunit "Data Type Management";
        ResultRecordRef: RecordRef;
        RecId: RecordId;
        ProdOperation: Code[10];
        ProdOrderNo: Code[20];
        PurchOrderNo: Code[20];
        ProdOrderLineNo: Integer;
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
                    PurchOrderNo := PurchaseLine."Document No.";
                    ProdOrderNo := PurchaseLine."Prod. Order No.";
                    ProdOrderLineNo := PurchaseLine."Prod. Order Line No.";
                    ProdOperation := PurchaseLine."Operation No.";
                end;
            Database::"Purch. Rcpt. Line":
                begin
                    ResultRecordRef.SetTable(PurchRcptLine);
                    PurchOrderNo := PurchRcptLine."Document No.";
                    ProdOrderNo := PurchRcptLine."Prod. Order No.";
                    ProdOrderLineNo := PurchRcptLine."Prod. Order Line No.";
                    ProdOperation := PurchRcptLine."Operation No.";
                end;
            Database::"Purch. Inv. Line":
                begin
                    ResultRecordRef.SetTable(PurchInvLine);
                    PurchOrderNo := PurchInvLine."Document No.";
                    ProdOrderNo := PurchInvLine."Prod. Order No.";
                    ProdOrderLineNo := PurchInvLine."Prod. Order Line No.";
                    ProdOperation := PurchInvLine."Operation No.";
                end;
        end;

        TransferLine.SetCurrentKey("Subcontr. Purch. Order No.", "Prod. Order No.", "Prod. Order Line No.", "Operation No.");
        TransferLine.SetRange("Subcontr. Purch. Order No.", PurchOrderNo);
        TransferLine.SetRange("Prod. Order No.", ProdOrderNo);
        TransferLine.SetRange("Prod. Order Line No.", ProdOrderLineNo);
        TransferLine.SetRange("Operation No.", ProdOperation);

        if not TransferLine.IsEmpty() then begin
            TransferLine.SetLoadFields(SystemId);

            TransferLine.FindFirst();
            TransferOrderNo := TransferLine."Document No.";
            exit(TransferOrderNo <> '');
        end;
    end;

    procedure ShowTransferOrdersAndReturnOrder(RecRelatedVariant: Variant; LookUpPage: Boolean; IsReturn: Boolean): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        TempTransferHeader: Record "Transfer Header" temporary;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
        NoTransferExistsTxt: Label 'No transfer order exists for this purchase order.';
    begin
        if not RecRelatedVariant.IsRecord() then
            exit(0);

        DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef);

        case RecRef.Number() of
            Database::"Prod. Order Component":
                begin
                    RecRef.SetTable(ProdOrderComponent);
                    if not ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.") then
                        exit;

                    GetProdOrderRtngLineFromProdOrderComp(ProdOrderRoutingLine, ProdOrderComponent);
                end;
            Database::"Purchase Line":
                begin
                    RecRef.SetTable(PurchaseLine);
                    GetProdOrderRtngLineFromPurchaseLine(ProdOrderRoutingLine, PurchaseLine);
                    if not ProdOrderLine.Get(ProdOrderRoutingLine.Status, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
                        exit;
                end;
            Database::"Prod. Order Routing Line":
                begin
                    RecRef.SetTable(ProdOrderRoutingLine);
                    if not ProdOrderLine.Get(ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.") then
                        exit;
                end;
            else
                exit(0)
        end;

        TransferLine.SetCurrentKey("Prod. Order No.", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.");
        TransferLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        TransferLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if IsReturn then begin
            TransferLine.SetRange("Routing Reference No.", 0);
            TransferLine.SetRange("Routing No.", '');
            TransferLine.SetRange("Operation No.", '');
        end else begin
            TransferLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            TransferLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
            TransferLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        end;

        if not TransferLine.IsEmpty() then
            if TransferLine.FindSet() then begin
                if not TempTransferHeader.IsEmpty() then
                    TempTransferHeader.DeleteAll();
                repeat
                    if TransferHeader.Get(TransferLine."Document No.") then begin
                        TempTransferHeader.Init();
                        TempTransferHeader.TransferFields(TransferHeader);
                        if TempTransferHeader.Insert() then;
                    end;
                until TransferLine.Next() = 0;
            end;

        if LookUpPage then begin
            if TempTransferHeader.Count() > 1 then
                Page.Run(Page::"Transfer Orders", TempTransferHeader)
            else
                if TempTransferHeader.FindSet() then
                    Page.Run(Page::"Transfer Order", TempTransferHeader)
                else
                    Message(NoTransferExistsTxt);
        end else
            exit(TempTransferHeader.Count());
    end;

    procedure GetSubcontractorNo(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Machine Center" then
            exit('');
        WorkCenter.SetLoadFields("Subcontractor No.");
        if WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then
            exit(WorkCenter."Subcontractor No.");
    end;

    procedure ShowSubcontractor(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center" then begin
            WorkCenter.Get(ProdOrderRoutingLine."Work Center No.");
            if Vendor.Get(WorkCenter."Subcontractor No.") then
                Page.Run(Page::"Vendor Card", Vendor);
        end;
    end;

    procedure GetPurchOrderQtyFromRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.CalcSums(PurchaseLine.Quantity);
        exit(PurchaseLine.Quantity);
    end;

    procedure ShowPurchaseOrderLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(PurchaseLine."Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(PurchaseLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchaseLine.SetRange(PurchaseLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchaseLine.SetRange(PurchaseLine."Operation No.", ProdOrderRoutingLine."Operation No.");

        Page.Run(Page::"Purchase Lines", PurchaseLine);
    end;

    procedure GetPurchReceiptQtyFromRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchRcptLine.SetRange(PurchRcptLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchRcptLine.CalcSums(PurchRcptLine.Quantity);
        exit(PurchRcptLine.Quantity);
    end;

    procedure ShowPurchaseReceiptLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchRcptLine.SetRange(PurchRcptLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchRcptLine.SetRange(PurchRcptLine."Operation No.", ProdOrderRoutingLine."Operation No.");

        Page.Run(Page::"Purch. Receipt Lines", PurchRcptLine);
    end;

    procedure GetPurchInvoicedQtyFromRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange(PurchInvLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchInvLine.SetRange(PurchInvLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchInvLine.SetRange(PurchInvLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchInvLine.CalcSums(PurchInvLine.Quantity);
        exit(PurchInvLine.Quantity);
    end;

    procedure ShowPurchaseInvoiceLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetCurrentKey(PurchInvLine.Type, PurchInvLine."Prod. Order No.", PurchInvLine."Prod. Order Line No.");
        PurchInvLine.SetRange(PurchInvLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        PurchInvLine.SetRange(PurchInvLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        PurchInvLine.SetRange(PurchInvLine."Operation No.", ProdOrderRoutingLine."Operation No.");

        Page.Run(Page::"Posted Purchase Invoice Lines", PurchInvLine);
    end;

    procedure GetNoOfTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Routing No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        TransferLine.SetRange(TransferLine."Routing No.", ProdOrderRoutingLine."Routing No.");
        TransferLine.SetRange(TransferLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        exit(TransferLine.Count());
    end;

    procedure GetNoOfReturnTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Routing Reference No.", 0);
        TransferLine.SetRange(TransferLine."Operation No.", '');
        exit(TransferLine.Count());
    end;

    procedure ShowTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Routing No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        TransferLine.SetRange(TransferLine."Routing No.", ProdOrderRoutingLine."Routing No.");
        TransferLine.SetRange(TransferLine."Operation No.", ProdOrderRoutingLine."Operation No.");
        Page.Run(Page::"Transfer Lines", TransferLine);
    end;

    procedure ShowReturnTransferLinesFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetCurrentKey(TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Routing Reference No.", TransferLine."Operation No.");
        TransferLine.SetRange(TransferLine."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        TransferLine.SetRange(TransferLine."Routing Reference No.", 0);
        TransferLine.SetRange(TransferLine."Operation No.", '');
        Page.Run(Page::"Transfer Lines", TransferLine);
    end;

    procedure GetNoOfLinkedComponentsFromRouting(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ProdOrderRoutingLine."Routing Link Code" = '' then
            exit(0);
        ProdOrderComponent.SetRange(ProdOrderComponent.Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        exit(ProdOrderComponent.Count());
    end;

    procedure ShowProdOrderComponents(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(ProdOrderComponent.Status, ProdOrderRoutingLine.Status);
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Prod. Order Line No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderComponent.SetRange(ProdOrderComponent."Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        Page.Run(Page::"Subc. Prod. Order Components", ProdOrderComponent);
    end;

    local procedure GetProdOrderRtngLineFromPurchaseLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PurchaseLine: Record "Purchase Line")
    begin
        ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", PurchaseLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Operation No.", PurchaseLine."Operation No.");
        if ProdOrderRoutingLine.IsEmpty() then
            exit;

        ProdOrderRoutingLine.FindFirst();
    end;

    procedure CalcNoOfPurchasePrices(var PurchaseLine: Record "Purchase Line"): Integer
    begin
        if IsItemLine(PurchaseLine) then
            exit(CountPriceOnPurchItemLine(PurchaseLine));
    end;

    local procedure CountPriceOnPurchItemLine(PurchaseLine: Record "Purchase Line"): Decimal
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        FilterSubContractorPriceForPurchLine(SubcontractorPrice, PurchaseLine);

        exit(SubcontractorPrice.Count());
    end;

    local procedure IsItemLine(PurchaseLine: Record "Purchase Line"): Boolean
    begin
        if (PurchaseLine.Type <> PurchaseLine.Type::Item) or (PurchaseLine."No." = '') then
            exit(false);
        exit(true);
    end;

    procedure ShowSubcontractorPrices(PurchaseLine: Record "Purchase Line")
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        FilterSubContractorPriceForPurchLine(SubcontractorPrice, PurchaseLine);

        Page.Run(Page::"Subcontractor Prices", SubcontractorPrice);
    end;

    procedure GetNoOfTransferOrders(RecRelatedVariant: Variant) NoOfTransferOrders: Integer
    var
        TransferLine: Record "Transfer Line";
        ListOfTransferHeaderNo: List of [Code[20]];
        PurchOrderNo: Code[20];
        PurchOrderLineNo: Integer;
    begin
        if not GetPurchaseOrderNoByVariant(RecRelatedVariant, PurchOrderNo, PurchOrderLineNo) then
            exit(0);

        FilterTransferLineToSubcontractorPurchaseOrder(PurchOrderNo, PurchOrderLineNo, TransferLine);
        if not TransferLine.FindSet() then
            exit(0);

        repeat
            if not ListOfTransferHeaderNo.Contains(TransferLine."Document No.") then
                ListOfTransferHeaderNo.Add(TransferLine."Document No.");
        until TransferLine.Next() = 0;
        NoOfTransferOrders := ListOfTransferHeaderNo.Count();

        exit(NoOfTransferOrders);
    end;

    local procedure FilterSubContractorPriceForPurchLine(var SubcontractorPrice: Record "Subcontractor Price"; PurchaseLine: Record "Purchase Line")
    begin
        SubcontractorPrice.SetCurrentKey("Vendor No.", "Item No.", "Work Center No.", "Variant Code", "Unit of Measure Code", "Currency Code");
        SubcontractorPrice.SetRange("Vendor No.", PurchaseLine."Buy-from Vendor No.");
        SubcontractorPrice.SetRange("Item No.", PurchaseLine."No.");
        SubcontractorPrice.SetRange("Work Center No.", PurchaseLine."Work Center No.");
        SubcontractorPrice.SetRange("Variant Code", PurchaseLine."Variant Code");
        SubcontractorPrice.SetRange("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
        SubcontractorPrice.SetRange("Currency Code", PurchaseLine."Currency Code");
    end;

    local procedure FilterTransferLineToSubcontractorPurchaseOrder(PurchOrderNo: Code[20]; PurchOrderLineNo: Integer; var TransferLine: Record "Transfer Line")
    begin
        TransferLine.SetCurrentKey("Subcontr. Purch. Order No.");
        TransferLine.SetRange("Subcontr. Purch. Order No.", PurchOrderNo);
        TransferLine.SetRange("Subcontr. PO Line No.", PurchOrderLineNo);
        TransferLine.SetFilter("Operation No.", '<>%1', '');
        TransferLine.SetFilter("Routing No.", '<>%1', '');
    end;
}