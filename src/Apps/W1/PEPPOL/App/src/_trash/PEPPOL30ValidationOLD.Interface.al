// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Interface for validating sales documents against PEPPOL 3.0 compliance requirements.
/// Provides comprehensive validation methods for sales headers, lines, and posted documents
/// to ensure they meet PEPPOL electronic document standards and business rules.
/// </summary>
interface "PEPPOL30 Validation OLD"
{
    /// <summary>
    /// Validates a sales document for PEPPOL compliance.
    /// Checks required fields, currency codes, addresses, VAT registration numbers, and other PEPPOL requirements.
    /// </summary>
    /// <param name="SalesHeader">The sales header record to validate.</param>
    procedure CheckSalesDocument(SalesHeader: Record "Sales Header")

    /// <summary>
    /// Validates all sales document lines for PEPPOL compliance.
    /// Checks line-specific requirements for electronic document transmission.
    /// </summary>
    /// <param name="SalesHeader">The sales header record whose lines should be validated.</param>
    procedure CheckSalesDocumentLines(SalesHeader: Record "Sales Header")

    /// <summary>
    /// Validates an individual sales document line for PEPPOL compliance.
    /// Checks unit of measure codes, descriptions, tax categories, and other line-specific requirements.
    /// </summary>
    /// <param name="SalesLine">The sales line record to validate.</param>
    procedure CheckSalesDocumentLine(SalesLine: Record "Sales Line")

    /// <summary>
    /// Validates a posted sales invoice for PEPPOL compliance.
    /// Performs validation checks on the invoice header and related data.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice header to validate.</param>
    procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")

    /// <summary>
    /// Validates a posted sales credit memo for PEPPOL compliance.
    /// Performs validation checks on the credit memo header and related data.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo header to validate.</param>
    procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")

    /// <summary>
    /// Checks if a sales line has the required type and description for PEPPOL electronic documents.
    /// Validates that the line type and description meet PEPPOL requirements.
    /// </summary>
    /// <param name="SalesLine">The sales line record to check.</param>
    /// <returns>True if the line type and description are valid for PEPPOL; otherwise, false.</returns>
    procedure CheckSalesLineTypeAndDescription(SalesLine: Record "Sales Line"): Boolean
}