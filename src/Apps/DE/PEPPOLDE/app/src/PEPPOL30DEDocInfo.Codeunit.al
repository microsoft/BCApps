// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.DE;

using Microsoft.Peppol;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// DE-specific PEPPOL document info provider. Returns the buyer reference value pushed by
/// the EDocumentDE bridge to "PEPPOL30 DE Context" before export. All other methods pass through
/// to the W1 standard implementation.
/// </summary>
codeunit 37402 "PEPPOL30 DE Doc Info" implements "PEPPOL Document Info Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        StandardProvider: Codeunit "PEPPOL30";

    procedure GetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var InvoiceTypeCodeListID: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var DocumentCurrencyCodeListID: Text; var TaxCurrencyCode: Text; var TaxCurrencyCodeListID: Text; var AccountingCost: Text)
    begin
        StandardProvider.GetGeneralInfo(SalesHeader, ID, IssueDate, InvoiceTypeCode, InvoiceTypeCodeListID, Note, TaxPointDate, DocumentCurrencyCode, DocumentCurrencyCodeListID, TaxCurrencyCode, TaxCurrencyCodeListID, AccountingCost);
    end;

    procedure GetGeneralInfoBIS(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)
    begin
        StandardProvider.GetGeneralInfoBIS(SalesHeader, ID, IssueDate, InvoiceTypeCode, Note, TaxPointDate, DocumentCurrencyCode, AccountingCost);
    end;

    procedure GetInvoicePeriodInfo(var StartDate: Text; var EndDate: Text)
    begin
        StandardProvider.GetInvoicePeriodInfo(StartDate, EndDate);
    end;

    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        StandardProvider.GetOrderReferenceInfo(SalesHeader, OrderReferenceID);
    end;

    procedure GetOrderReferenceInfoBIS(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)
    begin
        StandardProvider.GetOrderReferenceInfoBIS(SalesHeader, OrderReferenceID);
    end;

    procedure GetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)
    begin
        StandardProvider.GetContractDocRefInfo(SalesHeader, ContractDocumentReferenceID, DocumentTypeCode, ContractRefDocTypeCodeListID, DocumentType);
    end;

    procedure GetBuyerReference(SalesHeader: Record "Sales Header") BuyerReference: Text
    var
        DEContext: Codeunit "PEPPOL30 DE Context";
    begin
        // Run W1 first to keep the standard fallback if no context is present.
        BuyerReference := StandardProvider.GetBuyerReference(SalesHeader);
        // DE override: when the EDocumentDE bridge pushed a buyer reference value, use it.
        if DEContext.HasContext() and (DEContext.GetBuyerReference() <> '') then
            BuyerReference := DEContext.GetBuyerReference();
    end;

    procedure GetCrMemoBillingReferenceInfo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var InvoiceDocRefID: Text; var InvoiceDocRefIssueDate: Text)
    begin
        StandardProvider.GetCrMemoBillingReferenceInfo(SalesCrMemoHeader, InvoiceDocRefID, InvoiceDocRefIssueDate);
    end;
}
