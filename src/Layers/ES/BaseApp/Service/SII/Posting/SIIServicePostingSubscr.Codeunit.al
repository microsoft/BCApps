// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

#pragma warning disable AS0088
codeunit 7000079 "SII Service Posting Subscr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterPostWithLines', '', true, true)]
    local procedure OnAfterPostWithLines(var PassedServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    var
        ServSIIManagement: Codeunit "Serv. SII Management";
    begin
        ServSIIManagement.OnAfterPostServiceDoc(PassedServiceHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnFinalizeInvoiceDocumentOnBeforeServiceInvoiceHeaderInsert', '', true, true)]
    local procedure OnFinalizeInvoiceDocumentOnBeforeServiceInvoiceHeaderInsert(var ServiceInvoiceHeaderToInsert: Record "Service Invoice Header"; var TempServiceInvoiceHeader: Record "Service Invoice Header" temporary; var TempServiceHeader: Record "Service Header" temporary)
    begin
        ServiceInvoiceHeaderToInsert.SetSIIFirstSummaryDocNo(ServiceInvoiceHeaderToInsert.GetSIIFirstSummaryDocNo());
        ServiceInvoiceHeaderToInsert.SetSIILastSummaryDocNo(ServiceInvoiceHeaderToInsert.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnFinalizeCrMemoDocumentOnBeforeServiceCreditMemoHeaderInsert', '', true, true)]
    local procedure OnFinalizeCrMemoDocumentOnBeforeServiceCreditMemoHeaderInsert(var ServiceCrMemoHeaderToInsert: Record "Service Cr.Memo Header"; var TempServiceCrMemoHeader: Record "Service Cr.Memo Header" temporary; var TempServiceHeader: Record "Service Header" temporary)
    begin
        ServiceCrMemoHeaderToInsert.SetSIIFirstSummaryDocNo(ServiceCrMemoHeaderToInsert.GetSIIFirstSummaryDocNo());
        ServiceCrMemoHeaderToInsert.SetSIILastSummaryDocNo(ServiceCrMemoHeaderToInsert.GetSIILastSummaryDocNo());
    end;
}
