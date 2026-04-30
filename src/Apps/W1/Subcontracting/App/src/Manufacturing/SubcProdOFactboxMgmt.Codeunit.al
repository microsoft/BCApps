// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Utilities;
using System.Reflection;

codeunit 99001559 "Subc. ProdO. Factbox Mgmt."
{
    /// <summary>
    /// Opens the Released Production Order page for the production order linked to the given variant record.
    /// </summary>
    /// <param name="RecRelatedVariant">A record variant of a purchase or transfer document line.</param>
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
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit;
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLineNo);
        exit(ProdOrderRoutingLine.Count());
    end;

    /// <summary>
    /// Opens the Production Order Components page filtered to the production order linked to the given variant record.
    /// </summary>
    /// <param name="RecRelatedVariant">A record variant of a purchase or transfer document line.</param>
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
        if not SetProdOrderInformationByVariant(RecRelatedVariant, ProdOrderNo, ProdOrderLineNo, RoutingNo, OperationNo) then
            exit(0);

        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLineNo);
        exit(ProdOrderComponent.Count());
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
}
