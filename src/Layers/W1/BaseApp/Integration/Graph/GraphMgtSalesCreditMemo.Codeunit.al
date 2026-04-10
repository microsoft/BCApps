// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Sales.History;

codeunit 5507 "Graph Mgt - Sales Credit Memo"
{
    Permissions = TableData "Sales Cr.Memo Header" = rimd;

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer"; SellToAddressJSON: Text)
    begin
        ParseSellToCustomerAddressFromJSON(SellToAddressJSON, SalesCrMemoEntityBuffer);
    end;

    procedure ParseSellToCustomerAddressFromJSON(SellToAddressJSON: Text; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if SellToAddressJSON <> '' then begin
            RecRef.GetTable(SalesCrMemoEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(SellToAddressJSON, RecRef,
              SalesCrMemoEntityBuffer.FieldNo("Sell-to Address"), SalesCrMemoEntityBuffer.FieldNo("Sell-to Address 2"), SalesCrMemoEntityBuffer.FieldNo("Sell-to City"), SalesCrMemoEntityBuffer.FieldNo("Sell-to County"),
              SalesCrMemoEntityBuffer.FieldNo("Sell-to Country/Region Code"), SalesCrMemoEntityBuffer.FieldNo("Sell-to Post Code"));
            RecRef.SetTable(SalesCrMemoEntityBuffer);
        end;
    end;

    procedure ParseBillToCustomerAddressFromJSON(BillToAddressJSON: Text; var SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BillToAddressJSON <> '' then begin
            RecRef.GetTable(SalesCrMemoEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BillToAddressJSON, RecRef,
              SalesCrMemoEntityBuffer.FieldNo("Bill-to Address"), SalesCrMemoEntityBuffer.FieldNo("Bill-to Address 2"), SalesCrMemoEntityBuffer.FieldNo("Bill-to City"), SalesCrMemoEntityBuffer.FieldNo("Bill-to County"),
              SalesCrMemoEntityBuffer.FieldNo("Bill-to Country/Region Code"), SalesCrMemoEntityBuffer.FieldNo("Bill-to Post Code"));
            RecRef.SetTable(SalesCrMemoEntityBuffer);
        end;
    end;

    procedure SellToCustomerAddressToJSON(SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesCrMemoEntityBuffer."Sell-to Address", SalesCrMemoEntityBuffer."Sell-to Address 2",
              SalesCrMemoEntityBuffer."Sell-to City", SalesCrMemoEntityBuffer."Sell-to County", SalesCrMemoEntityBuffer."Sell-to Country/Region Code", SalesCrMemoEntityBuffer."Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesCrMemoEntityBuffer."Bill-to Address", SalesCrMemoEntityBuffer."Bill-to Address 2",
              SalesCrMemoEntityBuffer."Bill-to City", SalesCrMemoEntityBuffer."Bill-to County", SalesCrMemoEntityBuffer."Bill-to Country/Region Code", SalesCrMemoEntityBuffer."Bill-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        GraphMgtSalCrMemoBuf: Codeunit "Graph Mgt - Sal. Cr. Memo Buf.";
    begin
        GraphMgtSalCrMemoBuf.UpdateBufferTableRecords();
    end;
}

