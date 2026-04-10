// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

/// <summary>
/// Defines account types used for breakdown calculations in variable allocation methods.
/// Determines the source account type for balance calculations and distribution ratios.
/// </summary>
enum 2671 "Breakdown Account Type"
{
    Extensible = true;

    /// <summary>
    /// Uses G/L Account balances for breakdown calculations.
    /// </summary>
    value(0; "G/L Account")
    {
        Caption = 'G/L Account';
    }

    /// <summary>
    /// Uses Bank Account balances for breakdown calculations.
    /// </summary>
    value(1; "Bank Account")
    {
        Caption = 'Bank Account';
    }
}
