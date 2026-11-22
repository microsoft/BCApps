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
        CardIdTok: Label 'CORPCARD-0001', Locked = true;

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
    begin
        // [SCENARIO] Posting receipt data with an expenseId returns that card expense when the receipt fits it.
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
        CompleteTest();
    end;

    [Test]
    procedure CardExpenseMatchesAPIReturnsEmptyWhenGivenCardExpenseDoesNotFit()
    var
        Expense: Record Expense;
        ResponseText: Text;
    begin
        // [SCENARIO] Posting receipt data with an expenseId returns an empty id when the receipt does not fit that card expense.
        Initialize();

        // [GIVEN] A card expense of 20 waiting for a receipt.
        CreateCardExpense(Expense);
        Commit();

        // [WHEN] Receipt data of 21 is posted with the id of the expense.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetUserScopedURL(Expense, CardExpenseMatchesServiceNameTok), CreateReceiptRequest(WorkDate(), 21, Expense.SystemId), ResponseText, 201);

        // [THEN] An empty expense id is returned.
        Assert.IsTrue(IsNullGuid(GetExpenseId(ResponseText)), 'A receipt that does not fit the checked expense must return an empty id.');
        CompleteTest();
    end;

    [Test]
    procedure CardExpenseMatchesAPISelectsExpenseByCardLast4()
    var
        Expense: Record Expense;
        OtherCardExpense: Record Expense;
        EmptyGuid: Guid;
        ResponseText: Text;
    begin
        // [SCENARIO] Posting receipt data with cardLast4 returns the card expense paid with the card ending in those digits.
        Initialize();

        // [GIVEN] Two equal card expenses of the same expense user, paid with cards ending in 0001 and 7777.
        CreateCardExpense(Expense);
        CreateCardExpense(OtherCardExpense, CreateAdditionalCard('****7777'));
        Commit();

        // [WHEN] Receipt data with cardLast4 7777 is posted.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetUserScopedURL(Expense, CardExpenseMatchesServiceNameTok), CreateReceiptRequest(WorkDate(), 20, EmptyGuid, '7777'), ResponseText, 201);

        // [THEN] The expense paid with the card ending in 7777 is returned.
        Assert.AreEqual(OtherCardExpense.SystemId, GetExpenseId(ResponseText), 'The API must return the expense paid with the receipt card.');
        CompleteTest();
    end;

    [Test]
    procedure CardExpenseMatchesAPICheckReturnsEmptyForOtherCardLast4()
    var
        Expense: Record Expense;
        ResponseText: Text;
    begin
        // [SCENARIO] Posting receipt data with an expenseId and the cardLast4 of another card of the same expense user returns an empty id.
        Initialize();

        // [GIVEN] A card expense paid with the card ending in 0001 and another card of the same expense user ending in 7777.
        CreateCardExpense(Expense);
        CreateAdditionalCard('****7777');
        Commit();

        // [WHEN] Receipt data with cardLast4 7777 is posted with the id of the expense.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            GetUserScopedURL(Expense, CardExpenseMatchesServiceNameTok), CreateReceiptRequest(WorkDate(), 20, Expense.SystemId, '7777'), ResponseText, 201);

        // [THEN] An empty expense id is returned.
        Assert.IsTrue(IsNullGuid(GetExpenseId(ResponseText)), 'A receipt paid with another card must not fit the checked expense.');
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
    begin
        CreateCardExpense(Expense, CardIdTok);
    end;

    local procedure CreateCardExpense(var Expense: Record Expense; CardId: Code[50])
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
        ExpenseNo: Code[20];
    begin
        CorpCard.Get(CardId);
        CorpCardTestLib.CreateTransaction(CorpCardTrans, CorpCard);
        ExpenseWriter.CreateDraftFromTrans(CorpCardTrans, ExpenseNo);
        CorpCardTrans.Modify(true);
        Expense.Get(ExpenseNo);
    end;

    local procedure CreateAdditionalCard(MaskedCardNo: Text[30]): Code[50]
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.Get(CardIdTok);
        exit(CorpCardTestLib.CreateAdditionalCard(CorpCard, MaskedCardNo));
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
    begin
        exit(CreateReceiptRequest(ReceiptDate, ReceiptAmount, ExpenseSystemId, ''));
    end;

    local procedure CreateReceiptRequest(ReceiptDate: Date; ReceiptAmount: Decimal; ExpenseSystemId: Guid; CardLast4: Text): Text
    var
        Request: JsonObject;
        RequestText: Text;
    begin
        Request.Add('expenseDate', Format(ReceiptDate, 0, 9));
        Request.Add('amount', ReceiptAmount);
        Request.Add('merchantName', 'Contoso Coffee');
        if not IsNullGuid(ExpenseSystemId) then
            Request.Add('expenseId', LowerCase(DelChr(Format(ExpenseSystemId), '=', '{}')));
        if CardLast4 <> '' then
            Request.Add('cardLast4', CardLast4);
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
