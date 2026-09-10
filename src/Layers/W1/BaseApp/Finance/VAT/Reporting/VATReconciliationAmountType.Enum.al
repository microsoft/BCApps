// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Controls whether the VAT Reconciliation Report includes the Non-Deductible VAT portion in the
/// reported base and VAT amounts, or reports the deductible portion only.
/// </summary>
enum 261 "VAT Reconciliation Amount Type"
{
    Extensible = true;

    /// <summary>
    /// Report the full base and VAT amount, including both the deductible and the non-deductible portions.
    /// </summary>
    value(0; "Include Non-Deductible VAT")
    {
        Caption = 'Include Non-Deductible VAT';
    }
    /// <summary>
    /// Report only the deductible base and VAT amount, excluding the non-deductible portion.
    /// </summary>
    value(1; "Deductible VAT Only")
    {
        Caption = 'Deductible VAT Only';
    }
}
