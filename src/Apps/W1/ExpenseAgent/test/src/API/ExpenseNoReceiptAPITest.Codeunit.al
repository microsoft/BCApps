// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using System.TestLibraries.Utilities;

codeunit 148363 "Expense No Receipt API Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ExpensesServiceNameTok: Label 'expenses', Locked = true;
        CategoriesServiceNameTok: Label 'expenseCategories', Locked = true;

    [Test]
    procedure BlankDraftCanBeCreatedThroughAPI()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        RequestBody: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        RequestText: Text;
        ResponseText: Text;
        TargetURL: Text;
        ExpenseId: Guid;
    begin
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Commit();
        RequestBody.Add('expenseUserNumber', ExpenseUser."No.");
        RequestBody.Add('merchantName', '');
        RequestBody.Add('description', '');
        RequestBody.Add('expenseCategory', '');
        RequestBody.Add('currencyCode', '');
        RequestBody.Add('amount', 0);
        RequestBody.Add('expenseDate', Format(WorkDate(), 0, 9));
        RequestBody.WriteTo(RequestText);
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expenses API", ExpensesServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestText, ResponseText, 201);

        Response.ReadFrom(ResponseText);
        Response.Get('id', Token);
        Evaluate(ExpenseId, Token.AsValue().AsText());
        Expense.GetBySystemId(ExpenseId);
        Assert.AreEqual(Expense.Status::Open, Expense.Status, 'A draft must remain Open.');
        Assert.AreEqual('', Expense."Expense Category", 'A draft does not require a finalized category.');
        Assert.AreEqual('', Expense.Description, 'A draft does not require a finalized description.');
        Assert.AreEqual(0, Expense.Amount, 'A draft does not require an amount.');
        Assert.IsTrue(IsNullGuid(Expense."No Receipt Declaration ID"), 'Creating a draft must not generate a declaration.');
    end;

    [Test]
    procedure ScopedBlankDraftInheritsExpenseUserThroughAPI()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        RequestBody: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        RequestText: Text;
        ResponseText: Text;
        TargetURL: Text;
        ExpenseId: Guid;
    begin
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Commit();
        RequestBody.Add('merchantName', '');
        RequestBody.Add('description', '');
        RequestBody.Add('expenseCategory', '');
        RequestBody.Add('currencyCode', '');
        RequestBody.Add('amount', 0);
        RequestBody.Add('expenseDate', Format(WorkDate(), 0, 9));
        RequestBody.WriteTo(RequestText);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", 'expenseUsers', ExpensesServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestText, ResponseText, 201);

        Response.ReadFrom(ResponseText);
        Response.Get('id', Token);
        Evaluate(ExpenseId, Token.AsValue().AsText());
        Expense.GetBySystemId(ExpenseId);
        Assert.AreEqual(ExpenseUser."No.", Expense."Expense User No.", 'Scoped insertion must inherit the navigation owner without user fields in the payload.');
        Assert.AreEqual(Expense.Status::Open, Expense.Status, 'A scoped draft must remain Open.');
        Assert.AreEqual('', Expense."Expense Category", 'A scoped draft must allow an unfinished category.');
        Assert.AreEqual('', Expense.Description, 'A scoped draft must allow an unfinished description.');
        Assert.AreEqual('', Expense."Currency Code", 'An empty API currency must remain the internal LCY currency.');
        Assert.AreEqual(0, Expense.Amount, 'A scoped draft must allow an unfinished amount.');
        Assert.IsTrue(IsNullGuid(Expense."No Receipt Declaration ID"), 'Scoped insertion must not attest or generate a declaration.');
    end;

    [Test]
    procedure NoReceiptFieldsAndEnumsAreExposedThroughAPI()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        Response: JsonObject;
        Token: JsonToken;
        ResponseText: Text;
        TargetURL: Text;
    begin
        Initialize();
        CreateExpense(Expense);
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory."Amount Limit for No Receipt" := 101;
        ExpenseCategory.Modify();
        Expense.UpdateAmount();
        Expense.Modify();
        Commit();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Response.ReadFrom(ResponseText);
        Response.Get('noReceiptType', Token);
        Assert.AreEqual('Receipt_x0020_not_x0020_needed', Token.AsValue().AsText(), 'The default-schema enum wire name must remain stable.');
        Response.Get('noReceiptDeclarationCurrent', Token);
        Assert.IsFalse(Token.AsValue().AsBoolean(), 'An automatic exemption has no current declaration.');
        Response.Get('amountLCY', Token);
        Assert.AreEqual(100, Token.AsValue().AsDecimal(), 'The existing amountLCY field is the canonical local-currency amount.');

        Expense."No Receipt Type" := Expense."No Receipt Type"::"Lost Receipt";
        Expense.Modify();
        Commit();
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Clear(Response);
        Response.ReadFrom(ResponseText);
        Response.Get('noReceiptType', Token);
        Assert.AreEqual('Lost_x0020_Receipt', Token.AsValue().AsText(), 'The lost-receipt wire name must remain stable.');

        Clear(Expense."No Receipt Type");
        Expense.Modify();
        Commit();
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Clear(Response);
        Response.ReadFrom(ResponseText);
        Response.Get('noReceiptType', Token);
        Assert.AreEqual('_x0020_', Token.AsValue().AsText(), 'The blank wire name must remain stable.');

        ExpenseCategory."Attachment Enforcement" := ExpenseCategory."Attachment Enforcement"::"Not needed under limit";
        ExpenseCategory.Modify();
        Commit();
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(ExpenseCategory.SystemId), Page::"Expense Categories API", CategoriesServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Clear(Response);
        Response.ReadFrom(ResponseText);
        Response.Get('amountLimitForNoReceipt', Token);
        Assert.AreEqual(101, Token.AsValue().AsDecimal(), 'Category thresholds must be exposed in LCY.');
        Response.Get('attachmentEnforcement', Token);
        Assert.AreEqual('Not_x0020_needed_x0020_under_x0020_limit', Token.AsValue().AsText(), 'The existing enforcement field must remain exposed.');
    end;

    [Test]
    procedure CurrencyOnlyPatchInvalidatesDeclarationAndRecalculatesLCY()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        RequestBody: JsonObject;
        RequestText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        Initialize();
        CreateExpense(Expense);
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 1));
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Lost Receipt";
        Expense."No Receipt Decl. Current" := true;
        Expense.Modify();
        Commit();

        RequestBody.Add('currencyCode', Currency.Code);
        RequestBody.WriteTo(RequestText);
        TargetURL := LibraryGraphMgt.CreateTargetURL(Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, RequestText, ResponseText, 200);
        Expense.Get(Expense."No.");
        Assert.AreEqual(Currency.Code, Expense."Currency Code", 'A currency-only PATCH must validate and persist the currency.');
        Assert.AreNotEqual(100, Expense."Amount (LCY)", 'A currency-only PATCH must recalculate LCY.');
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'A currency-only PATCH must invalidate the declaration.');
    end;

    [Test]
    procedure BoundActionRequiresExplicitAttestationThroughAPI()
    var
        Expense: Record Expense;
        RequestBody: JsonObject;
        RequestText: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        Initialize();
        CreateExpense(Expense);
        Commit();
        RequestBody.Add('reason', 'Receipt was lost');
        RequestBody.Add('attestationConfirmed', false);
        RequestBody.WriteTo(RequestText);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, 'Microsoft.NAV.createNoReceiptDeclaration');
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestText, ResponseText, 400);
        Assert.ExpectedError('Confirm the declaration before creating the no receipt document.');
        Expense.Get(Expense."No.");
        Assert.IsTrue(IsNullGuid(Expense."No Receipt Declaration ID"), 'The bound action must not silently attest.');
    end;

    local procedure CreateExpense(var Expense: Record Expense)
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 100);
        Expense.Validate(Description, 'Taxi without a receipt');
        Expense.Modify();
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense No Receipt API Test");
        LibraryExpense.CleanUpBeforeTesting();
        if not IsInitialized then begin
            LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense No Receipt API Test");
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            LibraryERMCountryData.CreateGeneralPostingSetupData();
            LibraryERMCountryData.UpdatePurchasesPayablesSetup();
            LibraryERMCountryData.UpdateJournalTemplMandatory(false);
            LibraryExpense.SetupNumberSeriesInExpenseMgmt();
            LibraryExpense.InitializeExpenseSourceCode();
            LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
            IsInitialized := true;
            LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense No Receipt API Test");
        end;
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Allow No Receipt" := true;
        ExpenseAgentSetup."Use Rules" := false;
        ExpenseAgentSetup.Modify();
        Commit();
    end;
}
