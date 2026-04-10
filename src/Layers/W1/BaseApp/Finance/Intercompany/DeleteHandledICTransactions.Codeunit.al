// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

/// <summary>
/// Provides cleanup functionality for handled intercompany transactions.
/// Removes completed transactions from inbox and outbox to maintain system performance.
/// </summary>
/// <remarks>
/// Used for periodic maintenance to clean up processed IC transactions.
/// Helps prevent database growth from historical intercompany transaction data.
/// </remarks>
codeunit 430 "Delete Handled IC Transactions"
{

    trigger OnRun()
    begin
    end;
}

