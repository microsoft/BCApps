// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Service.History;

codeunit 10152 "Serv.EInv.Cancel Request Batch"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Invoice Cancel Request Batch", 'OnAfterCancelRequsetStatusBatch', '', true, true)]
    local procedure OnAfterCancelRequestStatusBatch()
    begin
        ProcessResponsePostedServiceInvoices();
        ProcessResponsePostedServiceCrMemos();
    end;

    local procedure ProcessResponsePostedServiceInvoices()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        ServiceInvoiceHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        ServiceInvoiceHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          ServiceInvoiceHeader."Electronic Document Status"::"Cancel In Progress",
          ServiceInvoiceHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(ServiceInvoiceHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure ProcessResponsePostedServiceCrMemos()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        ServiceCrMemoHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        ServiceCrMemoHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          ServiceCrMemoHeader."Electronic Document Status"::"Cancel In Progress",
          ServiceCrMemoHeader."Electronic Document Status"::"Cancel Error");
        RecRef.GetTable(ServiceCrMemoHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.CancelDocumentRequestStatus(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Invoice Cancel Request Batch", 'OnAfterCancelAfter72Hrs', '', true, true)]
    local procedure OnAfterCancelAfter72Hrs()
    begin
        CancelAfter72hrsServiceInvoices();
        CancelAfter72hrsServiceCrMemos();
    end;

    local procedure CancelAfter72hrsServiceInvoices()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        ServiceInvoiceHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        ServiceInvoiceHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          ServiceInvoiceHeader."Electronic Document Status"::"Cancel In Progress",
          ServiceInvoiceHeader."Electronic Document Status"::"Cancel Error");
        ServiceInvoiceHeader.SetFilter("Date/Time Cancel Sent", '>%1&<%2', 0DT, GetDateTime72HoursAgo());
        RecRef.GetTable(ServiceInvoiceHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.SetCancelManual(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CancelAfter72hrsServiceCrMemos()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        RecRef: RecordRef;
    begin
        ServiceCrMemoHeader.SetFilter("CFDI Cancellation ID", '<>%1', '');
        ServiceCrMemoHeader.SetFilter(
          "Electronic Document Status", '%1|%2',
          ServiceCrMemoHeader."Electronic Document Status"::"Cancel In Progress",
          ServiceCrMemoHeader."Electronic Document Status"::"Cancel Error");
        ServiceCrMemoHeader.SetFilter("Date/Time Cancel Sent", '>%1&<%2', 0DT, GetDateTime72HoursAgo());
        RecRef.GetTable(ServiceCrMemoHeader);
        if RecRef.FindSet(true) then
            repeat
                EInvoiceMgt.SetCancelManual(RecRef);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure GetDateTime72HoursAgo(): DateTime
    var
        TypeHelper: Codeunit System.Reflection."Type Helper";
    begin
        exit(
            TypeHelper.GetCurrentDateTimeInUserTimeZone() - 3 * 24 * 3600 * 1000);
    end;
}