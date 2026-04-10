// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Controls where VAT business posting group is derived from on documents.
/// Applies to Bill-to/Pay-to or Sell-to/Buy-from party selection.
/// </summary>
enum 98 "G/L Setup VAT Calculation"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Copy VAT Bus. Posting Group from the Bill-to (sales) or Pay-to (purchase) party.
    /// </summary>
    value(0; "Bill-to/Pay-to No.") { Caption = 'Bill-to/Pay-to No.'; }
    /// <summary>
    /// Copy VAT Bus. Posting Group from the Sell-to (sales) or Buy-from (purchase) party.
    /// </summary>
    value(1; "Sell-to/Buy-from No.") { Caption = 'Sell-to/Buy-from No.'; }
}
