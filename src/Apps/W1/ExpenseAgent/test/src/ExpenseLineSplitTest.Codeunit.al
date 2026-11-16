// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Foundation.Attachment;
using System.Utilities;

codeunit 148363 "Expense Line Split Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ExpenseLineSplit: Codeunit "Expense Line Split";
        IsInitialized: Boolean;
        SplitAmountTooHighErr: Label 'The amount to split must be less than the amount of the original line, %1.', Comment = '%1 = Amount of the original line';
        AgentNotEnabledErr: Label 'You can only split an expense with different users when the Expense Agent is enabled.';
        JustificationRequiredErr: Label 'Justification is required for this expense based on your organization''s rule.';
        ReceiptFileNameTxt: Label 'Receipt.txt', Locked = true;

    [Test]
    procedure SplitForSameUserMovesAmountsAndPreservesTotal()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        NewExpenseReportLine: Record "Expense Report Line";
        SplitCategory1: Record "Expense Category";
        SplitCategory2: Record "Expense Category";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        NewLineNos: List of [Integer];
        SourceAmount: Decimal;
        SplitAmount1: Decimal;
        SplitAmount2: Decimal;
    begin
        // [AI] v0.2
        // [SCENARIO 617067] Splitting a line for the same user moves the amounts to new lines and keeps the receipt total.
        Initialize();

        // [GIVEN] An open expense report with one line of amount X.
        SourceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, SourceAmount);

        // [GIVEN] Two split lines with different categories and amounts A1 and A2, where A1 + A2 < X.
        SplitAmount1 := Round(SourceAmount / 4, 0.01);
        SplitAmount2 := Round(SourceAmount / 5, 0.01);
        CreateExpenseCategory(SplitCategory1);
        CreateExpenseCategory(SplitCategory2);
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory1.Code, SplitAmount1);
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory2.Code, SplitAmount2);

        // [WHEN] The line is split for the same user.
        NewLineNos := ExpenseLineSplit.SplitLineForSameUser(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] The original line is reduced by A1 + A2 and remembers its original amount.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(SourceAmount - SplitAmount1 - SplitAmount2, ExpenseReportLine.Amount, 'The original line must be reduced by the split amounts.');
        Assert.AreEqual(SourceAmount, ExpenseReportLine."Original Amount", 'The original line must keep its amount before the split.');

        // [THEN] Two new lines are created with the split categories and amounts.
        Assert.AreEqual(2, NewLineNos.Count(), 'Two new lines must be created.');
        NewExpenseReportLine.Get(ExpenseReportHeader."No.", NewLineNos.Get(1));
        VerifySplitLine(NewExpenseReportLine, ExpenseReportLine, SplitCategory1.Code, SplitAmount1);
        NewExpenseReportLine.Get(ExpenseReportHeader."No.", NewLineNos.Get(2));
        VerifySplitLine(NewExpenseReportLine, ExpenseReportLine, SplitCategory2.Code, SplitAmount2);

        // [THEN] The total amount of the report still equals X.
        Assert.AreEqual(SourceAmount, GetReportTotalAmount(ExpenseReportHeader."No."), 'The total amount of the expense report must not change.');
    end;

    [Test]
    procedure SplitForSameUserCopiesReceiptAndSourceMetadata()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        NewExpenseReportLine: Record "Expense Report Line";
        SplitCategory: Record "Expense Category";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        NewLineNos: List of [Integer];
    begin
        // [AI] v0.2
        // [SCENARIO 617067] A new same-user split line keeps the receipt and the merchant data of the original line.
        Initialize();

        // [GIVEN] An open expense report line with a receipt attached.
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, LibraryRandom.RandDecInRange(100, 200, 2));
        CreateReceiptForExpenseReportLine(ExpenseReportLine);

        // [WHEN] The line is split for the same user.
        CreateExpenseCategory(SplitCategory);
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory.Code, Round(ExpenseReportLine.Amount / 2, 0.01));
        NewLineNos := ExpenseLineSplit.SplitLineForSameUser(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] The new line has a copy of the receipt and the original line keeps its receipt.
        NewExpenseReportLine.Get(ExpenseReportHeader."No.", NewLineNos.Get(1));
        Assert.AreEqual(1, CountExpenseReportLineAttachments(ExpenseReportLine), 'The original line must keep its receipt.');
        Assert.AreEqual(1, CountExpenseReportLineAttachments(NewExpenseReportLine), 'The new line must get a copy of the receipt.');

        // [THEN] The new line keeps the merchant, date and external document of the receipt.
        Assert.AreEqual(ExpenseReportLine."Merchant Name", NewExpenseReportLine."Merchant Name", 'Merchant Name must be copied.');
        Assert.AreEqual(ExpenseReportLine."Expense Ext. Doc. No.", NewExpenseReportLine."Expense Ext. Doc. No.", 'Expense Ext. Doc. No. must be copied.');
        Assert.AreEqual(ExpenseReportLine."Expense Date", NewExpenseReportLine."Expense Date", 'Expense Date must be copied.');
        Assert.AreEqual(ExpenseReportLine."Expense User No.", NewExpenseReportLine."Expense User No.", 'Expense User No. must be the same.');
    end;

    [Test]
    procedure SplitAgainKeepsFirstLineOfReceipt()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        FirstSplitLine: Record "Expense Report Line";
        SecondSplitLine: Record "Expense Report Line";
        SplitCategory: Record "Expense Category";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        NewLineNos: List of [Integer];
        SourceAmount: Decimal;
    begin
        // [AI] v0.2
        // [SCENARIO 617067] Splitting a line that was already split keeps pointing to the first line of the receipt.
        Initialize();

        // [GIVEN] An expense report line that was split once.
        SourceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, SourceAmount);
        CreateExpenseCategory(SplitCategory);
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory.Code, Round(SourceAmount / 2, 0.01));
        NewLineNos := ExpenseLineSplit.SplitLineForSameUser(ExpenseReportLine, TempExpenseSplitAllocation);
        FirstSplitLine.Get(ExpenseReportHeader."No.", NewLineNos.Get(1));

        // [WHEN] The new line is split again.
        TempExpenseSplitAllocation.DeleteAll();
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory.Code, Round(FirstSplitLine.Amount / 2, 0.01));
        NewLineNos := ExpenseLineSplit.SplitLineForSameUser(FirstSplitLine, TempExpenseSplitAllocation);

        // [THEN] The second split line points to the first line and keeps the amount of the receipt.
        SecondSplitLine.Get(ExpenseReportHeader."No.", NewLineNos.Get(1));
        Assert.AreEqual(ExpenseReportLine."Line No.", SecondSplitLine."Split from Line No.", 'The split line must point to the first line of the receipt.');
        Assert.AreEqual(SourceAmount, SecondSplitLine."Original Amount", 'The split line must keep the amount of the receipt.');
        Assert.AreEqual(SourceAmount, GetReportTotalAmount(ExpenseReportHeader."No."), 'The total amount of the expense report must not change.');
    end;

    [Test]
    procedure SplitForSameUserAppliesRuleToNewLine()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        NewExpenseReportLine: Record "Expense Report Line";
        SplitCategory: Record "Expense Category";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        NewLineNos: List of [Integer];
    begin
        // [AI] v0.2
        // [SCENARIO 617067] The rule of the split category is applied to the new line and validated.
        Initialize();

        // [GIVEN] A rule that always requires a justification for category C.
        CreateExpenseCategory(SplitCategory);
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, SplitCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::Always, '', '', ExpenseRuleCondition."Condition Type"::" ", 0);

        // [GIVEN] An open expense report line without a justification.
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, LibraryRandom.RandDecInRange(100, 200, 2));

        // [WHEN] Part of the line is split to category C.
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory.Code, Round(ExpenseReportLine.Amount / 2, 0.01));
        NewLineNos := ExpenseLineSplit.SplitLineForSameUser(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] The rule is stored on the new line.
        NewExpenseReportLine.Get(ExpenseReportHeader."No.", NewLineNos.Get(1));
        Assert.AreEqual(ExpenseRuleHeader.SystemId, NewExpenseReportLine."Applied Rule Id", 'The applicable rule must be applied to the new line.');

        // [THEN] The new line is validated against the rule.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", NewExpenseReportLine."Document No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", NewExpenseReportLine."Line No.");
        ExpenseReportRuleViolation.SetRange(Description, JustificationRequiredErr);
        Assert.RecordCount(ExpenseReportRuleViolation, 1);
    end;

    [Test]
    procedure SplitForSameUserRollsBackWhenSplitAmountIsTooHigh()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        SplitCategory1: Record "Expense Category";
        SplitCategory2: Record "Expense Category";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        SourceAmount: Decimal;
    begin
        // [AI] v0.2
        // [SCENARIO 617067] A split whose lines add up to the full amount is rejected and nothing is changed.
        Initialize();

        // [GIVEN] An open expense report line with amount X.
        SourceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, SourceAmount);

        // [GIVEN] Two split lines that add up to X.
        CreateExpenseCategory(SplitCategory1);
        CreateExpenseCategory(SplitCategory2);
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory1.Code, Round(SourceAmount / 2, 0.01));
        AddSplitLine(TempExpenseSplitAllocation, SplitCategory2.Code, SourceAmount - Round(SourceAmount / 2, 0.01));

        // [GIVEN] Save the expense report so that only the split is rolled back.
        Commit();

        // [WHEN] The line is split for the same user.
        asserterror ExpenseLineSplit.SplitLineForSameUser(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] An error is shown and the expense report is unchanged.
        Assert.ExpectedError(StrSubstNo(SplitAmountTooHighErr, SourceAmount));
        VerifyReportUnchanged(ExpenseReportLine, SourceAmount);
    end;

    [Test]
    procedure SplitForDifferentUsersCreatesOpenExpensesAndPreservesTotal()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser1: Record "Expense User";
        ExpenseUser2: Record "Expense User";
        Expense: Record Expense;
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        CreatedExpenseNos: List of [Code[20]];
        SourceAmount: Decimal;
        AllocatedAmount1: Decimal;
        AllocatedAmount2: Decimal;
    begin
        // [AI] v0.2
        // [SCENARIO 617067] Splitting a line with other users creates an open expense for each user and keeps the receipt total.
        Initialize();
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        // [GIVEN] An open expense report line with amount X.
        SourceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, SourceAmount);

        // [GIVEN] Allocations of A1 and A2 to two other users.
        AllocatedAmount1 := Round(SourceAmount / 4, 0.01);
        AllocatedAmount2 := Round(SourceAmount / 5, 0.01);
        LibraryExpense.CreateExpenseUser(ExpenseUser1);
        LibraryExpense.CreateExpenseUser(ExpenseUser2);
        AddAllocation(TempExpenseSplitAllocation, ExpenseUser1."No.", AllocatedAmount1);
        AddAllocation(TempExpenseSplitAllocation, ExpenseUser2."No.", AllocatedAmount2);

        // [WHEN] The line is split with the other users.
        CreatedExpenseNos := ExpenseLineSplit.SplitLineForDifferentUsers(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] The original line is reduced by A1 + A2 and remembers its original amount.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(SourceAmount - AllocatedAmount1 - AllocatedAmount2, ExpenseReportLine.Amount, 'The original line must be reduced by the allocated amounts.');
        Assert.AreEqual(SourceAmount, ExpenseReportLine."Original Amount", 'The original line must keep its amount before the split.');

        // [THEN] An open expense is created for each user with the allocated amount.
        Assert.AreEqual(2, CreatedExpenseNos.Count(), 'An expense must be created for each user.');
        Expense.Get(CreatedExpenseNos.Get(1));
        VerifySplitExpense(Expense, ExpenseReportLine, ExpenseUser1."No.", AllocatedAmount1);
        Expense.Get(CreatedExpenseNos.Get(2));
        VerifySplitExpense(Expense, ExpenseReportLine, ExpenseUser2."No.", AllocatedAmount2);

        // [THEN] The remaining line and the new expenses still add up to X.
        Assert.AreEqual(
            SourceAmount, GetReportTotalAmount(ExpenseReportHeader."No.") + GetSplitExpensesTotalAmount(ExpenseReportLine),
            'The amount of the receipt must be preserved across the expense report and the new expenses.');
    end;

    [Test]
    procedure SplitForDifferentUsersCopiesReceiptToExpense()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        DocumentAttachment: Record "Document Attachment";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        CreatedExpenseNos: List of [Code[20]];
    begin
        // [AI] v0.2
        // [SCENARIO 617067] The new expense for another user gets a copy of the receipt.
        Initialize();
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        // [GIVEN] An open expense report line with a receipt attached.
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, LibraryRandom.RandDecInRange(100, 200, 2));
        CreateReceiptForExpenseReportLine(ExpenseReportLine);

        // [WHEN] The line is split with another user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        AddAllocation(TempExpenseSplitAllocation, ExpenseUser."No.", Round(ExpenseReportLine.Amount / 2, 0.01));
        CreatedExpenseNos := ExpenseLineSplit.SplitLineForDifferentUsers(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] The new expense has a copy of the receipt and the original line keeps its receipt.
        Assert.AreEqual(1, CountExpenseReportLineAttachments(ExpenseReportLine), 'The original line must keep its receipt.');
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.SetRange("No.", CreatedExpenseNos.Get(1));
        Assert.RecordCount(DocumentAttachment, 1);
    end;

    [Test]
    procedure SplitForDifferentUsersFailsWhenAgentIsDisabled()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        SourceAmount: Decimal;
    begin
        // [AI] v0.2
        // [SCENARIO 617067] An expense cannot be split with other users when the Expense Agent is disabled.
        Initialize();

        // [GIVEN] The Expense Agent is disabled and an open expense report line with amount X.
        LibraryExpense.UpdateEnableAgentInAgentSetup(false);
        SourceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, SourceAmount);

        // [GIVEN] An allocation to another user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        AddAllocation(TempExpenseSplitAllocation, ExpenseUser."No.", Round(SourceAmount / 2, 0.01));

        // [GIVEN] Save the expense report so that only the split is rolled back.
        Commit();

        // [WHEN] The line is split with the other user.
        asserterror ExpenseLineSplit.SplitLineForDifferentUsers(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] An error is shown and nothing is changed.
        Assert.ExpectedError(AgentNotEnabledErr);
        VerifyReportUnchanged(ExpenseReportLine, SourceAmount);
        VerifyNoSplitExpenses(ExpenseReportLine);
    end;

    [Test]
    procedure SplitForDifferentUsersRollsBackWhenExpenseCannotBeCreated()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
        UnknownExpenseUserNo: Code[20];
        SourceAmount: Decimal;
    begin
        // [AI] v0.2
        // [SCENARIO 617067] When an expense cannot be created for one of the users, the whole split is rolled back.
        Initialize();
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        // [GIVEN] An open expense report line with amount X.
        SourceAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateExpenseReportWithLine(ExpenseReportHeader, ExpenseReportLine, SourceAmount);

        // [GIVEN] A valid allocation followed by an allocation to an expense user that does not exist.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        AddAllocation(TempExpenseSplitAllocation, ExpenseUser."No.", Round(SourceAmount / 4, 0.01));
        UnknownExpenseUserNo := LibraryUtility.GenerateGUID();
        TempExpenseSplitAllocation.Init();
        TempExpenseSplitAllocation."Line No." := 20000;
        TempExpenseSplitAllocation."Expense User No." := UnknownExpenseUserNo;
        TempExpenseSplitAllocation.Amount := Round(SourceAmount / 4, 0.01);
        TempExpenseSplitAllocation.Insert();

        // [GIVEN] Save the expense report so that only the split is rolled back.
        Commit();

        // [WHEN] The line is split with the users.
        asserterror ExpenseLineSplit.SplitLineForDifferentUsers(ExpenseReportLine, TempExpenseSplitAllocation);

        // [THEN] An error is shown, the original line is not reduced and no expense is created for the first user.
        Assert.ExpectedError(UnknownExpenseUserNo);
        VerifyReportUnchanged(ExpenseReportLine, SourceAmount);
        VerifyNoSplitExpenses(ExpenseReportLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Line Split Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Line Split Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Line Split Test");
    end;

    local procedure CreateExpenseCategory(var ExpenseCategory: Record "Expense Category")
    begin
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
    end;

    local procedure CreateExpenseReportWithLine(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line"; Amount: Decimal)
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateExpenseCategory(ExpenseCategory);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
    end;

    local procedure AddSplitLine(var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary; ExpenseCategoryCode: Code[20]; Amount: Decimal)
    begin
        TempExpenseSplitAllocation.Init();
        TempExpenseSplitAllocation."Line No." := GetNextAllocationLineNo(TempExpenseSplitAllocation);
        TempExpenseSplitAllocation.Validate("Expense Category", ExpenseCategoryCode);
        TempExpenseSplitAllocation.Validate(Amount, Amount);
        TempExpenseSplitAllocation.Insert();
    end;

    local procedure AddAllocation(var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary; ExpenseUserNo: Code[20]; Amount: Decimal)
    begin
        TempExpenseSplitAllocation.Init();
        TempExpenseSplitAllocation."Line No." := GetNextAllocationLineNo(TempExpenseSplitAllocation);
        TempExpenseSplitAllocation.Validate("Expense User No.", ExpenseUserNo);
        TempExpenseSplitAllocation.Validate(Amount, Amount);
        TempExpenseSplitAllocation.Insert();
    end;

    local procedure GetNextAllocationLineNo(var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary): Integer
    var
        TempLastExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
    begin
        TempLastExpenseSplitAllocation.Copy(TempExpenseSplitAllocation, true);
        TempLastExpenseSplitAllocation.Reset();
        if TempLastExpenseSplitAllocation.FindLast() then
            exit(TempLastExpenseSplitAllocation."Line No." + 10000);

        exit(10000);
    end;

    local procedure CreateReceiptForExpenseReportLine(ExpenseReportLine: Record "Expense Report Line")
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStream: OutStream;
    begin
        RecRef.GetTable(ExpenseReportLine);
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(ReceiptFileNameTxt);
        DocumentAttachment.SaveAttachment(RecRef, ReceiptFileNameTxt, TempBlob);
    end;

    local procedure CountExpenseReportLineAttachments(ExpenseReportLine: Record "Expense Report Line"): Integer
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", ExpenseReportLine."Document No.");
        DocumentAttachment.SetRange("Line No.", ExpenseReportLine."Line No.");
        exit(DocumentAttachment.Count());
    end;

    local procedure GetReportTotalAmount(ExpenseReportNo: Code[20]): Decimal
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        ExpenseReportLine.CalcSums(Amount);
        exit(ExpenseReportLine.Amount);
    end;

    local procedure GetSplitExpensesTotalAmount(ExpenseReportLine: Record "Expense Report Line"): Decimal
    var
        Expense: Record Expense;
    begin
        FilterSplitExpenses(Expense, ExpenseReportLine);
        Expense.CalcSums(Amount);
        exit(Expense.Amount);
    end;

    local procedure FilterSplitExpenses(var Expense: Record Expense; ExpenseReportLine: Record "Expense Report Line")
    begin
        Expense.SetRange("Split from Exp. Report No.", ExpenseReportLine."Document No.");
        Expense.SetRange("Split from Exp. Rep. Line No.", ExpenseReportLine."Line No.");
    end;

    local procedure VerifySplitLine(NewExpenseReportLine: Record "Expense Report Line"; SourceExpenseReportLine: Record "Expense Report Line"; ExpectedExpenseCategory: Code[20]; ExpectedAmount: Decimal)
    begin
        Assert.AreEqual(ExpectedExpenseCategory, NewExpenseReportLine."Expense Category", 'The new line must use the split category.');
        Assert.AreEqual(ExpectedAmount, NewExpenseReportLine.Amount, 'The new line must have the split amount.');
        Assert.AreEqual(SourceExpenseReportLine."Line No.", NewExpenseReportLine."Split from Line No.", 'The new line must point to the original line.');
        Assert.AreEqual(SourceExpenseReportLine."Original Amount", NewExpenseReportLine."Original Amount", 'The new line must keep the amount of the receipt.');
    end;

    local procedure VerifySplitExpense(Expense: Record Expense; SourceExpenseReportLine: Record "Expense Report Line"; ExpectedExpenseUserNo: Code[20]; ExpectedAmount: Decimal)
    begin
        Assert.AreEqual(Expense.Status::Open, Expense.Status, 'The new expense must be open so that the user can confirm it.');
        Assert.AreEqual(ExpectedExpenseUserNo, Expense."Expense User No.", 'The new expense must belong to the selected user.');
        Assert.AreEqual(ExpectedAmount, Expense.Amount, 'The new expense must have the allocated amount.');
        Assert.AreEqual(SourceExpenseReportLine."Expense Category", Expense."Expense Category", 'The new expense must keep the category of the original line.');
        Assert.AreEqual(SourceExpenseReportLine."Merchant Name", Expense."Merchant Name", 'The new expense must keep the merchant of the original line.');
        Assert.AreEqual(SourceExpenseReportLine."Original Amount", Expense."Original Amount", 'The new expense must keep the amount of the receipt.');
        Assert.AreEqual(SourceExpenseReportLine."Document No.", Expense."Split from Exp. Report No.", 'The new expense must point to the original expense report.');
        Assert.AreEqual(SourceExpenseReportLine."Line No.", Expense."Split from Exp. Rep. Line No.", 'The new expense must point to the original line.');
        Assert.AreEqual('', Expense."Expense Report No.", 'The new expense must not be added to an expense report.');
    end;

    local procedure VerifyReportUnchanged(ExpenseReportLine: Record "Expense Report Line"; ExpectedAmount: Decimal)
    var
        StoredExpenseReportLine: Record "Expense Report Line";
    begin
        StoredExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(ExpectedAmount, StoredExpenseReportLine.Amount, 'The original line must not be reduced.');
        Assert.AreEqual(0, StoredExpenseReportLine."Original Amount", 'The original amount must not be set.');

        StoredExpenseReportLine.SetRange("Document No.", ExpenseReportLine."Document No.");
        Assert.RecordCount(StoredExpenseReportLine, 1);
    end;

    local procedure VerifyNoSplitExpenses(ExpenseReportLine: Record "Expense Report Line")
    var
        Expense: Record Expense;
    begin
        FilterSplitExpenses(Expense, ExpenseReportLine);
        Assert.RecordIsEmpty(Expense);
    end;
}
