// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines VAT entry selection criteria based on entry status for VAT statement reporting.
/// Controls which VAT entries are included in reports based on their open or closed status.
/// </summary>
enum 12 "VAT Statement Report Selection"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Include only open VAT entries that have not been settled or closed.
    /// </summary>
    value(0; Open) { Caption = 'Open'; }
    /// <summary>
    /// Include only closed VAT entries that have been settled or processed.
    /// </summary>
    value(1; Closed) { Caption = 'Closed'; }
    /// <summary>
    /// Include both open and closed VAT entries in the statement calculation.
    /// </summary>
    value(2; "Open and Closed") { Caption = 'Open and Closed'; }
}
