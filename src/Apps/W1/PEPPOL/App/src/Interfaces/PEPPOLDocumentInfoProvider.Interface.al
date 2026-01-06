// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

interface "PEPPOL Document Info Provider"
{
    /// <summary>
    /// Gets general information for non-BIS (full) PEPPOL document creation including list identifiers and tax currency.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ID">Return value: Document ID.</param>
    /// <param name="IssueDate">Return value: Document issue date.</param>
    /// <param name="InvoiceTypeCode">Return value: Invoice type code.</param>
    /// <param name="InvoiceTypeCodeListID">Return value: Invoice type code list ID.</param>
    /// <param name="Note">Return value: Document note.</param>
    /// <param name="TaxPointDate">Return value: Tax point date.</param>
    /// <param name="DocumentCurrencyCode">Return value: Document currency code.</param>
    /// <param name="DocumentCurrencyCodeListID">Return value: Document currency code list ID.</param>
    /// <param name="TaxCurrencyCode">Return value: Tax currency code.</param>
    /// <param name="TaxCurrencyCodeListID">Return value: Tax currency code list ID.</param>
    /// <param name="AccountingCost">Return value: Accounting cost.</param>
    procedure GetGeneralInfo(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var InvoiceTypeCodeListID: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var DocumentCurrencyCodeListID: Text; var TaxCurrencyCode: Text; var TaxCurrencyCodeListID: Text; var AccountingCost: Text)

    /// <summary>
    /// Gets general information for PEPPOL BIS format document creation.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ID">Return value: Document ID.</param>
    /// <param name="IssueDate">Return value: Document issue date.</param>
    /// <param name="InvoiceTypeCode">Return value: Invoice type code.</param>
    /// <param name="Note">Return value: Document note.</param>
    /// <param name="TaxPointDate">Return value: Tax point date.</param>
    /// <param name="DocumentCurrencyCode">Return value: Document currency code.</param>
    /// <param name="AccountingCost">Return value: Accounting cost.</param>
    procedure GetGeneralInfoBIS(SalesHeader: Record "Sales Header"; var ID: Text; var IssueDate: Text; var InvoiceTypeCode: Text; var Note: Text; var TaxPointDate: Text; var DocumentCurrencyCode: Text; var AccountingCost: Text)

    /// <summary>
    /// Gets invoice period information for PEPPOL documents.
    /// </summary>
    /// <param name="StartDate">Return value: Invoice period start date.</param>
    /// <param name="EndDate">Return value: Invoice period end date.</param>
    procedure GetInvoicePeriodInfo(var StartDate: Text; var EndDate: Text)

    /// <summary>
    /// Gets order reference information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="OrderReferenceID">Return value: Order reference ID.</param>
    procedure GetOrderReferenceInfo(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)

    /// <summary>
    /// Gets order reference information for PEPPOL BIS format.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="OrderReferenceID">Return value: Order reference ID.</param>
    procedure GetOrderReferenceInfoBIS(SalesHeader: Record "Sales Header"; var OrderReferenceID: Text)

    /// <summary>
    /// Gets contract document reference information from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <param name="ContractDocumentReferenceID">Return value: Contract document reference ID.</param>
    /// <param name="DocumentTypeCode">Return value: Document type code.</param>
    /// <param name="ContractRefDocTypeCodeListID">Return value: Contract reference document type code list ID.</param>
    /// <param name="DocumentType">Return value: Document type.</param>
    procedure GetContractDocRefInfo(SalesHeader: Record "Sales Header"; var ContractDocumentReferenceID: Text; var DocumentTypeCode: Text; var ContractRefDocTypeCodeListID: Text; var DocumentType: Text)

    /// <summary>
    /// Gets the buyer reference from the sales header.
    /// </summary>
    /// <param name="SalesHeader">The sales header record.</param>
    /// <returns>The buyer reference text.</returns>
    procedure GetBuyerReference(SalesHeader: Record "Sales Header") BuyerReference: Text

    /// <summary>
    /// Gets credit memo billing reference information for referencing the original invoice.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo header.</param>
    /// <param name="InvoiceDocRefID">Return value: Invoice document reference ID.</param>
    /// <param name="InvoiceDocRefIssueDate">Return value: Invoice document reference issue date.</param>
    procedure GetCrMemoBillingReferenceInfo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var InvoiceDocRefID: Text; var InvoiceDocRefIssueDate: Text)
}