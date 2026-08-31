// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148315 "Expense Users API Test"
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
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseUsers', Locked = true;

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

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Users API Test");
        if IsInitialized then
            exit;

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
