// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

/// <summary>
/// Defines the types of sales documents that can be received through the intercompany inbox.
/// Used to categorize and process different types of sales transactions from partner companies.
/// </summary>
enum 435 "IC Inbox Sales Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Sales order document received from intercompany partner for fulfillment.
    /// </summary>
    value(0; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Sales invoice document received from intercompany partner for payment processing.
    /// </summary>
    value(1; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Sales credit memo document received from intercompany partner for return processing.
    /// </summary>
    value(2; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Sales return order document received from intercompany partner for return processing.
    /// </summary>
    value(3; "Return Order") { Caption = 'Return Order'; }
}
