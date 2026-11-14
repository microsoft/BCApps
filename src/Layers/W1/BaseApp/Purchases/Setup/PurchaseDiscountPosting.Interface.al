// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

/// <summary>
/// Determines which discounts are posted separately on purchase invoice lines using the supplied setup record.
/// </summary>
interface "Purchase Discount Posting"
{
    procedure ShouldPostInvoiceDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean;

    procedure ShouldPostLineDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean;

    procedure ShouldPostPaymentDiscount(PurchSetup: Record "Purchases & Payables Setup"): Boolean;
}
