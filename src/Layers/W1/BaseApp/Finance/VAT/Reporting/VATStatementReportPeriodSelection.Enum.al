// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines period selection options for VAT statement reporting and filtering.
/// Controls how VAT entries are included based on their posting dates relative to the reporting period.
/// </summary>
#pragma warning disable AL0659
enum 13 "VAT Statement Report Period Selection"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Include VAT entries posted before the period start date and within the reporting period.
    /// </summary>
    value(0; "Before and Within Period") { Caption = 'Before and Within Period'; }
    /// <summary>
    /// Include only VAT entries posted within the specified reporting period dates.
    /// </summary>
    value(1; "Within Period") { Caption = 'Within Period'; }
}
