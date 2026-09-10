// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SpendRequest;
using Microsoft.HumanResources.Employee;

// These HTTP tests are excluded in Expense_Agent_Tests.DisabledTest.json per the PR review.
// Re-enable them after BCApps CI provisions an authenticated OData endpoint and a dedicated
// test company with committed fixtures and disabled test isolation, then remove the exclusions.
// In-process lifecycle, date, and scope coverage in "Spend Request Test", and restrictive role
// coverage in "Expense Permissions Test", remain enabled; only the HTTP scenarios are excluded.
codeunit 148347 "Travel Requests API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
#if not CLEAN30
        SpendRequestsServiceNameTok: Label 'spendRequests', Locked = true;
#endif
        ApproverViewsServiceNameTok: Label 'approverViews', Locked = true;
        TravelRequestsServiceNameTok: Label 'travelRequests', Locked = true;
        TravelersServiceNameTok: Label 'travelers', Locked = true;
        ApproveTravelRequestActionTok: Label 'Microsoft.NAV.approveTravelRequest', Locked = true;
        CreateExpenseReportActionTok: Label 'Microsoft.NAV.createExpenseReport', Locked = true;
        ExpenseReportsServiceNameTok: Label 'expenseReports', Locked = true;
        TravelRequestDetailsServiceNameTok: Label 'travelRequestDetails', Locked = true;
        BadRequestResponseErr: Label 'Response code is 400 (BadRequest).', Locked = true;
        RequestedByCannotBeChangedErr: Label 'cannot be changed', Locked = true;
        RequestedByRequestBodyLbl: Label '{"requestedBy":"%1"}', Comment = '%1 = Employee number', Locked = true;
        ApproveTravelRequestBodyLbl: Label '{"approverExpenseUserNo":"%1"}', Comment = '%1 = Approver Expense User No.', Locked = true;
        StatusRequestBodyLbl: Label '{"status":"Released"}', Locked = true;
        StatusReadOnlyErr: Label 'Control ''status'' is read-only.', Locked = true;
        InvalidTravelRequestDatesErr: Label 'Expected End Date cannot be before Expected Start Date.', Locked = true;
        ExpenseUserNotLinkedErr: Label 'No expense user is linked to employee %1.', Comment = '%1 = Employee No.';
        StatusNotOpenErr: Label 'must have the status', Locked = true;

    [Test]
    procedure TravelersAPIMapsEmployeeNumberToExpenseUser()
    var
        Employee: Record Employee;
        OtherEmployee: Record Employee;
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        Traveler: Record Traveler;
        Request: JsonObject;
        Response: JsonObject;
        EmployeeNumber: JsonToken;
        TargetURL: Text;
        RequestBody: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] A traveler supplied as an employee is stored as the linked Expense User.
        Initialize();

        // [GIVEN] An Expense User linked to an employee and an open travel request.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        Request.Add('employeeNumber', ExpenseUser."Employee No.");
        Request.WriteTo(RequestBody);
        Commit();

        // [WHEN] The employee is added through the Travelers API.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Travel Requests API", TravelRequestsServiceNameTok);
        TargetURL := AppendPathToAPIURL(TargetURL, '/' + TravelersServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 201);

        // [THEN] The Traveler stores the corresponding Expense User number.
        Traveler.SetRange("Spend Request No.", TravelRequest."No.");
        Traveler.FindFirst();
        Traveler.TestField("Expense User No.", ExpenseUser."No.");

        // [THEN] The API returns the employee mapping without exposing Expense User fields.
        Response.ReadFrom(ResponseText);
        Response.Get('employeeNumber', EmployeeNumber);
        Assert.AreEqual(ExpenseUser."Employee No.", EmployeeNumber.AsValue().AsText(), 'The mapped employee number must be returned.');
        Assert.IsFalse(Response.Contains('expenseUserNo'), 'The Expense User number must not be exposed.');
        Assert.IsFalse(Response.Contains('expenseUserName'), 'The Expense User name must not be exposed.');

        // [WHEN] The travel request is read with travelers and employees expanded.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Travel Requests API", TravelRequestsServiceNameTok);
        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&$expand=travelers,employees'
        else
            TargetURL += '?$expand=travelers,employees';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Stored Expense Users are projected back as the request's full Employee entities.
        Assert.AreNotEqual(
            0, StrPos(ResponseText, '"employeeNumber":"' + ExpenseUser."Employee No." + '"'),
            'Expanded travelers must return the mapped employee number.');
        Assert.AreEqual(0, StrPos(ResponseText, 'expenseUserNo'), 'Expanded travelers must not expose Expense User numbers.');
        Assert.AreEqual(0, StrPos(ResponseText, 'expenseUserName'), 'Expanded travelers must not expose Expense User names.');
        Employee.Get(ExpenseUser."Employee No.");
        OtherEmployee.Get(OtherExpenseUser."Employee No.");
        Assert.AreNotEqual(
            0, StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(Employee.SystemId)))),
            'The traveler Employee entity must be returned.');
        Assert.AreEqual(
            0, StrPos(LowerCase(ResponseText), LowerCase(LibraryGraphMgt.StripBrackets(Format(OtherEmployee.SystemId)))),
            'Employees who are not travelers must not be returned.');
    end;

    [Test]
    procedure TravelersAPIRejectsEmployeeWithoutExpenseUser()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        ErrorResponse: JsonToken;
        ErrorMessage: JsonToken;
        Request: JsonObject;
        Response: JsonObject;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] A traveler must be linked to an Expense User.
        Initialize();

        // [GIVEN] An employee without an Expense User and an open travel request.
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        Request.Add('employeeNumber', Employee."No.");
        Request.WriteTo(RequestBody);
        Commit();

        // [WHEN] The employee is added through the Travelers API.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Travel Requests API", TravelRequestsServiceNameTok);
        TargetURL := AppendPathToAPIURL(TargetURL, '/' + TravelersServiceNameTok);
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 400);

        // [THEN] The API identifies the employee without an Expense User.
        Assert.ExpectedError(BadRequestResponseErr);
        Response.ReadFrom(ResponseText);
        Response.Get('error', ErrorResponse);
        ErrorResponse.AsObject().Get('message', ErrorMessage);
        Assert.AreNotEqual(
            0, StrPos(ErrorMessage.AsValue().AsText(), StrSubstNo(ExpenseUserNotLinkedErr, Employee."No.")),
            'The response must identify the employee without an Expense User.');
    end;

    [Test]
    procedure CreateExpenseReportActionRecreatesDeletedReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] The bound OData action recreates a deleted report for an approved travel request.
        Initialize();

        // [GIVEN] An approved request whose automatically created report was deleted.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        TravelRequest.Validate("Requested For", ExpenseUser."No.");
        TravelRequest.Modify(true);
        LibraryExpense.SetSpendRequestStatus(TravelRequest, TravelRequest.Status::Approved);
        ExpenseReportHeader.CreateFromApprovedTravelRequest(TravelRequest);
        ExpenseReportHeader.SetRange("Spend Request No.", TravelRequest."No.");
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.Delete(true);
        Commit();

        // [WHEN] The create expense report action is invoked through the owner's OData route.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok);
        TargetURL := AppendPathToAPIURL(
            TargetURL, '/' + TravelRequestsServiceNameTok + '(' +
            LibraryGraphMgt.StripBrackets(Format(TravelRequest.SystemId)) + ')/' + CreateExpenseReportActionTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{}', ResponseText, 201);

        // [THEN] A new report is linked to the request and its Expense User.
        ExpenseReportHeader.SetRange("Spend Request No.", TravelRequest."No.");
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.TestField("Expense User No.", ExpenseUser."No.");
    end;

    [Test]
    procedure ApproveTravelRequestActionCreatesExpenseReport()
    var
        ApprovalSetup: Record "Expense Approval Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ApproverExpenseUser: Record "Expense User";
        RequestedForExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        TargetURL: Text;
        RequestBody: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Approving a travel request through its bound OData action creates the expense report.
        Initialize();

        // [GIVEN] A released travel request assigned to an approver.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        LibraryExpense.CreateExpenseUser(RequestedForExpenseUser);
        CreateApprover(ApproverExpenseUser);
        LibraryExpense.CreateExpenseApprovalSetup(
            ApprovalSetup, RequestedForExpenseUser."No.", ApproverExpenseUser."No.");
        CreatePendingTravelRequest(TravelRequest, RequestedForExpenseUser);
        Commit();

        // [WHEN] The approve travel request action is invoked through OData.
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            Format(TravelRequest.SystemId), Page::"Travel Requests API",
            TravelRequestsServiceNameTok, ApproveTravelRequestActionTok);
        RequestBody := StrSubstNo(ApproveTravelRequestBodyLbl, ApproverExpenseUser."No.");
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 200);

        // [THEN] The request is approved and a report is created for Requested For.
        TravelRequest.Get(TravelRequest."No.");
        TravelRequest.TestField(Status, TravelRequest.Status::Approved);
        ExpenseReportHeader.SetRange("Spend Request No.", TravelRequest."No.");
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.TestField("Expense User No.", RequestedForExpenseUser."No.");
    end;

    [Test]
    procedure TravelRequestsAPINormalizesCurrency()
    var
        ExpenseUser: Record "Expense User";
        Request: JsonObject;
        TargetURL: Text;
    begin
        // [SCENARIO] The user-scoped header API maps LCY without bypassing currency validation.
        Initialize();

        // [GIVEN] A linked expense user creating a travel request.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Request.Add('requestedBy', ExpenseUser."Employee No.");
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok);
        TargetURL := AppendPathToAPIURL(TargetURL, '/' + TravelRequestsServiceNameTok);

        // [WHEN] Currency is supplied, changed, cleared, and omitted over HTTP.
        // [THEN] API and storage representations agree and table validation remains active.
        VerifyTravelRequestCurrencyAPI(TargetURL, Request, false);
    end;

    [Test]
    procedure TravelRequestDetailsAPINormalizesCurrency()
    var
        ExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        Request: JsonObject;
        TargetURL: Text;
    begin
        // [SCENARIO] The user-scoped detail API accepts LCY ISO codes and retains foreign-currency rules.
        Initialize();

        // [GIVEN] An open travel request owned by a linked expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok);
        TargetURL := AppendPathToAPIURL(
            TargetURL, '/' + TravelRequestsServiceNameTok + '(' +
            LibraryGraphMgt.StripBrackets(Format(TravelRequest.SystemId)) + ')/' + TravelRequestDetailsServiceNameTok);

        // [WHEN] Currency is supplied, changed, cleared, and omitted over HTTP.
        // [THEN] API and storage representations agree and table validation remains active.
        VerifyTravelRequestCurrencyAPI(TargetURL, Request, true);
    end;

    [Test]
    procedure TravelRequestsAPIPreservesAndUpdatesDates()
    var
        ExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        Request: JsonObject;
        Response: JsonObject;
        ErrorResponse: JsonToken;
        ErrorMessage: JsonToken;
        RequestSystemId: Guid;
        StartDate: Date;
        EndDate: Date;
        TargetURL: Text;
        RecordURL: Text;
        RequestBody: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] User-scoped POST and PATCH preserve and validate the final date pair.
        Initialize();

        // [GIVEN] A linked user and a future pair, with id first and end before start in the payload.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        RequestSystemId := CreateGuid();
        StartDate := WorkDate() + 30;
        EndDate := WorkDate() + 33;
        Request.Add('id', LibraryGraphMgt.StripBrackets(Format(RequestSystemId)));
        Request.Add('requestedBy', ExpenseUser."Employee No.");
        Request.Add('expectedEndDate', Format(EndDate, 0, 9));
        Request.Add('expectedStartDate', Format(StartDate, 0, 9));
        Request.WriteTo(RequestBody);
        Commit();

        // [WHEN] The request is created through user-scoped navigation.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok);
        TargetURL := AppendPathToAPIURL(TargetURL, '/' + TravelRequestsServiceNameTok);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 201);

        // [THEN] POST, GET, and storage retain the supplied dates and identity.
        AssertAPIDates(ResponseText, StartDate, EndDate);
        TravelRequest.GetBySystemId(RequestSystemId);
        Assert.AreEqual(StartDate, TravelRequest."Expected Start Date", 'The API start date must be persisted.');
        Assert.AreEqual(EndDate, TravelRequest."Expected End Date", 'The API end date must be persisted.');
        RecordURL := AppendPathToAPIURL(TargetURL, '(' + LibraryGraphMgt.StripBrackets(Format(RequestSystemId)) + ')');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, RecordURL, 200);
        AssertAPIDates(ResponseText, StartDate, EndDate);

        // [WHEN] A start-first PATCH moves the range beyond the old end.
        StartDate += 30;
        EndDate += 30;
        Clear(Request);
        Request.Add('expectedStartDate', Format(StartDate, 0, 9));
        Request.Add('expectedEndDate', Format(EndDate, 0, 9));
        Request.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(RecordURL, RequestBody, ResponseText, 200);

        // [THEN] The complete later range is accepted.
        AssertAPIDates(ResponseText, StartDate, EndDate);

        // [WHEN] An end-first PATCH moves the range before the old start.
        StartDate := WorkDate() - 33;
        EndDate := WorkDate() - 30;
        Clear(Request);
        Request.Add('expectedEndDate', Format(EndDate, 0, 9));
        Request.Add('expectedStartDate', Format(StartDate, 0, 9));
        Request.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(RecordURL, RequestBody, ResponseText, 200);

        // [THEN] The complete earlier range is accepted.
        AssertAPIDates(ResponseText, StartDate, EndDate);

        // [WHEN] Only the end date is changed.
        EndDate += 1;
        Clear(Request);
        Request.Add('expectedEndDate', Format(EndDate, 0, 9));
        Request.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(RecordURL, RequestBody, ResponseText, 200);

        // [THEN] The omitted start remains unchanged.
        AssertAPIDates(ResponseText, StartDate, EndDate);

        // [WHEN] A start-only PATCH would exceed the stored end.
        Clear(Request);
        Request.Add('expectedStartDate', Format(EndDate + 1, 0, 9));
        Request.WriteTo(RequestBody);
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(RecordURL, RequestBody, ResponseText, 400);

        // [THEN] The date-range error is returned and the previous valid pair remains stored.
        Assert.ExpectedError(BadRequestResponseErr);
        Response.ReadFrom(ResponseText);
        Response.Get('error', ErrorResponse);
        ErrorResponse.AsObject().Get('message', ErrorMessage);
        Assert.AreNotEqual(0, StrPos(ErrorMessage.AsValue().AsText(), InvalidTravelRequestDatesErr), 'The invalid date range must cause the rejection.');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, RecordURL, 200);
        AssertAPIDates(ResponseText, StartDate, EndDate);
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
        // [SCENARIO] Expense Users expose only travel requests owned by their linked employee.
        Initialize();

        // [GIVEN] Two expense users with requests owned by their distinct employee numbers.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        Assert.AreNotEqual(
            ExpenseUser."No.", ExpenseUser."Employee No.",
            'The test requires different Expense User and Employee numbers.');
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        CreateTravelRequest(OtherTravelRequest, OtherExpenseUser."Employee No.");
        Commit();

        // [WHEN] The first user's travel requests are expanded through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok);
        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&$expand=travelRequests'
        else
            TargetURL += '?$expand=travelRequests';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);
        TravelRequestIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(TravelRequest.SystemId)));
        OtherTravelRequestIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(OtherTravelRequest.SystemId)));

        // [THEN] Only the request owned by that employee is returned.
        Assert.AreNotEqual(
            0, StrPos(ResponseText, TravelRequestIdTxt),
            'The Expense User should expose the Travel Request linked by Employee No.');
        Assert.AreEqual(
            0, StrPos(ResponseText, OtherTravelRequestIdTxt),
            'The Expense User should not expose another employee''s Travel Request.');

        // [WHEN] The owner is renamed and the same GUID-based URL is requested.
        ExpenseUser.Rename(CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExpenseUser."No.")));
        Commit();
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);

        // [THEN] The stable URL still includes only the original owner's request.
        Assert.AreNotEqual(0, StrPos(ResponseText, TravelRequestIdTxt), 'Owner navigation must survive a business-number rename.');
        Assert.AreEqual(0, StrPos(ResponseText, OtherTravelRequestIdTxt), 'Renaming must not broaden the owner scope.');
    end;

    [Test]
    procedure ExpenseReportAPIExposesLinkedTravelRequest()
    var
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        TravelRequest: Record "Spend Request";
        Response: JsonObject;
        TravelRequestId: JsonToken;
        LinkedTravelRequest: JsonToken;
        LinkedTravelRequestId: JsonToken;
        TargetURL: Text;
        ResponseText: Text;
        ExpectedId: Text;
    begin
        // [SCENARIO] The report's projected GUID and expanded navigation identify the same approved travel request.
        Initialize();

        // [GIVEN] An expense report created from an approved travel request.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        TravelRequest.Validate("Requested For", ExpenseUser."No.");
        TravelRequest.Modify(true);
        LibraryExpense.SetSpendRequestStatus(TravelRequest, TravelRequest.Status::Approved);
        ExpenseReportHeader.CreateFromApprovedTravelRequest(TravelRequest);
        ExpenseReportHeader.SetRange("Spend Request No.", TravelRequest."No.");
        ExpenseReportHeader.FindFirst();
        Commit();

        // [WHEN] The report is retrieved with its travel request expanded.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseReportHeader.SystemId), Page::"Expense Reports API", ExpenseReportsServiceNameTok);
        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&$expand=travelRequest'
        else
            TargetURL += '?$expand=travelRequest';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The report's GUID and expanded request identify the originating travel request.
        Response.ReadFrom(ResponseText);
        Response.Get('travelRequestId', TravelRequestId);
        Response.Get('travelRequest', LinkedTravelRequest);
        LinkedTravelRequest.AsObject().Get('id', LinkedTravelRequestId);
        ExpectedId := LowerCase(LibraryGraphMgt.StripBrackets(Format(TravelRequest.SystemId)));
        Assert.AreEqual(ExpectedId, LowerCase(TravelRequestId.AsValue().AsText()), 'The report must expose the linked travel request GUID.');
        Assert.AreEqual(ExpectedId, LowerCase(LinkedTravelRequestId.AsValue().AsText()), 'The expanded navigation must return the linked travel request.');
    end;

    [Test]
    procedure TravelRequestDetailsAPIExposesTypeAndCategory()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        TravelRequest: Record "Spend Request";
        TravelRequestDetail: Record "Spend Request Detail";
        Response: JsonObject;
        DetailType: JsonToken;
        CategoryCode: JsonToken;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] The detail API projects its line type and expense category.
        Initialize();

        // [GIVEN] A Category detail line with an expense category.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateSpendRequestDetail(TravelRequestDetail, TravelRequest."No.", 0);
        TravelRequestDetail.Validate(Type, TravelRequestDetail.Type::Category);
        TravelRequestDetail.Validate("Expense Category Code", ExpenseCategory.Code);
        TravelRequestDetail.Modify(true);
        Commit();

        // [WHEN] The detail is retrieved through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequestDetail.SystemId), Page::"Travel Request Details API", TravelRequestDetailsServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The payload includes the stored type and expense category.
        Response.ReadFrom(ResponseText);
        Response.Get('type', DetailType);
        Response.Get('expenseCategoryCode', CategoryCode);
        Assert.AreEqual('Category', DetailType.AsValue().AsText(), 'The detail API must expose the Category line type.');
        Assert.AreEqual(ExpenseCategory.Code, CategoryCode.AsValue().AsText(), 'The detail API must expose the expense category code.');
    end;

    [Test]
    procedure ApproverViewReturnsOnlyAssignedTravelRequests()
    var
        ApprovalSetup: Record "Expense Approval Setup";
        OtherApprovalSetup: Record "Expense Approval Setup";
        ApproverExpenseUser: Record "Expense User";
        OtherApproverExpenseUser: Record "Expense User";
        RequestedExpenseUser: Record "Expense User";
        OtherRequestedExpenseUser: Record "Expense User";
        AssignedTravelRequest: Record "Spend Request";
        OtherTravelRequest: Record "Spend Request";
        TargetURL: Text;
        ResponseText: Text;
        AssignedTravelRequestIdTxt: Text;
        OtherTravelRequestIdTxt: Text;
    begin
        // [SCENARIO] Approver Views expose only pending travel requests assigned to the approver.
        Initialize();

        // [GIVEN] Two pending requests assigned to different approvers.
        LibraryExpense.CreateExpenseUser(RequestedExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherRequestedExpenseUser);
        CreateApprover(ApproverExpenseUser);
        CreateApprover(OtherApproverExpenseUser);
        LibraryExpense.CreateExpenseApprovalSetup(
            ApprovalSetup, RequestedExpenseUser."No.", ApproverExpenseUser."No.");
        LibraryExpense.CreateExpenseApprovalSetup(
            OtherApprovalSetup, OtherRequestedExpenseUser."No.", OtherApproverExpenseUser."No.");
        CreatePendingTravelRequest(AssignedTravelRequest, RequestedExpenseUser);
        CreatePendingTravelRequest(OtherTravelRequest, OtherRequestedExpenseUser);
        Commit();

        // [WHEN] The first approver's travel requests are expanded through the API.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ApproverExpenseUser.SystemId), Page::"Approver View API", ApproverViewsServiceNameTok);
        if StrPos(TargetURL, '?') <> 0 then
            TargetURL += '&$expand=travelRequests'
        else
            TargetURL += '?$expand=travelRequests';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        ResponseText := LowerCase(ResponseText);
        AssignedTravelRequestIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(AssignedTravelRequest.SystemId)));
        OtherTravelRequestIdTxt := LowerCase(LibraryGraphMgt.StripBrackets(Format(OtherTravelRequest.SystemId)));

        // [THEN] Only the request assigned to that approver is returned.
        Assert.AreNotEqual(
            0, StrPos(ResponseText, AssignedTravelRequestIdTxt),
            'The Approver View should expose the Travel Request assigned to the approver.');
        Assert.AreEqual(
            0, StrPos(ResponseText, OtherTravelRequestIdTxt),
            'The Approver View should not expose a Travel Request assigned to another approver.');
    end;

    [Test]
    procedure TravelRequestsAPIAllowsOwnerOnInsertAndUnchangedPatch()
    var
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        Response: JsonObject;
        RequestId: JsonToken;
        ErrorResponse: JsonToken;
        ErrorMessage: JsonToken;
        TravelRequestSystemId: Guid;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The owner can be supplied on POST and resent unchanged on PATCH.
        Initialize();

        // [GIVEN] An expense user linked to an employee.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        Commit();

        // [WHEN] A travel request is created with that employee as its owner.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(ExpenseUser.SystemId), Page::"Expense Users API", ExpenseUsersServiceNameTok);
        TargetURL := AppendPathToAPIURL(TargetURL, '/' + TravelRequestsServiceNameTok);

        // [WHEN] POST attempts to assign another employee under this user's GUID.
        RequestBody := StrSubstNo(RequestedByRequestBodyLbl, OtherExpenseUser."Employee No.");
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 400);

        // [THEN] The owner mismatch is rejected before a request can be inserted.
        Assert.ExpectedError(BadRequestResponseErr);
        Response.ReadFrom(ResponseText);
        Response.Get('error', ErrorResponse);
        ErrorResponse.AsObject().Get('message', ErrorMessage);
        Assert.AreNotEqual(
            0, StrPos(ErrorMessage.AsValue().AsText(), TravelRequest.FieldCaption("Requested By")),
            'The rejection must identify the owner mismatch.');

        // [WHEN] POST supplies the employee matching this user's GUID.
        RequestBody := StrSubstNo(RequestedByRequestBodyLbl, ExpenseUser."Employee No.");
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 201);

        // [THEN] The new travel request stores the supplied owner.
        Response.ReadFrom(ResponseText);
        Response.Get('id', RequestId);
        Evaluate(TravelRequestSystemId, RequestId.AsValue().AsText());
        TravelRequest.GetBySystemId(TravelRequestSystemId);
        Assert.AreEqual(ExpenseUser."Employee No.", TravelRequest."Requested By", 'POST must accept the travel request owner.');
        Assert.AreEqual(TravelRequest."Document Type"::"Travel Request", TravelRequest."Document Type", 'POST must create a travel request.');

        // [WHEN] The purpose is updated while resending the same owner.
        // [THEN] PATCH succeeds without changing the owner.
        TargetURL := AppendPathToAPIURL(TargetURL, '(' + LibraryGraphMgt.StripBrackets(Format(TravelRequest.SystemId)) + ')');
        AssertOwnerPreservingPatch(TargetURL, TravelRequest);
    end;

    [Test]
    procedure TravelRequestsAPIRejectsLifecycleFieldChanges()
    var
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        OriginalRequestedBy: Code[20];
        Response: JsonObject;
        ErrorResponse: JsonToken;
        ErrorCode: JsonToken;
        ErrorMessage: JsonToken;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] PATCH cannot reassign a travel request or change its status.
        Initialize();

        // [GIVEN] An open travel request and another expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        OriginalRequestedBy := TravelRequest."Requested By";
        Commit();

        // [WHEN] PATCH attempts to change the owner.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Travel Requests API", TravelRequestsServiceNameTok);
        RequestBody := StrSubstNo(RequestedByRequestBodyLbl, OtherExpenseUser."Employee No.");
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 400);

        // [THEN] The API identifies the immutable owner and the affected request.
        Assert.ExpectedError(BadRequestResponseErr);
        AssertOwnerChangeError(ResponseText, TravelRequest);

        // [WHEN] PATCH attempts to change the status.
        Clear(ResponseText);
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(
            TargetURL, StatusRequestBodyLbl, ResponseText, 400);

        // [THEN] The API rejects the read-only status, leaving ownership and status unchanged.
        Assert.ExpectedError(BadRequestResponseErr);
        Response.ReadFrom(ResponseText);
        Response.Get('error', ErrorResponse);
        ErrorResponse.AsObject().Get('code', ErrorCode);
        ErrorResponse.AsObject().Get('message', ErrorMessage);
        Assert.AreEqual('BadRequest', ErrorCode.AsValue().AsText(), 'The status update must be rejected by the OData read-only guard.');
        Assert.AreNotEqual(0, StrPos(ErrorMessage.AsValue().AsText(), StatusReadOnlyErr), 'The API error must identify the read-only status control.');
        TravelRequest.Get(TravelRequest."No.");
        Assert.AreEqual(
            OriginalRequestedBy, TravelRequest."Requested By",
            'The Travel Requests API must not change the Travel Request owner.');
        Assert.AreEqual(
            TravelRequest.Status::Open, TravelRequest.Status,
            'The Travel Requests API must not change the Travel Request status.');
    end;

