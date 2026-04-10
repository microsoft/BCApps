// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;

codeunit 5505 "Graph Mgt - Sales Quote"
{

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer"; SellToAddressJSON: Text)
    begin
        ParseSellToCustomerAddressFromJSON(SellToAddressJSON, SalesQuoteEntityBuffer);
    end;

    procedure ParseSellToCustomerAddressFromJSON(SellToAddressJSON: Text; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if SellToAddressJSON <> '' then begin
            RecRef.GetTable(SalesQuoteEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(SellToAddressJSON, RecRef,
              SalesQuoteEntityBuffer.FieldNo("Sell-to Address"), SalesQuoteEntityBuffer.FieldNo("Sell-to Address 2"), SalesQuoteEntityBuffer.FieldNo("Sell-to City"), SalesQuoteEntityBuffer.FieldNo("Sell-to County"),
              SalesQuoteEntityBuffer.FieldNo("Sell-to Country/Region Code"), SalesQuoteEntityBuffer.FieldNo("Sell-to Post Code"));
            RecRef.SetTable(SalesQuoteEntityBuffer);
        end;
    end;

    procedure ParseBillToCustomerAddressFromJSON(BillToAddressJSON: Text; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BillToAddressJSON <> '' then begin
            RecRef.GetTable(SalesQuoteEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BillToAddressJSON, RecRef,
              SalesQuoteEntityBuffer.FieldNo("Bill-to Address"), SalesQuoteEntityBuffer.FieldNo("Bill-to Address 2"), SalesQuoteEntityBuffer.FieldNo("Bill-to City"), SalesQuoteEntityBuffer.FieldNo("Bill-to County"),
              SalesQuoteEntityBuffer.FieldNo("Bill-to Country/Region Code"), SalesQuoteEntityBuffer.FieldNo("Bill-to Post Code"));
            RecRef.SetTable(SalesQuoteEntityBuffer);
        end;
    end;

    procedure ParseShipToCustomerAddressFromJSON(ShipToAddressJSON: Text; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then begin
            RecRef.GetTable(SalesQuoteEntityBuffer);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
              SalesQuoteEntityBuffer.FieldNo("Ship-to Address"), SalesQuoteEntityBuffer.FieldNo("Ship-to Address 2"), SalesQuoteEntityBuffer.FieldNo("Ship-to City"), SalesQuoteEntityBuffer.FieldNo("Ship-to County"),
              SalesQuoteEntityBuffer.FieldNo("Ship-to Country/Region Code"), SalesQuoteEntityBuffer.FieldNo("Ship-to Post Code"));
            RecRef.SetTable(SalesQuoteEntityBuffer);
        end;
    end;

    procedure SellToCustomerAddressToJSON(SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesQuoteEntityBuffer."Sell-to Address", SalesQuoteEntityBuffer."Sell-to Address 2",
              SalesQuoteEntityBuffer."Sell-to City", SalesQuoteEntityBuffer."Sell-to County", SalesQuoteEntityBuffer."Sell-to Country/Region Code", SalesQuoteEntityBuffer."Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesQuoteEntityBuffer."Bill-to Address", SalesQuoteEntityBuffer."Bill-to Address 2",
              SalesQuoteEntityBuffer."Bill-to City", SalesQuoteEntityBuffer."Bill-to County", SalesQuoteEntityBuffer."Bill-to Country/Region Code", SalesQuoteEntityBuffer."Bill-to Post Code", JSON);
    end;

    procedure ShipToCustomerAddressToJSON(SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(SalesQuoteEntityBuffer."Ship-to Address", SalesQuoteEntityBuffer."Ship-to Address 2",
              SalesQuoteEntityBuffer."Ship-to City", SalesQuoteEntityBuffer."Ship-to County", SalesQuoteEntityBuffer."Ship-to Country/Region Code", SalesQuoteEntityBuffer."Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        GraphMgtSalesQuoteBuffer.UpdateBufferTableRecords();
    end;
}

