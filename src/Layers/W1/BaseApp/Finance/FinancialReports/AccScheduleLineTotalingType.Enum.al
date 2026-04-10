// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

#pragma warning disable AL0659
/// <summary>
/// Defines totaling methods and data sources for account schedule line calculations.
/// Specifies how account schedule lines aggregate financial data from various Business Central modules.
/// </summary>
/// <remarks>
/// Extensible enum supporting diverse totaling approaches including G/L accounts, cost accounting,
/// cash flow forecasting, formulas, and percentage calculations. Enables flexible financial reporting
/// across multiple data dimensions and calculation methodologies.
/// </remarks>
enum 85 "Acc. Schedule Line Totaling Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Totals from G/L accounts that allow direct posting transactions.
    /// </summary>
    value(0; "Posting Accounts")
    {
        Caption = 'Posting Accounts';
    }
    /// <summary>
    /// Totals from G/L accounts configured as total accounts with account ranges.
    /// </summary>
    value(1; "Total Accounts")
    {
        Caption = 'Total Accounts';
    }
    /// <summary>
    /// Uses custom formula expressions to calculate values from other account schedule lines.
    /// </summary>
    value(2; Formula)
    {
        Caption = 'Formula';
    }
    /// <summary>
    /// Sets the base amount for percentage calculations in subsequent account schedule lines.
    /// </summary>
    value(5; "Set Base For Percent")
    {
        Caption = 'Set Base For Percent';
    }
    /// <summary>
    /// Totals from cost accounting cost types for cost center and cost object reporting.
    /// </summary>
    value(6; "Cost Type")
    {
        Caption = 'Cost Type';
    }
    /// <summary>
    /// Totals from cost accounting cost types configured as total cost types with cost type ranges.
    /// </summary>
    value(7; "Cost Type Total")
    {
        Caption = 'Cost Type Total';
    }
    /// <summary>
    /// Totals from cash flow forecast entries for cash flow analysis and planning.
    /// </summary>
    value(8; "Cash Flow Entry Accounts")
    {
        Caption = 'Cash Flow Entry Accounts';
    }
    /// <summary>
    /// Totals from cash flow accounts configured as total accounts for cash flow reporting.
    /// </summary>
    value(9; "Cash Flow Total Accounts")
    {
        Caption = 'Cash Flow Total Accounts';
    }
    /// <summary>
    /// Totals based on G/L account category classifications for standardized financial statement presentation.
    /// </summary>
    value(10; "Account Category")
    {
        Caption = 'Account Category';
    }
}
