// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Inventory.Transfer;
using Microsoft.Sales.History;

codeunit 3371 "EDoc Carta Porte Print Buffer"
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SourceSalesShipmentHeader: Record "Sales Shipment Header";
        SourceTransferShipmentHeader: Record "Transfer Shipment Header";
        SourceDocumentTableId: Integer;

    procedure SetSalesShipment(SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        SourceSalesShipmentHeader := SalesShipmentHeader;
        SourceDocumentTableId := Database::"Sales Shipment Header";
    end;

    procedure SetTransferShipment(TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        SourceTransferShipmentHeader := TransferShipmentHeader;
        SourceDocumentTableId := Database::"Transfer Shipment Header";
    end;

    procedure GetSourceTableId(): Integer
    begin
        exit(SourceDocumentTableId);
    end;

    procedure GetSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        SalesShipmentHeader := SourceSalesShipmentHeader;
    end;

    procedure GetTransferShipment(var TransferShipmentHeader: Record "Transfer Shipment Header")
    begin
        TransferShipmentHeader := SourceTransferShipmentHeader;
    end;

    procedure Clear()
    begin
        System.Clear(SourceSalesShipmentHeader);
        System.Clear(SourceTransferShipmentHeader);
        SourceDocumentTableId := 0;
    end;
}
