// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148345 "Policies To Evaluate API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ExpenseReportLinesServiceNameTok: Label 'expenseReportLines', Locked = true;
        PoliciesToEvaluateServiceNameTok: Label 'policiesToEvaluate', Locked = true;

    [Test]
    procedure PoliciesToEvaluateAPIRebuildsForChangedSubject()
    var
        ExpensePolicyA: Record "Expense Policy";
        ExpensePolicyB: Record "Expense Policy";
        ExpenseReportLineA: Record "Expense Report Line";
        ExpenseReportLineB: Record "Expense Report Line";
        PolicyAIdText: Text;
        PolicyBIdText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policies-to-evaluate API rebuilds its temporary rows when the parent line changes.
        Initialize();
        CreateReportLinesAndPolicies(ExpenseReportLineA, ExpensePolicyA, ExpenseReportLineB, ExpensePolicyB);
        PolicyAIdText := LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpensePolicyA.SystemId)));
        PolicyBIdText := LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpensePolicyB.SystemId)));
        Commit();

        // [WHEN] Policies are requested for the first expense report line.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportLineA.SystemId),
            Page::"Expense Report Lines API",
            ExpenseReportLinesServiceNameTok,
            PoliciesToEvaluateServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] Only the first line's applicable policy is returned.
        Assert.AreNotEqual(0, StrPos(ResponseText, PolicyAIdText), 'The first line''s policy must be returned.');
        Assert.AreEqual(0, StrPos(ResponseText, PolicyBIdText), 'The second line''s policy must not be returned for the first line.');

        // [WHEN] Policies are requested for the second expense report line.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseReportLineB.SystemId),
            Page::"Expense Report Lines API",
            ExpenseReportLinesServiceNameTok,
            PoliciesToEvaluateServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] The temporary result is rebuilt for the changed subject.
        Assert.AreNotEqual(0, StrPos(ResponseText, PolicyBIdText), 'The second line''s policy must be returned.');
        Assert.AreEqual(0, StrPos(ResponseText, PolicyAIdText), 'The first line''s policy must not remain after the subject changes.');
        CompleteTest();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Policies To Evaluate API Test");
        LibraryExpense.CleanUpBeforeTesting();
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthHelper);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Policies To Evaluate API Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Enable Agent" := true;
        ExpenseAgentSetup.Modify();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Policies To Evaluate API Test");
    end;

    local procedure CreateReportLinesAndPolicies(
        var ExpenseReportLineA: Record "Expense Report Line";
        var ExpensePolicyA: Record "Expense Policy";
        var ExpenseReportLineB: Record "Expense Report Line";
        var ExpensePolicyB: Record "Expense Policy")
    var
        ExpenseCategoryA: Record "Expense Category";
        ExpenseCategoryB: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategoryA,
            ExpenseCategoryA."Reimbursement Type"::"Employee Paid",
            "Expense Detail Needed"::" ",
            ExpensePaymentMethod.Code);
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategoryB,
            ExpenseCategoryB."Reimbursement Type"::"Employee Paid",
            "Expense Detail Needed"::" ",
            ExpensePaymentMethod.Code);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLineA,
            ExpenseReportHeader,
            ExpenseUser."No.",
            ExpenseCategoryA.Code,
            ExpensePaymentMethod.Code,
            true,
            '',
            100);
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLineB,
            ExpenseReportHeader,
            ExpenseUser."No.",
            ExpenseCategoryB.Code,
            ExpensePaymentMethod.Code,
            true,
            '',
            200);
        LibraryExpense.CreateExpensePolicy(ExpensePolicyA, ExpenseCategoryA.Code, 'Policy for the first test category.');
        LibraryExpense.CreateExpensePolicy(ExpensePolicyB, ExpenseCategoryB.Code, 'Policy for the second test category.');
    end;

    local procedure CompleteTest()
    begin
        LibraryExpense.CleanUpBeforeTesting();
        Commit();
    end;
}
