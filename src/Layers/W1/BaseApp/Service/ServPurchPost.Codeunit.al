// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Item;

codeunit 6454 "Serv. Purch.-Post"
{
    Permissions = TableData "Service Item" = rimd;
    SingleInstance = true;

    var
        ServItemManagement: Codeunit ServItemManagement;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforeCheckAndUpdate', '', false, false)]
    local procedure OnRunOnBeforeCheckAndUpdate(var PurchaseHeader: Record "Purchase Header"; var ModifyHeader: Boolean)
    begin
        Clear(ServItemManagement);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterInsertReceiptHeader', '', false, false)]
    local procedure OnAfterInsertReceiptHeader(var PurchHeader: Record "Purchase Header")
    begin
        ServItemManagement.CopyReservation(PurchHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnPostCombineSalesOrderShipmentOnAfterUpdateSalesOrderLine', '', false, false)]
    local procedure OnPostCombineSalesOrderShipmentOnAfterUpdateSalesOrderLine(SalesOrderHeader: Record "Sales Header"; var SalesOrderLine: Record "Sales Line"; SalesShipmentLine: Record "Sales Shipment Line")
    begin
        ServItemManagement.CreateServItemOnSalesLineShpt(SalesOrderHeader, SalesOrderLine, SalesShipmentLine);
    end;
}