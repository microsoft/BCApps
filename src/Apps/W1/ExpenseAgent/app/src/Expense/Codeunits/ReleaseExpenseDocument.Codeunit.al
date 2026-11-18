// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Releases and reopens expenses after checking that the required information is filled in.
/// </summary>
codeunit 6980 "Release Expense Document"
{
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
        NoReceiptDeclarationNotCurrentErr: Label 'The no receipt declaration for expense %1 is missing or no longer current. Create the declaration again before releasing the expense.', Comment = '%1 = Expense No.';
        NoReceiptWithOriginalReceiptErr: Label 'Expense %1 has both an original receipt and a no receipt declaration. Cancel the no receipt declaration before releasing the expense.', Comment = '%1 = Expense No.';

    local procedure "Code"()
    var
        NoReceiptDeclarationMgt: Codeunit "No Receipt Declaration Mgt.";
        CorpCardSelectionMgt: Codeunit "EA Corp Card Selection Mgt";
    begin
        if Expense.Status = Expense.Status::Released then
            exit;

        Expense.TestField("Expense User No.");
        Expense.TestField("Expense Category");

        if Expense."Job No." <> '' then
            Expense.TestField("Job Task No.");

        Expense.ApplyRule(false, true);
        CorpCardSelectionMgt.ValidateExpenseCard(Expense, true);

        if Expense."No Receipt Type" = Expense."No Receipt Type"::"Lost Receipt" then begin
            if NoReceiptDeclarationMgt.HasOriginalReceipt(Expense) then
                Error(NoReceiptWithOriginalReceiptErr, Expense."No.");
            if not NoReceiptDeclarationMgt.HasCurrentDeclaration(Expense) then
                Error(NoReceiptDeclarationNotCurrentErr, Expense."No.");
        end;

        Expense.Status := Expense.Status::Released;
        Expense.Modify(true);

        OnAfterReleaseExpense(Expense);
    end;

    internal procedure Reopen(var ExpenseRecord: Record Expense)
    begin
        if ExpenseRecord.Status = ExpenseRecord.Status::Open then
            exit;

        ExpenseRecord.Status := ExpenseRecord.Status::Open;
        ExpenseRecord.Modify(true);
    end;

    /// <summary>
    /// Releases the expense as the current user after checking that the required fields are filled in and that the expense complies with the expense rules.
    /// </summary>
    /// <param name="ExpenseRecord">The expense to release. The record is updated with the new status.</param>
    procedure PerformManualRelease(var ExpenseRecord: Record Expense)
    begin
        PerformManualCheckAndRelease(ExpenseRecord);
    end;

    /// <summary>
    /// Checks and releases the expense as the current user. An error is raised if the expense does not meet the release requirements.
    /// </summary>
    /// <param name="ExpenseRecord">The expense to check and release. The record is updated with the new status.</param>
    procedure PerformManualCheckAndRelease(var ExpenseRecord: Record Expense)
    begin
        Codeunit.Run(Codeunit::"Release Expense Document", ExpenseRecord);
    end;

    /// <summary>
    /// Reopens the released expense as the current user so that it can be edited again. The expense must not be included in an expense report.
    /// </summary>
    /// <param name="ExpenseRecord">The expense to reopen. The record is updated with the new status.</param>
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