// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;

codeunit 5753 GetSourceDocumentList
{
    procedure ReturnListofWhseShipments(e: ErrorInfo)
    var
        WarehouseShipmentLines: Record "Warehouse Shipment Line";
        WhseShipmentLinesPage: Page "Whse. Shipment Lines";
        SalesOrderNo: Code[20];
        SalesOrderType: Enum "Sales Document Type";
        SalesSourceType: Integer;
        dimension: Text;
    begin
        e.CustomDimensions.Get('Source Type', dimension);
        Evaluate(SalesSourceType, dimension);
        e.CustomDimensions.Get('Source Subtype', dimension);
        Evaluate(SalesOrderType, dimension);
        e.CustomDimensions.Get('Source No.', dimension);
        Evaluate(SalesOrderNo, dimension);
        WarehouseShipmentLines.SetRange("Source Type", SalesSourceType);
        WarehouseShipmentLines.SetRange("Source Subtype", SalesOrderType);
        WarehouseShipmentLines.SetRange("Source No.", SalesOrderNo);
        WhseShipmentLinesPage.SetTableView(WarehouseShipmentLines);
        WhseShipmentLinesPage.Run();
    end;

    procedure ReturnListofPurchaseReceipts(e: ErrorInfo)
    var
        WarehouseReceiptLines: Record "Warehouse Receipt Line";
        WhseReceiptLinesPage: Page "Whse. Receipt Lines";
        PurchaseOrderNo: Code[20];
        PurchaseOrderType: Enum "Purchase Document Type";
        PurchaseSourceType: Integer;
        dimension: Text;
    begin
        e.CustomDimensions.Get('Source Type', dimension);
        Evaluate(PurchaseSourceType, dimension);
        e.CustomDimensions.Get('Source Subtype', dimension);
        Evaluate(PurchaseOrderType, dimension);
        e.CustomDimensions.Get('Source No.', dimension);
        Evaluate(PurchaseOrderNo, dimension);
        WarehouseReceiptLines.SetRange("Source Type", PurchaseSourceType);
        WarehouseReceiptLines.SetRange("Source Subtype", PurchaseOrderType);
        WarehouseReceiptLines.SetRange("Source No.", PurchaseOrderNo);
        WhseReceiptLinesPage.SetTableView(WarehouseReceiptLines);
        WhseReceiptLinesPage.Run();
    end;
}
