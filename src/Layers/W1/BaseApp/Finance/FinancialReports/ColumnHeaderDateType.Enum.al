#pragma warning disable AS0088

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Defines date formatting options for column headers in financial reports.
/// Controls how date periods are displayed in column layout headers for readability.
/// </summary>
enum 764 ColumnHeaderDateType
{
    /// <summary>
    /// No date formatting applied to column header.
    /// </summary>
    value(0; Blank)
    {
        Caption = ' ';
    }
    /// <summary>
    /// Displays weekday name in column header format.
    /// </summary>
    value(1; Weekday)
    {
        Caption = 'Weekday';
    }
    /// <summary>
    /// Shows week number or week range in column header.
    /// </summary>
    value(2; Week)
    {
        Caption = 'Week';
    }
    /// <summary>
    /// Displays month name only in column header format.
    /// </summary>
    value(3; Month)
    {
        Caption = 'Month';
    }
    /// <summary>
    /// Shows month name and year combination in column header.
    /// </summary>
    value(4; MonthAndYear)
    {
        Caption = 'Month and Year';
    }
    /// <summary>
    /// Displays quarter designation in column header format.
    /// </summary>
    value(5; Quarter)
    {
        Caption = 'Quarter';
    }
    /// <summary>
    /// Shows quarter and year combination in column header.
    /// </summary>
    value(6; QuarterAndYear)
    {
        Caption = 'Quarter and Year';
    }
    /// <summary>
    /// Displays year only in column header format.
    /// </summary>
    value(7; Year)
    {
        Caption = 'Year';
    }
    /// <summary>
    /// Shows complete date with day, month, and year in column header.
    /// </summary>
    value(10; FullDate)
    {
        Caption = 'Full Date';
    }
}