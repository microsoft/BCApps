// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

#pragma warning disable AL0659
/// <summary>
/// Defines the types of purchase documents that can be received through the intercompany inbox.
/// Used to categorize and process different types of purchase transactions from partner companies.
/// </summary>
enum 437 "IC Inbox Purchase Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Purchase order document received from intercompany partner for processing.
    /// </summary>
    value(0; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Purchase invoice document received from intercompany partner for payment processing.
    /// </summary>
    value(1; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Purchase credit memo document received from intercompany partner for return processing.
    /// </summary>
    value(2; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Purchase return order document received from intercompany partner for return processing.
    /// </summary>
    value(3; "Return Order") { Caption = 'Return Order'; }
}
