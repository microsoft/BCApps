// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.EServices.EDocument;
using Microsoft.Sales.Receivables;

codeunit 1408 "Sales Credit Memo Hdr. - Edit"
{
    Permissions = TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Copy(Rec);
        SalesCrMemoHeader.ReadIsolation(IsolationLevel::UpdLock);
        SalesCrMemoHeader.Find();
        SalesCrMemoHeader."Shipping Agent Code" := Rec."Shipping Agent Code";
        SalesCrMemoHeader."Shipping Agent Service Code" := Rec."Shipping Agent Service Code";
        SalesCrMemoHeader."Package Tracking No." := Rec."Package Tracking No.";
        SalesCrMemoHeader."Company Bank Account Code" := Rec."Company Bank Account Code";
        SalesCrMemoHeader."Operation Description" := Rec."Operation Description";
        SalesCrMemoHeader."Operation Description 2" := Rec."Operation Description 2";
        SalesCrMemoHeader."Special Scheme Code" := Rec."Special Scheme Code";
        SalesCrMemoHeader."Cr. Memo Type" := Rec."Cr. Memo Type";
        SalesCrMemoHeader."Correction Type" := Rec."Correction Type";
        SalesCrMemoHeader."Corrected Invoice No." := Rec."Corrected Invoice No.";
        SalesCrMemoHeader."ID Type" := Rec."ID Type";
        SalesCrMemoHeader."Succeeded Company Name" := Rec."Succeeded Company Name";
        SalesCrMemoHeader."Succeeded VAT Registration No." := Rec."Succeeded VAT Registration No.";
        SalesCrMemoHeader."Issued By Third Party" := Rec."Issued By Third Party";
        SalesCrMemoHeader.SetSIIFirstSummaryDocNo(Rec.GetSIIFirstSummaryDocNo());
        SalesCrMemoHeader.SetSIILastSummaryDocNo(Rec.GetSIILastSummaryDocNo());
        SalesCrMemoHeader."Posting Description" := Rec."Posting Description";
        OnBeforeSalesCrMemoHeaderModify(SalesCrMemoHeader, Rec);
        SalesCrMemoHeader.TestField("No.", Rec."No.");
        SalesCrMemoHeader.Modify();
        Rec := SalesCrMemoHeader;
        UpdateSIIDocUploadState(Rec);
        UpdateCustLedgerEntry(Rec);

        OnRunOnAfterSalesCrMemoHeaderEdit(Rec);
    end;

    local procedure UpdateSIIDocUploadState(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
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
             SalesCrMemoHeader."Posting Date",
             SalesCrMemoHeader."No.")
        then
            exit;

        xSIIDocUploadState := SIIDocUploadState;
        SIIDocUploadState.AssignSalesCreditMemoType(SalesCrMemoHeader."Cr. Memo Type");
        SIIDocUploadState.AssignSalesSchemeCode(SalesCrMemoHeader."Special Scheme Code");
        SIISchemeCodeMgt.ValidateSalesSpecialRegimeCodeInSIIDocUploadState(xSIIDocUploadState, SIIDocUploadState);
        SIIDocUploadState.IDType := SalesCrMemoHeader."ID Type";
        SIIDocUploadState."Succeeded Company Name" := SalesCrMemoHeader."Succeeded Company Name";
        SIIDocUploadState."Succeeded VAT Registration No." := SalesCrMemoHeader."Succeeded VAT Registration No.";
        SIIDocUploadState."Issued By Third Party" := SIIDocUploadState."Issued By Third Party";
        SIIDocUploadState."Is Credit Memo Removal" := SIIDocUploadState.IsCreditMemoRemoval();
        SIIDocUploadState."First Summary Doc. No." := CopyStr(SalesCrMemoHeader.GetSIIFirstSummaryDocNo(), 1, 35);
        SIIDocUploadState."Last Summary Doc. No." := CopyStr(SalesCrMemoHeader.GetSIILastSummaryDocNo(), 1, 35);
        SIIDocUploadState.Modify();
    end;

    local procedure UpdateCustLedgerEntry(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not GetCustLedgerEntry(CustLedgerEntry, SalesCrMemoHeader) then
            exit;
        CustLedgerEntry.Description := SalesCrMemoHeader."Posting Description";
        OnBeforeUpdateCustLedgerEntryAfterSetValues(CustLedgerEntry, SalesCrMemoHeader);
        Codeunit.Run(Codeunit::"Cust. Entry-Edit", CustLedgerEntry);
    end;

    local procedure GetCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Boolean
    begin
        if SalesCrMemoHeader."Cust. Ledger Entry No." = 0 then
            exit(false);
        CustLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        exit(CustLedgerEntry.Get(SalesCrMemoHeader."Cust. Ledger Entry No."));
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeSalesCrMemoHeaderModify(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgerEntryAfterSetValues(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSalesCrMemoHeaderEdit(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
}
