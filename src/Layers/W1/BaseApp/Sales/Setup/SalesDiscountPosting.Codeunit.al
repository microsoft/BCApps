// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

codeunit 323 "Sales Discount Posting" implements "Sales Discount Posting"
{
    procedure ShouldPostInvoiceDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean
    begin
        exit(SalesSetup."Discount Posting" in
            [SalesSetup."Discount Posting"::"Invoice Discounts", SalesSetup."Discount Posting"::"All Discounts"]);
    end;

    procedure ShouldPostLineDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean
    begin
        exit(SalesSetup."Discount Posting" in
            [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]);
    end;

    procedure ShouldPostPaymentDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean
    begin
        // W1 posts payment discounts when applying payments, not on sales invoice lines.
        exit(false);
    end;
}
