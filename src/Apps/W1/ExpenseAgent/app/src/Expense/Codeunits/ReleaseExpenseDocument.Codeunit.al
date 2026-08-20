// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6980 "Release Expense Document"
{
    Access = Internal;
    TableNo = Expense;
    Permissions = TableData Expense = rm;

    trigger OnRun()
    begin
        Expense.Copy(Rec);
        Expense.SetHideValidationDialog(Rec.GetHideValidationDialog());
        Code();
        Rec := Expense;
    end;

    var
        Expense: Record Expense;

    local procedure "Code"()
    begin
        if Expense.Status = Expense.Status::Released then
            exit;

        Expense.TestField("Expense User No.");
        Expense.TestField("Expense Category");

        if Expense."Job No." <> '' then
            Expense.TestField("Job Task No.");

        Expense.ApplyRule(false, true);

        Expense.Status := Expense.Status::Released;
        Expense.Modify(true);

        OnAfterReleaseExpense(Expense);
    end;

    procedure Reopen(var ExpenseRecord: Record Expense)
    begin
        if ExpenseRecord.Status = ExpenseRecord.Status::Open then
            exit;

        ExpenseRecord.Status := ExpenseRecord.Status::Open;
        ExpenseRecord.Modify(true);
    end;

    procedure PerformManualRelease(var ExpenseRecord: Record Expense)
    begin
        PerformManualCheckAndRelease(ExpenseRecord);
    end;

    procedure PerformManualCheckAndRelease(var ExpenseRecord: Record Expense)
    begin
        Codeunit.Run(Codeunit::"Release Expense Document", ExpenseRecord);
    end;

    procedure PerformManualReopen(var ExpenseRecord: Record Expense)
    begin
        CheckReopenStatus(ExpenseRecord);

        Reopen(ExpenseRecord);
    end;

    local procedure CheckReopenStatus(ExpenseRecord: Record Expense)
    begin
        ExpenseRecord.TestField("Expense Report No.", '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseExpense(var Expense: Record Expense)
    begin
    end;
}