#if not CLEAN30
    [Test]
    procedure LegacySpendRequestsAPIAllowsUnchangedOwner()
    var
        ExpenseUser: Record "Expense User";
        TravelRequest: Record "Spend Request";
        TargetURL: Text;
    begin
        // [SCENARIO] Legacy clients may resend the unchanged owner when updating a travel request.
        Initialize();

        // [GIVEN] A travel request owned by a linked employee.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        Commit();

        // [WHEN] The purpose is updated through the legacy endpoint with the same owner.
        // [THEN] PATCH succeeds without changing the owner.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Spend Requests API", SpendRequestsServiceNameTok);
        AssertOwnerPreservingPatch(TargetURL, TravelRequest);
    end;

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
        // [SCENARIO] The legacy endpoint cannot bypass travel request ownership protection.
        Initialize();

        // [GIVEN] A travel request owned by one of two expense users.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        OriginalRequestedBy := TravelRequest."Requested By";
        Commit();

        // [WHEN] PATCH through the legacy endpoint attempts to change the owner.
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Spend Requests API", SpendRequestsServiceNameTok);
        RequestBody := StrSubstNo(RequestedByRequestBodyLbl, OtherExpenseUser."Employee No.");
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 400);

        // [THEN] The owner change is rejected and the original owner is preserved.
        Assert.ExpectedError(BadRequestResponseErr);
        AssertOwnerChangeError(ResponseText, TravelRequest);
        TravelRequest.Get(TravelRequest."No.");
        Assert.AreEqual(
            OriginalRequestedBy, TravelRequest."Requested By",
            'The legacy Spend Requests API must not change the Travel Request owner.');
    end;
