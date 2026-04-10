// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Handles import transactions for payment reconciliation journals.
/// Processes transaction data and creates new reconciliation statements.
/// </summary>
codeunit 9023 "Pmt. Rec. Jnl. Import Trans."
{

    trigger OnRun()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.ImportAndProcessToNewStatement();
    end;
}

