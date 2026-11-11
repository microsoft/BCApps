// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.RoleCenters;

#pragma warning disable AS0088
codeunit 7000027 "SII Sales Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateBillToCustomerNoOnSII', '', true, false)]
    local procedure SalesHeaderOnAfterValidateBillToCustomerNo(var SalesHeader: Record "Sales Header")
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SalesHeader.Validate("ID Type", SIIManagement.GetSalesIDType(SalesHeader."Bill-to Customer No.", SalesHeader."Correction Type", SalesHeader."Corrected Invoice No."));
        SIIManagement.UpdateSIIInfoInSalesDoc(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateCorrectedInvoiceNoOnSII', '', true, false)]
    local procedure SalesHeaderOnAfterValidateCorrectedInvoiceNo(var SalesHeader: Record "Sales Header")
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SalesHeader.Validate("ID Type", SIIManagement.GetSalesIDType(SalesHeader."Bill-to Customer No.", SalesHeader."Correction Type", SalesHeader."Corrected Invoice No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterInitRecord', '', true, false)]
    local procedure SalesHeaderOnAfterInitRecord(var SalesHeader: Record "Sales Header")
    var
        SIIManagement: Codeunit "SII Management";
    begin
        SIIManagement.UpdateSIIInfoInSalesDoc(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateEvent', 'VAT Prod. Posting Group', true, false)]
    local procedure SalesLineOnAfterValidateVATProdPostingGroup(var Rec: Record "Sales Line")
    var
        SIISchemeCodeMgt: Codeunit "SII Scheme Code Mgt.";
    begin
        SIISchemeCodeMgt.UpdateSalesSpecialSchemeCodeInSalesLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterCopyCustLedgerEntryFromGenJnlLine', '', true, false)]
    local procedure OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry."Invoice Type" := GenJournalLine."Sales Invoice Type";
        CustLedgerEntry."Cr. Memo Type" := GenJournalLine."Sales Cr. Memo Type";
        CustLedgerEntry."Special Scheme Code" := GenJournalLine."Sales Special Scheme Code";
        CustLedgerEntry."Succeeded Company Name" := GenJournalLine."Succeeded Company Name";
        CustLedgerEntry."Succeeded VAT Registration No." := GenJournalLine."Succeeded VAT Registration No.";
        CustLedgerEntry."ID Type" := GenJournalLine."ID Type";
        CustLedgerEntry."Issued By Third Party" := GenJournalLine."Issued By Third Party";
        CustLedgerEntry."Do Not Send To SII" := GenJournalLine."Do Not Send To SII";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Pstd. Sales Cr. Memo - Update", OnAfterRecordChanged, '', true, false)]
    local procedure OnAfterRecordChanged(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; xSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or
          (SalesCrMemoHeader."Operation Description" <> xSalesCrMemoHeader."Operation Description") or
          (SalesCrMemoHeader."Operation Description 2" <> xSalesCrMemoHeader."Operation Description 2") or
          (SalesCrMemoHeader."Special Scheme Code" <> xSalesCrMemoHeader."Special Scheme Code") or
          (SalesCrMemoHeader."Cr. Memo Type" <> xSalesCrMemoHeader."Cr. Memo Type") or
          (SalesCrMemoHeader."ID Type" <> xSalesCrMemoHeader."ID Type") or
          (SalesCrMemoHeader."Succeeded Company Name" <> xSalesCrMemoHeader."Succeeded Company Name") or
          (SalesCrMemoHeader."Succeeded VAT Registration No." <> xSalesCrMemoHeader."Succeeded VAT Registration No.") or
          (SalesCrMemoHeader.GetSIIFirstSummaryDocNo() <> xSalesCrMemoHeader.GetSIIFirstSummaryDocNo()) or
          (SalesCrMemoHeader.GetSIILastSummaryDocNo() <> xSalesCrMemoHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Sales Invoice - Update", OnAfterRecordIsChanged, '', true, false)]
    local procedure SalesInvoiceHeaderOnAfterRecordIsChanged(var SalesInvoiceHeader: Record "Sales Invoice Header"; xSalesInvoiceHeader: Record "Sales Invoice Header"; var RecordIsChanged: Boolean)
    begin
        RecordIsChanged := RecordIsChanged or
          (SalesInvoiceHeader."Operation Description" <> xSalesInvoiceHeader."Operation Description") or
          (SalesInvoiceHeader."Operation Description 2" <> xSalesInvoiceHeader."Operation Description 2") or
          (SalesInvoiceHeader."Special Scheme Code" <> xSalesInvoiceHeader."Special Scheme Code") or
          (SalesInvoiceHeader."Invoice Type" <> xSalesInvoiceHeader."Invoice Type") or
          (SalesInvoiceHeader."ID Type" <> xSalesInvoiceHeader."ID Type") or
          (SalesInvoiceHeader."Succeeded Company Name" <> xSalesInvoiceHeader."Succeeded Company Name") or
          (SalesInvoiceHeader."Succeeded VAT Registration No." <> xSalesInvoiceHeader."Succeeded VAT Registration No.") or
          (SalesInvoiceHeader."Issued By Third Party" <> xSalesInvoiceHeader."Issued By Third Party") or
          (SalesInvoiceHeader.GetSIIFirstSummaryDocNo() <> xSalesInvoiceHeader.GetSIIFirstSummaryDocNo()) or
          (SalesInvoiceHeader.GetSIILastSummaryDocNo() <> xSalesInvoiceHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Invoice Header - Edit", OnRunOnBeforeSalesInvoiceHeaderModify, '', true, false)]
    local procedure OnRunOnBeforeSalesInvoiceHeaderModify(var SalesInvoiceHeader: Record "Sales Invoice Header"; FromSalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader."Operation Description" := FromSalesInvoiceHeader."Operation Description";
        SalesInvoiceHeader."Operation Description 2" := FromSalesInvoiceHeader."Operation Description 2";
        SalesInvoiceHeader."Special Scheme Code" := FromSalesInvoiceHeader."Special Scheme Code";
        SalesInvoiceHeader."Invoice Type" := FromSalesInvoiceHeader."Invoice Type";
        SalesInvoiceHeader."ID Type" := FromSalesInvoiceHeader."ID Type";
        SalesInvoiceHeader."Succeeded Company Name" := FromSalesInvoiceHeader."Succeeded Company Name";
        SalesInvoiceHeader."Succeeded VAT Registration No." := FromSalesInvoiceHeader."Succeeded VAT Registration No.";
        SalesInvoiceHeader."Issued By Third Party" := FromSalesInvoiceHeader."Issued By Third Party";
        SalesInvoiceHeader.SetSIIFirstSummaryDocNo(FromSalesInvoiceHeader.GetSIIFirstSummaryDocNo());
        SalesInvoiceHeader.SetSIILastSummaryDocNo(FromSalesInvoiceHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Invoice Header - Edit", OnRunOnAfterSalesInvoiceHeaderEdit, '', true, false)]
    local procedure OnRunOnAfterSalesInvoiceHeaderEdit(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        UpdateSIIDocUploadState(SalesInvoiceHeader);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Credit Memo Hdr. - Edit", OnBeforeSalesCrMemoHeaderModify, '', true, false)]
    local procedure OnBeforeSalesCrMemoHeaderModify(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader."Operation Description" := FromSalesCrMemoHeader."Operation Description";
        SalesCrMemoHeader."Operation Description 2" := FromSalesCrMemoHeader."Operation Description 2";
        SalesCrMemoHeader."Special Scheme Code" := FromSalesCrMemoHeader."Special Scheme Code";
        SalesCrMemoHeader."Cr. Memo Type" := FromSalesCrMemoHeader."Cr. Memo Type";
        SalesCrMemoHeader."ID Type" := FromSalesCrMemoHeader."ID Type";
        SalesCrMemoHeader."Succeeded Company Name" := FromSalesCrMemoHeader."Succeeded Company Name";
        SalesCrMemoHeader."Succeeded VAT Registration No." := FromSalesCrMemoHeader."Succeeded VAT Registration No.";
        SalesCrMemoHeader."Issued By Third Party" := FromSalesCrMemoHeader."Issued By Third Party";
        SalesCrMemoHeader.SetSIIFirstSummaryDocNo(FromSalesCrMemoHeader.GetSIIFirstSummaryDocNo());
        SalesCrMemoHeader.SetSIILastSummaryDocNo(FromSalesCrMemoHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Credit Memo Hdr. - Edit", OnRunOnAfterSalesCrMemoHeaderEdit, '', true, false)]
    local procedure OnRunOnAfterSalesCrMemoHeaderEdit(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        UpdateSIIDocUploadState(SalesCrMemoHeader);
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice", OnPostLedgerEntryOnAfterCopyToGenJnlLine, '', true, false)]
    local procedure OnPostLedgerEntryOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        GenJnlLine."Sales Invoice Type" := SalesHeader."Invoice Type";
        GenJnlLine."Sales Cr. Memo Type" := SalesHeader."Cr. Memo Type";
        GenJnlLine."Sales Special Scheme Code" := SalesHeader."Special Scheme Code";
        GenJnlLine."Succeeded Company Name" := SalesHeader."Succeeded Company Name";
        GenJnlLine."Succeeded VAT Registration No." := SalesHeader."Succeeded VAT Registration No.";
        GenJnlLine."ID Type" := SalesHeader."ID Type";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeSalesInvHeaderInsert, '', true, false)]
    local procedure OnBeforeSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header")
    begin
        SalesInvHeader.SetSIIFirstSummaryDocNo(SalesHeader.GetSIIFirstSummaryDocNo());
        SalesInvHeader.SetSIILastSummaryDocNo(SalesHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforeSalesCrMemoHeaderInsert, '', true, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header")
    begin
        SalesCrMemoHeader.SetSIIFirstSummaryDocNo(SalesHeader.GetSIIFirstSummaryDocNo());
        SalesCrMemoHeader.SetSIILastSummaryDocNo(SalesHeader.GetSIILastSummaryDocNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SO Activities Calculate", OnAfterCalculateFieldValues, '', true, false)]
    local procedure OnAfterCalculateFieldValues(SalesCue: Record "Sales Cue"; var ReturnResults: Dictionary of [Text, Text])
    begin
        ReturnResults.Add(SalesCue.FieldName("Missing SII Entries"), Format(SalesCue."Missing SII Entries"));
        ReturnResults.Add(SalesCue.FieldName("Days Since Last SII Check"), Format(SalesCue."Days Since Last SII Check"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SO Activities Calculate", OnAfterEvaluateResults, '', true, false)]
    local procedure OnAfterEvaluateResults(ResultsDictionary: Dictionary of [Text, Text]; var SalesCue: Record "Sales Cue")
    var
        ResultValue: Text;
    begin
        if ResultsDictionary.Get(SalesCue.FieldName("Missing SII Entries"), ResultValue) then
            Evaluate(SalesCue."Missing SII Entries", ResultValue);
        if ResultsDictionary.Get(SalesCue.FieldName("Days Since Last SII Check"), ResultValue) then
            Evaluate(SalesCue."Days Since Last SII Check", ResultValue);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SO Activities Calculate", OnAfterCalculateCueFieldValues, '', true, false)]
    local procedure OnAfterCalculateCueFieldValues(var SalesCue: Record "Sales Cue")
    var
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        SalesCue."Missing SII Entries" := SIIRecreateMissingEntries.GetMissingEntriesCount();
        SalesCue."Days Since Last SII Check" := SIIRecreateMissingEntries.GetDaysSinceLastCheck();
    end;

}
