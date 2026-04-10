// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// Controls VAT reporting date functionality activation and modification permissions within Business Central.
/// Manages whether users can enable, modify, or disable VAT reporting date features.
/// </summary>
/// <remarks>
/// Usage: Set in General Ledger Setup to control VAT reporting date behavior across the system.
/// Impact: Affects VAT date validation, VAT return processing, and user interface availability.
/// </remarks>
enum 259 "VAT Reporting Date Usage"
{
    Extensible = false;

    /// <summary>
    /// Enables VAT reporting date functionality with full user modification capabilities.
    /// </summary>
    value(0; Enabled)
    {
        Caption = 'Enabled';
    }
    /// <summary>
    /// Enables VAT reporting date functionality but prevents users from modifying VAT dates on documents.
    /// </summary>
    value(1; "Enabled (Prevent modification)")
    {
        Caption = 'Enabled (Prevent modification)';
    }
    /// <summary>
    /// Completely disables VAT reporting date functionality throughout the system.
    /// </summary>
    value(2; Disabled)
    {
        Caption = 'Disabled';
    }
}
