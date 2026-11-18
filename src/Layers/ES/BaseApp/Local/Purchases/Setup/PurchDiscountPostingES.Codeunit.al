// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

codeunit 10798 "Purch. Discount Posting ES" implements "Purchase Discount Posting"
{
    procedure ShouldPostInvoiceDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean
    begin
        exit(PurchSetup."Post Invoice Discount");
    end;

    procedure ShouldPostLineDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean
    begin
        exit(PurchSetup."Post Line Discount");
    end;

    procedure ShouldPostPaymentDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean
    begin
        exit(PurchSetup."Post Payment Discount");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchases & Payables Setup", 'OnAfterGetDiscountPostingSetup', '', false, false)]
    local procedure OnAfterGetDiscountPostingSetup(var DiscountPostingSetup: Interface "Purchase Discount Posting")
    var
        PurchDiscountPostingES: Codeunit "Purch. Discount Posting ES";
    begin
        DiscountPostingSetup := PurchDiscountPostingES;
    end;
}
