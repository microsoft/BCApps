// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 5476 "Graph Mgt - Sales Inv. Lines"
{

    trigger OnRun()
    begin
    end;


    procedure GetUnitOfMeasureJSON(var SalesInvoiceLineAggregate: Record "Sales Invoice Line Aggregate"): Text
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        UnitOfMeasureJSON: Text;
    begin
        if SalesInvoiceLineAggregate."No." = '' then
            exit;

        case SalesInvoiceLineAggregate.Type of
            SalesInvoiceLineAggregate.Type::Item:
                begin
                    if not Item.Get(SalesInvoiceLineAggregate."No.") then
                        exit;

                    UnitOfMeasureJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, SalesInvoiceLineAggregate."Unit of Measure Code");
                end;
            else
                UnitOfMeasureJSON := GraphMgtComplexTypes.GetUnitOfMeasureJSON(SalesInvoiceLineAggregate."Unit of Measure Code");
        end;

        exit(UnitOfMeasureJSON);
    end;

    [Scope('Cloud')]
    procedure GetDocumentIdFilterFromIdFilter(IdFilter: Text): Text
    begin
        exit(CopyStr(IdFilter, 1, 36));
    end;

    [Scope('Cloud')]
    procedure GetSalesOrderDocumentIdFilterFromSystemId(Id: Guid): Text
    var
        SalesLine: Record "Sales Line";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
    begin
        if not SalesLine.GetBySystemId(Id) then
            exit(' ');
        SalesOrderEntityBuffer.Get(SalesLine."Document No.");
        exit(Format(SalesOrderEntityBuffer.Id));
    end;

    [Scope('Cloud')]
    procedure GetSalesQuoteDocumentIdFilterFromSystemId(Id: Guid): Text
    var
        SalesLine: Record "Sales Line";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
    begin
        if not SalesLine.GetBySystemId(Id) then
            exit(' ');
        SalesQuoteEntityBuffer.Get(SalesLine."Document No.");
        exit(Format(SalesQuoteEntityBuffer.Id));
    end;

    [Scope('Cloud')]
    procedure GetSalesCreditMemoDocumentIdFilterFromSystemId(Id: Guid): Text
    var
        SalesLine: Record "Sales Line";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        if SalesCrMemoLine.GetBySystemId(Id) then
            if SalesCrMemoEntityBuffer.Get(SalesCrMemoLine."Document No.", true) then
                exit(Format(SalesCrMemoEntityBuffer.Id));
        if SalesLine.GetBySystemId(Id) then
            if SalesCrMemoEntityBuffer.Get(SalesLine."Document No.", false) then
                exit(Format(SalesCrMemoEntityBuffer.Id));
        exit(' ');
    end;

    [Scope('Cloud')]
    procedure GetSalesInvoiceDocumentIdFilterFromSystemId(Id: Guid): Text
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceEntityAggr: Record "Sales Invoice Entity Aggregate";
    begin
        if SalesInvoiceLine.GetBySystemId(Id) then
            if SalesInvoiceEntityAggr.Get(SalesInvoiceLine."Document No.", true) then
                exit(Format(SalesInvoiceEntityAggr.Id));
        if SalesLine.GetBySystemId(Id) then
            if SalesInvoiceEntityAggr.Get(SalesLine."Document No.", false) then
                exit(Format(SalesInvoiceEntityAggr.Id));
        exit(' ');
    end;

    [Scope('Cloud')]
    procedure GetPurchaseInvoiceDocumentIdFilterFromSystemId(Id: Guid): Text
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        PurchaseInvoiceEntityAggr: Record "Purch. Inv. Entity Aggregate";
    begin
        if PurchaseInvoiceLine.GetBySystemId(Id) then
            if PurchaseInvoiceEntityAggr.Get(PurchaseInvoiceLine."Document No.", true) then
                exit(Format(PurchaseInvoiceEntityAggr.Id));
        if PurchaseLine.GetBySystemId(Id) then
            if PurchaseInvoiceEntityAggr.Get(PurchaseLine."Document No.", false) then
                exit(Format(PurchaseInvoiceEntityAggr.Id));
        exit(' ');
    end;
}

