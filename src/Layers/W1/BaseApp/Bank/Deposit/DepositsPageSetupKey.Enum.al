// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Defines keys for identifying different deposit-related page and report types.
/// Used for page setup configuration in the deposit management system.
/// </summary>
/// <remarks>
/// This enum is used in conjunction with the Deposits Page Setup table for mapping page and report objects.
/// Provides standardized identifiers for deposit workflow components.
/// </remarks>
enum 500 "Deposits Page Setup Key"
{
    /// <summary>
    /// Main deposits overview page for managing multiple deposit documents.
    /// </summary>
    value(0; DepositsPage)
    { }

    /// <summary>
    /// Individual deposit document page for detailed deposit entry and editing.
    /// </summary>
    value(1; DepositPage)
    { }

    /// <summary>
    /// List page showing collection of deposit documents with summary information.
    /// </summary>
    value(2; DepositListPage)
    { }

    /// <summary>
    /// Report for printing or generating deposit documentation and summaries.
    /// </summary>
    value(3; DepositReport)
    { }

    /// <summary>
    /// Test report for validating deposit data before final processing or posting.
    /// </summary>
    value(4; DepositTestReport)
    { }

    /// <summary>
    /// List page for viewing posted bank deposit records and transaction history.
    /// </summary>
    value(5; PostedBankDepositListPage)
    { }
}
