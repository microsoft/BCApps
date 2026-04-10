// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

/// <summary>
/// Defines account types for allocation destinations with support for parent document inheritance.
/// Controls where allocated amounts are posted and how account information is derived.
/// </summary>
enum 2670 "Destination Account Type"
{
    Extensible = true;

    /// <summary>
    /// Allocates to G/L Account with specified account number.
    /// </summary>
    value(0; "G/L Account")
    {
        Caption = 'G/L Account';
    }

    /// <summary>
    /// Allocates to Bank Account with specified account number.
    /// </summary>
    value(1; "Bank Account")
    {
        Caption = 'Bank Account';
    }

    /// <summary>
    /// Inherits account type and number from the parent document line.
    /// </summary>
    value(2; "Inherit from Parent")
    {
        Caption = 'Inherit from parent';
    }
}
