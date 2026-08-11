// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Navigate;

codeunit 6994 "Expense Preview Post Instance"
{
    Access = Internal;
    SingleInstance = true;

    procedure InsertDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        if HasExpenseEntry then
            InsertDocumentEntryForExpenseLedgerEntry(TempDocumentEntry);
    end;

    local procedure InsertDocumentEntryForExpenseLedgerEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(TempExpenseLedgerEntry);

        if RecRef.IsEmpty() then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := RecRef.Number;
        TempDocumentEntry."Table ID" := RecRef.Number;
        TempDocumentEntry."Table Name" := CopyStr(RecRef.Caption, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecRef.Count();
        TempDocumentEntry.Insert();
    end;

    procedure InsertExpenseLedgerEntry(var ExpenseLedgEntry: Record "Expense Ledger Entry"; RunTrigger: Boolean)
    begin
        if ExpenseLedgEntry.IsTemporary() then
            exit;

        TempExpenseLedgerEntry := ExpenseLedgEntry;
        TempExpenseLedgerEntry."Document No." := '***';
        TempExpenseLedgerEntry.Insert();
        HasExpenseEntry := true;
    end;

    procedure ShowEntries()
    begin
        Page.Run(Page::"Expense Ledger Entries", TempExpenseLedgerEntry);
    end;

    procedure Initialize()
    begin
        ClearAll();
        TempExpenseLedgerEntry.Reset();
        TempExpenseLedgerEntry.DeleteAll();
    end;

    var
        TempExpenseLedgerEntry: Record "Expense Ledger Entry" temporary;
        HasExpenseEntry: Boolean;
}