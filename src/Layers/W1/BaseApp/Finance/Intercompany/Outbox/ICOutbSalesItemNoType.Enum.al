// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

/// <summary>
/// Defines item number types for intercompany outbox sales line item identification.
/// Controls how item numbers are interpreted and mapped for intercompany sales transactions.
/// </summary>
/// <remarks>
/// Standard values: Internal No., Common Item No., Cross Reference.
/// Extensible via enum extensions for custom item numbering schemes in intercompany scenarios.
/// </remarks>
enum 438 "IC Outb. Sales Item No. Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Internal item number used within the current company for item identification.
    /// </summary>
    value(0; "Internal No.") { Caption = 'Order'; }
    /// <summary>
    /// Common item number shared across intercompany partners for standardized item identification.
    /// </summary>
    value(1; "Common Item No.") { Caption = 'Common Item No.'; }
    /// <summary>
    /// Cross reference or item reference number for partner-specific item mapping.
    /// </summary>
    value(2; "Cross Reference") { Caption = 'Item Reference'; }
}
