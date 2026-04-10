// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

/// <summary>
/// Represents the periods of time for which date compression can summarize entries.
/// </summary>

enum 9040 "Date Compression Period Length"
{
    Extensible = false;

    /// <summary>
    /// Summarize data for each day.
    /// </summary>
    value(0; Day)
    {
        Caption = 'Day';
    }

    /// <summary>
    /// Summarize data for each week.
    /// </summary>
    value(1; Week)
    {
        Caption = 'Week';
    }

    /// <summary>
    /// Summarize data for each month.
    /// </summary>
    value(2; Month)
    {
        Caption = 'Month';
    }

    /// <summary>
    /// Summarize data for each quarter.
    /// </summary>
    value(3; Quarter)
    {
        Caption = 'Quarter';
    }

    /// <summary>
    /// Summarize data for each year.
    /// </summary>
    value(4; Year)
    {
        Caption = 'Year';
    }

    /// <summary>
    /// Summarize data for each period.
    /// </summary>
    value(5; Period)
    {
        Caption = 'Period';
    }
}
