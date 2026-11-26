// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Service.History;

#pragma warning disable AS0088
codeunit 7000078 "SII Service History Subscr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Page, Page::"Posted Serv. Cr. Memo - Update", 'OnBeforeRecordIsChangedOnSII', '', true, false)]
    local procedure OnBeforeRecordIsChangedOnSII(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; xServiceCrMemoHeader: Record "Service Cr.Memo Header"; var RecordIsChanged: Boolean)
    begin
        RecordIsChanged := RecordIsChanged or
          (ServiceCrMemoHeader."Operation Description" <> xServiceCrMemoHeader."Operation Description") or
          (ServiceCrMemoHeader."Operation Description 2" <> xServiceCrMemoHeader."Operation Description 2") or
          (ServiceCrMemoHeader."Special Scheme Code" <> xServiceCrMemoHeader."Special Scheme Code") or
          (ServiceCrMemoHeader."Cr. Memo Type" <> xServiceCrMemoHeader."Cr. Memo Type") or
          (ServiceCrMemoHeader."Issued By Third Party" <> xServiceCrMemoHeader."Issued By Third Party") or
          (ServiceCrMemoHeader.GetSIIFirstSummaryDocNo() <> xServiceCrMemoHeader.GetSIIFirstSummaryDocNo()) or
          (ServiceCrMemoHeader.GetSIILastSummaryDocNo() <> xServiceCrMemoHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Service Inv. - Update", 'OnAfterRecordChanged', '', true, true)]
    local procedure OnAfterRecordChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or
          (ServiceInvoiceHeader."Operation Description" <> xServiceInvoiceHeader."Operation Description") or
          (ServiceInvoiceHeader."Operation Description 2" <> xServiceInvoiceHeader."Operation Description 2") or
          (ServiceInvoiceHeader."Special Scheme Code" <> xServiceInvoiceHeader."Special Scheme Code") or
          (ServiceInvoiceHeader."Invoice Type" <> xServiceInvoiceHeader."Invoice Type") or
          (ServiceInvoiceHeader."ID Type" <> xServiceInvoiceHeader."ID Type") or
          (ServiceInvoiceHeader."Succeeded Company Name" <> xServiceInvoiceHeader."Succeeded Company Name") or
          (ServiceInvoiceHeader."Succeeded VAT Registration No." <> xServiceInvoiceHeader."Succeeded VAT Registration No.") or
          (ServiceInvoiceHeader."Issued By Third Party" <> xServiceInvoiceHeader."Issued By Third Party") or
          (ServiceInvoiceHeader.GetSIIFirstSummaryDocNo() <> xServiceInvoiceHeader.GetSIIFirstSummaryDocNo()) or
          (ServiceInvoiceHeader.GetSIILastSummaryDocNo() <> xServiceInvoiceHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', true, true)]
    local procedure OnOnRunOnBeforeTestFieldNo(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader."Operation Description" := ServiceInvoiceHeaderRec."Operation Description";
        ServiceInvoiceHeader."Operation Description 2" := ServiceInvoiceHeaderRec."Operation Description 2";
        ServiceInvoiceHeader."Special Scheme Code" := ServiceInvoiceHeaderRec."Special Scheme Code";
        ServiceInvoiceHeader."Invoice Type" := ServiceInvoiceHeaderRec."Invoice Type";
        ServiceInvoiceHeader."ID Type" := ServiceInvoiceHeaderRec."ID Type";
        ServiceInvoiceHeader."Succeeded Company Name" := ServiceInvoiceHeaderRec."Succeeded Company Name";
        ServiceInvoiceHeader."Succeeded VAT Registration No." := ServiceInvoiceHeaderRec."Succeeded VAT Registration No.";
        ServiceInvoiceHeader."Issued By Third Party" := ServiceInvoiceHeaderRec."Issued By Third Party";
        ServiceInvoiceHeader.SetSIIFirstSummaryDocNo(ServiceInvoiceHeaderRec.GetSIIFirstSummaryDocNo());
        ServiceInvoiceHeader.SetSIILastSummaryDocNo(ServiceInvoiceHeaderRec.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Inv. Header - Edit", 'OnRunOnAfterServiceInvoiceHeaderEdit', '', true, true)]
    local procedure OnRunOnAfterServiceInvoiceHeaderEdit(var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        UpdateSIIDocUploadState(ServiceInvoiceHeader);
    end;

    local procedure UpdateSIIDocUploadState(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        xSIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::Invoice.AsInteger(),
             ServiceInvoiceHeader."Posting Date",
             ServiceInvoiceHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignSalesInvoiceType(ServiceInvoiceHeader."Invoice Type");
        SIIDocUploadState.AssignSalesSchemeCode(ServiceInvoiceHeader."Special Scheme Code");
        SIISchemeCodeMgt.ValidateServiceSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := ServiceInvoiceHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := ServiceInvoiceHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := ServiceInvoiceHeader."Succeeded VAT Registration No.";
        SIIDocUploadState."Issued By Third Party" := ServiceInvoiceHeader."Issued By Third Party";
        SIIDocUploadState."First Summary Doc. No." := CopyStr(ServiceInvoiceHeader.GetSIIFirstSummaryDocNo(), 1, 35);
        SIIDocUploadState."Last Summary Doc. No." := CopyStr(ServiceInvoiceHeader.GetSIILastSummaryDocNo(), 1, 35);
        SIIDocUploadState.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Cr. Memo Header - Edit", 'OnRunOnAfterServiceCrMemoHeaderFind', '', true, false)]
    local procedure OnRunOnAfterServiceCrMemoHeaderFind(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoHeader."Operation Description" := FromServiceCrMemoHeader."Operation Description";
        ServiceCrMemoHeader."Operation Description 2" := FromServiceCrMemoHeader."Operation Description 2";
        ServiceCrMemoHeader."Special Scheme Code" := FromServiceCrMemoHeader."Special Scheme Code";
        ServiceCrMemoHeader."Cr. Memo Type" := FromServiceCrMemoHeader."Cr. Memo Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Cr. Memo Header - Edit", 'OnRunOnBeforeTestFieldNo', '', true, false)]
    local procedure OnRunOnBeforeTestFieldNo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        ServiceCrMemoHeader."Issued By Third Party" := FromServiceCrMemoHeader."Issued By Third Party";
        ServiceCrMemoHeader.SetSIIFirstSummaryDocNo(FromServiceCrMemoHeader.GetSIIFirstSummaryDocNo());
        ServiceCrMemoHeader.SetSIILastSummaryDocNo(FromServiceCrMemoHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Cr. Memo Header - Edit", 'OnRunOnAfterServiceCrMemoHeaderEdit', '', true, false)]
    local procedure OnRunOnAfterServiceCrMemoHeaderEdit(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
        UpdateSIIDocUploadState(ServiceCrMemoHeader);
    end;

    local procedure UpdateSIIDocUploadState(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        xSIIDocUploadState: Record "SII Doc. Upload State";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIManagement: Codeunit "SII Management";
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        if not SIIManagement.IsSIISetupEnabled() then
            exit;

        if not SIIDocUploadState.GetSIIDocUploadStateByDocument(
             SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(),
             SIIDocUploadState."Document Type"::"Credit Memo".AsInteger(),
             ServiceCrMemoHeader."Posting Date",
             ServiceCrMemoHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignSalesCreditMemoType(ServiceCrMemoHeader."Cr. Memo Type");
        SIIDocUploadState.AssignSalesSchemeCode(ServiceCrMemoHeader."Special Scheme Code");
        SIISchemeCodeMgt.ValidateServiceSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState."Is Credit Memo Removal" := SIIDocUploadState.IsCreditMemoRemoval();
        SIIDocUploadState."Issued By Third Party" := ServiceCrMemoHeader."Issued By Third Party";
        SIIDocUploadState."First Summary Doc. No." := CopyStr(ServiceCrMemoHeader.GetSIIFirstSummaryDocNo(), 1, 35);
        SIIDocUploadState."Last Summary Doc. No." := CopyStr(ServiceCrMemoHeader.GetSIILastSummaryDocNo(), 1, 35);
        SIIDocUploadState.Modify();
    end;
}
