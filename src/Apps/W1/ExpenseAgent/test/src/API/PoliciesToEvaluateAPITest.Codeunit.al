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
        IsInitialized: Boolean;
        ExpenseReportLinesServiceNameTok: Label 'expenseReportLines', Locked = true;

    [Test]
    procedure PoliciesToEvaluateAPIRebuildsForChangedSubject()
    var
        ExpensePolicyA: Record "Expense Policy";
        ExpensePolicyB: Record "Expense Policy";
        ExpenseReportLineA: Record "Expense Report Line";
        ExpenseReportLineB: Record "Expense Report Line";
        PoliciesForLineA: JsonArray;
        PoliciesForLineB: JsonArray;
        LineAIdText: Text;
        LineBIdText: Text;
        PolicyAIdText: Text;
        PolicyBIdText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policies-to-evaluate API rebuilds its temporary rows when the parent line changes.
        Initialize();
        CreateReportLinesAndPolicies(ExpenseReportLineA, ExpensePolicyA, ExpenseReportLineB, ExpensePolicyB);
        LineAIdText := LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseReportLineA.SystemId)));
        LineBIdText := LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseReportLineB.SystemId)));
        PolicyAIdText := LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpensePolicyA.SystemId)));
        PolicyBIdText := LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpensePolicyB.SystemId)));
        Commit();

        // [WHEN] Both lines and their policies to evaluate are requested in one expanded response.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Report Lines API", ExpenseReportLinesServiceNameTok);
        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&$expand=policiesToEvaluate'
        else
            TargetURL += '?$expand=policiesToEvaluate';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Each line's nested collection contains only its applicable policy.
        Assert.IsTrue(TryGetPoliciesForLine(ResponseText, LineAIdText, PoliciesForLineA), 'The first expense report line must be returned.');
        Assert.IsTrue(TryGetPoliciesForLine(ResponseText, LineBIdText, PoliciesForLineB), 'The second expense report line must be returned.');
        Assert.IsTrue(PolicyCollectionContains(PoliciesForLineA, PolicyAIdText), 'The first line''s policy must be returned for the first line.');
        Assert.IsFalse(PolicyCollectionContains(PoliciesForLineA, PolicyBIdText), 'The second line''s policy must not be returned for the first line.');
        Assert.IsTrue(PolicyCollectionContains(PoliciesForLineB, PolicyBIdText), 'The second line''s policy must be returned for the second line.');
        Assert.IsFalse(PolicyCollectionContains(PoliciesForLineB, PolicyAIdText), 'The first line''s policy must not be returned for the second line.');
        CompleteTest();
    end;

    local procedure TryGetPoliciesForLine(ResponseText: Text; LineIdText: Text; var PoliciesToEvaluate: JsonArray): Boolean
    var
        RootObject: JsonObject;
        LineObject: JsonObject;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        PropertyToken: JsonToken;
    begin
        Clear(PoliciesToEvaluate);
        RootObject.ReadFrom(ResponseText);
        if not RootObject.Get('value', PropertyToken) then
            exit(false);

        LinesArray := PropertyToken.AsArray();
        foreach LineToken in LinesArray do begin
            LineObject := LineToken.AsObject();
            if LineObject.Get('id', PropertyToken) then
                if LowerCase(PropertyToken.AsValue().AsText()) = LineIdText then begin
                    if not LineObject.Get('policiesToEvaluate', PropertyToken) then
                        exit(false);
                    PoliciesToEvaluate := PropertyToken.AsArray();
                    exit(true);
                end;
        end;
        exit(false);
    end;

    local procedure PolicyCollectionContains(PoliciesToEvaluate: JsonArray; PolicyIdText: Text): Boolean
    var
        PolicyObject: JsonObject;
        PolicyToken: JsonToken;
        PropertyToken: JsonToken;
    begin
        foreach PolicyToken in PoliciesToEvaluate do begin
            PolicyObject := PolicyToken.AsObject();
            if PolicyObject.Get('policySystemId', PropertyToken) then
                if LowerCase(PropertyToken.AsValue().AsText()) = PolicyIdText then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Policies To Evaluate API Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
        if IsInitialized then
            exit;

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
