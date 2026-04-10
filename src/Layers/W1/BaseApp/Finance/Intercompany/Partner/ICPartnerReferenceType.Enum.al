// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

/// <summary>
/// Defines reference types for mapping between company-specific and intercompany items and accounts.
/// Enables translation of internal references to partner-compatible identifiers in IC transactions.
/// </summary>
/// <remarks>
/// Used in IC mappings to determine how items and accounts are referenced in partner communications.
/// Standard enum covers the most common mapping scenarios for intercompany data exchange.
/// </remarks>
enum 107 "IC Partner Reference Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// No reference type specified for the mapping.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Reference points to a general ledger account number.
    /// </summary>
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Reference points to an item number in the partner's item master.
    /// </summary>
    value(2; "Item") { Caption = 'Item'; }
    /// <summary>
    /// Reference points to an item charge used for additional costs on items.
    /// </summary>
    value(5; "Charge (Item)") { Caption = 'Charge (Item)'; }
    /// <summary>
    /// Reference uses cross-reference item numbering for partner-specific identification.
    /// </summary>
    value(6; "Cross Reference") { Caption = 'Cross Reference'; }
    /// <summary>
    /// Reference uses common item number shared across intercompany partners.
    /// </summary>
    value(7; "Common Item No.") { Caption = 'Common Item No.'; }
    /// <summary>
    /// Reference uses vendor-specific item number for partner identification.
    /// </summary>
    value(8; "Vendor Item No.") { Caption = 'Vendor Item No.'; }
}
