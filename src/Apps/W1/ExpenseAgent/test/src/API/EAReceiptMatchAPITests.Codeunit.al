// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [Receipt Matching] [API]
codeunit 148369 "EA Receipt Match API Tests"
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
        ExpensesServiceNameTok: Label 'expenses', Locked = true;
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
    procedure ExpensesAPIPendingCardExpenseIsTrueOnlyForCardExpenseWaitingForReceipt()
    var
        PendingExpense: Record Expense;
        ExpenseWithReceipt: Record Expense;
        LostReceiptExpense: Record Expense;
        ReleasedExpense: Record Expense;
        UnlinkedExpense: Record Expense;
        ManualExpense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ExpenseIds: List of [Guid];
        ResponseText: Text;
    begin
        // [SCENARIO] pendingCardExpense is true only for open card expenses linked to a transaction, without a receipt or a no receipt declaration.
        Initialize();

        // [GIVEN] A card expense waiting for a receipt, one with a receipt, one declared as lost receipt, one released, one no longer linked to its transaction and a manual expense paid with the card.
        CreateCardExpense(PendingExpense);
        CreateCardExpenseWithReceipt(ExpenseWithReceipt);
        CreateLostReceiptCardExpense(LostReceiptExpense);
        CreateCardExpense(ReleasedExpense);
        ReleasedExpense.Status := ReleasedExpense.Status::Released;
        ReleasedExpense.Modify();
        CreateCardExpense(UnlinkedExpense);
        UnlinkedExpense."Credit Card Feed No." := 0;
        UnlinkedExpense.Modify();
        CorpCard.Get(CardIdTok);
        CorpCardTestLib.InsertExpense(ManualExpense, CorpCard);
        Commit();

        // [WHEN] The expenses of the expense user are filtered on pendingCardExpense eq true.
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(
            ResponseText, LibraryGraphMgt.AppendQueryParameterToTargetURL(GetUserScopedURL(PendingExpense, ExpensesServiceNameTok), '$filter=pendingCardExpense eq true'), 200);

        // [THEN] Only the card expense waiting for a receipt is returned.
        GetExpenseIds(ResponseText, 'value', ExpenseIds);
        Assert.AreEqual(1, ExpenseIds.Count(), 'Only the card expense waiting for a receipt must be pending.');
        Assert.IsTrue(ExpenseIds.Contains(PendingExpense.SystemId), 'The card expense waiting for a receipt must be pending.');
        CompleteTest();
    end;

    [Test]
    procedure ExpenseUsersAPIExpandFiltersExpensesOnPendingCardExpenseBeforeTop()
    var
        ExpenseWithReceipt: Record Expense;
        LostReceiptExpense: Record Expense;
        PendingExpense: Record Expense;
        OtherPendingExpense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseIds: List of [Guid];
        ResponseText: Text;
    begin
        // [SCENARIO] Expanding the expenses of an expense user filtered on pendingCardExpense applies the filter before $top.
        Initialize();

        // [GIVEN] Two card expenses that are not pending, followed by two newer card expenses that are.
        CreateCardExpenseWithReceipt(ExpenseWithReceipt);
        CreateLostReceiptCardExpense(LostReceiptExpense);
        CreateCardExpense(PendingExpense);
        CreateCardExpense(OtherPendingExpense);
        ExpenseUser.Get(PendingExpense."Expense User No.");
        Commit();

        // [WHEN] The expense user is read with expenses expanded on pendingCardExpense eq false, newest first, top 2.
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(
            ResponseText,
            LibraryGraphMgt.AppendQueryParameterToTargetURL(
                LibraryGraphMgt.CreateTargetURL(Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok),
                '$expand=expenses($filter=pendingCardExpense eq false;$orderby=systemCreatedAt desc;$top=2)'),
            200);

        // [THEN] The two expenses that are not pending are returned.
        GetExpenseIds(ResponseText, 'expenses', ExpenseIds);
        Assert.AreEqual(2, ExpenseIds.Count(), 'The filter must be applied before $top.');
        Assert.IsTrue(ExpenseIds.Contains(ExpenseWithReceipt.SystemId), 'The expense with a receipt must be returned.');
        Assert.IsTrue(ExpenseIds.Contains(LostReceiptExpense.SystemId), 'The expense declared as lost receipt must be returned.');
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
        Expense."Merchant Name" := 'CONTOSO COFFEE';
        Expense.Modify();
    end;

    local procedure CreateAdditionalCard(MaskedCardNo: Text[30]): Code[50]
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.Get(CardIdTok);
        exit(CorpCardTestLib.CreateAdditionalCard(CorpCard, MaskedCardNo));
    end;

    local procedure CreateCardExpenseWithReceipt(var Expense: Record Expense)
    begin
        CreateCardExpense(Expense);
        Expense."Receipt Attached" := true;
        Expense.Modify();
    end;

    local procedure CreateLostReceiptCardExpense(var Expense: Record Expense)
    begin
        CreateCardExpense(Expense);
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Lost Receipt";
        Expense.Modify();
    end;

    local procedure GetExpenseIds(ResponseText: Text; ArrayName: Text; var ExpenseIds: List of [Guid])
    var
        Response: JsonObject;
        Rows: JsonToken;
        Row: JsonToken;
        IdToken: JsonToken;
        ExpenseId: Guid;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get(ArrayName, Rows);
        foreach Row in Rows.AsArray() do begin
            Row.AsObject().Get('id', IdToken);
            Evaluate(ExpenseId, IdToken.AsValue().AsText());
            ExpenseIds.Add(ExpenseId);
        end;
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
