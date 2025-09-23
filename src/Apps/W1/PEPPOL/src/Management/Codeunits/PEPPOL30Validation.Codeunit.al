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

    procedure CheckSalesDocument(SalesHeader: Record "Sales Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocument(SalesHeader);
    end;

    procedure CheckSalesDocumentLines(SalesHeader: Record "Sales Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocumentLines(SalesHeader);
    end;

    procedure CheckSalesDocumentLine(SalesLine: Record "Sales Line")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocumentLine(SalesLine);
    end;

    procedure CheckSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesInvoice(SalesInvoiceHeader);
    end;

    procedure CheckSalesCreditMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesCreditMemo(SalesCrMemoHeader);
    end;

    procedure CheckSalesLineTypeAndDescription(SalesLine: Record "Sales Line"): Boolean
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        exit(PEPPOL30ValidationImpl.CheckSalesLineTypeAndDescription(SalesLine));
    end;
}

