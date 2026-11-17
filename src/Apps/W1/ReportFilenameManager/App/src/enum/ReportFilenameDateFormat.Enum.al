// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

enum 8126 "Report Filename Date Format"
{
    // Fixed formats rather than the user's regional format, so a date in a file name is unambiguous
    // and has no characters that are illegal in a file name. The default, year first, sorts by date.

    Extensible = true;
    Caption = 'Report Filename Date Format';
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
