// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6913 "Expense Line Split Mgt."
{
    Access = Internal;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        NonRefundableExceedsRemainingErr: Label 'The remaining amount after split would be lower than %1. Adjust the split amount or %1 first.', Comment = '%1 = Non-Refundable Amount field caption';
        DifferentUsersSplitDisabledErr: Label 'Split Expense -> Different users is available only when the Expense Agent scenario is enabled.';

    internal procedure SplitSameUser(var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseSplitDialog: Page "Expense Split Dialog";
        SplitAmount: Decimal;
        SplitCategoryCode: Code[20];
    begin
        ExpenseReportLine.TestStatusOpen();

        ExpenseSplitDialog.SetValues(ExpenseReportLine.Amount, ExpenseReportLine."Expense Category");
        if ExpenseSplitDialog.RunModal() <> Action::OK then
            exit;

        ExpenseSplitDialog.GetValues(SplitAmount, SplitCategoryCode);

        CreateSplitLine(ExpenseReportLine, SplitAmount, SplitCategoryCode);
        UpdateSourceLineAmount(ExpenseReportLine, SplitAmount);
    end;

    internal procedure SplitDifferentUsers(var ExpenseReportLine: Record "Expense Report Line")
    var
        TempSplitAllocation: Record "Expense Split Allocation" temporary;
        ExpenseSplitAllocations: Page "Expense Split Allocations";
        TotalAllocatedAmount: Decimal;
    begin
        if not IsDifferentUsersSplitEnabled() then
            Error(DifferentUsersSplitDisabledErr);

        ExpenseReportLine.TestStatusOpen();

        ExpenseSplitAllocations.Initialize(ExpenseReportLine."Expense User No.", ExpenseReportLine.Amount);
        if ExpenseSplitAllocations.RunModal() <> Action::OK then
            exit;

        ExpenseSplitAllocations.GetAllocations(TempSplitAllocation);
        TotalAllocatedAmount := CreateExpensesForAllocations(ExpenseReportLine, TempSplitAllocation);

        UpdateSourceLineAmount(ExpenseReportLine, TotalAllocatedAmount);
    end;

    internal procedure IsDifferentUsersSplitEnabled(): Boolean
    begin
        ExpenseAgentSetup.GetRecordOnce();
        exit(ExpenseAgentSetup."Enable Agent");
    end;

    local procedure CreateSplitLine(SourceLine: Record "Expense Report Line"; SplitAmount: Decimal; SplitCategoryCode: Code[20])
    var
        NewLine: Record "Expense Report Line";
    begin
        NewLine.TransferFields(SourceLine, false);
        NewLine."Document No." := SourceLine."Document No.";
        NewLine."Line No." := NewLine.GetNextExpenseReportLineNo(SourceLine."Document No.");
        NewLine."Expense No." := '';
        Clear(NewLine."Applied Rule Id");
        NewLine."Policies Evaluated At" := 0DT;
        NewLine."Policy Eval Version" := 0;
        NewLine."Evaluated Policy Version" := 0;
        NewLine."User Confirmed" := false;

        NewLine.SetSkipRuleApplication(true);
        NewLine.Insert(true);
        if SplitCategoryCode <> '' then
            NewLine.Validate("Expense Category", SplitCategoryCode);

        NewLine.Validate(Amount, SplitAmount);
        NewLine.UpdateAmounts();
        NewLine.SetSkipRuleApplication(false);
        NewLine.ApplyRule(false, true);
        NewLine.Modify(true);
    end;

    local procedure UpdateSourceLineAmount(var SourceLine: Record "Expense Report Line"; SplitAmount: Decimal)
    begin
        if SourceLine."Non-Refundable Amount" > (SourceLine.Amount - SplitAmount) then
            Error(NonRefundableExceedsRemainingErr, SourceLine.FieldCaption("Non-Refundable Amount"));

        SourceLine.Validate(Amount, SourceLine.Amount - SplitAmount);
        SourceLine.Modify(true);
    end;

    local procedure CreateExpensesForAllocations(SourceLine: Record "Expense Report Line"; var TempSplitAllocation: Record "Expense Split Allocation" temporary): Decimal
    var
        TotalAllocatedAmount: Decimal;
    begin
        if TempSplitAllocation.FindSet() then
            repeat
                CreateExpenseFromLine(SourceLine, TempSplitAllocation."Expense User No.", TempSplitAllocation.Amount);
                TotalAllocatedAmount += TempSplitAllocation.Amount;
            until TempSplitAllocation.Next() = 0;

        exit(TotalAllocatedAmount);
    end;

    local procedure CreateExpenseFromLine(SourceLine: Record "Expense Report Line"; TargetExpenseUserNo: Code[20]; SplitAmount: Decimal)
    var
        Expense: Record Expense;
    begin
        Expense.Init();
        Expense.SetSkipRuleApplication(true);
        Expense.Insert(true);

        Expense.Validate("Expense User No.", TargetExpenseUserNo);
        Expense.Validate("Expense Category", SourceLine."Expense Category");
        Expense.Validate("Expense Subcategory", SourceLine."Expense Subcategory Code");
        Expense.Validate(Description, SourceLine.Description);
        Expense.Validate(Justification, SourceLine.Justification);
        Expense.Validate("Expense Date", SourceLine."Expense Date");
        Expense.Validate("Expense Time", SourceLine."Expense Time");
        Expense.Validate("Currency Code", SourceLine."Expense Currency Code");
        Expense.Validate("Payment Method Code", SourceLine."Payment Method Code");
        Expense.Validate("Reimbursement Type", SourceLine."Reimbursement Type");
        Expense.Validate(Refundable, SourceLine.Refundable);
        Expense.Validate("Expense Location", SourceLine."Expense Location");
        Expense.Validate("Starting Date and Time", SourceLine."Starting Date and Time");
        Expense.Validate("Ending Date and Time", SourceLine."Ending Date and Time");
        Expense.Validate(Mileage, SourceLine.Mileage);
        Expense.Validate("Round Trip", SourceLine."Round Trip");
        Expense.Validate("Vehicle Type", SourceLine."Vehicle Type");
        Expense.Validate("VAT Bus. Posting Group", SourceLine."VAT Bus. Posting Group");
        Expense.Validate("VAT Prod. Posting Group", SourceLine."VAT Prod. Posting Group");
        Expense.Validate("Job No.", SourceLine."Job No.");
        Expense.Validate("Job Task No.", SourceLine."Job Task No.");
        Expense.Validate(Billable, SourceLine.Billable);
        Expense.Validate("Billable to Customer", SourceLine."Billable to Customer");
        Expense.Validate("Expense Ext. Doc. No.", SourceLine."Expense Ext. Doc. No.");
        Expense.Validate("Merchant Name", SourceLine."Merchant Name");
        Expense.Validate("Merchant Registration No.", SourceLine."Merchant Registration No.");
        Expense.Validate("Merchant VAT Registration No.", SourceLine."Merchant VAT Registration No.");
        Expense.Validate("Unit of Measure Code", SourceLine."Unit of Measure Code");
        Expense.Validate("Expense Detail Required", SourceLine."Expense Detail Required");
        Expense.Validate("Non-Refundable Amount", 0);
        Expense.Validate(Amount, SplitAmount);

        Expense."Starting Point" := SourceLine."Starting Point";
        Expense."Ending Point" := SourceLine."Ending Point";
        Expense."Shortcut Dimension 1 Code" := SourceLine."Shortcut Dimension 1 Code";
        Expense."Shortcut Dimension 2 Code" := SourceLine."Shortcut Dimension 2 Code";
        Expense."Dimension Set ID" := SourceLine."Dimension Set ID";

        Expense.SetSkipRuleApplication(false);
        Expense.ApplyRule(false, true);
        Expense.Modify(true);
    end;
}
