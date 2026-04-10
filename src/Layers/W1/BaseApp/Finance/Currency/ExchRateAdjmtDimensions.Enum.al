// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Defines how dimensions are handled during exchange rate adjustment processing.
/// Controls which dimension values are applied to adjustment entries.
/// </summary>
/// <remarks>
/// Used in exchange rate adjustment procedures to determine dimension inheritance.
/// Extensible to support custom dimension handling strategies.
/// </remarks>
enum 597 "Exch. Rate Adjmt. Dimensions"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Use dimensions from the original source entries being adjusted.
    /// </summary>
    value(0; "Source Entry Dimensions") { Caption = 'Source Entry Dimensions'; }
    /// <summary>
    /// Do not apply any dimensions to adjustment entries.
    /// </summary>
    value(1; "No Dimensions") { Caption = 'No Dimensions'; }
    /// <summary>
    /// Use default dimensions configured for the G/L account.
    /// </summary>
    value(2; "G/L Account Dimensions") { Caption = 'G/L Account Dimensions'; }
}
