// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.HumanResources.Employee;

codeunit 148315 "Expense Users API Test"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowAllOutboundRequests;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseUsers', Locked = true;
        EmployeesServiceNameTok: Label 'employees', Locked = true;
        AvailableApproversServiceNameTok: Label 'availableApprovers', Locked = true;

    [Test]
    procedure AvailableApproversIncludeParentAndExcludeIneligibleUsers()
    var
        ParentExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        NonApproverExpenseUser: Record "Expense User";
        UnlinkedApproverExpenseUser: Record "Expense User";
        Response: JsonObject;
        Approvers: JsonArray;
        TargetURL: Text;
        FilteredURL: Text;
        ResponseText: Text;
    begin
        Initialize();
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(ParentExpenseUser, true);
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(ApproverExpenseUser, true);
        LibraryExpense.CreateExpenseUser(NonApproverExpenseUser);
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(UnlinkedApproverExpenseUser, true);
        UnlinkedApproverExpenseUser."Employee No." := '';
        UnlinkedApproverExpenseUser.Modify();
        Commit();

        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(ParentExpenseUser.SystemId), Page::"Expense Users API",
            ServiceNameTok, AvailableApproversServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The response must be valid JSON.');
        Approvers := Response.GetArray('value');

        AssertApproverInCollection(Approvers, ApproverExpenseUser.SystemId, true);
        AssertApproverInCollection(Approvers, ParentExpenseUser.SystemId, true);
        AssertApproverInCollection(Approvers, NonApproverExpenseUser.SystemId, false);
        AssertApproverInCollection(Approvers, UnlinkedApproverExpenseUser.SystemId, false);

        FilteredURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, '$filter=id eq ' + LibraryGraphMgt.StripBrackets(Format(ParentExpenseUser.SystemId)));
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, FilteredURL, 200);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The response must be valid JSON.');
        Approvers := Response.GetArray('value');
        Assert.AreEqual(1, Approvers.Count(), 'A caller filter can select the parent expense user when they can approve.');
        AssertApproverInCollection(Approvers, ParentExpenseUser.SystemId, true);

        FilteredURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(TargetURL, '$filter=canApprove eq false');
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, FilteredURL, 200);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The response must be valid JSON.');
        Approvers := Response.GetArray('value');
        Assert.AreEqual(0, Approvers.Count(), 'A caller filter must not include users who cannot approve.');

        FilteredURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(TargetURL, '$filter=employeeNumber eq ''''');
        Clear(ResponseText);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, FilteredURL, 200);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The response must be valid JSON.');
        Approvers := Response.GetArray('value');
        Assert.AreEqual(0, Approvers.Count(), 'A caller filter must not include users without an employee link.');
    end;

    [Test]
    procedure ExpandedAvailableApproversIncludeEachParent()
    var
        FirstExpenseUser: Record "Expense User";
        SecondExpenseUser: Record "Expense User";
        Response: JsonObject;
        ExpenseUsers: JsonArray;
        ExpenseUserToken: JsonToken;
        ExpenseUserObject: JsonObject;
        Approvers: JsonArray;
        TargetURL: Text;
        ResponseText: Text;
        FirstUserId: Text;
        SecondUserId: Text;
    begin
        Initialize();
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(FirstExpenseUser, true);
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(SecondExpenseUser, true);
        Commit();

        FirstUserId := LowerCase(LibraryGraphMgt.StripBrackets(Format(FirstExpenseUser.SystemId)));
        SecondUserId := LowerCase(LibraryGraphMgt.StripBrackets(Format(SecondExpenseUser.SystemId)));
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Users API", ServiceNameTok);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, '$filter=id eq ' + FirstUserId + ' or id eq ' + SecondUserId);
        TargetURL := LibraryGraphMgt.AppendQueryParameterToTargetURL(
            TargetURL, '$expand=availableApprovers($filter=id eq ' + FirstUserId + ' or id eq ' + SecondUserId + ')');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Assert.IsTrue(Response.ReadFrom(ResponseText), 'The response must be valid JSON.');
        ExpenseUsers := Response.GetArray('value');
        Assert.AreEqual(2, ExpenseUsers.Count(), 'Both parent expense users must be returned.');

        foreach ExpenseUserToken in ExpenseUsers do begin
            ExpenseUserObject := ExpenseUserToken.AsObject();
            Approvers := ExpenseUserObject.GetArray('availableApprovers');
            Assert.AreEqual(2, Approvers.Count(), 'Each expanded collection must contain both approvers.');
            AssertApproverInCollection(Approvers, FirstExpenseUser.SystemId, true);
            AssertApproverInCollection(Approvers, SecondExpenseUser.SystemId, true);
        end;
    end;

    [Test]
    procedure EmployeesAPICanFilterExpenseUsers()
    var
        LinkedExpenseUser: Record "Expense User";
        UnlinkedEmployee: Record Employee;
        TargetURL: Text;
        ResponseText: Text;
        LinkedEmployeeIdTxt: Text;
        UnlinkedEmployeeIdTxt: Text;
    begin
        // [SCENARIO] The Employees API can be filtered to employees linked to Expense Users.
        Initialize();

        // [GIVEN] One linked employee and one employee without an Expense User.
        LibraryExpense.CreateExpenseUser(LinkedExpenseUser);
        LibraryHumanResource.CreateEmployee(UnlinkedEmployee);
        Commit();

        // [WHEN] The employee collection is filtered by isExpenseUser.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Employees API", EmployeesServiceNameTok);
        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&$filter=isExpenseUser eq true'
        else
            TargetURL += '?$filter=isExpenseUser eq true';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);
        UnlinkedEmployeeIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(UnlinkedEmployee.SystemId)));
        LinkedEmployeeIdTxt := GetEmployeeSystemIdText(LinkedExpenseUser."Employee No.");

        // [THEN] Only the employee linked to an Expense User is returned.
        Assert.AreNotEqual(0, StrPos(ResponseText, LinkedEmployeeIdTxt), 'The linked employee must be returned.');
        Assert.AreEqual(0, StrPos(ResponseText, UnlinkedEmployeeIdTxt), 'The unlinked employee must not be returned.');
    end;

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
        Assert.ExpectedError('Response code is 404');

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

    local procedure AssertApproverInCollection(Approvers: JsonArray; ExpenseUserSystemId: Guid; ExpectedPresent: Boolean)
    var
        ApproverToken: JsonToken;
        Approver: JsonObject;
        ExpenseUserId: Text;
        Found: Boolean;
    begin
        ExpenseUserId := LowerCase(LibraryGraphMgt.StripBrackets(Format(ExpenseUserSystemId)));
        foreach ApproverToken in Approvers do begin
            Approver := ApproverToken.AsObject();
            if LowerCase(Approver.GetText('id')) = ExpenseUserId then
                Found := true;
        end;
        Assert.AreEqual(ExpectedPresent, Found, 'Unexpected approver visibility for expense user ' + ExpenseUserId);
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

    local procedure GetEmployeeSystemIdText(EmployeeNo: Code[20]): Text
    var
        Employee: Record Employee;
    begin
        Employee.Get(EmployeeNo);
        exit(LowerCase(LibraryGraphMgt.StripBrackets(Format(Employee.SystemId))));
    end;
}
