// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.SpendRequest;

codeunit 148347 "Travel Requests API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        APITestAuthHelper: Codeunit "Expense API Test Auth Helper";
        IsInitialized: Boolean;
        ExpenseUsersServiceNameTok: Label 'expenseUsers', Locked = true;
#if not CLEAN30
        SpendRequestsServiceNameTok: Label 'spendRequests', Locked = true;
#endif
        ApproverViewsServiceNameTok: Label 'approverViews', Locked = true;
        TravelRequestsServiceNameTok: Label 'travelRequests', Locked = true;
        ExpenseReportsServiceNameTok: Label 'expenseReports', Locked = true;
        TravelRequestDetailsServiceNameTok: Label 'travelRequestDetails', Locked = true;
        BadRequestResponseErr: Label 'Response code is 400 (BadRequest).', Locked = true;
        RequestedByCannotBeChangedErr: Label 'cannot be changed', Locked = true;
        RequestedByRequestBodyLbl: Label '{"requestedBy":"%1"}', Comment = '%1 = Employee number', Locked = true;
        StatusRequestBodyLbl: Label '{"status":"Released"}', Locked = true;
        StatusReadOnlyErr: Label 'Control ''status'' is read-only.', Locked = true;

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
        LibraryExpense.CreateTraveler(TravelRequest."No.", ExpenseUser."No.");
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
        TravelRequest: Record "Spend Request";
        Response: JsonObject;
        RequestId: JsonToken;
        TravelRequestSystemId: Guid;
        RequestBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] The owner can be supplied on POST and resent unchanged on PATCH.
        Initialize();

        // [GIVEN] An expense user linked to an employee.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Commit();

        // [WHEN] A travel request is created with that employee as its owner.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Travel Requests API", TravelRequestsServiceNameTok);
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
        TargetURL := LibraryGraphMgt.CreateTargetURL(
            Format(TravelRequest.SystemId), Page::"Travel Requests API", TravelRequestsServiceNameTok);
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
