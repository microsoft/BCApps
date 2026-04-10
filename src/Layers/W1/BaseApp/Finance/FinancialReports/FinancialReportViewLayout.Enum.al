// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Controls visibility of filter and parameter information in financial report layouts.
/// Determines what additional information is displayed alongside report data.
/// </summary>
enum 5000 "Financial Report View Layout"
{
    Extensible = true;

    /// <summary>
    /// Hides all filter and parameter information in report layout.
    /// </summary>
    value(0; "Show None")
    {
        Caption = 'Show None';
    }
    /// <summary>
    /// Displays only filter information without additional parameters.
    /// </summary>
    value(1; "Show Filters Only")
    {
        Caption = 'Show Filters Only';
    }
    /// <summary>
    /// Shows complete filter and parameter information in report layout.
    /// </summary>
    value(2; "Show All")
    {
        Caption = 'Show All';
    }
}
