// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.VAT.Setup;

codeunit 148348 "Expense VAT Spec. API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
    end;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseVATSpecifications', Locked = true;

    [Test]
    procedure AgentVATSpecificationIsInsertedThroughAPI()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseVATSpecification: Record "Expense VAT Specification";
        RequestBody: JsonObject;
        ResponseText: Text;
        RequestText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] An authorized Expense Agent caller creates a VAT specification through the OData API.
        Initialize();

        // [GIVEN] A persisted expense that can own the agent-authored VAT specification.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 120);
        Commit();

        // [WHEN] The VAT specification is posted through the published API endpoint.
        RequestBody.Add('expenseNo', Expense."No.");
        RequestBody.Add('vatPercent', 20);
        RequestBody.Add('vatBaseAmount', 100);
        RequestBody.Add('vatAmount', 20);
        RequestBody.Add('amount', 120);
        RequestBody.Add('amountLCY', 120);
        RequestBody.Add('vatBaseAmountLCY', 100);
        RequestBody.Add('vatAmountLCY', 20);
        RequestBody.Add('confidence', 0.95);
        RequestBody.WriteTo(RequestText);
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense VAT Spec. API", ServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestText, ResponseText, 201);

        // [THEN] OnInsertRecord inserted one row and exit(false) prevented a duplicate platform insert.
        ExpenseVATSpecification.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseVATSpecification, 1);
        ExpenseVATSpecification.FindFirst();

        // [THEN] The endpoint persisted the caller payload as an immutable agent-authored source.
        Assert.AreEqual(ExpenseVATSpecification.Source::Agent, ExpenseVATSpecification.Source, 'The persisted source must be Agent.');
        Assert.AreEqual(20, ExpenseVATSpecification."VAT %", 'The VAT percent must match the API payload.');
        Assert.AreEqual(100, ExpenseVATSpecification."VAT Base Amount", 'The VAT base amount must match the API payload.');
        Assert.AreEqual(20, ExpenseVATSpecification."VAT Amount", 'The VAT amount must match the API payload.');
        Assert.AreEqual(120, ExpenseVATSpecification.Amount, 'The amount must match the API payload.');
        Assert.AreEqual(120, ExpenseVATSpecification."Amount (LCY)", 'The LCY amount must match the API payload.');
        Assert.AreEqual(100, ExpenseVATSpecification."VAT Base Amount (LCY)", 'The LCY VAT base amount must match the API payload.');
        Assert.AreEqual(20, ExpenseVATSpecification."VAT Amount (LCY)", 'The LCY VAT amount must match the API payload.');
        Assert.AreEqual(0.95, ExpenseVATSpecification.Confidence, 'The confidence must match the API payload.');
        Assert.AreNotEqual(
            0,
            StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseVATSpecification.SystemId)))),
            'The response must identify the row inserted by OnInsertRecord.');
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense VAT Spec. API Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense VAT Spec. API Test");
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Default VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        ExpenseAgentSetup.Modify(true);
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense VAT Spec. API Test");
    end;
}