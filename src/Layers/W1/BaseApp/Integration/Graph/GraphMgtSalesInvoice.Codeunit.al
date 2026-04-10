// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Sales.History;

codeunit 5475 "Graph Mgt - Sales Invoice"
{
    Permissions = TableData "Sales Invoice Header" = rimd;

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate"; SellToAddressJSON: Text)
    begin
        ParseSellToCustomerAddressFromJSON(SellToAddressJSON, SalesInvoiceEntityAggregate);
    end;

    procedure ParseSellToCustomerAddressFromJSON(SellToAddressJSON: Text; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if SellToAddressJSON <> '' then begin
            RecRef.GetTable(SalesInvoiceEntityAggregate);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(SellToAddressJSON, RecRef,
              SalesInvoiceEntityAggregate.FieldNo("Sell-to Address"), SalesInvoiceEntityAggregate.FieldNo("Sell-to Address 2"), SalesInvoiceEntityAggregate.FieldNo("Sell-to City"), SalesInvoiceEntityAggregate.FieldNo("Sell-to County"),
              SalesInvoiceEntityAggregate.FieldNo("Sell-to Country/Region Code"), SalesInvoiceEntityAggregate.FieldNo("Sell-to Post Code"));
            RecRef.SetTable(SalesInvoiceEntityAggregate);
        end;
    end;

    procedure ParseBillToCustomerAddressFromJSON(BillToAddressJSON: Text; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BillToAddressJSON <> '' then begin
            RecRef.GetTable(SalesInvoiceEntityAggregate);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BillToAddressJSON, RecRef,
              SalesInvoiceEntityAggregate.FieldNo("Bill-to Address"), SalesInvoiceEntityAggregate.FieldNo("Bill-to Address 2"), SalesInvoiceEntityAggregate.FieldNo("Bill-to City"), SalesInvoiceEntityAggregate.FieldNo("Bill-to County"),
              SalesInvoiceEntityAggregate.FieldNo("Bill-to Country/Region Code"), SalesInvoiceEntityAggregate.FieldNo("Bill-to Post Code"));
            RecRef.SetTable(SalesInvoiceEntityAggregate);
        end;
    end;

    procedure ParseShipToCustomerAddressFromJSON(ShipToAddressJSON: Text; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then begin
            RecRef.GetTable(SalesInvoiceEntityAggregate);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
              SalesInvoiceEntityAggregate.FieldNo("Ship-to Address"), SalesInvoiceEntityAggregate.FieldNo("Ship-to Address 2"), SalesInvoiceEntityAggregate.FieldNo("Ship-to City"), SalesInvoiceEntityAggregate.FieldNo("Ship-to County"),
              SalesInvoiceEntityAggregate.FieldNo("Ship-to Country/Region Code"), SalesInvoiceEntityAggregate.FieldNo("Ship-to Post Code"));
            RecRef.SetTable(SalesInvoiceEntityAggregate);
        end;
    end;

    procedure SellToCustomerAddressToJSON(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesInvoiceEntityAggregate."Sell-to Address", SalesInvoiceEntityAggregate."Sell-to Address 2",
              SalesInvoiceEntityAggregate."Sell-to City", SalesInvoiceEntityAggregate."Sell-to County", SalesInvoiceEntityAggregate."Sell-to Country/Region Code", SalesInvoiceEntityAggregate."Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesInvoiceEntityAggregate."Bill-to Address", SalesInvoiceEntityAggregate."Bill-to Address 2",
              SalesInvoiceEntityAggregate."Bill-to City", SalesInvoiceEntityAggregate."Bill-to County", SalesInvoiceEntityAggregate."Bill-to Country/Region Code", SalesInvoiceEntityAggregate."Bill-to Post Code", JSON);
    end;

    procedure ShipToCustomerAddressToJSON(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesInvoiceEntityAggregate."Ship-to Address", SalesInvoiceEntityAggregate."Ship-to Address 2",
              SalesInvoiceEntityAggregate."Ship-to City", SalesInvoiceEntityAggregate."Ship-to County", SalesInvoiceEntityAggregate."Ship-to Country/Region Code", SalesInvoiceEntityAggregate."Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SalesInvoiceAggregator.UpdateAggregateTableRecords();
    end;
}

