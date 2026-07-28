// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Expense report aggregation for corporate card expenses.
/// Creates and manages Expense Reports from individual corp card transactions.
/// GL posting is handled by the standard ExpenseReportPost codeunit when the report is posted.
/// </summary>
codeunit 7219 EACorpCardReportMgt
{
    Access = Internal;

    var
        NoExpensesForEmployeeErr: Label 'No open expenses found for employee %1 to add to the report.', Comment = '%1 = Employee No.';
        ReportAlreadyExistsErr: Label 'An expense report already exists for employee %1 dated %2. Use the existing report or create a new one.', Comment = '%1 = Employee No., %2 = Date';
        ExpenseNotReadyErr: Label 'Expense %1 is not ready for reporting (status: %2). Status must be Open or Released.', Comment = '%1 = Expense No., %2 = Status';

    /// <summary>
    /// Creates a new Expense Report for the given employee and adds open corp card expenses to it.
    /// </summary>
    internal procedure CreateReportFromCorpCardExpenses(ExpenseUserNo: Code[20]) ReportNo: Code[20]
    var
        ExpenseReportHeader: Record "Expense Report Header";
        Expense: Record Expense;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseUser: Record "Expense User";
        AuditSubscribers: Codeunit EACorpCardAuditSubscribers;
    begin
        ExpenseUser.Get(ExpenseUserNo);
        ExpenseAgentSetup.GetRecordOnce();

        // Find all open corp card expenses for this employee
        Expense.SetRange("Expense User No.", ExpenseUserNo);
        Expense.SetFilter(Status, '%1|%2', Expense.Status::Open, Expense.Status::Released);
        Expense.SetFilter("Expense Report No.", ''); // Not yet added to a report

        if Expense.IsEmpty() then
            Error(NoExpensesForEmployeeErr, ExpenseUserNo);

        // Create new expense report
        ExpenseReportHeader.Init();
        ExpenseReportHeader."No." := '';
        ExpenseReportHeader."Expense User No." := ExpenseUserNo;
        ExpenseReportHeader."Expense Report Date" := Today();
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Open;
        ExpenseReportHeader.Insert(true);

        ReportNo := ExpenseReportHeader."No.";

        // Add all matching expenses to the report
        if Expense.FindSet() then
            repeat
                if Expense.Status in [Expense.Status::Open, Expense.Status::Released] then begin
                    Expense."Expense Report No." := ReportNo;
                    Expense.Modify();
                end;
            until Expense.Next() = 0;

        AuditSubscribers.LogReportCreatedFromCorpCard(ReportNo, ExpenseUserNo);
    end;

    /// <summary>
    /// Adds a specific expense to an Expense Report.
    /// </summary>
    internal procedure AddExpenseToReport(ExpenseNo: Code[20]; ReportNo: Code[20])
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        Expense.Get(ExpenseNo);
        if not (Expense.Status in [Expense.Status::Open, Expense.Status::Released]) then
            Error(ExpenseNotReadyErr, ExpenseNo, Expense.Status);

        ExpenseReportHeader.Get(ReportNo);

        Expense."Expense Report No." := ReportNo;
        Expense.Modify();
    end;

    /// <summary>
    /// Marks a corp card expense as released (ready for adding to a report).
    /// </summary>
    internal procedure ReleaseExpenseForReporting(ExpenseNo: Code[20])
    var
        Expense: Record Expense;
    begin
        Expense.Get(ExpenseNo);
        if Expense.Status <> Expense.Status::Open then
            Error(ExpenseNotReadyErr, ExpenseNo, Expense.Status);

        Expense.Status := Expense.Status::Released;
        Expense.Modify();
    end;
}
