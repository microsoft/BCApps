// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

codeunit 10126 "Bank Acc. Ledg. Entry-Reset"
{
    TableNo = "Bank Account Ledger Entry";
    Permissions = TableData "Bank Account Ledger Entry" = rm;

    trigger OnRun()
    begin
        BankAccountLedgerEntry.Get(Rec."Entry No.");
        BankAccountLedgerEntry."Statement Line No." := 0;
        BankAccountLedgerEntry."Statement No." := '';
        BankAccountLedgerEntry."Statement Status" := Rec."Statement Status"::Open;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Modify();
    end;

    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
}
