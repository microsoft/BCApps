// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Reflection;

codeunit 10151 "E-Invoice Cancel Request Batch"
{

    trigger OnRun()
    begin
        CancelAfter72hrs();
        CancelRequestStatusBatch();
    end;

    local procedure CancelRequestStatusBatch()
    begin
        ProcessResponsePostedSalesInvoices();
        ProcessResponsePostedSalesCrMemos();
        ProcessResponsePostedSalesShipments();
        ProcessResponsePostedTransferShipments();
        ProcessResponseCustomerLedgerEntries();

        OnAfterCancelRequsetStatusBatch();
    end;

    local procedure ProcessResponsePostedSalesInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesInvoiceHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesInvoiceHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesInvoiceHeader."Electronic Document Status"::"Cancel In Progress",
          SalesInvoiceHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(SalesInvoiceHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedSalesCrMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesCrMemoHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesCrMemoHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesCrMemoHeader."Electronic Document Status"::"Cancel In Progress",
          SalesCrMemoHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(SalesCrMemoHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedSalesShipments()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        TransferShipmentHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        TransferShipmentHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          TransferShipmentHeader."Electronic Document Status"::"Cancel In Progress",
          TransferShipmentHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(TransferShipmentHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedTransferShipments()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesShipmentHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesShipmentHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesShipmentHeader."Electronic Document Status"::"Cancel In Progress",
          SalesShipmentHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(SalesShipmentHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponseCustomerLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        CustLedgerEntry.SetFilter("CFDI Cancellation ID", '<>%1', '');
        CustLedgerEntry.SetFilter(
          "Electronic Document Status", '%1|%2',
          CustLedgerEntry."Electronic Document Status"::"Cancel In Progress",
          CustLedgerEntry."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(CustLedgerEntry);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CancelAfter72hrs()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if GeneralLedgerSetup.Get() and not GeneralLedgerSetup."Cancel on Time Expiration" then
            exit;

        CancelAfter72hrsSalesInvoices();
        CancelAfter72hrsSalesCrMemos();
        CancelAfter72hrsSalesShipments();
        CancelAfter72hrsTransferShipments();
        CancelAfter72hrsCustomerLedgerEntries();

        OnAfterCancelAfter72Hrs();
    end;

    local procedure CancelAfter72hrsSalesInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesInvoiceHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesInvoiceHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesInvoiceHeader."Electronic Document Status"::"Cancel In Progress",
          SalesInvoiceHeader."Electronic Document Status"::"Cancel Error");
        SalesInvoiceHeader.SetFilter("Date/Time Cancel Sent", '>%1&<%2', 0DT, GetDateTime72HoursAgo());
        RecRef.GetTable(SalesInvoiceHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.SetCancelManual(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CancelAfter72hrsSalesCrMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesCrMemoHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesCrMemoHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesCrMemoHeader."Electronic Document Status"::"Cancel In Progress",
          SalesCrMemoHeader."Electronic Document Status"::"Cancel Error");
        SalesCrMemoHeader.SetFilter("Date/Time Cancel Sent", '>%1&<%2', 0DT, GetDateTime72HoursAgo());
        RecRef.GetTable(SalesCrMemoHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.SetCancelManual(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CancelAfter72hrsSalesShipments()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        TransferShipmentHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        TransferShipmentHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          TransferShipmentHeader."Electronic Document Status"::"Cancel In Progress",
          TransferShipmentHeader."Electronic Document Status"::"Cancel Error");
        TransferShipmentHeader.SetFilter("Date/Time Cancel Sent", '>%1&<%2', 0DT, GetDateTime72HoursAgo());
        RecRef.GetTable(TransferShipmentHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.SetCancelManual(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CancelAfter72hrsTransferShipments()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        SalesShipmentHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        SalesShipmentHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          SalesShipmentHeader."Electronic Document Status"::"Cancel In Progress",
          SalesShipmentHeader."Electronic Document Status"::"Cancel Error");
        SalesShipmentHeader.SetFilter("Date/Time Cancel Sent", '>%1&<%2', 0DT, GetDateTime72HoursAgo());
        RecRef.GetTable(SalesShipmentHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.SetCancelManual(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CancelAfter72hrsCustomerLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        CustLedgerEntry.SetFilter("CFDI Cancellation ID", '<>%1', '');
        CustLedgerEntry.SetFilter(
          "Electronic Document Status", '%1|%2',
          CustLedgerEntry."Electronic Document Status"::"Cancel In Progress",
          CustLedgerEntry."Electronic Document Status"::"Cancel Error");
        CustLedgerEntry.SetFilter("Date/Time Cancel Sent", '>%1&<%2', 0DT, GetDateTime72HoursAgo());
        RecRef.GetTable(CustLedgerEntry);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.SetCancelManual(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure GetDateTime72HoursAgo(): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(
            TypeHelper.GetCurrentDateTimeInUserTimeZone() - 3 * 24 * 3600 * 1000);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCancelRequsetStatusBatch()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCancelAfter72Hrs()
    begin
    end;
}

