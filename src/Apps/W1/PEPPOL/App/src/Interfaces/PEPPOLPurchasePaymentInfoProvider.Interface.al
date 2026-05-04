// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Payment Info Provider"
{
    /// <summary>
    /// Gets payment terms information from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="PaymentTermsNote">Returns the payment terms note.</param>
    procedure GetPaymentTermsInfo(PurchaseHeader: Record "Purchase Header"; var PaymentTermsNote: Text)
}
