// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

codeunit 10799 "Sales Discount Posting ES" implements "Sales Discount Posting"
{
    procedure ShouldPostInvoiceDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean
    begin
        exit(SalesSetup."Post Invoice Discount");
    end;

    procedure ShouldPostLineDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean
    begin
        exit(SalesSetup."Post Line Discount");
    end;

    procedure ShouldPostPaymentDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean
    begin
        exit(SalesSetup."Post Payment Discount");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales & Receivables Setup", 'OnAfterGetDiscountPostingSetup', '', false, false)]
    local procedure OnAfterGetDiscountPostingSetup(var DiscountPostingSetup: Interface "Sales Discount Posting")
    var
        SalesDiscountPostingES: Codeunit "Sales Discount Posting ES";
    begin
        DiscountPostingSetup := SalesDiscountPostingES;
    end;
}
