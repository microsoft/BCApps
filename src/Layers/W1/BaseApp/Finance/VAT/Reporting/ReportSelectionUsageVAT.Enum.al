// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines usage contexts for VAT-related report selection and assignment.
/// Controls which reports are used for different VAT statement and advance notification scenarios.
/// </summary>
enum 584 "Report Selection Usage VAT"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Standard VAT statement reporting for periodic VAT calculations and submissions.
    /// </summary>
    value(0; "VAT Statement") { Caption = 'VAT Statement'; }
    /// <summary>
    /// Sales VAT advance notification account reporting for preview and validation.
    /// </summary>
    value(1; "Sales VAT Adv. Not. Acc") { Caption = 'Sales VAT Adv. Not. Acc'; }
    /// <summary>
    /// Scheduled VAT statement reporting for automated or batch processing scenarios.
    /// </summary>
    value(2; "VAT Statement Schedule") { Caption = 'VAT Statement Schedule'; }
}
