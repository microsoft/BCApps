// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// Defines which date should be used as the VAT reporting date for VAT return calculations and reporting.
/// Controls whether posting date or document date is used for VAT period assignments and tax authority reporting.
/// </summary>
/// <remarks>
/// Usage: Configured in General Ledger Setup and used throughout VAT processing and reporting.
/// Impact: Affects VAT return period assignments, VAT entries, and statutory reporting deadlines.
/// </remarks>
#pragma warning disable AS0090
enum 255 "VAT Reporting Date"
{
    /// <summary>
    /// Uses transaction posting date for VAT reporting period assignment and VAT return calculations.
    /// </summary>
    value(0; "Posting Date") { Caption = 'Posting Date'; }
    /// <summary>
    /// Uses original document date for VAT reporting period assignment and VAT return calculations.
    /// </summary>
    value(1; "Document Date") { Caption = 'Document Date'; }
}
#pragma warning restore
