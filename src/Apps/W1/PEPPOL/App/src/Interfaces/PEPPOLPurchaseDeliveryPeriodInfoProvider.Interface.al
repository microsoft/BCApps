// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Purchases.Document;

interface "PEPPOL Purchase Delivery Period Info Provider"
{
    /// <summary>
    /// Gets the requested delivery period from the purchase header.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record.</param>
    /// <param name="StartDate">Returns the requested delivery period start date.</param>
    /// <param name="EndDate">Returns the requested delivery period end date.</param>
    procedure GetRequestedDeliveryPeriod(PurchaseHeader: Record "Purchase Header"; var StartDate: Text; var EndDate: Text)
}
