// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148296 "Exp. Report Per Diem API Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseReportLinePerDiems', Locked = true;
        MethodNotAllowedResponseErr: Label 'Response code is 405', Locked = true;
        BadRequestResponseErr: Label 'Response code is 400', Locked = true;

    [Test]
    procedure PerDiemAPIRejectsInsert()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        RequestBody: JsonObject;
        RequestText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Clients cannot add daily rows outside BC's parent-driven generation.
        Initialize();
        CreateEvaluatedReportLineWithPerDiem(ExpenseReportLine, ExpenseReportLinePerDiem);
        RequestBody.Add('expenseReportNo', ExpenseReportLine."Document No.");
        RequestBody.Add('expenseReportLineNo', ExpenseReportLine."Line No.");
        RequestBody.Add('lineNo', ExpenseReportLinePerDiem."Line No." + 10000);
        RequestBody.Add('date', ExpenseReportLinePerDiem.Date + 1);
        RequestBody.WriteTo(RequestText);
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Exp. Report Line Per Diem API", ServiceNameTok);
        Commit();

        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestText, ResponseText, 405);
        Assert.ExpectedError(MethodNotAllowedResponseErr);

        AssertRowsUnchanged(ExpenseReportLine, ExpenseReportLinePerDiem);
    end;

    [Test]
    procedure PerDiemAPIRejectsDelete()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Clients cannot delete a generated daily row or change its evaluated parent.
        Initialize();
        CreateEvaluatedReportLineWithPerDiem(ExpenseReportLine, ExpenseReportLinePerDiem);
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseReportLinePerDiem.SystemId), Page::"Exp. Report Line Per Diem API", ServiceNameTok);
        Commit();

        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 400);
        Assert.ExpectedError(BadRequestResponseErr);

        AssertRowsUnchanged(ExpenseReportLine, ExpenseReportLinePerDiem);
    end;

    [Test]
    procedure PerDiemAPIRetainsRead()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ResponseBody: JsonObject;
        ResponseToken: JsonToken;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Generated per diems remain readable without invalidating the parent.
        Initialize();
        CreateEvaluatedReportLineWithPerDiem(ExpenseReportLine, ExpenseReportLinePerDiem);
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseReportLinePerDiem.SystemId), Page::"Exp. Report Line Per Diem API", ServiceNameTok);
        Commit();

        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        ResponseBody.ReadFrom(ResponseText);
        ResponseBody.Get('id', ResponseToken);
        Assert.AreEqual(
            LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseReportLinePerDiem.SystemId))),
            LowerCase(ResponseToken.AsValue().AsText()), 'GET must return the generated row.');
        ResponseBody.Get('perDiemAmount', ResponseToken);
        Assert.AreEqual(100, ResponseToken.AsValue().AsDecimal(), 'GET must expose the daily amount.');
        ResponseBody.Get('breakfast', ResponseToken);
        Assert.IsFalse(ResponseToken.AsValue().AsBoolean(), 'Breakfast must initially be excluded.');
        ResponseBody.Get('lunch', ResponseToken);
        Assert.IsFalse(ResponseToken.AsValue().AsBoolean(), 'Lunch must initially be excluded.');
        ResponseBody.Get('dinner', ResponseToken);
        Assert.IsFalse(ResponseToken.AsValue().AsBoolean(), 'Dinner must initially be excluded.');
        AssertRowsUnchanged(ExpenseReportLine, ExpenseReportLinePerDiem);
    end;

    [Test]
    procedure PerDiemAPIMealPatchReducesAmountAndInvalidatesParent()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        EvaluatedVersion: Integer;
        EvaluatedAt: DateTime;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] PATCH remains available for meals and invalidates the previously evaluated parent.
        Initialize();
        CreateEvaluatedReportLineWithPerDiem(ExpenseReportLine, ExpenseReportLinePerDiem);
        EvaluatedVersion := ExpenseReportLine."Evaluated Policy Version";
        EvaluatedAt := ExpenseReportLine."Policies Evaluated At";
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseReportLinePerDiem.SystemId), Page::"Exp. Report Line Per Diem API", ServiceNameTok);
        Commit();

        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(
            TargetURL, '{"breakfast":true,"lunch":true,"dinner":true}', ResponseText, 200);

        ExpenseReportLinePerDiem.Get(
            ExpenseReportLinePerDiem."Expense Report No.", ExpenseReportLinePerDiem."Expense Report Line No.", ExpenseReportLinePerDiem."Line No.");
        Assert.IsTrue(ExpenseReportLinePerDiem.Breakfast, 'PATCH must persist breakfast.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Lunch, 'PATCH must persist lunch.');
        Assert.IsTrue(ExpenseReportLinePerDiem.Dinner, 'PATCH must persist dinner.');
        Assert.AreEqual(40, ExpenseReportLinePerDiem."Per Diem Amount", 'The daily amount must reflect the 10%, 20%, and 30% meal reductions.');
        Assert.AreEqual(100, ExpenseReportLinePerDiem."Original Per Diem Amount", 'PATCH must preserve the original daily rate.');
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(40, ExpenseReportLine.Amount, 'The parent amount must reflect the reduced daily amount.');
        Assert.IsTrue(ExpenseReportLine."Policy Eval Version" > EvaluatedVersion, 'Meal changes must advance the parent policy version.');
        Assert.AreEqual(EvaluatedVersion, ExpenseReportLine."Evaluated Policy Version", 'PATCH must not mark the new version evaluated.');
        Assert.AreEqual(EvaluatedAt, ExpenseReportLine."Policies Evaluated At", 'PATCH must preserve the prior evaluation timestamp.');
        Assert.AreEqual("Expense Policy Status"::Stale, ExpenseReportLine.GetPolicyStatus(), 'Meal changes must leave the parent policy evaluation stale.');
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);
    end;

    local procedure AssertRowsUnchanged(ExpenseReportLine: Record "Expense Report Line"; ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem")
    var
        StoredLine: Record "Expense Report Line";
        StoredPerDiem: Record "Expense Report Line Per Diem";
    begin
        StoredPerDiem.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        StoredPerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(StoredPerDiem, 1);
        StoredPerDiem.GetBySystemId(ExpenseReportLinePerDiem.SystemId);
        Assert.AreEqual(ExpenseReportLinePerDiem.SystemRowVersion, StoredPerDiem.SystemRowVersion, 'The generated row must not change.');
        StoredLine.GetBySystemId(ExpenseReportLine.SystemId);
        Assert.AreEqual(ExpenseReportLine.SystemRowVersion, StoredLine.SystemRowVersion, 'The parent and its policy evaluation must not change.');
    end;

    local procedure CreateEvaluatedReportLineWithPerDiem(var ExpenseReportLine: Record "Expense Report Line"; var ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem")
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpensePolicy: Record "Expense Policy";
        ExpensePolicyEvaluation: Record "Expense Policy Evaluation";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::"Per Diem", ExpensePaymentMethod.Code);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        ExpenseReportLine.SetSkipRuleApplication(true);
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', 100);
        ExpenseReportLine.SetSkipRuleApplication(false);

        ExpenseReportLinePerDiem.Init();
        ExpenseReportLinePerDiem."Expense Report No." := ExpenseReportLine."Document No.";
        ExpenseReportLinePerDiem."Expense Report Line No." := ExpenseReportLine."Line No.";
        ExpenseReportLinePerDiem."Line No." := 10000;
        ExpenseReportLinePerDiem.Date := WorkDate();
        ExpenseReportLinePerDiem."Per Diem Amount" := 100;
        ExpenseReportLinePerDiem."Original Per Diem Amount" := 100;
        ExpenseReportLinePerDiem."Breakfast Reduction Percent" := 10;
        ExpenseReportLinePerDiem."Lunch Reduction Percent" := 20;
        ExpenseReportLinePerDiem."Dinner Reduction Percent" := 30;
        ExpenseReportLinePerDiem.Insert(true);

        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        LibraryExpense.CreateExpensePolicy(ExpensePolicy, ExpenseCategory.Code, 'Meals must comply with the per-diem policy.');
        LibraryExpense.CreateExpensePolicyEvaluation(ExpensePolicyEvaluation, ExpenseReportLine, ExpensePolicy, 'Compliant before meal changes.', true);
        ExpenseReportLine.MarkPoliciesEvaluated(ExpenseReportLine."Policy Eval Version");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual("Expense Policy Status"::Cleared, ExpenseReportLine.GetPolicyStatus(), 'The parent must be cleared before the API request.');
        ExpenseReportLinePerDiem.Get(
            ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", ExpenseReportLinePerDiem."Line No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Exp. Report Per Diem API Test");
        LibraryExpense.CleanUpBeforeTesting();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Exp. Report Per Diem API Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Exp. Report Per Diem API Test");
    end;
}
