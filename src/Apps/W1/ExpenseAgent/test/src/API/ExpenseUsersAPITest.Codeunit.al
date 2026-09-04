// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.SpendRequest;

codeunit 148315 "Expense Users API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseUsers', Locked = true;
        SpendRequestsServiceNameTok: Label 'spendRequests', Locked = true;
        BadRequestResponseErr: Label 'Response status code does not match expected', Locked = true;
        RequestedByCannotBeChangedErr: Label 'The owner of a travel request cannot be changed.', Locked = true;

    [Test]
    procedure UnlinkedExpenseUserIsHiddenFromAPI()
    var
        LinkedExpenseUser: Record "Expense User";
        UnlinkedExpenseUser: Record "Expense User";
        TargetURL: Text;
        ResponseText: Text;
        LinkedUserIdTxt: Text;
        UnlinkedUserIdTxt: Text;
    begin
        // [SCENARIO] An Expense User without a linked Employee No. must not
        // surface through the agent-facing Expense Users API, so the gateway
        // never lets such a user past sign-in. Exercise the actual published
        // OData endpoint of page "Expense Users API" via LibraryGraphMgt so
        // the OnOpenPage filter is invoked end-to-end.
        Initialize();

        // [GIVEN] one Expense User linked to an Employee
        LibraryExpense.CreateExpenseUser(LinkedExpenseUser);

        // [GIVEN] one Expense User without an Employee link
        UnlinkedExpenseUser.Init();
        UnlinkedExpenseUser.Validate(
            "No.",
            LibraryUtility.GenerateRandomCode(UnlinkedExpenseUser.FieldNo("No."), Database::"Expense User"));
        UnlinkedExpenseUser.Insert(true);
        Commit();

        LinkedUserIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(LinkedExpenseUser.SystemId)));
        UnlinkedUserIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(UnlinkedExpenseUser.SystemId)));

        // [WHEN] the linked user is fetched by id through the API
        // [THEN] the request succeeds (200)
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(LinkedExpenseUser.SystemId), Page::"Expense Users API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [WHEN] the unlinked user is fetched by id through the API
        // [THEN] the API responds 404 because the visibility filter hides it
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(UnlinkedExpenseUser.SystemId), Page::"Expense Users API", ServiceNameTok);
        asserterror LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 404);

        // [WHEN] the full collection is fetched through the API
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Users API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] the linked user appears in the list
        Assert.AreNotEqual(0, StrPos(ResponseText, LinkedUserIdTxt),
            'Linked Expense User should appear in the list response');

        // [THEN] the unlinked user is absent from the list
        Assert.AreEqual(0, StrPos(ResponseText, UnlinkedUserIdTxt),
            'Unlinked Expense User should not appear in the list response');
    end;

    [Test]
    procedure TravelRequestsAreScopedByEmployeeNumber()
    var
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        OtherTravelRequest: Record "Spend Request";
        TargetURL: Text;
        ResponseText: Text;
        TravelRequestIdTxt: Text;
        OtherTravelRequestIdTxt: Text;
    begin
        Initialize();

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        Assert.AreNotEqual(
            ExpenseUser."No.", ExpenseUser."Employee No.",
            'The test requires different Expense User and Employee numbers.');
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        CreateTravelRequest(OtherTravelRequest, OtherExpenseUser."Employee No.");
        Commit();

        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", ServiceNameTok);
        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&$expand=travelRequests'
        else
            TargetURL += '?$expand=travelRequests';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);
        TravelRequestIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(TravelRequest.SystemId)));
        OtherTravelRequestIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(OtherTravelRequest.SystemId)));

        Assert.AreNotEqual(
            0, StrPos(ResponseText, TravelRequestIdTxt),
            'The Expense User should expose the Travel Request linked by Employee No.');
        Assert.AreEqual(
            0, StrPos(ResponseText, OtherTravelRequestIdTxt),
            'The Expense User should not expose another employee''s Travel Request.');
    end;

#if not CLEAN30
    [Test]
    procedure LegacySpendRequestsAPIRejectsTravelRequestOwnerChange()
    var
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        OriginalRequestedBy: Code[20];
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        Initialize();

        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        OriginalRequestedBy := TravelRequest."Requested By";
        Commit();

        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Spend Requests API", SpendRequestsServiceNameTok);
        RequestBody := StrSubstNo('{"requestedBy":"%1"}', OtherExpenseUser."Employee No.");
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 400);

        Assert.ExpectedError(BadRequestResponseErr);
        Assert.AreNotEqual(
            0, StrPos(ResponseText, RequestedByCannotBeChangedErr),
            'The legacy Spend Requests API should explain that the Travel Request owner is immutable.');
        TravelRequest.Get(TravelRequest."No.");
        Assert.AreEqual(
            OriginalRequestedBy, TravelRequest."Requested By",
            'The legacy Spend Requests API must not change the Travel Request owner.');
    end;
#endif

    local procedure CreateTravelRequest(var TravelRequest: Record "Spend Request"; EmployeeNo: Code[20])
    begin
        LibraryExpense.CreateSpendRequest(TravelRequest);
        TravelRequest.Validate("Requested By", EmployeeNo);
        TravelRequest.Modify(true);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Users API Test");
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthHelper);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Users API Test");
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Users API Test");
    end;
}
