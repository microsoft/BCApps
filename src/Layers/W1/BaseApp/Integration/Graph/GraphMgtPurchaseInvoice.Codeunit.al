// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Purchases.History;

codeunit 5527 "Graph Mgt - Purchase Invoice"
{
    Permissions = TableData "Purch. Inv. Header" = rimd;

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; BuyFromAddressJSON: Text)
    begin
        ParseBuyFromVendorAddressFromJSON(BuyFromAddressJSON, PurchInvEntityAggregate);
    end;

    procedure ParseBuyFromVendorAddressFromJSON(BuyFromAddressJSON: Text; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BuyFromAddressJSON <> '' then begin
            RecRef.GetTable(PurchInvEntityAggregate);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BuyFromAddressJSON, RecRef,
              PurchInvEntityAggregate.FieldNo("Buy-from Address"), PurchInvEntityAggregate.FieldNo("Buy-from Address 2"), PurchInvEntityAggregate.FieldNo("Buy-from City"), PurchInvEntityAggregate.FieldNo("Buy-from County"),
              PurchInvEntityAggregate.FieldNo("Buy-from Country/Region Code"), PurchInvEntityAggregate.FieldNo("Buy-from Post Code"));
            RecRef.SetTable(PurchInvEntityAggregate);
        end;
    end;

    procedure ParsePayToVendorAddressFromJSON(PayToAddressJSON: Text; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PayToAddressJSON <> '' then begin
            RecRef.GetTable(PurchInvEntityAggregate);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PayToAddressJSON, RecRef,
              PurchInvEntityAggregate.FieldNo("Pay-to Address"), PurchInvEntityAggregate.FieldNo("Pay-to Address 2"), PurchInvEntityAggregate.FieldNo("Pay-to City"), PurchInvEntityAggregate.FieldNo("Pay-to County"),
              PurchInvEntityAggregate.FieldNo("Pay-to Country/Region Code"), PurchInvEntityAggregate.FieldNo("Pay-to Post Code"));
            RecRef.SetTable(PurchInvEntityAggregate);
        end;
    end;

    procedure ParseShipToVendorAddressFromJSON(ShipToAddressJSON: Text; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then begin
            RecRef.GetTable(PurchInvEntityAggregate);
            GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
              PurchInvEntityAggregate.FieldNo("Ship-to Address"), PurchInvEntityAggregate.FieldNo("Ship-to Address 2"), PurchInvEntityAggregate.FieldNo("Ship-to City"), PurchInvEntityAggregate.FieldNo("Ship-to County"),
              PurchInvEntityAggregate.FieldNo("Ship-to Country/Region Code"), PurchInvEntityAggregate.FieldNo("Ship-to Post Code"));
            RecRef.SetTable(PurchInvEntityAggregate);
        end;
    end;

    procedure BuyFromVendorAddressToJSON(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(PurchInvEntityAggregate."Buy-from Address", PurchInvEntityAggregate."Buy-from Address 2",
              PurchInvEntityAggregate."Buy-from City", PurchInvEntityAggregate."Buy-from County", PurchInvEntityAggregate."Buy-from Country/Region Code", PurchInvEntityAggregate."Buy-from Post Code", JSON);
    end;

    procedure PayToVendorAddressToJSON(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(PurchInvEntityAggregate."Pay-to Address", PurchInvEntityAggregate."Pay-to Address 2",
              PurchInvEntityAggregate."Pay-to City", PurchInvEntityAggregate."Pay-to County", PurchInvEntityAggregate."Pay-to Country/Region Code", PurchInvEntityAggregate."Pay-to Post Code", JSON);
    end;

    procedure ShipToVendorAddressToJSON(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        GraphMgtComplexTypes.GetPostalAddressJSON(PurchInvEntityAggregate."Ship-to Address", PurchInvEntityAggregate."Ship-to Address 2",
              PurchInvEntityAggregate."Ship-to City", PurchInvEntityAggregate."Ship-to County", PurchInvEntityAggregate."Ship-to Country/Region Code", PurchInvEntityAggregate."Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        PurchInvAggregator.UpdateAggregateTableRecords();
    end;
}

