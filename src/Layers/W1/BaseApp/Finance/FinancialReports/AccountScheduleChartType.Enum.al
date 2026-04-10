// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Defines chart visualization types for account schedule data presentation in financial reports.
/// Controls how numerical data is displayed in graphical format for analysis and reporting.
/// </summary>
enum 763 "Account Schedule Chart Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Default empty value indicating no specific chart type is selected.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Line chart displaying data points connected by lines for trend analysis.
    /// </summary>
    value(1; "Line") { Caption = 'Line'; }
    /// <summary>
    /// Step line chart showing data values as horizontal steps between periods.
    /// </summary>
    value(2; "StepLine") { Caption = 'StepLine'; }
    /// <summary>
    /// Column chart displaying data as vertical bars for comparative analysis.
    /// </summary>
    value(3; "Column") { Caption = 'Column'; }
    /// <summary>
    /// Stacked column chart showing cumulative values with category breakdowns.
    /// </summary>
    value(4; "StackedColumn") { Caption = 'StackedColumn'; }
}
