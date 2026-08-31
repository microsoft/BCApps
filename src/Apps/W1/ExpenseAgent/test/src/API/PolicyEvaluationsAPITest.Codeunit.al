// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148344 "Policy Evaluations API Test"
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
        ServiceNameTok: Label 'expensePolicyEvaluations', Locked = true;
        BadRequestResponseErr: Label 'Response code is 400', Locked = true;
        SubjectVersionRequiredErr: Label 'Subject Version is required.';
        PolicyVersionRequiredErr: Label 'Policy Version is required.';
        ExpenseReportLineSubjectTypeTok: Label 'Expense_x0020_Report_x0020_Line', Locked = true;

    [Test]
    procedure PolicyEvaluationAPIInsertsFlagWithRequiredVersions()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
        ExpenseReportLine: Record "Expense Report Line";
        RequestBody: JsonObject;
        RequestBodyText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policy evaluation API accepts an evaluation result with current subject and policy versions.
        Initialize();
        CreateReportLineAndPolicy(ExpenseReportLine, ExpensePolicy);
        CreateRequestBody(RequestBody, ExpenseReportLine, ExpensePolicy, true, true);
        RequestBody.WriteTo(RequestBodyText);
        Commit();

        // [WHEN] The evaluation is posted through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Policy Evaluations API", ServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 201);

        // [THEN] The evaluation is stored with the supplied versions.
        ExpensePolicyEvaluation.Get(
            "Expense Policy Subject"::"Expense Report Line",
            ExpenseReportLine.SystemId,
            ExpensePolicy.SystemId,
            ExpenseReportLine."Policy Eval Version",
            ExpensePolicy."Version");
        Assert.IsTrue(ExpensePolicyEvaluation.Compliant, 'The API must store the supplied compliance result.');
        CompleteTest();
    end;

    [Test]
    procedure PolicyEvaluationAPIRejectsMissingSubjectVersion()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpenseReportLine: Record "Expense Report Line";
        RequestBody: JsonObject;
        RequestBodyText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policy evaluation API requires the subject version.
        Initialize();
        CreateReportLineAndPolicy(ExpenseReportLine, ExpensePolicy);
        CreateRequestBody(RequestBody, ExpenseReportLine, ExpensePolicy, false, true);
        RequestBody.WriteTo(RequestBodyText);
        Commit();

        // [WHEN] An evaluation without subjectVersion is posted.
        // [THEN] The API rejects the request.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Policy Evaluations API", ServiceNameTok);
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 400);
        Assert.ExpectedError(BadRequestResponseErr);
        Assert.ExpectedError(SubjectVersionRequiredErr);
        CompleteTest();
    end;

    [Test]
    procedure PolicyEvaluationAPIRejectsMissingPolicyVersion()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpenseReportLine: Record "Expense Report Line";
        RequestBody: JsonObject;
        RequestBodyText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policy evaluation API requires the policy version.
        Initialize();
        CreateReportLineAndPolicy(ExpenseReportLine, ExpensePolicy);
        CreateRequestBody(RequestBody, ExpenseReportLine, ExpensePolicy, true, false);
        RequestBody.WriteTo(RequestBodyText);
        Commit();

        // [WHEN] An evaluation without policyVersion is posted.
        // [THEN] The API rejects the request.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Policy Evaluations API", ServiceNameTok);
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 400);
        Assert.ExpectedError(BadRequestResponseErr);
        Assert.ExpectedError(PolicyVersionRequiredErr);
        CompleteTest();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Policy Evaluations API Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Policy Evaluations API Test");
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
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Policy Evaluations API Test");
    end;

    local procedure CreateReportLineAndPolicy(var ExpenseReportLine: Record "Expense Report Line"; var ExpensePolicy: Record "Expense Policy")
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory,
            ExpenseCategory."Reimbursement Type"::"Employee Paid",
            "Expense Detail Needed"::" ",
            ExpensePaymentMethod.Code);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine,
            ExpenseReportHeader,
            ExpenseUser."No.",
            ExpenseCategory.Code,
            ExpensePaymentMethod.Code,
            true,
            '',
            100);
        LibraryExpense.CreateExpensePolicy(ExpensePolicy, ExpenseCategory.Code, 'Receipts must comply with the test policy.');
    end;

    local procedure CreateRequestBody(
        var RequestBody: JsonObject;
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePolicy: Record "Expense Policy";
        IncludeSubjectVersion: Boolean;
        IncludePolicyVersion: Boolean)
    begin
        RequestBody.Add('subjectSystemId', ExpenseReportLine.SystemId);
        RequestBody.Add('subjectType', ExpenseReportLineSubjectTypeTok);
        if IncludeSubjectVersion then
            RequestBody.Add('subjectVersion', ExpenseReportLine."Policy Eval Version");
        RequestBody.Add('policySystemId', ExpensePolicy.SystemId);
        if IncludePolicyVersion then
            RequestBody.Add('policyVersion', ExpensePolicy."Version");
        RequestBody.Add('reason', 'The expense complies with the policy.');
        RequestBody.Add('compliant', true);
    end;

    local procedure CompleteTest()
    begin
        LibraryExpense.CleanUpBeforeTesting();
        Commit();
    end;
}
