// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Defines the types of VAT amounts to calculate and display in VAT statement lines.
/// Controls which VAT entry fields are used for amount calculations and totaling.
/// </summary>
enum 258 "VAT Statement Line Amount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// No specific amount type selected - used for non-calculation line types.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Standard VAT amount from VAT entries for the statement line calculation.
    /// </summary>
    value(1; "Amount") { Caption = 'Amount'; }
    /// <summary>
    /// VAT base amount from VAT entries for the statement line calculation.
    /// </summary>
    value(2; "Base") { Caption = 'Base'; }
    /// <summary>
    /// Unrealized VAT amount for companies using cash-based VAT accounting.
    /// </summary>
    value(3; "Unrealized Amount") { Caption = 'Unrealized Amount'; }
    /// <summary>
    /// Unrealized VAT base amount for companies using cash-based VAT accounting.
    /// </summary>
    value(4; "Unrealized Base") { Caption = 'Unrealized Base'; }
    /// <summary>
    /// Non-deductible VAT amount portion that cannot be claimed for input VAT.
    /// </summary>
    value(6; "Non-Deductible Amount") { Caption = 'Non-Deductible Amount'; }
    /// <summary>
    /// Non-deductible VAT base amount corresponding to non-claimable input VAT.
    /// </summary>
    value(7; "Non-Deductible Base") { Caption = 'Non-Deductible Base'; }
    /// <summary>
    /// Full VAT amount including both deductible and non-deductible portions.
    /// </summary>
    value(8; "Full Amount") { Caption = 'Full Amount'; }
    /// <summary>
    /// Full VAT base amount including both deductible and non-deductible portions.
    /// </summary>
    value(9; "Full Base") { Caption = 'Full Base'; }
}
