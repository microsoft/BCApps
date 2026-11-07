// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Defines payment processing types for bank transactions and check handling.
/// Determines validation rules and processing methods for different payment forms.
/// </summary>
/// <remarks>
/// Used in Payment Method and Bank Account setup. Extensible for custom payment types.
/// </remarks>
enum 272 "Bank Payment Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// No specific payment type specified.
    /// </summary>
    value(0; " ")
    {
    }
    /// <summary>
    /// Computer-generated check with automated numbering and validation.
    /// </summary>
    value(1; "Computer Check")
    {
        Caption = 'Computer Check';
    }
    /// <summary>
    /// Manually written check requiring manual entry and tracking.
    /// </summary>
    value(2; "Manual Check")
    {
        Caption = 'Manual Check';
    }
    /// <summary>
    /// Electronic funds transfer or ACH payment processing.
    /// </summary>
    value(3; "Electronic Payment")
    {
        Caption = 'Electronic Payment';
    }
    /// <summary>
    /// International ACH Transaction for cross-border electronic payments.
    /// </summary>
    value(4; "Electronic Payment-IAT")
    {
        Caption = 'Electronic Payment-IAT';
    }
}
