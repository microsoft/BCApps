// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 134861 "Sales Shpt.-Inv. Link Subscr."
{
    EventSubscriberInstance = Manual;

    var
        ShipmentNo: Code[20];
        InvoiceNo: Code[20];

    procedure SetShipmentNo(NewShipmentNo: Code[20])
    begin
        ShipmentNo := NewShipmentNo;
    end;

    procedure SetInvoiceNo(NewInvoiceNo: Code[20])
    begin
        InvoiceNo := NewInvoiceNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Shipment-Invoice Link", 'OnAfterGetShipmentsForInvoice', '', false, false)]
    local procedure MarkAdditionalShipmentOnAfterGetShipmentsForInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        if ShipmentNo = '' then
            exit;
        if SalesShipmentHeader.Get(ShipmentNo) then
            SalesShipmentHeader.Mark(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Shipment-Invoice Link", 'OnAfterGetInvoicesForShipment', '', false, false)]
    local procedure MarkAdditionalInvoiceOnAfterGetInvoicesForShipment(SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if InvoiceNo = '' then
            exit;
        if SalesInvoiceHeader.Get(InvoiceNo) then
            SalesInvoiceHeader.Mark(true);
    end;
}
