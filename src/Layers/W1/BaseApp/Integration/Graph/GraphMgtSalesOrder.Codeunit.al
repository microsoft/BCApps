// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Sales.History;

codeunit 5495 "Graph Mgt - Sales Order"
{
    Permissions = TableData "Sales Invoice Header" = rimd;

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer"; SellToAddressJSON: Text)
    begin
        ParseSellToCustomerAddressFromJSON(SellToAddressJSON, SalesOrderEntityBuffer);
    end;

    procedure ParseSellToCustomerAddressFromJSON(SellToAddressJSON: Text; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if SellToAddressJSON <> '' then begin
            RecRef.GetTable(SalesOrderEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(SellToAddressJSON, RecRef,
              SalesOrderEntityBuffer.FieldNo("Sell-to Address"), SalesOrderEntityBuffer.FieldNo("Sell-to Address 2"), SalesOrderEntityBuffer.FieldNo("Sell-to City"), SalesOrderEntityBuffer.FieldNo("Sell-to County"),
              SalesOrderEntityBuffer.FieldNo("Sell-to Country/Region Code"), SalesOrderEntityBuffer.FieldNo("Sell-to Post Code"));
            RecRef.SetTable(SalesOrderEntityBuffer);
        end;
    end;

    procedure ParseBillToCustomerAddressFromJSON(BillToAddressJSON: Text; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BillToAddressJSON <> '' then begin
            RecRef.GetTable(SalesOrderEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BillToAddressJSON, RecRef,
              SalesOrderEntityBuffer.FieldNo("Bill-to Address"), SalesOrderEntityBuffer.FieldNo("Bill-to Address 2"), SalesOrderEntityBuffer.FieldNo("Bill-to City"), SalesOrderEntityBuffer.FieldNo("Bill-to County"),
              SalesOrderEntityBuffer.FieldNo("Bill-to Country/Region Code"), SalesOrderEntityBuffer.FieldNo("Bill-to Post Code"));
            RecRef.SetTable(SalesOrderEntityBuffer);
        end;
    end;

    procedure ParseShipToCustomerAddressFromJSON(ShipToAddressJSON: Text; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then begin
            RecRef.GetTable(SalesOrderEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
              SalesOrderEntityBuffer.FieldNo("Ship-to Address"), SalesOrderEntityBuffer.FieldNo("Ship-to Address 2"), SalesOrderEntityBuffer.FieldNo("Ship-to City"), SalesOrderEntityBuffer.FieldNo("Ship-to County"),
              SalesOrderEntityBuffer.FieldNo("Ship-to Country/Region Code"), SalesOrderEntityBuffer.FieldNo("Ship-to Post Code"));
            RecRef.SetTable(SalesOrderEntityBuffer);
        end;
    end;

    procedure SellToCustomerAddressToJSON(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesOrderEntityBuffer."Sell-to Address", SalesOrderEntityBuffer."Sell-to Address 2",
              SalesOrderEntityBuffer."Sell-to City", SalesOrderEntityBuffer."Sell-to County", SalesOrderEntityBuffer."Sell-to Country/Region Code", SalesOrderEntityBuffer."Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesOrderEntityBuffer."Bill-to Address", SalesOrderEntityBuffer."Bill-to Address 2",
              SalesOrderEntityBuffer."Bill-to City", SalesOrderEntityBuffer."Bill-to County", SalesOrderEntityBuffer."Bill-to Country/Region Code", SalesOrderEntityBuffer."Bill-to Post Code", JSON);
    end;

    procedure ShipToCustomerAddressToJSON(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesOrderEntityBuffer."Ship-to Address", SalesOrderEntityBuffer."Ship-to Address 2",
              SalesOrderEntityBuffer."Ship-to City", SalesOrderEntityBuffer."Ship-to County", SalesOrderEntityBuffer."Ship-to Country/Region Code", SalesOrderEntityBuffer."Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        GraphMgtSalesOrderBuffer: Codeunit "Graph Mgt - Sales Order Buffer";
    begin
        GraphMgtSalesOrderBuffer.UpdateBufferTableRecords();
    end;
}

