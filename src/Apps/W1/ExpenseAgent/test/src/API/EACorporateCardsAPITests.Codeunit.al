// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

// [FEATURE] [Expense Agent] [Corporate Card] [API]
codeunit 148372 "EA Corporate Cards API Tests"
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
        CorporateCardsServiceNameTok: Label 'corporateCards', Locked = true;
        FirstCardIdTok: Label 'CORPCARD-0001', Locked = true;
        SecondCardIdTok: Label 'CORPCARD-0002', Locked = true;

    [Test]
    procedure ExpenseUsersAPIReturnsOnlyUnblockedCardsOfFirstExpenseUser()
    var
        FirstCard: Record "EA Corp Card";
        FirstUserBlockedCard: Record "EA Corp Card";
        SecondCard: Record "EA Corp Card";
        CardIds: List of [Guid];
    begin
        // [SCENARIO] expenseUsers({id})/corporateCards returns only the unblocked cards of that expense user.
        Initialize();

        // [GIVEN] Two expense users with a card each, and a blocked card for the first expense user.
        FirstCard.Get(FirstCardIdTok);
        SecondCard.Get(SecondCardIdTok);
        Assert.AreNotEqual(FirstCard."Expense User No.", SecondCard."Expense User No.", 'The cards must belong to different expense users.');
        FirstUserBlockedCard.Get(CorpCardTestLib.CreateAdditionalCard(FirstCard, '****7777'));
        FirstUserBlockedCard.Blocked := true;
        FirstUserBlockedCard.Modify();
        Commit();

        // [WHEN] The corporate cards of the first expense user are read through the expense user.
        GetCardIds(GetUserScopedURL(FirstCard."Expense User No."), CardIds);

        // [THEN] Only the unblocked card of the first expense user is returned.
        Assert.AreEqual(1, CardIds.Count(), 'Only the unblocked card of the first expense user must be returned.');
        Assert.IsTrue(CardIds.Contains(FirstCard.SystemId), 'The card of the first expense user must be returned.');
        CompleteTest();
    end;

    [Test]
    procedure ExpenseUsersAPIReturnsOnlyCardsOfSecondExpenseUser()
    var
        FirstCard: Record "EA Corp Card";
        SecondCard: Record "EA Corp Card";
        CardIds: List of [Guid];
    begin
        // [SCENARIO] expenseUsers({id})/corporateCards does not return the cards of another expense user.
        Initialize();

        // [GIVEN] Two expense users with a card each.
        FirstCard.Get(FirstCardIdTok);
        SecondCard.Get(SecondCardIdTok);
        Assert.AreNotEqual(FirstCard."Expense User No.", SecondCard."Expense User No.", 'The cards must belong to different expense users.');
        Commit();

        // [WHEN] The corporate cards of the second expense user are read through the expense user.
        GetCardIds(GetUserScopedURL(SecondCard."Expense User No."), CardIds);

        // [THEN] Only the card of the second expense user is returned.
        Assert.AreEqual(1, CardIds.Count(), 'Only the card of the second expense user must be returned.');
        Assert.IsTrue(CardIds.Contains(SecondCard.SystemId), 'The card of the second expense user must be returned.');
        CompleteTest();
    end;

    [Test]
    procedure CorporateCardsAPIFilteredOnExpenseUserNumberReturnsCardsOfThatExpenseUser()
    var
        FirstCard: Record "EA Corp Card";
        CardIds: List of [Guid];
    begin
        // [SCENARIO] The deprecated corporateCards route filtered on expenseUserNumber still returns the cards of that expense user.
        Initialize();

        // [GIVEN] An expense user with a card.
        FirstCard.Get(FirstCardIdTok);
        Commit();

        // [WHEN] The corporate cards are read with a filter on the expense user number.
        GetCardIds(
            LibraryGraphMgt.AppendQueryParameterToTargetURL(
                LibraryGraphMgt.CreateTargetURL('', Page::"Expense Corporate Cards API", CorporateCardsServiceNameTok),
                StrSubstNo('$filter=expenseUserNumber eq ''%1''', FirstCard."Expense User No.")),
            CardIds);

        // [THEN] Only the card of that expense user is returned.
        Assert.AreEqual(1, CardIds.Count(), 'Only the card of the expense user must be returned.');
        Assert.IsTrue(CardIds.Contains(FirstCard.SystemId), 'The card of the expense user must be returned.');
        CompleteTest();
    end;

    [Test]
    procedure CorporateCardsAPIWithoutExpenseUserReturnsError()
    var
        ResponseText: Text;
    begin
        // [SCENARIO] corporateCards without an expense user is rejected.
        Initialize();
        Commit();

        // [WHEN] The corporate cards are read without an expense user.
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(
            ResponseText, LibraryGraphMgt.CreateTargetURL('', Page::"Expense Corporate Cards API", CorporateCardsServiceNameTok), 400);

        // [THEN] The request fails because the expense user filter is required.
        Assert.ExpectedError('Response code is 400 (BadRequest)');
        Assert.ExpectedError('Read corporate cards through a single expense user.');
    end;

    local procedure Initialize()
    begin
        CorpCardTestLib.InitializeCorpCardData();
    end;

    local procedure CompleteTest()
    begin
        CorpCardTestLib.DeleteCorpCardTransactionalData();
        LibraryExpense.CleanUpBeforeTesting();
        Commit();
    end;

    local procedure GetUserScopedURL(ExpenseUserNo: Code[20]): Text
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.Get(ExpenseUserNo);
        exit(LibraryGraphMgt.CreateTargetURLWithSubpage(Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok, CorporateCardsServiceNameTok));
    end;

    local procedure GetCardIds(TargetURL: Text; var CardIds: List of [Guid])
    var
        Response: JsonObject;
        Rows: JsonToken;
        Row: JsonToken;
        IdToken: JsonToken;
        ResponseText: Text;
        CardId: Guid;
    begin
        Clear(CardIds);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Response.ReadFrom(ResponseText);
        Response.Get('value', Rows);
        foreach Row in Rows.AsArray() do begin
            Row.AsObject().Get('id', IdToken);
            Evaluate(CardId, IdToken.AsValue().AsText());
            CardIds.Add(CardId);
        end;
    end;
}
