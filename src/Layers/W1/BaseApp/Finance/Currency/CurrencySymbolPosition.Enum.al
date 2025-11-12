// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;

/// <summary>
/// Enum to define the position of the currency symbol in relation to the amount.
/// </summary>
enum 51 "Currency Symbol Position"
{
    Extensible = true;

    /// <summary>
    /// Represents the scenario where the currency symbol is placed before the amount.
    /// </summary>
    value(0; "Before Amount")
    {
        Caption = 'Before Amount';
    }
    /// <summary>
    /// Represents the scenario where the currency symbol is placed after the amount.
    /// </summary>
    value(1; "After Amount")
    {
        Caption = 'After Amount';
    }
}