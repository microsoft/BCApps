// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.EServices.EDocument;

codeunit 10765 "Sales Invoice Header - Edit"
{
    Permissions = TableData "Sales Invoice Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader := Rec;
        SalesInvoiceHeader.LockTable();
        SalesInvoiceHeader.Find();
        SalesInvoiceHeader."Operation Description" := Rec."Operation Description";
        SalesInvoiceHeader."Operation Description 2" := Rec."Operation Description 2";
        SalesInvoiceHeader."Special Scheme Code" := Rec."Special Scheme Code";
        SalesInvoiceHeader."Invoice Type" := Rec."Invoice Type";
        SalesInvoiceHeader."ID Type" := Rec."ID Type";
        SalesInvoiceHeader."Succeeded Company Name" := Rec."Succeeded Company Name";
        SalesInvoiceHeader."Succeeded VAT Registration No." := Rec."Succeeded VAT Registration No.";
        SalesInvoiceHeader."Issued By Third Party" := Rec."Issued By Third Party";
        SalesInvoiceHeader.SetSIIFirstSummaryDocNo(Rec.GetSIIFirstSummaryDocNo());
        SalesInvoiceHeader.SetSIILastSummaryDocNo(Rec.GetSIILastSummaryDocNo());
        SalesInvoiceHeader."Dispute Status" := Rec."Dispute Status";

        OnRunOnBeforeSalesInvoiceHeaderModify(SalesInvoiceHeader, Rec);
        SalesInvoiceHeader.TestField("No.", Rec."No.");
        SalesInvoiceHeader.Modify();
        Rec := SalesInvoiceHeader;
        UpdateSIIDocUploadState(Rec);
    end;

    local procedure UpdateSIIDocUploadState(SalesInvoiceHeader: Record "Sales Invoice Header")
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
             SalesInvoiceHeader."Posting Date",
             SalesInvoiceHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignSalesInvoiceType(SalesInvoiceHeader."Invoice Type");
        SIIDocUploadState.AssignSalesSchemeCode(SalesInvoiceHeader."Special Scheme Code");
        SIISchemeCodeMgt.ValidateSalesSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := SalesInvoiceHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := SalesInvoiceHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := SalesInvoiceHeader."Succeeded VAT Registration No.";
        SIIDocUploadState."Issued By Third Party" := SalesInvoiceHeader."Issued By Third Party";
        SIIDocUploadState."First Summary Doc. No." := CopyStr(SalesInvoiceHeader.GetSIIFirstSummaryDocNo(), 1, 35);
        SIIDocUploadState."Last Summary Doc. No." := CopyStr(SalesInvoiceHeader.GetSIILastSummaryDocNo(), 1, 35);
        SIIDocUploadState.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSalesInvoiceHeaderModify(var SalesInvoiceHeader: Record "Sales Invoice Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

