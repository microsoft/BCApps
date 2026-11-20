// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [Receipt Matching] [API]
codeunit 148354 "EA Receipt Match API Tests"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
        CardExpenseMatchesServiceNameTok: Label 'cardExpenseMatches', Locked = true;
        PendingCardExpensesServiceNameTok: Label 'pendingCardExpenses', Locked = true;

    [Test]
    procedure CardExpenseMatchesAPIReturnsMatchingCardExpense()
    var
        Expense: Record Expense;
        ResponseText: Text;
    begin
        // [SCENARIO] Posting extracted receipt data under the expense user returns the matching card expense.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense);
        Commit();

        // [WHEN] The receipt data is posted through expenseUsers({id})/cardExpenseMatches.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetUserScopedURL(Expense, CardExpenseMatchesServiceNameTok), CreateReceiptRequest(WorkDate(), 20), ResponseText, 201);

        // [THEN] The response contains the card expense id.
        Assert.AreEqual(Expense.SystemId, GetExpenseId(ResponseText), 'The API must return the matching card expense.');
        CompleteTest();
    end;

    [Test]
    procedure CardExpenseMatchesAPIChecksGivenCardExpense()
    var
        Expense: Record Expense;
        OtherExpense: Record Expense;
        ResponseText: Text;
        NoMatchResponseText: Text;
    begin
        // [SCENARIO] Posting receipt data with an expenseId checks only that card expense.
        Initialize();

        // [GIVEN] Two card expenses of 20 waiting for a receipt.
        CreateCardExpense(Expense);
        CreateCardExpense(OtherExpense);
        Commit();

        // [WHEN] Receipt data of 20 is posted with the id of the second expense.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetUserScopedURL(Expense, CardExpenseMatchesServiceNameTok), CreateReceiptRequest(WorkDate(), 20, OtherExpense.SystemId), ResponseText, 201);

        // [THEN] The second expense is returned.
        Assert.AreEqual(OtherExpense.SystemId, GetExpenseId(ResponseText), 'The API must return the checked card expense.');

        // [WHEN] Receipt data of 21 is posted with the id of the second expense.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetUserScopedURL(Expense, CardExpenseMatchesServiceNameTok), CreateReceiptRequest(WorkDate(), 21, OtherExpense.SystemId), NoMatchResponseText, 201);

        // [THEN] An empty expense id is returned.
        Assert.IsTrue(IsNullGuid(GetExpenseId(NoMatchResponseText)), 'A receipt that does not fit the checked expense must return an empty id.');
        CompleteTest();
    end;

    [Test]
    procedure PendingCardExpensesAPIListsOnlyExpensesWaitingForReceipt()
    var
        PendingExpense: Record Expense;
        ExpenseWithReceipt: Record Expense;
        LostReceiptExpense: Record Expense;
        Response: JsonObject;
        Rows: JsonToken;
        Row: JsonToken;
        IdToken: JsonToken;
        ExpenseId: Guid;
        ResponseText: Text;
    begin
        // [SCENARIO] The pending list contains card expenses that still need a receipt.
        Initialize();

        // [GIVEN] A card expense waiting for a receipt, one with a receipt and one declared as lost receipt.
        CreateCardExpense(PendingExpense);
        CreateCardExpense(ExpenseWithReceipt);
        ExpenseWithReceipt."Receipt Attached" := true;
        ExpenseWithReceipt.Modify();
        CreateCardExpense(LostReceiptExpense);
        LostReceiptExpense."No Receipt Type" := LostReceiptExpense."No Receipt Type"::"Lost Receipt";
        LostReceiptExpense.Modify();
        Commit();

        // [WHEN] The list is read through expenseUsers({id})/pendingCardExpenses.
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, GetUserScopedURL(PendingExpense, PendingCardExpensesServiceNameTok), 200);

        // [THEN] Only the expense still waiting for a receipt is listed.
        Response.ReadFrom(ResponseText);
        Response.Get('value', Rows);
        Assert.AreEqual(1, Rows.AsArray().Count(), 'Only the pending card expense must be listed.');
        Rows.AsArray().Get(0, Row);
        Row.AsObject().Get('id', IdToken);
        Evaluate(ExpenseId, IdToken.AsValue().AsText());
        Assert.AreEqual(PendingExpense.SystemId, ExpenseId, 'The pending card expense must be listed.');
        CompleteTest();
    end;

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
    end;

    local procedure CompleteTest()
    begin
        CorpCardTestLib.DeleteCorpCardTransactionalData();
        LibraryExpense.CleanUpBeforeTesting();
        Commit();
    end;

    local procedure CreateCardExpense(var Expense: Record Expense)
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        CorpCard.Get('CORPCARD-0001');
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        CorpCardTrans.Modify(true);
        Expense.Get(ExpenseNo);
    end;

    local procedure GetUserScopedURL(Expense: Record Expense; SubpageServiceName: Text): Text
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        exit(LibraryGraphMgt.CreateTargetURLWithSubpage(Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok, SubpageServiceName));
    end;

    local procedure CreateReceiptRequest(ReceiptDate: Date; ReceiptAmount: Decimal): Text
    var
        EmptyGuid: Guid;
    begin
        exit(CreateReceiptRequest(ReceiptDate, ReceiptAmount, EmptyGuid));
    end;

    local procedure CreateReceiptRequest(ReceiptDate: Date; ReceiptAmount: Decimal; ExpenseSystemId: Guid): Text
    var
        Request: JsonObject;
        RequestText: Text;
    begin
        Request.Add('expenseDate', Format(ReceiptDate, 0, 9));
        Request.Add('amount', ReceiptAmount);
        Request.Add('merchantName', 'Contoso Coffee');
        if not IsNullGuid(ExpenseSystemId) then
            Request.Add('expenseId', LowerCase(DelChr(Format(ExpenseSystemId), '=', '{}')));
        Request.WriteTo(RequestText);
        exit(RequestText);
    end;

    local procedure GetExpenseId(ResponseText: Text) ExpenseId: Guid
    var
        Response: JsonObject;
        IdToken: JsonToken;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get('expenseId', IdToken);
        Evaluate(ExpenseId, IdToken.AsValue().AsText());
    end;
}
