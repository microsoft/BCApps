#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.EServices.EDocument;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 10602 "Service Post Print NO"
{
    ObsoleteReason = 'This codeunit is deprecated and will be removed in a future release.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post+Print", 'OnGetReportOnBeforeExportServiceInvoice', '', true, true)]
    local procedure OnGetReportOnBeforeExportServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceHeader: Record "Service Header")
    var
        EInvoiceExportServiceInvoice: Codeunit "E-Invoice Export Serv. Invoice";
    begin
        if ServiceHeader."E-Invoice" then
            if ServiceInvoiceHeader.Find('=') then
                EInvoiceExportServiceInvoice.Run(ServiceInvoiceHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post+Print", 'OnGetReportOnBeforeExportServiceCrMemo', '', true, true)]
    local procedure OnGetReportOnBeforeExportServiceCrMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var ServiceHeader: Record "Service Header")
    var
        EInvoiceExportServiceCrMemo: Codeunit "E-Invoice Exp. Serv. Cr. Memo";
    begin
        if ServiceHeader."E-Invoice" then
            if ServiceCrMemoHeader.Find('=') then
                EInvoiceExportServiceCrMemo.Run(ServiceCrMemoHeader);
    end;


}
#endif