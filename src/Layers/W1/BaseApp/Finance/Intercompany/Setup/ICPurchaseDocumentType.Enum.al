// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

/// <summary>
/// Defines document types for intercompany purchase transactions with specific processing and mapping rules.
/// Controls document flow and validation requirements in purchase-side intercompany operations.
/// </summary>
enum 436 "IC Purchase Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Empty value used as default or placeholder for unspecified document types.
    /// </summary>
    value(0; " ") { }
    /// <summary>
    /// Purchase order document for goods or services from intercompany partner.
    /// </summary>
    value(1; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Purchase invoice document for completed transactions with intercompany partner.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Purchase credit memo document for returns or adjustments with intercompany partner.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Purchase return order document for returning goods to intercompany partner.
    /// </summary>
    value(5; "Return Order") { Caption = 'Return Order'; }
}
