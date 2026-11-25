// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [Receipt Matching] [API]
codeunit 148371 "EA Receipt Match API Tests"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
        CardExpenseMatchesServiceNameTok: Label 'cardExpenseMatches', Locked = true;
        ExpensesServiceNameTok: Label 'expenses', Locked = true;
        CardReceiptDataServiceNameTok: Label 'cardReceiptData', Locked = true;
        ApplyURLTxt: Label '%1(%2)/Microsoft.NAV.apply', Locked = true, Comment = '%1 = Card receipt data collection URL, %2 = Card receipt data id';
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
    procedure ExpensesAPICardExpenseAwaitingReportIncludesOpenAndReleasedExpenses()
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
        // [SCENARIO] An open or released off-report card expense awaits a report regardless of its receipt.
        Initialize();

        // [GIVEN] A card expense without a receipt, one with a receipt, one declared as lost receipt, one released, one no longer linked to its transaction and a manual expense paid with the card.
        CreateCardExpense(PendingExpense);
        CreateCardExpenseWithReceipt(ExpenseWithReceipt);
        CreateLostReceiptCardExpense(LostReceiptExpense);
        CreateReleasedCardExpense(ReleasedExpense);
        CreateUnlinkedCardExpense(UnlinkedExpense);
        CorpCard.Get(CardIdTok);
        CorpCardTestLib.InsertExpense(ManualExpense, CorpCard);
        Commit();

        // [WHEN] The expense user's expenses are filtered to those awaiting a report.
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(
            ResponseText, LibraryGraphMgt.AppendQueryParameterToTargetURL(GetUserScopedURL(PendingExpense, ExpensesServiceNameTok), '$filter=cardExpenseAwaitingReport eq true'), 200);

        // [THEN] Only the open or released card-origin expenses linked to a transaction are returned.
        GetExpenseIds(ResponseText, 'value', ExpenseIds);
        Assert.AreEqual(4, ExpenseIds.Count(), 'Only open or released off-report card expenses linked to a transaction must be returned.');
        Assert.IsTrue(ExpenseIds.Contains(ReleasedExpense.SystemId), 'A released off-report card expense must await a report.');
        Assert.IsTrue(ExpenseIds.Contains(PendingExpense.SystemId), 'The card expense without a receipt must be pending.');
        Assert.IsTrue(ExpenseIds.Contains(ExpenseWithReceipt.SystemId), 'The card expense with a receipt must be pending.');
        Assert.IsTrue(ExpenseIds.Contains(LostReceiptExpense.SystemId), 'The card expense declared as lost receipt must be pending.');
        CompleteTest();
    end;

    [Test]
    procedure ExpenseUsersAPIExpandFiltersExpensesOnCardExpenseAwaitingReportBeforeTop()
    var
        ManualExpense: Record Expense;
        CorpCard: Record "EA Corp Card";
        ReleasedExpense: Record Expense;
        UnlinkedExpense: Record Expense;
        PendingExpense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseIds: List of [Guid];
        ResponseText: Text;
    begin
        // [SCENARIO] The expanded awaiting-report filter applies before $top.
        Initialize();

        // [GIVEN] Two card expenses that are not pending, followed by two newer card expenses that are.
        CorpCard.Get(CardIdTok);
        CorpCardTestLib.InsertExpense(ManualExpense, CorpCard);
        CreateUnlinkedCardExpense(UnlinkedExpense);
        CreateCardExpense(PendingExpense);
        CreateReleasedCardExpense(ReleasedExpense);
        ExpenseUser.Get(PendingExpense."Expense User No.");
        Commit();

        // [WHEN] Read the two newest expenses that do not await a report.
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(
            ResponseText,
            LibraryGraphMgt.AppendQueryParameterToTargetURL(
                LibraryGraphMgt.CreateTargetURL(Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok),
                '$expand=expenses($filter=cardExpenseAwaitingReport eq false;$orderby=systemCreatedAt desc;$top=2)'),
            200);

        // [THEN] The two expenses that are not pending are returned.
        GetExpenseIds(ResponseText, 'expenses', ExpenseIds);
        Assert.AreEqual(2, ExpenseIds.Count(), 'The filter must be applied before $top.');
        Assert.IsFalse(ExpenseIds.Contains(ReleasedExpense.SystemId), 'The released, linked card expense still awaits a report.');
        Assert.IsTrue(ExpenseIds.Contains(ManualExpense.SystemId), 'The manual expense must be returned.');
        Assert.IsTrue(ExpenseIds.Contains(UnlinkedExpense.SystemId), 'The expense no longer linked to its transaction must be returned.');
        CompleteTest();
    end;

    [Test]
    procedure CardReceiptDataAPIDeepInsertThenApplyAttachesReceipt()
    var
        Expense: Record Expense;
        CardReceiptData: Record "EA Card Receipt Data";
        CardReceiptParticipant: Record "EA Card Receipt Participant";
        ExpenseParticipant: Record "Expense Participant";
        ContentOutStream: OutStream;
        ResponseText: Text;
        TargetURL: Text;
        ReceiptDataId: Guid;
    begin
        // [SCENARIO] Receipt data and its participants are created in one request under the expense, and the apply action attaches them.
        Initialize();

        // [GIVEN] A card expense waiting for a receipt.
        CreateCardExpense(Expense);
        Commit();

        // [WHEN] Receipt data with a participant is posted through expenses({id})/cardReceiptData.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(Format(Expense.SystemId), Page::"Expenses API", ExpensesServiceNameTok, CardReceiptDataServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, CreateCardReceiptDataRequest(), ResponseText, 201);

        // [THEN] The receipt data is linked to the expense and its participant to the receipt data.
        ReceiptDataId := GetId(ResponseText);
        CardReceiptData.Get(ReceiptDataId);
        CardReceiptData.TestField("Expense SystemId", Expense.SystemId);
        CardReceiptData.TestField("Expense No.", Expense."No.");
        CardReceiptParticipant.SetRange("Receipt Data Id", ReceiptDataId);
        Assert.AreEqual(1, CardReceiptParticipant.Count(), 'The participant must be linked to the receipt data.');

        // [WHEN] The receipt file is uploaded and the apply action is called.
        CardReceiptData."Attachment Content".CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText('receipt');
        CardReceiptData.Modify();
        Commit();
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(
            StrSubstNo(ApplyURLTxt, TargetURL, LowerCase(DelChr(Format(ReceiptDataId), '=', '{}'))), '', ResponseText, 200);

        // [THEN] The expense has the receipt, the justification and the participant, and the receipt data is deleted.
        Expense.Get(Expense."No.");
        Expense.TestField("Receipt Attached", true);
        Expense.TestField(Justification, 'Client meeting');
        ExpenseParticipant.SetRange("Expense No.", Expense."No.");
        Assert.AreEqual(1, ExpenseParticipant.Count(), 'The participant must be added to the expense.');
        Assert.IsFalse(CardReceiptData.Get(ReceiptDataId), 'The receipt data must be deleted after it is applied.');
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

    local procedure CreateReleasedCardExpense(var Expense: Record Expense)
    begin
        CreateCardExpense(Expense);
        Expense.Status := Expense.Status::Released;
        Expense.Modify();
    end;

    local procedure CreateUnlinkedCardExpense(var Expense: Record Expense)
    begin
        CreateCardExpense(Expense);
        Expense."Credit Card Feed No." := 0;
        Expense.Modify();
    end;

    local procedure CreateCardReceiptDataRequest(): Text
    var
        Request: JsonObject;
        Participant: JsonObject;
        Participants: JsonArray;
        RequestText: Text;
    begin
        Request.Add('fileName', 'receipt.pdf');
        Request.Add('justification', 'Client meeting');
        Participant.Add('participantType', 'External');
        Participant.Add('participantName', 'Jane Doe');
        Participants.Add(Participant);
        Request.Add('cardReceiptParticipants', Participants);
        Request.WriteTo(RequestText);
        exit(RequestText);
    end;

    local procedure GetId(ResponseText: Text) Id: Guid
    var
        Response: JsonObject;
        IdToken: JsonToken;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get('id', IdToken);
        Evaluate(Id, IdToken.AsValue().AsText());
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
