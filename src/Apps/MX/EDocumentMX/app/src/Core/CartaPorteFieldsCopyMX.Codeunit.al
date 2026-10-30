// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Inventory.Transfer;

codeunit 3372 "Carta Porte Fields Copy MX"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Header", OnBeforeInsertEvent, '', false, false)]
    local procedure CopyCartaPorteFieldsToSalesShipment(var Rec: Record "Sales Shipment Header"; RunTrigger: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec.IsTemporary() then
            exit;
        if not SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Order No.") then
            exit;
        Rec."SAT Transport Type" := SalesHeader."SAT Transport Type";
        Rec."SAT ISTMO" := SalesHeader."SAT ISTMO";
        Rec."SAT ISTMO Polo Origen" := SalesHeader."SAT ISTMO Polo Origen";
        Rec."SAT ISTMO Polo Destino" := SalesHeader."SAT ISTMO Polo Destino";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", OnBeforeInsertEvent, '', false, false)]
    local procedure CopyCartaPorteFieldsToTransferShipment(var Rec: Record "Transfer Shipment Header"; RunTrigger: Boolean)
    var
        TransferHeader: Record "Transfer Header";
    begin
        if Rec.IsTemporary() then
            exit;
        if not TransferHeader.Get(Rec."Transfer Order No.") then
            exit;
        Rec."SAT Transport Type" := TransferHeader."SAT Transport Type";
        Rec."SAT ISTMO" := TransferHeader."SAT ISTMO";
        Rec."SAT ISTMO Polo Origen" := TransferHeader."SAT ISTMO Polo Origen";
        Rec."SAT ISTMO Polo Destino" := TransferHeader."SAT ISTMO Polo Destino";
    end;
}
