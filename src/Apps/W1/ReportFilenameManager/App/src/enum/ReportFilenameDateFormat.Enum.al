// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 50111 "Report Filename Date Format"
{
    // Deliberately not localised. A date in a file name is an identifier, not presentation:
    // it has to sort correctly, mean the same thing to everyone who receives it, and survive
    // the sanitiser. A regional format fails all three - dd/MM/yyyy and MM/dd/yyyy are
    // indistinguishable once read back, and the slashes are illegal in a file name anyway,
    // so stripping them turns 07/09/2026 into an ambiguous 07092026.
    //
    // The choice is the administrator's, from a validated list, and it is the same for every
    // user and every language. Year first is the default because it sorts.

    Extensible = true;
    Caption = 'Report Filename Date Format';
    // Public: extensible means an extension adds values, which requires reaching it.
    Access = Public;

    value(0; YearMonthDay)
    {
        Caption = 'Year-Month-Day';
    }
    value(1; YearMonthDayCompact)
    {
        Caption = 'Year-Month-Day (Compact)';
    }
    value(2; DayMonthYear)
    {
        Caption = 'Day-Month-Year';
    }
    value(3; YearMonth)
    {
        Caption = 'Year-Month';
    }
    value(4; Year)
    {
        Caption = 'Year';
    }
}
