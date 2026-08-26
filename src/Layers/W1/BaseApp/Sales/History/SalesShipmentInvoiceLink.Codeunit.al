// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Ledger;

codeunit 1300 "Sales Shipment-Invoice Link"
{
    Access = Internal;

    var
        NoRelatedShipmentsMsg: Label 'There are no posted sales shipments related to sales invoice %1.', Comment = '%1 = the number of the posted sales invoice';
        NoRelatedInvoicesMsg: Label 'There are no posted sales invoices related to sales shipment %1.', Comment = '%1 = the number of the posted sales shipment';

    /// <summary>
    /// Shows the posted sales shipments that are related to a posted sales invoice.
    /// When exactly one shipment is related, it opens directly. Otherwise the related shipments are shown in a list.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice to find the related shipments for.</param>
    procedure ShowShipmentsForInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        if not GetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader) then begin
            Message(NoRelatedShipmentsMsg, SalesInvoiceHeader."No.");
            exit;
        end;

        if SalesShipmentHeader.Count() = 1 then
            Page.Run(Page::"Posted Sales Shipment", SalesShipmentHeader)
        else
            Page.Run(Page::"Posted Sales Shipments", SalesShipmentHeader);
    end;

    /// <summary>
    /// Shows the posted sales invoices that are related to a posted sales shipment.
    /// When exactly one invoice is related, it opens directly. Otherwise the related invoices are shown in a list.
    /// </summary>
    /// <param name="SalesShipmentHeader">The posted sales shipment to find the related invoices for.</param>
    procedure ShowInvoicesForShipment(SalesShipmentHeader: Record "Sales Shipment Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not GetInvoicesForShipment(SalesShipmentHeader, SalesInvoiceHeader) then begin
            Message(NoRelatedInvoicesMsg, SalesShipmentHeader."No.");
            exit;
        end;

        if SalesInvoiceHeader.Count() = 1 then
            Page.Run(Page::"Posted Sales Invoice", SalesInvoiceHeader)
        else
            Page.Run(Page::"Posted Sales Invoices", SalesInvoiceHeader);
    end;

    /// <summary>
    /// Finds the posted sales shipments that are related to a posted sales invoice.
    /// The relation is resolved from the item ledger entries that the invoice invoiced, and from the shipment
    /// that individual invoice lines were created from.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice to find the related shipments for.</param>
    /// <param name="SalesShipmentHeader">Returns the related shipments as a marked-only record set.</param>
    /// <returns>True if at least one related shipment was found; otherwise false.</returns>
    procedure GetShipmentsForInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentHeader: Record "Sales Shipment Header"): Boolean
    begin
        SalesShipmentHeader.Reset();
        SalesShipmentHeader.ClearMarks();

        MarkShipmentsFromItemEntries(SalesInvoiceHeader."No.", SalesShipmentHeader);
        MarkShipmentsFromInvoiceLines(SalesInvoiceHeader."No.", SalesShipmentHeader);
        OnAfterGetShipmentsForInvoice(SalesInvoiceHeader, SalesShipmentHeader);

        SalesShipmentHeader.MarkedOnly(true);
        exit(SalesShipmentHeader.FindFirst());
    end;

    /// <summary>
    /// Finds the posted sales invoices that are related to a posted sales shipment.
    /// The relation is resolved from the item ledger entries that the shipment created, and from the invoice
    /// lines that were created from the shipment.
    /// </summary>
    /// <param name="SalesShipmentHeader">The posted sales shipment to find the related invoices for.</param>
    /// <param name="SalesInvoiceHeader">Returns the related invoices as a marked-only record set.</param>
    /// <returns>True if at least one related invoice was found; otherwise false.</returns>
    procedure GetInvoicesForShipment(SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.ClearMarks();

        MarkInvoicesFromItemEntries(SalesShipmentHeader."No.", SalesInvoiceHeader);
        MarkInvoicesFromInvoiceLines(SalesShipmentHeader."No.", SalesInvoiceHeader);
        OnAfterGetInvoicesForShipment(SalesShipmentHeader, SalesInvoiceHeader);

        SalesInvoiceHeader.MarkedOnly(true);
        exit(SalesInvoiceHeader.FindFirst());
    end;

    local procedure MarkShipmentsFromItemEntries(InvoiceNo: Code[20]; var SalesShipmentHeader: Record "Sales Shipment Header")
    var
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        if not SetInvoicedItemEntryFilters(ValueItemLedgerEntries) then
            exit;

        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_No, InvoiceNo);
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            MarkShipmentHeader(SalesShipmentHeader, ValueItemLedgerEntries.Item_Ledg_Document_No);
        ValueItemLedgerEntries.Close();
    end;

    local procedure MarkInvoicesFromItemEntries(ShipmentNo: Code[20]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        ValueItemLedgerEntries: Query "Value Item Ledger Entries";
    begin
        if not SetInvoicedItemEntryFilters(ValueItemLedgerEntries) then
            exit;

        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_No, ShipmentNo);
        ValueItemLedgerEntries.Open();
        while ValueItemLedgerEntries.Read() do
            MarkInvoiceHeader(SalesInvoiceHeader, ValueItemLedgerEntries.Value_Entry_Doc_No);
        ValueItemLedgerEntries.Close();
    end;

    local procedure SetInvoicedItemEntryFilters(var ValueItemLedgerEntries: Query "Value Item Ledger Entries"): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        if not (ValueEntry.ReadPermission and ItemLedgerEntry.ReadPermission) then
            exit(false);

        ValueItemLedgerEntries.SetRange(Value_Entry_Doc_Type, Enum::"Item Ledger Document Type"::"Sales Invoice");
        ValueItemLedgerEntries.SetRange(Value_Entry_Type, Enum::"Cost Entry Type"::"Direct Cost");
        ValueItemLedgerEntries.SetFilter(Value_Entry_Invoiced_Qty, '<>%1', 0);
        ValueItemLedgerEntries.SetRange(Item_Ledg_Document_Type, Enum::"Item Ledger Document Type"::"Sales Shipment");
        ValueItemLedgerEntries.SetFilter(Item_Ledg_Invoice_Quantity, '<>%1', 0);
        exit(true);
    end;

    local procedure MarkShipmentsFromInvoiceLines(InvoiceNo: Code[20]; var SalesShipmentHeader: Record "Sales Shipment Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetLoadFields("Shipment No.");
        SalesInvoiceLine.SetRange("Document No.", InvoiceNo);
        SalesInvoiceLine.SetFilter("Shipment No.", '<>%1', '');
        if SalesInvoiceLine.FindSet() then
            repeat
                MarkShipmentHeader(SalesShipmentHeader, SalesInvoiceLine."Shipment No.");
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure MarkInvoicesFromInvoiceLines(ShipmentNo: Code[20]; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetLoadFields("Document No.");
        SalesInvoiceLine.SetCurrentKey("Shipment No.", "Shipment Line No.");
        SalesInvoiceLine.SetRange("Shipment No.", ShipmentNo);
        if SalesInvoiceLine.FindSet() then
            repeat
                MarkInvoiceHeader(SalesInvoiceHeader, SalesInvoiceLine."Document No.");
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure MarkShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; ShipmentNo: Code[20])
    begin
        if ShipmentNo = '' then
            exit;
        if SalesShipmentHeader.Get(ShipmentNo) then
            SalesShipmentHeader.Mark(true);
    end;

    local procedure MarkInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; InvoiceNo: Code[20])
    begin
        if InvoiceNo = '' then
            exit;
        if SalesInvoiceHeader.Get(InvoiceNo) then
            SalesInvoiceHeader.Mark(true);
    end;

    /// <summary>
    /// Raised after the posted sales shipments related to a posted sales invoice have been marked.
    /// Use it to mark additional shipments that are related through a custom relation.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice that the shipments were found for.</param>
    /// <param name="SalesShipmentHeader">The shipment record set that the related shipments are marked in.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetShipmentsForInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesShipmentHeader: Record "Sales Shipment Header")
    begin
    end;

    /// <summary>
    /// Raised after the posted sales invoices related to a posted sales shipment have been marked.
    /// Use it to mark additional invoices that are related through a custom relation.
    /// </summary>
    /// <param name="SalesShipmentHeader">The posted sales shipment that the invoices were found for.</param>
    /// <param name="SalesInvoiceHeader">The invoice record set that the related invoices are marked in.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetInvoicesForShipment(SalesShipmentHeader: Record "Sales Shipment Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}
