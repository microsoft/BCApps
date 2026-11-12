// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

codeunit 310 "Purch. Discount Posting" implements "Purchase Discount Posting"
{
    procedure ShouldPostInvoiceDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean
    begin
        exit(PurchSetup."Discount Posting" in
            [PurchSetup."Discount Posting"::"Invoice Discounts", PurchSetup."Discount Posting"::"All Discounts"]);
    end;

    procedure ShouldPostLineDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean
    begin
        exit(PurchSetup."Discount Posting" in
            [PurchSetup."Discount Posting"::"Line Discounts", PurchSetup."Discount Posting"::"All Discounts"]);
    end;

    procedure ShouldPostPaymentDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean
    begin
        // W1 posts payment discounts when applying payments, not on purchase invoice lines.
        exit(false);
    end;
}
