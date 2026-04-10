// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

/// <summary>
/// Defines document types for intercompany sales transactions with specific processing and mapping rules.
/// Controls document flow and validation requirements in sales-side intercompany operations.
/// </summary>
enum 434 "IC Sales Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Empty value used as default or placeholder for unspecified document types.
    /// </summary>
    value(0; " ") { }
    /// <summary>
    /// Sales order document for goods or services to intercompany partner.
    /// </summary>
    value(1; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Sales invoice document for completed transactions with intercompany partner.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Sales credit memo document for returns or adjustments with intercompany partner.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Sales return order document for receiving returns from intercompany partner.
    /// </summary>
    value(5; "Return Order") { Caption = 'Return Order'; }
}
