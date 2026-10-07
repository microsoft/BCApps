// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Finance.Currency;

/// <summary>
/// Enum to define when the currency symbol should be shown.
/// This enum is used in the General Ledger Setup to control the display of currency symbols.
/// It allows for flexible configurations based on user preferences or business requirements.
/// The values represent different scenarios for displaying currency symbols in financial documents.
/// </summary>
enum 50 "Show Currency"
{
    Extensible = true;

    /// <summary>
    /// Represents the scenario where the currency symbol is never shown.
    /// </summary>
    value(0; Never)
    {
        Caption = 'Never';
    }
    /// <summary>
    /// Represents the scenario where the currency symbol is shown only for foreign currency amounts.
    /// </summary>
    value(1; "FCY Symbol Only")
    {
        Caption = 'FCY Symbol Only';
    }
    /// <summary>
    /// Represents the scenario where the currency code is shown for foreign currency amounts only.
    /// </summary>
    value(2; "FCY Currency Code Only")
    {
        Caption = 'FCY Currency Code Only';
    }
    /// <summary>
    /// Represents the scenario where the currency symbol is shown for both local currency and foreign currency amounts.
    /// </summary>
    value(3; "LCY and FCY Symbol")
    {
        Caption = 'LCY and FCY Symbol';
    }
    /// <summary>
    /// Represents the scenario where the currency code is shown for both local currency and foreign currency amounts
    /// </summary>
    value(4; "LCY and FCY Currency Code")
    {
        Caption = 'LCY and FCY Currency Code';
    }
}