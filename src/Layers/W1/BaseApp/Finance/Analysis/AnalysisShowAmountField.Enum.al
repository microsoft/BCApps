// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Defines the amount field types for displaying financial data in analysis reports.
/// Controls which amount fields are shown when viewing G/L account analysis data.
/// </summary>
enum 748 "Analysis Show Amount Field"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Display the net amount field (debit amounts minus credit amounts).
    /// </summary>
    value(0; "Amount") { Caption = 'Amount'; }
    /// <summary>
    /// Display only debit amounts from G/L entries.
    /// </summary>
    value(1; "Debit Amount") { Caption = 'Debit Amount'; }
    /// <summary>
    /// Display only credit amounts from G/L entries.
    /// </summary>
    value(2; "Credit Amount") { Caption = 'Credit Amount'; }
}
