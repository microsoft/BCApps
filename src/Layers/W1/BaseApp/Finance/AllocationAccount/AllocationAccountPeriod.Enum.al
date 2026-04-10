// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

/// <summary>
/// Defines time periods used for calculation in variable allocation account methods.
/// Provides comprehensive date range options for balance and amount calculations.
/// </summary>
enum 2674 "Allocation Account Period"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Uses account balance as of the posting date for allocation calculations.
    /// </summary>
    value(0; "Balance at Date") { Caption = 'Balance at Date'; }
    /// <summary>
    /// Uses fiscal year totals for allocation calculations.
    /// </summary>
    value(1; "Fiscal Year") { Caption = 'Fiscal Year'; }
    /// <summary>
    /// Uses current week totals for allocation calculations.
    /// </summary>
    value(2; "Week") { Caption = 'Week'; }
    /// <summary>
    /// Uses previous week totals for allocation calculations.
    /// </summary>
    value(3; "Last Week") { Caption = 'Last Week'; }
    /// <summary>
    /// Uses current month totals for allocation calculations.
    /// </summary>
    value(4; "Month") { Caption = 'Month'; }
    /// <summary>
    /// Uses previous month totals for allocation calculations.
    /// </summary>
    value(5; "Last Month") { Caption = 'Last Month'; }
    /// <summary>
    /// Uses current quarter totals for allocation calculations.
    /// </summary>
    value(6; "Quarter") { Caption = 'Quarter'; }
    /// <summary>
    /// Uses previous quarter totals for allocation calculations.
    /// </summary>
    value(7; "Last Quarter") { Caption = 'Last quarter'; }
    /// <summary>
    /// Uses current year totals for allocation calculations.
    /// </summary>
    value(8; "Year") { Caption = 'Year'; }
    /// <summary>
    /// Uses previous year totals for allocation calculations.
    /// </summary>
    value(9; "Last Year") { Caption = 'Last Year'; }
    /// <summary>
    /// Uses same month from previous year for allocation calculations.
    /// </summary>
    value(10; "Month of Last Year") { Caption = 'Month of Last Year'; }
    /// <summary>
    /// Uses current accounting period totals for allocation calculations.
    /// </summary>
    value(11; "Period") { Caption = 'Period'; }
    /// <summary>
    /// Uses previous accounting period totals for allocation calculations.
    /// </summary>
    value(12; "Last Period") { Caption = 'Last Period'; }
    /// <summary>
    /// Uses same accounting period from previous year for allocation calculations.
    /// </summary>
    value(13; "Period of Last Year") { Caption = 'Period of Last Year'; }
    /// <summary>
    /// Uses previous fiscal year totals for allocation calculations.
    /// </summary>
    value(14; "Last Fiscal Year") { Caption = 'Last Fiscal Year'; }
}
