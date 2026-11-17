// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;
#if not CLEANSCHEMA28
#pragma warning disable AS0082, AS0125 // re-id'ing enum values
#endif

/// <summary>
/// Enum to define the position of the currency symbol in relation to the amount.
/// </summary>
enum 51 "Currency Symbol Position"
{
    Extensible = true;

    /// <summary>
    /// Specifies the position of the currency symbol in relation to the amount.
    /// Selecting this value will make the symbol follow the default position set in the General Ledger Setup table for the local currency (LCY) symbol.
    /// </summary>
    value(0; Default)
    {
        Caption = 'Default';
    }

    /// <summary>
    /// Represents the scenario where the currency symbol is placed before the amount.
    /// </summary>
    value(1; "Before Amount")
    {
        Caption = 'Before Amount';
    }
    /// <summary>
    /// Represents the scenario where the currency symbol is placed after the amount.
    /// </summary>
    value(2; "After Amount")
    {
        Caption = 'After Amount';
    }
}