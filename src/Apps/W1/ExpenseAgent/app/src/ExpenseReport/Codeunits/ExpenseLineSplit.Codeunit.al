// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Splits an expense report line, either into a new line for the same user or into new open expenses for other users.
/// </summary>
codeunit 7140 "Expense Line Split"
{
    Access = Internal;

    var
        LineAmountMustBePositiveErr: Label 'You can only split expense report lines that have an amount greater than zero.';
        CannotSplitCalculatedAmountErr: Label 'You cannot split expense report line %1 because the amount of %2 expenses is calculated automatically.', Comment = '%1 = Line No., %2 = Expense Detail Required';
        CannotSplitItemizedLineErr: Label 'You cannot split expense report line %1 because it has itemizations. Adjust the itemizations instead.', Comment = '%1 = Line No.';
        CannotSplitLineWithVATSpecErr: Label 'You cannot split expense report line %1 because it has a VAT specification. Adjust the VAT specification instead.', Comment = '%1 = Line No.';
        SplitAmountMustBePositiveErr: Label 'The amount to split must be greater than zero.';
        SplitAmountTooHighErr: Label 'The amount to split must be less than the amount of the original line, %1.', Comment = '%1 = Amount of the original line';
        RemainingBelowNonRefundableErr: Label 'The remaining amount of the original line, %1, cannot be less than its non-refundable amount, %2.', Comment = '%1 = Remaining amount, %2 = Non-refundable amount';
        ExpenseCategoryMissingErr: Label 'You must specify the expense category for the new line.';
        CategoryWithCalculatedAmountErr: Label 'You cannot use expense category %1 for a split line because the amount of %2 expenses is calculated automatically.', Comment = '%1 = Expense Category, %2 = Expense Detail Required';
        NoSplitLinesErr: Label 'Add at least one line with an expense category and the amount to split.';
        SplitLineAmountMissingErr: Label 'You must specify an amount greater than zero for expense category %1.', Comment = '%1 = Expense Category';
        NoAllocationsErr: Label 'Add at least one user and the amount to split the expense with.';
        AllocationUserMissingErr: Label 'You must specify an expense user on every allocation line.';
        AllocationAmountMissingErr: Label 'You must specify an amount greater than zero for expense user %1.', Comment = '%1 = Expense User No.';
        AllocationSameUserErr: Label 'You cannot split the expense with expense user %1 because the expense report belongs to this user. Use Split Expense - Same User instead.', Comment = '%1 = Expense User No.';
        AllocationDuplicateUserErr: Label 'Expense user %1 is added more than once.', Comment = '%1 = Expense User No.';
        AgentNotEnabledErr: Label 'You can only split an expense with different users when the Expense Agent is enabled.';
        ExpensesCreatedMsg: Label '%1 expense(s) were created with status Open: %2.\\The selected users must confirm the expenses before they can be processed.', Comment = '%1 = Number of expenses, %2 = List of expense numbers';

    /// <summary>
    /// Lets the user enter one or more amounts with an expense category, and moves them from the line to new lines on the same expense report.
    /// </summary>
    internal procedure SplitForSameUser(var ExpenseReportLine: Record "Expense Report Line")
    var
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        SplitExpenseLine: Page "Split Expense Line";
    begin
        CheckLineCanBeSplit(ExpenseReportLine);

        SplitExpenseLine.SetExpenseReportLine(ExpenseReportLine);
        if SplitExpenseLine.RunModal() <> Action::OK then
            exit;

        SplitExpenseLine.GetSplitLines(TempExpenseSplitAllocation);
        SplitLineForSameUser(ExpenseReportLine, TempExpenseSplitAllocation);
    end;

    /// <summary>
    /// Lets the user allocate amounts of the line to other expense users, and creates an open expense for each of them.
    /// </summary>
    internal procedure SplitForDifferentUsers(var ExpenseReportLine: Record "Expense Report Line")
    var
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        SplitExpenseLineUsers: Page "Split Expense Line Users";
        CreatedExpenseNos: List of [Code[20]];
    begin
        CheckLineCanBeSplitWithDifferentUsers(ExpenseReportLine);

        SplitExpenseLineUsers.SetExpenseReportLine(ExpenseReportLine);
        if SplitExpenseLineUsers.RunModal() <> Action::OK then
            exit;

        SplitExpenseLineUsers.GetAllocations(TempExpenseSplitAllocation);
        CreatedExpenseNos := SplitLineForDifferentUsers(ExpenseReportLine, TempExpenseSplitAllocation);
        if GuiAllowed() then
            Message(ExpensesCreatedMsg, CreatedExpenseNos.Count(), JoinExpenseNos(CreatedExpenseNos));
    end;

    internal procedure SplitLineForSameUser(var ExpenseReportLine: Record "Expense Report Line"; var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary) NewLineNos: List of [Integer]
    var
        NewExpenseReportLine: Record "Expense Report Line";
        TotalSplitAmount: Decimal;
        PreviousLineNo: Integer;
    begin
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        CheckLineCanBeSplit(ExpenseReportLine);
        TotalSplitAmount := CheckSplitLines(ExpenseReportLine, TempExpenseSplitAllocation);

        ReduceLineAmount(ExpenseReportLine, TotalSplitAmount);

        PreviousLineNo := ExpenseReportLine."Line No.";
        TempExpenseSplitAllocation.FindSet();
        repeat
            NewExpenseReportLine := CreateSplitLine(ExpenseReportLine, PreviousLineNo, TempExpenseSplitAllocation);
            PreviousLineNo := NewExpenseReportLine."Line No.";
            NewLineNos.Add(PreviousLineNo);
        until TempExpenseSplitAllocation.Next() = 0;
    end;

    internal procedure SplitLineForDifferentUsers(var ExpenseReportLine: Record "Expense Report Line"; var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary) CreatedExpenseNos: List of [Code[20]]
    var
        TotalAllocatedAmount: Decimal;
    begin
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        CheckLineCanBeSplitWithDifferentUsers(ExpenseReportLine);
        TotalAllocatedAmount := CheckAllocations(ExpenseReportLine, TempExpenseSplitAllocation);

        ReduceLineAmount(ExpenseReportLine, TotalAllocatedAmount);

        TempExpenseSplitAllocation.FindSet();
        repeat
            CreatedExpenseNos.Add(CreateExpenseForUser(ExpenseReportLine, TempExpenseSplitAllocation));
        until TempExpenseSplitAllocation.Next() = 0;
    end;

    internal procedure IsSplitWithDifferentUsersAvailable(): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then
            exit(false);

        exit(ExpenseAgentSetup."Enable Agent");
    end;

    internal procedure CheckLineCanBeSplit(ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
    begin
        ExpenseReportLine.TestField("Document No.");
        ExpenseReportLine.TestField("Line No.");
        ExpenseReportLine.TestStatusOpen();
        if ExpenseReportLine.Amount <= 0 then
            Error(LineAmountMustBePositiveErr);
        if IsAmountCalculated(ExpenseReportLine."Expense Detail Required") then
            Error(CannotSplitCalculatedAmountErr, ExpenseReportLine."Line No.", ExpenseReportLine."Expense Detail Required");

        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineItem.IsEmpty() then
            Error(CannotSplitItemizedLineErr, ExpenseReportLine."Line No.");

        // VAT specification rows are posted instead of the line amount, so they would no longer match a reduced line.
        ExpenseReportLineVATSpec.SetRange("Document No.", ExpenseReportLine."Document No.");
        ExpenseReportLineVATSpec.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        if not ExpenseReportLineVATSpec.IsEmpty() then
            Error(CannotSplitLineWithVATSpecErr, ExpenseReportLine."Line No.");
    end;

    internal procedure CheckSplitAmount(ExpenseReportLine: Record "Expense Report Line"; SplitAmount: Decimal)
    begin
        if SplitAmount <= 0 then
            Error(SplitAmountMustBePositiveErr);
        if SplitAmount >= ExpenseReportLine.Amount then
            Error(SplitAmountTooHighErr, ExpenseReportLine.Amount);
        if ExpenseReportLine.Amount - SplitAmount < ExpenseReportLine."Non-Refundable Amount" then
            Error(RemainingBelowNonRefundableErr, ExpenseReportLine.Amount - SplitAmount, ExpenseReportLine."Non-Refundable Amount");
    end;

    internal procedure CheckSplitCategory(ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
    begin
        if ExpenseCategoryCode = '' then
            Error(ExpenseCategoryMissingErr);

        ExpenseCategory.Get(ExpenseCategoryCode);
        ExpenseCategory.TestField(Inactive, false);
        if IsAmountCalculated(ExpenseCategory."Expense Detail Required") then
            Error(CategoryWithCalculatedAmountErr, ExpenseCategory.Code, ExpenseCategory."Expense Detail Required");
        if ExpenseSubcategoryCode = '' then
            exit;

        ExpenseSubcategory.Get(ExpenseCategoryCode, ExpenseSubcategoryCode);
        ExpenseSubcategory.TestField(Inactive, false);
    end;

    /// <summary>
    /// Validates the new lines of a same-user split and returns the total amount to split.
    /// </summary>
    internal procedure CheckSplitLines(ExpenseReportLine: Record "Expense Report Line"; var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary) TotalSplitAmount: Decimal
    begin
        TempExpenseSplitAllocation.Reset();
        if not TempExpenseSplitAllocation.FindSet() then
            Error(NoSplitLinesErr);
        repeat
            CheckSplitCategory(TempExpenseSplitAllocation."Expense Category", TempExpenseSplitAllocation."Expense Subcategory Code");
            if TempExpenseSplitAllocation.Amount <= 0 then
                Error(SplitLineAmountMissingErr, TempExpenseSplitAllocation."Expense Category");

            TotalSplitAmount += TempExpenseSplitAllocation.Amount;
        until TempExpenseSplitAllocation.Next() = 0;

        CheckSplitAmount(ExpenseReportLine, TotalSplitAmount);
    end;

    /// <summary>
    /// Validates the allocations and returns the total allocated amount.
    /// </summary>
    internal procedure CheckAllocations(ExpenseReportLine: Record "Expense Report Line"; var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary) TotalAllocatedAmount: Decimal
    var
        ExpenseUserNos: List of [Code[20]];
    begin
        TempExpenseSplitAllocation.Reset();
        if not TempExpenseSplitAllocation.FindSet() then
            Error(NoAllocationsErr);
        repeat
            if TempExpenseSplitAllocation."Expense User No." = '' then
                Error(AllocationUserMissingErr);
            if TempExpenseSplitAllocation.Amount <= 0 then
                Error(AllocationAmountMissingErr, TempExpenseSplitAllocation."Expense User No.");
            if TempExpenseSplitAllocation."Expense User No." = ExpenseReportLine."Expense User No." then
                Error(AllocationSameUserErr, TempExpenseSplitAllocation."Expense User No.");
            if ExpenseUserNos.Contains(TempExpenseSplitAllocation."Expense User No.") then
                Error(AllocationDuplicateUserErr, TempExpenseSplitAllocation."Expense User No.");
            ExpenseUserNos.Add(TempExpenseSplitAllocation."Expense User No.");

            TotalAllocatedAmount += TempExpenseSplitAllocation.Amount;
        until TempExpenseSplitAllocation.Next() = 0;

        CheckSplitAmount(ExpenseReportLine, TotalAllocatedAmount);
    end;

    local procedure CheckLineCanBeSplitWithDifferentUsers(ExpenseReportLine: Record "Expense Report Line")
    begin
        if not IsSplitWithDifferentUsersAvailable() then
            Error(AgentNotEnabledErr);

        CheckLineCanBeSplit(ExpenseReportLine);
    end;

    local procedure IsAmountCalculated(ExpenseDetailRequired: Enum "Expense Detail Needed"): Boolean
    begin
        exit(ExpenseDetailRequired in [ExpenseDetailRequired::"Per Diem", ExpenseDetailRequired::Mileage]);
    end;

    local procedure ReduceLineAmount(var ExpenseReportLine: Record "Expense Report Line"; AmountToMove: Decimal)
    begin
        if ExpenseReportLine."Original Amount" = 0 then
            ExpenseReportLine."Original Amount" := ExpenseReportLine.Amount;
        ExpenseReportLine.Validate(Amount, ExpenseReportLine.Amount - AmountToMove);
        ExpenseReportLine.Modify(true);
    end;

    local procedure CreateSplitLine(SourceExpenseReportLine: Record "Expense Report Line"; PreviousLineNo: Integer; ExpenseSplitAllocation: Record "Expense Split Allocation") NewExpenseReportLine: Record "Expense Report Line"
    var
        ExpenseReport: Codeunit "Expense Report";
    begin
        NewExpenseReportLine.Init();
        NewExpenseReportLine."Document No." := SourceExpenseReportLine."Document No.";
        NewExpenseReportLine."Line No." := GetSplitLineNo(SourceExpenseReportLine, PreviousLineNo);
        NewExpenseReportLine.SetSkipRuleApplication(true);
        NewExpenseReportLine.SetHideValidationDialog(true);
        NewExpenseReportLine.Insert(true);

        NewExpenseReportLine.Validate("Expense Category", ExpenseSplitAllocation."Expense Category");
        if ExpenseSplitAllocation."Expense Subcategory Code" <> '' then
            NewExpenseReportLine.Validate("Expense Subcategory Code", ExpenseSplitAllocation."Expense Subcategory Code");
        if ExpenseSplitAllocation.Description <> '' then
            NewExpenseReportLine.Validate(Description, ExpenseSplitAllocation.Description);
        if ExpenseSplitAllocation."Expense Subcategory Code" <> '' then
            NewExpenseReportLine.Validate(Description, NewExpenseReportLine.UpdatePostingDescription());

        NewExpenseReportLine.Validate("Expense Date", SourceExpenseReportLine."Expense Date");
        NewExpenseReportLine.Validate("Expense Time", SourceExpenseReportLine."Expense Time");
        NewExpenseReportLine.Validate("Expense Currency Code", SourceExpenseReportLine."Expense Currency Code");
        if SourceExpenseReportLine."Payment Method Code" <> '' then
            NewExpenseReportLine.Validate("Payment Method Code", SourceExpenseReportLine."Payment Method Code");
        NewExpenseReportLine.Validate(Justification, SourceExpenseReportLine.Justification);
        NewExpenseReportLine.Validate("Merchant Name", SourceExpenseReportLine."Merchant Name");
        NewExpenseReportLine.Validate("Merchant Registration No.", SourceExpenseReportLine."Merchant Registration No.");
        NewExpenseReportLine.Validate("Merchant VAT Registration No.", SourceExpenseReportLine."Merchant VAT Registration No.");
        NewExpenseReportLine.Validate("Expense Ext. Doc. No.", SourceExpenseReportLine."Expense Ext. Doc. No.");
        NewExpenseReportLine."Expense Vendor No." := SourceExpenseReportLine."Expense Vendor No.";
        NewExpenseReportLine.Validate(Billable, SourceExpenseReportLine.Billable);
        NewExpenseReportLine.Validate("Billable to Customer", SourceExpenseReportLine."Billable to Customer");
        NewExpenseReportLine.Validate("Job No.", SourceExpenseReportLine."Job No.");
        NewExpenseReportLine.Validate("Job Task No.", SourceExpenseReportLine."Job Task No.");
        NewExpenseReportLine."Dimension Set ID" := SourceExpenseReportLine."Dimension Set ID";
        NewExpenseReportLine."Shortcut Dimension 1 Code" := SourceExpenseReportLine."Shortcut Dimension 1 Code";
        NewExpenseReportLine."Shortcut Dimension 2 Code" := SourceExpenseReportLine."Shortcut Dimension 2 Code";
        SetVATProdPostingGroup(NewExpenseReportLine, SourceExpenseReportLine, ExpenseSplitAllocation."Expense Category", ExpenseSplitAllocation."Expense Subcategory Code");
        if SourceExpenseReportLine."VAT Liable" and NewExpenseReportLine.Refundable then begin
            NewExpenseReportLine."Vendor No." := SourceExpenseReportLine."Vendor No.";
            NewExpenseReportLine."VAT Liable" := true;
        end;
        NewExpenseReportLine.Validate(Amount, ExpenseSplitAllocation.Amount);
        NewExpenseReportLine."Original Amount" := SourceExpenseReportLine."Original Amount";
        NewExpenseReportLine."Split from Line No." := GetOriginalLineNo(SourceExpenseReportLine);

        NewExpenseReportLine.SetSkipRuleApplication(false);
        NewExpenseReportLine.ApplyRule(true, false);
        NewExpenseReportLine.Modify(true);

        // The receipt covers both lines, so the new line keeps a copy of it.
        ExpenseReport.CopyReportLineAttachments(
            SourceExpenseReportLine."Document No.", SourceExpenseReportLine."Line No.", NewExpenseReportLine."Document No.", NewExpenseReportLine."Line No.");
        NewExpenseReportLine.Get(NewExpenseReportLine."Document No.", NewExpenseReportLine."Line No.");
    end;

    local procedure SetVATProdPostingGroup(var NewExpenseReportLine: Record "Expense Report Line"; SourceExpenseReportLine: Record "Expense Report Line"; ExpenseCategoryCode: Code[20]; ExpenseSubcategoryCode: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubcategory: Record "Expense Subcategory";
        VATProdPostingGroup: Code[20];
    begin
        VATProdPostingGroup := SourceExpenseReportLine."VAT Prod. Posting Group";
        if ExpenseCategory.Get(ExpenseCategoryCode) then
            if ExpenseCategory."VAT Prod. Posting Group" <> '' then
                VATProdPostingGroup := ExpenseCategory."VAT Prod. Posting Group";
        if ExpenseSubcategory.Get(ExpenseCategoryCode, ExpenseSubcategoryCode) then
            if ExpenseSubcategory."VAT Prod. Posting Group" <> '' then
                VATProdPostingGroup := ExpenseSubcategory."VAT Prod. Posting Group";
        if VATProdPostingGroup = '' then
            exit;
        if NewExpenseReportLine."VAT Bus. Posting Group" = '' then
            NewExpenseReportLine."VAT Prod. Posting Group" := VATProdPostingGroup
        else
            NewExpenseReportLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
    end;

    // A line that was split again keeps pointing to the first line of the receipt.
    local procedure GetOriginalLineNo(SourceExpenseReportLine: Record "Expense Report Line"): Integer
    begin
        if SourceExpenseReportLine."Split from Line No." <> 0 then
            exit(SourceExpenseReportLine."Split from Line No.");

        exit(SourceExpenseReportLine."Line No.");
    end;

    local procedure GetSplitLineNo(SourceExpenseReportLine: Record "Expense Report Line"; PreviousLineNo: Integer): Integer
    var
        NextExpenseReportLine: Record "Expense Report Line";
    begin
        NextExpenseReportLine.SetLoadFields("Line No.");
        NextExpenseReportLine.SetRange("Document No.", SourceExpenseReportLine."Document No.");
        NextExpenseReportLine.SetFilter("Line No.", '>%1', PreviousLineNo);
        if not NextExpenseReportLine.FindFirst() then
            exit(PreviousLineNo + 10000);
        if NextExpenseReportLine."Line No." - PreviousLineNo > 1 then
            exit(PreviousLineNo + (NextExpenseReportLine."Line No." - PreviousLineNo) div 2);

        exit(SourceExpenseReportLine.GetNextExpenseReportLineNo(SourceExpenseReportLine."Document No."));
    end;

    local procedure CreateExpenseForUser(SourceExpenseReportLine: Record "Expense Report Line"; ExpenseSplitAllocation: Record "Expense Split Allocation"): Code[20]
    var
        Expense: Record Expense;
    begin
        Expense.Init();
        Expense.Insert(true);

        Expense.SetHideValidationDialog(true);
        Expense.Validate("Expense User No.", ExpenseSplitAllocation."Expense User No.");
        Expense.Validate("Expense Category", SourceExpenseReportLine."Expense Category");
        if SourceExpenseReportLine."Expense Subcategory Code" <> '' then
            Expense.Validate("Expense Subcategory", SourceExpenseReportLine."Expense Subcategory Code");
        Expense.Validate(Description, SourceExpenseReportLine.Description);
        Expense.Validate(Justification, SourceExpenseReportLine.Justification);
        Expense.Validate("Expense Date", SourceExpenseReportLine."Expense Date");
        Expense.Validate("Expense Time", SourceExpenseReportLine."Expense Time");
        Expense.Validate("Merchant Name", SourceExpenseReportLine."Merchant Name");
        Expense.Validate("Merchant Registration No.", SourceExpenseReportLine."Merchant Registration No.");
        Expense.Validate("Merchant VAT Registration No.", SourceExpenseReportLine."Merchant VAT Registration No.");
        Expense.Validate("Expense Ext. Doc. No.", SourceExpenseReportLine."Expense Ext. Doc. No.");
        Expense."Expense Vendor No." := SourceExpenseReportLine."Expense Vendor No.";
        if SourceExpenseReportLine."Payment Method Code" <> '' then
            Expense.Validate("Payment Method Code", SourceExpenseReportLine."Payment Method Code");
        Expense.Validate(Refundable, SourceExpenseReportLine.Refundable);
        Expense.Validate(Billable, SourceExpenseReportLine.Billable);
        Expense.Validate("Billable to Customer", SourceExpenseReportLine."Billable to Customer");
        Expense.Validate("Job No.", SourceExpenseReportLine."Job No.");
        Expense.Validate("Job Task No.", SourceExpenseReportLine."Job Task No.");
        Expense.Validate("VAT Bus. Posting Group", SourceExpenseReportLine."VAT Bus. Posting Group");
        Expense.Validate("VAT Prod. Posting Group", SourceExpenseReportLine."VAT Prod. Posting Group");
        Expense.Validate("Currency Code", SourceExpenseReportLine."Expense Currency Code");
        Expense.Validate(Amount, ExpenseSplitAllocation.Amount);
        Expense."Original Amount" := SourceExpenseReportLine."Original Amount";
        Expense."Split from Exp. Report No." := SourceExpenseReportLine."Document No.";
        Expense."Split from Exp. Rep. Line No." := GetOriginalLineNo(SourceExpenseReportLine);
        Expense.Modify(true);

        CopyLineAttachmentsToExpense(SourceExpenseReportLine, Expense."No.");
        exit(Expense."No.");
    end;

    local procedure CopyLineAttachmentsToExpense(SourceExpenseReportLine: Record "Expense Report Line"; ExpenseNo: Code[20])
    var
        SourceDocumentAttachment: Record "Document Attachment";
        NewDocumentAttachment: Record "Document Attachment";
    begin
        SourceDocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        SourceDocumentAttachment.SetRange("No.", SourceExpenseReportLine."Document No.");
        SourceDocumentAttachment.SetRange("Line No.", SourceExpenseReportLine."Line No.");
        if SourceDocumentAttachment.FindSet() then
            repeat
                NewDocumentAttachment := SourceDocumentAttachment;
                NewDocumentAttachment."Table ID" := Database::Expense;
                NewDocumentAttachment."No." := ExpenseNo;
                NewDocumentAttachment."Line No." := 0;
                NewDocumentAttachment.ID := 0;
                NewDocumentAttachment.Insert(true);
            until SourceDocumentAttachment.Next() = 0;
    end;

    local procedure JoinExpenseNos(ExpenseNos: List of [Code[20]]) Result: Text
    var
        ExpenseNo: Code[20];
    begin
        foreach ExpenseNo in ExpenseNos do
            if Result = '' then
                Result := ExpenseNo
            else
                Result += ', ' + ExpenseNo;
    end;
}
