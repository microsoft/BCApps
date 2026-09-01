// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Handles navigation to posted bank deposits list page through extensible events.
/// Provides access to historical deposit records and transaction history via extensions.
/// </summary>
/// <remarks>
/// This codeunit enables posted bank deposit list access through extension implementations.
/// Used for viewing completed deposit transactions and audit trail information.
/// </remarks>
codeunit 1515 "Open P. Bank Deposits L. Page"
{
    trigger OnRun()
    begin
        OnOpenPostedBankDepositsListPage();
    end;

    /// <summary>
    /// Integration event for opening posted bank deposits list page.
    /// Allows extensions to provide posted deposit viewing and audit functionality.
    /// </summary>
    /// <remarks>
    /// Raised from OnRun trigger to enable extension-based posted deposit navigation.
    /// Typically implemented by the Bank Deposits extension for historical deposit data.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOpenPostedBankDepositsListPage()
    begin
    end;
}
