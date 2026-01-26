#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

codeunit 10768 "Service Invoice Header - Edit"
{
    Permissions = TableData "Service Invoice Header" = rm;
    TableNo = "Service Invoice Header";
    ObsoleteReason = 'Replaced by W1 codeunit Service Inv. Header - Edit';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader := Rec;
        ServiceInvoiceHeader.LockTable();
        ServiceInvoiceHeader.Find();
        ServiceInvoiceHeader."Country/Region Code" := Rec."Country/Region Code";
        ServiceInvoiceHeader."Bill-to Country/Region Code" := Rec."Bill-to Country/Region Code";
        ServiceInvoiceHeader."Ship-to Country/Region Code" := Rec."Ship-to Country/Region Code";

        ServiceInvoiceHeader."Operation Description" := Rec."Operation Description";
        ServiceInvoiceHeader."Operation Description 2" := Rec."Operation Description 2";
        ServiceInvoiceHeader."Special Scheme Code" := Rec."Special Scheme Code";
        ServiceInvoiceHeader."Invoice Type" := Rec."Invoice Type";
        ServiceInvoiceHeader."ID Type" := Rec."ID Type";
        ServiceInvoiceHeader."Succeeded Company Name" := Rec."Succeeded Company Name";
        ServiceInvoiceHeader."Succeeded VAT Registration No." := Rec."Succeeded VAT Registration No.";
        ServiceInvoiceHeader."Issued By Third Party" := Rec."Issued By Third Party";
        ServiceInvoiceHeader.SetSIIFirstSummaryDocNo(Rec.GetSIIFirstSummaryDocNo());
        ServiceInvoiceHeader.SetSIILastSummaryDocNo(Rec.GetSIILastSummaryDocNo());

        OnRunOnBeforeServiceInvoiceHeaderModify(ServiceInvoiceHeader, Rec);
        ServiceInvoiceHeader.TestField("No.", Rec."No.");
        ServiceInvoiceHeader.Modify();
        Rec := ServiceInvoiceHeader;
        UpdateSIIDocUploadState(Rec);
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

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceInvoiceHeaderModify(var ServiceInvoiceHeader: Record "Service Invoice Header"; FromServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}
#endif
