// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Defines methods for applying payments and invoices in customer and vendor ledger entries.
/// Controls automatic application behavior for document matching and settlement processing.
/// </summary>
/// <remarks>
/// Used by payment application engines to determine document matching strategies.
/// Supports both manual application control and automatic oldest-first application logic.
/// Integrates with customer and vendor posting setup for application preferences.
/// </remarks>
enum 1381 "Application Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Manual application requiring user selection of specific documents for settlement.
    /// </summary>
    value(0; Manual)
    {
        Caption = 'Manual';
    }
    /// <summary>
    /// Automatic application using oldest document first strategy for payment settlement.
    /// </summary>
    value(1; "Apply to Oldest")
    {
        Caption = 'Apply to Oldest';
    }
}
