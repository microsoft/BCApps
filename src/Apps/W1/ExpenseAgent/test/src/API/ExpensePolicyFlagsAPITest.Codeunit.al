// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148344 "Expense Policy Flags API Test"
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
        ServiceNameTok: Label 'expensePolicyFlags', Locked = true;
        BadRequestResponseErr: Label 'Response code is 400', Locked = true;

    [Test]
    procedure PolicyFlagAPIInsertsFlagWithRequiredVersions()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyFlag: Record "Expense Policy Flag";
        ExpenseReportLine: Record "Expense Report Line";
        RequestBody: JsonObject;
        RequestBodyText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policy flag API accepts an evaluation result with current subject and policy versions.
        Initialize();
        CreateReportLineAndPolicy(ExpenseReportLine, ExpensePolicy);
        CreateRequestBody(RequestBody, ExpenseReportLine, ExpensePolicy, true, true);
        RequestBody.WriteTo(RequestBodyText);
        Commit();

        // [WHEN] The flag is posted through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Policy Flags API", ServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 201);

        // [THEN] The flag is stored with the supplied versions.
        ExpensePolicyFlag.Get(
            "Expense Policy Subject"::"Expense Report Line",
            ExpenseReportLine.SystemId,
            ExpensePolicy.SystemId,
            ExpenseReportLine."Policy Eval Version",
            ExpensePolicy."Version");
        Assert.IsTrue(ExpensePolicyFlag.Compliant, 'The API must store the supplied compliance result.');
        CompleteTest();
    end;

    [Test]
    procedure PolicyFlagAPIRejectsMissingSubjectVersion()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpenseReportLine: Record "Expense Report Line";
        RequestBody: JsonObject;
        RequestBodyText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policy flag API requires the subject version.
        Initialize();
        CreateReportLineAndPolicy(ExpenseReportLine, ExpensePolicy);
        CreateRequestBody(RequestBody, ExpenseReportLine, ExpensePolicy, false, true);
        RequestBody.WriteTo(RequestBodyText);
        Commit();

        // [WHEN] A flag without subjectVersion is posted.
        // [THEN] The API rejects the request.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Policy Flags API", ServiceNameTok);
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 400);
        Assert.ExpectedError(BadRequestResponseErr);
        CompleteTest();
    end;

    [Test]
    procedure PolicyFlagAPIRejectsMissingPolicyVersion()
    var
        ExpensePolicy: Record "Expense Policy";
        ExpenseReportLine: Record "Expense Report Line";
        RequestBody: JsonObject;
        RequestBodyText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The policy flag API requires the policy version.
        Initialize();
        CreateReportLineAndPolicy(ExpenseReportLine, ExpensePolicy);
        CreateRequestBody(RequestBody, ExpenseReportLine, ExpensePolicy, true, false);
        RequestBody.WriteTo(RequestBodyText);
        Commit();

        // [WHEN] A flag without policyVersion is posted.
        // [THEN] The API rejects the request.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Policy Flags API", ServiceNameTok);
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBodyText, ResponseText, 400);
        Assert.ExpectedError(BadRequestResponseErr);
        CompleteTest();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Policy Flags API Test");
        LibraryExpense.CleanUpBeforeTesting();
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthHelper);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Policy Flags API Test");
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
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Policy Flags API Test");
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
        RequestBody.Add('subjectType', 'expenseReportLine');
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