#endif

    local procedure VerifyTravelRequestCurrencyAPI(TargetURL: Text; Request: JsonObject; IsDetail: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        TravelRequest: Record "Spend Request";
        TravelRequestDetail: Record "Spend Request Detail";
        SystemId: Guid;
        ForeignCurrencyCode: Code[10];
        InvalidCurrencyCode: Code[10];
        ForeignExchangeRate: Decimal;
        AmountField: Text;
        RecordURL: Text;
        SelectedCurrencyURL: Text;
        RequestBody: Text;
        ResponseText: Text;
    begin
        // [GIVEN] Configured LCY and a foreign currency with a non-unit exchange rate.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");
        ForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(Today(), 1, 2);
        Currency.Get(ForeignCurrencyCode);
        ForeignExchangeRate := Currency.GetExchangeRate(Today());
        Assert.AreNotEqual(GeneralLedgerSetup."LCY Code", ForeignCurrencyCode, 'The fixture must use a foreign currency.');
        Assert.AreNotEqual(1, ForeignExchangeRate, 'The fixture must exercise exchange-rate validation.');
        InvalidCurrencyCode := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(InvalidCurrencyCode));
        Assert.AreNotEqual(GeneralLedgerSetup."LCY Code", InvalidCurrencyCode, 'The invalid code must not be LCY.');
        Assert.IsFalse(Currency.Get(InvalidCurrencyCode), 'The invalid code must not exist in Currency.');
        SystemId := CreateGuid();
        if IsDetail then
            AmountField := 'expectedAmount'
        else
            AmountField := 'totalExpectedAmount';
        Request.Add('id', LibraryGraphMgt.StripBrackets(Format(SystemId)));
        Request.Add('currencyCode', GeneralLedgerSetup."LCY Code");
        Request.Add(AmountField, 100);
        Request.WriteTo(RequestBody);
        Commit();

        // [WHEN] POST explicitly supplies the LCY ISO code.
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 201);

        // [THEN] It is stored as blank and returned as the configured LCY code.
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, GeneralLedgerSetup."LCY Code", '', 1);
        RecordURL := AppendPathToAPIURL(TargetURL, '(' + LibraryGraphMgt.StripBrackets(Format(SystemId)) + ')');
        if StrPos(RecordURL, '?') = 0 then
            SelectedCurrencyURL := RecordURL + '?$select=currencyCode'
        else
            SelectedCurrencyURL := RecordURL + '&$select=currencyCode';
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, SelectedCurrencyURL, 200);
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, GeneralLedgerSetup."LCY Code", '', 1);

        // [WHEN] PATCH switches to a configured foreign currency.
        PatchCurrency(RecordURL, ForeignCurrencyCode, ResponseText);

        // [THEN] The foreign code is retained and the table computes its exchange rate.
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, ForeignCurrencyCode, ForeignCurrencyCode, ForeignExchangeRate);

        // [WHEN] An amount-only PATCH omits currency.
        Clear(Request);
        Request.Add(AmountField, 200);
        Request.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(RecordURL, RequestBody, ResponseText, 200);

        // [THEN] Neither the foreign currency nor its exchange rate is reset to LCY.
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, ForeignCurrencyCode, ForeignCurrencyCode, ForeignExchangeRate);

        // [WHEN] PATCH supplies LCY explicitly, then switches back to foreign currency and clears it.
        PatchCurrency(RecordURL, GeneralLedgerSetup."LCY Code", ResponseText);
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, GeneralLedgerSetup."LCY Code", '', 1);
        PatchCurrency(RecordURL, ForeignCurrencyCode, ResponseText);
        PatchCurrency(RecordURL, '', ResponseText);

        // [THEN] Both explicit LCY and blank inputs return the canonical ISO code.
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, GeneralLedgerSetup."LCY Code", '', 1);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, SelectedCurrencyURL, 200);
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, GeneralLedgerSetup."LCY Code", '', 1);

        // [WHEN] PATCH supplies an unknown non-LCY code.
        // [THEN] Currency validation rejects it rather than treating it as local currency.
        AssertCurrencyPatchError(RecordURL, InvalidCurrencyCode, InvalidCurrencyCode);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, RecordURL, 200);
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, GeneralLedgerSetup."LCY Code", '', 1);

        // [GIVEN] The request is no longer Open.
        if IsDetail then begin
            TravelRequestDetail.GetBySystemId(SystemId);
            TravelRequest.Get(TravelRequestDetail."Spend Request No.");
        end else
            TravelRequest.GetBySystemId(SystemId);
        LibraryExpense.SetSpendRequestStatus(TravelRequest, TravelRequest.Status::Released);
        Commit();

        // [WHEN] PATCH attempts a currency change.
        // [THEN] The existing Open-status validation rejects it without changing currency.
        AssertCurrencyPatchError(RecordURL, ForeignCurrencyCode, StatusNotOpenErr);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, RecordURL, 200);
        AssertTravelRequestCurrency(ResponseText, SystemId, IsDetail, GeneralLedgerSetup."LCY Code", '', 1);
    end;

    local procedure PatchCurrency(TargetURL: Text; CurrencyCode: Code[10]; var ResponseText: Text)
    var
        Request: JsonObject;
        RequestBody: Text;
    begin
        Request.Add('currencyCode', CurrencyCode);
        Request.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 200);
    end;

    local procedure AssertCurrencyPatchError(TargetURL: Text; CurrencyCode: Code[10]; ExpectedError: Text)
    var
        Request: JsonObject;
        Response: JsonObject;
        ErrorResponse: JsonToken;
        ErrorMessage: JsonToken;
        RequestBody: Text;
        ResponseText: Text;
    begin
        Request.Add('currencyCode', CurrencyCode);
        Request.WriteTo(RequestBody);
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 400);
        Assert.ExpectedError(BadRequestResponseErr);
        Response.ReadFrom(ResponseText);
        Response.Get('error', ErrorResponse);
        ErrorResponse.AsObject().Get('message', ErrorMessage);
        Assert.AreNotEqual(0, StrPos(ErrorMessage.AsValue().AsText(), ExpectedError), 'The expected table validation must cause the rejection.');
    end;

    local procedure AssertTravelRequestCurrency(ResponseText: Text; SystemId: Guid; IsDetail: Boolean; APICurrencyCode: Code[10]; StoredCurrencyCode: Code[10]; ExchangeRate: Decimal)
    var
        TravelRequest: Record "Spend Request";
        TravelRequestDetail: Record "Spend Request Detail";
        Response: JsonObject;
        CurrencyCode: JsonToken;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get('currencyCode', CurrencyCode);
        Assert.AreEqual(APICurrencyCode, CurrencyCode.AsValue().AsText(), 'The API must expose the canonical currency code.');
        if IsDetail then begin
            TravelRequestDetail.GetBySystemId(SystemId);
            Assert.AreEqual(StoredCurrencyCode, TravelRequestDetail."Currency Code", 'The detail must store the BC currency representation.');
            Assert.AreEqual(ExchangeRate, TravelRequestDetail."Currency Exchange Rate", 'The detail currency trigger must maintain the exchange rate.');
        end else begin
            TravelRequest.GetBySystemId(SystemId);
            Assert.AreEqual(StoredCurrencyCode, TravelRequest."Currency Code", 'The header must store the BC currency representation.');
            Assert.AreEqual(ExchangeRate, TravelRequest."Currency Exchange Rate", 'The header currency trigger must maintain the exchange rate.');
        end;
    end;

    local procedure AppendPathToAPIURL(TargetURL: Text; PathSuffix: Text): Text
    var
        QueryPosition: Integer;
    begin
        QueryPosition := StrPos(TargetURL, '?');
        if QueryPosition = 0 then
            exit(TargetURL + PathSuffix);

        exit(CopyStr(TargetURL, 1, QueryPosition - 1) + PathSuffix + CopyStr(TargetURL, QueryPosition));
    end;

    local procedure AssertAPIDates(ResponseText: Text; StartDate: Date; EndDate: Date)
    var
        Response: JsonObject;
        StartDateToken: JsonToken;
        EndDateToken: JsonToken;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get('expectedStartDate', StartDateToken);
        Response.Get('expectedEndDate', EndDateToken);
        Assert.AreEqual(StartDate, StartDateToken.AsValue().AsDate(), 'The API must return the effective start date.');
        Assert.AreEqual(EndDate, EndDateToken.AsValue().AsDate(), 'The API must return the effective end date.');
    end;

    local procedure AssertOwnerPreservingPatch(TargetURL: Text; TravelRequest: Record "Spend Request")
    var
        Request: JsonObject;
        Response: JsonObject;
        RequestedBy: JsonToken;
        Purpose: JsonToken;
        RequestBody: Text;
        ResponseText: Text;
        ExpectedPurpose: Text;
    begin
        ExpectedPurpose := 'Updated business trip';
        Request.Add('requestedBy', TravelRequest."Requested By");
        Request.Add('purpose', ExpectedPurpose);
        Request.WriteTo(RequestBody);
        LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, RequestBody, ResponseText, 200);

        Response.ReadFrom(ResponseText);
        Response.Get('requestedBy', RequestedBy);
        Response.Get('purpose', Purpose);
        Assert.AreEqual(TravelRequest."Requested By", RequestedBy.AsValue().AsText(), 'PATCH must preserve the owner.');
        Assert.AreEqual(ExpectedPurpose, Purpose.AsValue().AsText(), 'PATCH must update the purpose when the owner is unchanged.');
    end;

    local procedure AssertOwnerChangeError(ResponseText: Text; TravelRequest: Record "Spend Request")
    var
        Response: JsonObject;
        ErrorResponse: JsonToken;
        ErrorMessage: JsonToken;
        MessageText: Text;
    begin
        Response.ReadFrom(ResponseText);
        Response.Get('error', ErrorResponse);
        ErrorResponse.AsObject().Get('message', ErrorMessage);
        MessageText := ErrorMessage.AsValue().AsText();
        Assert.AreNotEqual(0, StrPos(MessageText, RequestedByCannotBeChangedErr), 'The API must reject the owner change.');
        Assert.AreNotEqual(0, StrPos(MessageText, TravelRequest.FieldCaption("Requested By")), 'The error must identify Requested By.');
        Assert.AreNotEqual(0, StrPos(MessageText, TravelRequest."No."), 'The error must identify the travel request.');
    end;

    local procedure CreateTravelRequest(var TravelRequest: Record "Spend Request"; EmployeeNo: Code[20])
    begin
        LibraryExpense.CreateSpendRequest(TravelRequest);
        TravelRequest.Validate("Requested By", EmployeeNo);
        TravelRequest.Modify(true);
    end;

    local procedure CreatePendingTravelRequest(var TravelRequest: Record "Spend Request"; ExpenseUser: Record "Expense User")
    begin
        CreateTravelRequest(TravelRequest, ExpenseUser."Employee No.");
        TravelRequest.Validate("Requested For", ExpenseUser."No.");
        TravelRequest.Modify(true);
        LibraryExpense.SetSpendRequestStatus(TravelRequest, TravelRequest.Status::Released);
    end;

    local procedure CreateApprover(var ExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser."Can Approve" := true;
        ExpenseUser."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(ExpenseUser."User Id For Approvals"));
        ExpenseUser.Modify(true);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Travel Requests API Test");
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthHelper);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Travel Requests API Test");
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Travel Requests API Test");
    end;
}
