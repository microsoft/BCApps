// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Defines when deferral schedules should start relative to the document posting date.
/// Controls the timing of the first deferral recognition entry.
/// </summary>
#pragma warning disable AL0659
enum 1701 "Deferral Calculation Start Date"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Uses the exact posting date of the source document as the deferral start date.
    /// </summary>
    value(0; "Posting Date") { Caption = 'Posting Date'; }
    /// <summary>
    /// Adjusts start date to the beginning of the accounting period containing the posting date.
    /// </summary>
    value(1; "Beginning of Period") { Caption = 'Beginning of Period'; }
    /// <summary>
    /// Adjusts start date to the end of the accounting period containing the posting date.
    /// </summary>
    value(2; "End of Period") { Caption = 'End of Period'; }
    /// <summary>
    /// Adjusts start date to the beginning of the next accounting period after the posting date.
    /// </summary>
    value(3; "Beginning of Next Period") { Caption = 'Beginning of Next Period'; }
    /// <summary>
    /// Adjusts start date to the beginning of the next calendar year after the posting date.
    /// </summary>
    value(4; "Beginning of Next Calendar Year") { Caption = 'Beginning of Next Calendar Year'; }
}
