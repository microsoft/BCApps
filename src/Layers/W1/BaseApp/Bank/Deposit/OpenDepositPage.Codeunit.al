// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

/// <summary>
/// Handles navigation to individual deposit document pages through extensible events.
/// Provides access to specific deposit entry and editing functionality via extensions.
/// </summary>
/// <remarks>
/// This codeunit delegates individual deposit page opening to extension implementations.
/// Enables access to detailed deposit document management when direct page access is unavailable.
/// </remarks>
codeunit 1505 "Open Deposit Page"
{
    trigger OnRun()
    begin
        OnOpenDepositPage();
    end;

    /// <summary>
    /// Integration event for opening an individual deposit document page.
    /// Allows extensions to provide deposit document editing and entry functionality.
    /// </summary>
    /// <remarks>
    /// Raised from OnRun trigger to enable extension-based deposit document navigation.
    /// Typically implemented by the Bank Deposits extension for specific deposit records.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnOpenDepositPage()
    begin
    end;
}
