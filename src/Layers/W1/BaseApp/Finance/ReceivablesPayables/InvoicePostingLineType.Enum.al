// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Defines line types for invoice posting buffer entries to categorize different posting elements.
/// Used by invoice posting engines to classify and process various line types during posting operations.
/// </summary>
/// <remarks>
/// Supports classification of posting lines for proper G/L account distribution and document line processing.
/// Extensible to allow custom line types for specialized posting scenarios.
/// Integrates with invoice posting buffer tables for structured data processing.
/// </remarks>
enum 49 "Invoice Posting Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Exchange rate difference posting for prepayment amounts.
    /// </summary>
    value(0; "Prepmt. Exch. Rate Difference") { Caption = 'Prepmt. Exch. Rate Difference'; }
    /// <summary>
    /// General ledger account posting for G/L transactions.
    /// </summary>
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Item posting for inventory-related transactions.
    /// </summary>
    value(2; Item) { Caption = 'Item'; }
    /// <summary>
    /// Resource posting for service and time-based transactions.
    /// </summary>
    value(3; "Resource") { Caption = 'Resource'; }
    /// <summary>
    /// Fixed asset posting for asset-related transactions.
    /// </summary>
    value(4; "Fixed Asset") { Caption = 'Fixed Asset'; }
}
