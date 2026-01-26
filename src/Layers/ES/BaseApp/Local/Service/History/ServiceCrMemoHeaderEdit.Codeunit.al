// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.VAT.Ledger;

codeunit 10769 "Service Cr. Memo Header - Edit"
{
    Permissions = TableData "Service Cr.Memo Header" = rm;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader := Rec;
        ServiceCrMemoHeader.LockTable();
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader."Operation Description" := Rec."Operation Description";
        ServiceCrMemoHeader."Operation Description 2" := Rec."Operation Description 2";
        ServiceCrMemoHeader."Special Scheme Code" := Rec."Special Scheme Code";
        ServiceCrMemoHeader."Cr. Memo Type" := Rec."Cr. Memo Type";
        OnRunOnBeforeServiceCrMemoHeaderModify(ServiceCrMemoHeader, Rec);
        ServiceCrMemoHeader."Issued By Third Party" := Rec."Issued By Third Party";
        ServiceCrMemoHeader.SetSIIFirstSummaryDocNo(Rec.GetSIIFirstSummaryDocNo());
        ServiceCrMemoHeader.SetSIILastSummaryDocNo(Rec.GetSIILastSummaryDocNo());

        ServiceCrMemoHeader.TestField("No.", Rec."No.");
        ServiceCrMemoHeader.Modify();
        Rec := ServiceCrMemoHeader;
        UpdateSIIDocUploadState(Rec);
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

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceCrMemoHeaderModify(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", 'OnIsCorrectiveCrMemoDiffPeriodOnAfterCheckSales', '', false, false)]
    local procedure OnIsCorrectiveCrMemoDiffPeriodOnAfterCheckSales(var VATEntry: Record "VAT Entry"; StartDateFormula: DateFormula; EndDateFormula: DateFormula; var Result: Boolean)
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceCrMemoHeader.Get(VATEntry."Document No.");
        if ServiceCrMemoHeader."Corrected Invoice No." = '' then
            Result := false
        else begin
            ServiceInvoiceHeader.Get(ServiceCrMemoHeader."Corrected Invoice No.");
            Result := not (ServiceInvoiceHeader."Posting Date" in
                        [CalcDate(StartDateFormula, ServiceCrMemoHeader."Posting Date") ..
                            CalcDate(EndDateFormula, ServiceCrMemoHeader."Posting Date")]);
        end;
    end;
}

