// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 37202 "PEPPOL30 Validation" implements "PEPPOL30 Validation"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        CheckSalesDocument(Rec);
        CheckSalesDocumentLines(Rec);
    end;

    /// <summary>
    /// Validates a sales document header against PEPPOL 3.0 requirements.
    /// Checks mandatory fields, formats, and business rules at the document level.
    /// </summary>
    /// <param name="SalesHeader">The sales header record to validate.</param>
    procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocument(SalesHeader);
    end;

    /// <summary>
    /// Validates all sales document lines associated with a sales header against PEPPOL 3.0 requirements.
    /// Iterates through all lines and performs line-level validation checks.
    /// </summary>
    /// <param name="SalesHeader">The sales header record whose lines should be validated.</param>
    procedure CheckSalesDocumentLines(SalesHeader: Record "Sales Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocumentLines(SalesHeader);
    end;

    /// <summary>
    /// Validates a single sales document line against PEPPOL 3.0 requirements.
    /// Checks line-specific mandatory fields, formats, and business rules.
    /// </summary>
    /// <param name="SalesLine">The sales line record to validate.</param>
    procedure CheckSalesDocumentLine(SalesLine: Record "Sales Line")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocumentLine(SalesLine);
    end;

    /// <summary>
    /// Validates a posted sales invoice against PEPPOL 3.0 requirements.
    /// Performs validation checks specific to posted sales invoice documents.
    /// </summary>
    /// <param name="SalesInvoiceHeader">The posted sales invoice header record to validate.</param>
    procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesInvoice(SalesInvoiceHeader);
    end;

    /// <summary>
    /// Validates a posted sales credit memo against PEPPOL 3.0 requirements.
    /// Performs validation checks specific to posted sales credit memo documents.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The posted sales credit memo header record to validate.</param>
    procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesCreditMemo(SalesCrMemoHeader);
    end;

    /// <summary>
    /// Validates the type and description fields of a sales line to ensure PEPPOL 3.0 compliance.
    /// Checks that the line type is valid and that required description fields are properly filled.
    /// </summary>
    /// <param name="SalesLine">The sales line record to validate.</param>
    /// <returns>True if the sales line type and description are valid, false otherwise.</returns>
    procedure CheckSalesLineTypeAndDescription(SalesLine: Record "Sales Line"): Boolean
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        exit(PEPPOL30ValidationImpl.CheckSalesLineTypeAndDescription(SalesLine));
    end;
}
