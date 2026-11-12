// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

/// <summary>
/// Determines which discounts are posted separately on sales invoice lines using the supplied setup record.
/// </summary>
interface "Sales Discount Posting"
{
    procedure ShouldPostInvoiceDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean;

    procedure ShouldPostLineDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean;

    procedure ShouldPostPaymentDiscount(SalesSetup: Record "Sales & Receivables Setup"): Boolean;
}
