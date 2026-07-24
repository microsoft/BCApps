// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 11362 "Employee Ledger Entry NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Employee Ledger Entry", 'OnAfterCopyEmployeeLedgerEntryFromGenJnlLine', '', false, false)]
    local procedure OnAfterCopyEmployeeLedgerEntryFromGenJnlLine(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        EmployeeLedgerEntry."Transaction Mode Code" := GenJournalLine."Transaction Mode Code";
    end;
}