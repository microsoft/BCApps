// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SpendRequest;
using Microsoft.Foundation.AuditCodes;
using Microsoft.HumanResources.Setup;

codeunit 148369 "Travel Request Approval Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        TravelRequestApproval: Codeunit "Travel Request Approval";
        IsInitialized: Boolean;
        NotTravelRequestApproverErr: Label 'is not authorized', Locked = true;
        ApproverRequiredErr: Label 'Configure the approver in Expense Approval Setup.', Locked = true;
        ApprovalLimitExceededErr: Label 'exceeds the', Locked = true;
        AlternateApproverActorErr: Label 'Only the owner of the travel request or an approval administrator can assign an alternate approver.', Locked = true;
        NotTravelRequestOwnerRecallErr: Label 'cannot recall travel request', Locked = true;
        PendingTravelApproverErr: Label 'is the approver for travel request', Locked = true;
        ApproverAssignedMsg: Label 'The travel request must be assigned to the expected approver.';
        AlternateApproverMsg: Label 'The travel request must record the expected alternate approver.';
        PrimaryApproverMsg: Label 'The travel request must record the expected primary approver.';
        RoutedRequestVisibleMsg: Label 'The assigned approver must see the routed travel request.';
        RoutedRequestHiddenMsg: Label 'An approver from the approval setup must not see a travel request routed to another approver.';
        ActivityLoggedMsg: Label 'Exactly one activity entry of the expected type must be logged.';
        ActorRoleMsg: Label 'The activity entry must record the expected actor role.';
        ActorMsg: Label 'The activity entry must be attributed to the expected expense user.';
        ActionResultMsg: Label 'The travel request page action must return an updated result.';

    [Test]
    procedure SubmitAssignsApproverFromApprovalSetup()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
    begin
        // [SCENARIO] Submitting a travel request assigns the approver from the approval setup.
        Initialize();

        // [GIVEN] A travel request within the unlimited approver's authority.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");

        // [WHEN] The owner submits the travel request.
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The travel request waits for the approver from the approval setup.
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Released);
        Assert.AreEqual(Approver."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
        SpendRequest.TestField("Alternate Approver No.", '');
        SpendRequest.TestField("Primary Approver No.", '');
    end;

    [Test]
    procedure SubmitEscalatesWhenAmountExceedsApprovalLimit()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        LimitedApprover: Record "Expense User";
        UnlimitedApprover: Record "Expense User";
    begin
        // [SCENARIO] A travel request above the approver's limit is escalated through the approver's own approval setup.
        Initialize();

        // [GIVEN] Approver "A" with a limit of 100 whose approver is the unlimited approver "B".
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(LimitedApprover);
        SetApprovalLimit(LimitedApprover, 100);
        CreateApprover(UnlimitedApprover);
        SetApprover(TravelerExpenseUser."No.", LimitedApprover."No.");
        SetApprover(LimitedApprover."No.", UnlimitedApprover."No.");

        // [WHEN] A travel request of 500 is submitted.
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The travel request is assigned to "B".
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(UnlimitedApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);

        // [THEN] "A" cannot approve it, but "B" can.
        Commit();
        asserterror TravelRequestApproval.Approve(SpendRequest, LimitedApprover."No.");
        Assert.ExpectedError(NotTravelRequestApproverErr);
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestApproval.Approve(SpendRequest, UnlimitedApprover."No.");
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Approved);
        SpendRequest.TestField("Approval Expense User No.", UnlimitedApprover."No.");
    end;

    [Test]
    procedure SubmitFailsWhenNoApproverCoversAmount()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        LimitedApprover: Record "Expense User";
    begin
        // [SCENARIO] A travel request above every available approval limit cannot be submitted.
        Initialize();

        // [GIVEN] Approver "A" with a limit of 100, no further approver, and no default approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(LimitedApprover);
        SetApprovalLimit(LimitedApprover, 100);
        SetApprover(TravelerExpenseUser."No.", LimitedApprover."No.");

        // [WHEN] A travel request of 500 is submitted.
        asserterror TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The submission fails and asks for an approver in the approval setup.
        Assert.ExpectedError(ApproverRequiredErr);
    end;

    [Test]
    procedure SubmitRoutesToTravelerWithinOwnApprovalLimit()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
    begin
        // [SCENARIO] An approver-capable traveler approves their own travel request within their own limit.
        Initialize();

        // [GIVEN] A traveler who can approve up to 1000 and has another approver in the approval setup.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        MakeApprover(TravelerExpenseUser);
        SetApprovalLimit(TravelerExpenseUser, 1000);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");

        // [WHEN] A travel request of 500 is submitted.
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The traveler is the approver.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(TravelerExpenseUser."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
    end;

    [Test]
    procedure SubmitRoutesToApproverWhenTravelerExceedsOwnApprovalLimit()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
    begin
        // [SCENARIO] An approver-capable traveler above their own limit is routed to the configured approver.
        Initialize();

        // [GIVEN] A traveler who can approve up to 100 and has an unlimited approver in the approval setup.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        MakeApprover(TravelerExpenseUser);
        SetApprovalLimit(TravelerExpenseUser, 100);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");

        // [WHEN] A travel request of 500 is submitted.
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The configured approver is the approver.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(Approver."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
    end;

    [Test]
    procedure ApproveFailsWhenApprovalLimitIsReducedAfterSubmission()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
    begin
        // [SCENARIO] The approval limit is checked again when the approver approves.
        Initialize();

        // [GIVEN] A submitted travel request of 500 assigned to an unlimited approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [GIVEN] The approver's authority is reduced to 100.
        SetApprovalLimit(Approver, 100);

        // [WHEN] The approver approves the travel request.
        SpendRequest.Get(SpendRequest."No.");
        asserterror TravelRequestApproval.Approve(SpendRequest, Approver."No.");

        // [THEN] The approval fails because the travel request exceeds the approval limit.
        Assert.ExpectedError(ApprovalLimitExceededErr);
    end;

    [Test]
    procedure DirectlyReleasedTravelRequestKeepsApproverFromApprovalSetup()
    var
        SpendRequest: Record "Spend Request";
        FilteredTravelRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO] A travel request released in the client is listed for, and approved by, the approver from the approval setup.
        Initialize();

        // [GIVEN] A travel request released in the client, without an assigned approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        ReleaseSpendRequest.Release(SpendRequest);
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField("Approver Expense User No.", '');

        // [THEN] The approver from the approval setup sees the travel request.
        FilterPendingTravelRequests(FilteredTravelRequest, Approver, SpendRequest."No.");
        Assert.IsFalse(FilteredTravelRequest.IsEmpty(), RoutedRequestVisibleMsg);

        // [WHEN] The approver from the approval setup approves the travel request.
        TravelRequestApproval.Approve(SpendRequest, Approver."No.");

        // [THEN] The travel request is approved and remembers its approver.
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Approved);
        Assert.AreEqual(Approver."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
    end;

    [Test]
    procedure DirectlyReleasedTravelRequestRoutesByApprovalLimit()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        LimitedApprover: Record "Expense User";
        UnlimitedApprover: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO] A travel request released in the client above the approver's limit is escalated like a submission when a decision is made.
        Initialize();

        // [GIVEN] A travel request of 500 released in the client, with approver "A" limited to 100 and escalation to "B".
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(LimitedApprover);
        SetApprovalLimit(LimitedApprover, 100);
        CreateApprover(UnlimitedApprover);
        SetApprover(TravelerExpenseUser."No.", LimitedApprover."No.");
        SetApprover(LimitedApprover."No.", UnlimitedApprover."No.");
        ReleaseSpendRequest.Release(SpendRequest);
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField("Approver Expense User No.", '');

        // [WHEN] "A" attempts to approve the travel request.
        Commit();
        asserterror TravelRequestApproval.Approve(SpendRequest, LimitedApprover."No.");

        // [THEN] The approval is rejected because the travel request is escalated to "B".
        Assert.ExpectedError(NotTravelRequestApproverErr);

        // [WHEN] "B" approves the travel request.
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestApproval.Approve(SpendRequest, UnlimitedApprover."No.");

        // [THEN] The travel request is approved by "B".
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Approved);
        Assert.AreEqual(UnlimitedApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
        SpendRequest.TestField("Approval Expense User No.", UnlimitedApprover."No.");
    end;

    [Test]
    procedure SubmitAssignsActiveAlternateApprover()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // [SCENARIO] A travel request is delegated to the active alternate approver of its approver on submission.
        Initialize();

        // [GIVEN] An approver with an alternate approver whose coverage is active today.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        CreateAlternateApproverCoverage(Approver."No.", AlternateApprover."No.", WorkDate(), 0D);

        // [WHEN] The owner submits the travel request.
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The alternate approver is assigned, and the primary approver is kept for the end of the coverage.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(AlternateApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
        Assert.AreEqual(AlternateApprover."No.", SpendRequest."Alternate Approver No.", AlternateApproverMsg);
        Assert.AreEqual(Approver."No.", SpendRequest."Primary Approver No.", PrimaryApproverMsg);

        // [THEN] The delegation is logged in the travel request history.
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::AlternateApproverAssigned, ExpenseActivityLogEntry), ActivityLoggedMsg);
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Administrator, ExpenseActivityLogEntry."Actor Role", ActorRoleMsg);

        // [THEN] The alternate approver can approve the travel request.
        TravelRequestApproval.Approve(SpendRequest, AlternateApprover."No.");
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Approved);
    end;

    [Test]
    procedure OwnerAssignsAlternateApproverToSubmittedTravelRequest()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // [SCENARIO] The owner assigns the alternate approver whose coverage started after the submission.
        Initialize();

        // [GIVEN] A submitted travel request, followed by alternate coverage for its approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        CreateAlternateApproverCoverage(Approver."No.", AlternateApprover."No.", WorkDate(), 0D);

        // [WHEN] The owner assigns the alternate approver.
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestApproval.AssignAlternateApprover(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The alternate approver is assigned and the assignment is logged for the owner.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(AlternateApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
        Assert.AreEqual(Approver."No.", SpendRequest."Primary Approver No.", PrimaryApproverMsg);
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::AlternateApproverAssigned, ExpenseActivityLogEntry), ActivityLoggedMsg);
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Submitter, ExpenseActivityLogEntry."Actor Role", ActorRoleMsg);
        Assert.AreEqual(TravelerExpenseUser.SystemId, ExpenseActivityLogEntry."Actor Record System ID", ActorMsg);
    end;

    [Test]
    procedure AssignAlternateApproverPageAction()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        AlternateApprover: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] The alternate approver page procedure delegates a submitted travel request.
        Initialize();

        // [GIVEN] A submitted travel request whose approver has active alternate coverage.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        CreateAlternateApproverCoverage(Approver."No.", AlternateApprover."No.", WorkDate(), 0D);
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestsAPI.SetRecord(SpendRequest);

        // [WHEN] The page procedure is invoked directly, without an HTTP request.
        TravelRequestsAPI.AssignAlternateApprover(ActionContext, TravelerExpenseUser."No.");

        // [THEN] The action returns Updated and the alternate approver is assigned.
        Assert.AreEqual(Format(WebServiceActionResultCode::Updated), Format(ActionContext.GetResultCode()), ActionResultMsg);
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(AlternateApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
    end;

    [Test]
    procedure AssignAlternateApproverRejectsOtherExpenseUser()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        AlternateApprover: Record "Expense User";
    begin
        // [SCENARIO] Only the owner of the travel request can assign an alternate approver through the agent.
        Initialize();

        // [GIVEN] A submitted travel request whose approver has active alternate coverage, and another expense user.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        CreateAlternateApproverCoverage(Approver."No.", AlternateApprover."No.", WorkDate(), 0D);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);

        // [WHEN] The other expense user assigns the alternate approver.
        SpendRequest.Get(SpendRequest."No.");
        asserterror TravelRequestApproval.AssignAlternateApprover(SpendRequest, OtherExpenseUser."No.");

        // [THEN] The assignment is rejected.
        Assert.ExpectedError(AlternateApproverActorErr);
    end;

    [Test]
    procedure DelegationReportReturnsTravelRequestWhenCoverageEnds()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseAlternateApprover: Record "Expense Alternate Approver";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // [SCENARIO] The delegation report returns a travel request to its primary approver when the alternate coverage ends.
        Initialize();

        // [GIVEN] A travel request delegated to an alternate approver on submission.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        CreateAlternateApproverCoverage(Approver."No.", AlternateApprover."No.", WorkDate() - 5, 0D);
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [GIVEN] The alternate coverage ended yesterday.
        ExpenseAlternateApprover.Get(Approver."No.", AlternateApprover."No.", WorkDate() - 5);
        ExpenseAlternateApprover.Validate("Effective End Date", WorkDate() - 1);
        ExpenseAlternateApprover.Modify(true);

        // [WHEN] The delegation report runs for the travel request.
        RunDelegationReport(SpendRequest."No.");

        // [THEN] The travel request is assigned to the primary approver again and the return is logged.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(Approver."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
        SpendRequest.TestField("Alternate Approver No.", '');
        SpendRequest.TestField("Primary Approver No.", '');
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::AlternateApproverReverted, ExpenseActivityLogEntry), ActivityLoggedMsg);
    end;

    [Test]
    procedure DelegationReportAssignsAlternateApproverWhenCoverageStarts()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        AlternateApprover: Record "Expense User";
    begin
        // [SCENARIO] The delegation report delegates a submitted travel request when the alternate coverage starts.
        Initialize();

        // [GIVEN] A submitted travel request, followed by alternate coverage for its approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        CreateAlternateApproverCoverage(Approver."No.", AlternateApprover."No.", WorkDate(), 0D);

        // [WHEN] The delegation report runs for the travel request.
        RunDelegationReport(SpendRequest."No.");

        // [THEN] The alternate approver is assigned.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(AlternateApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
        Assert.AreEqual(Approver."No.", SpendRequest."Primary Approver No.", PrimaryApproverMsg);
    end;

    [Test]
    procedure ApproverFilterFollowsRoutedApprover()
    var
        SpendRequest: Record "Spend Request";
        FilteredTravelRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        LimitedApprover: Record "Expense User";
        UnlimitedApprover: Record "Expense User";
    begin
        // [SCENARIO] Pending travel requests are listed for the approver they are routed to, not for the approver from the approval setup.
        Initialize();

        // [GIVEN] A travel request escalated from approver "A" to approver "B".
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(LimitedApprover);
        SetApprovalLimit(LimitedApprover, 100);
        CreateApprover(UnlimitedApprover);
        SetApprover(TravelerExpenseUser."No.", LimitedApprover."No.");
        SetApprover(LimitedApprover."No.", UnlimitedApprover."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [WHEN] The approver filter of "B" is applied.
        FilterPendingTravelRequests(FilteredTravelRequest, UnlimitedApprover, SpendRequest."No.");

        // [THEN] "B" sees the travel request.
        Assert.IsFalse(FilteredTravelRequest.IsEmpty(), RoutedRequestVisibleMsg);

        // [WHEN] The approver filter of "A" is applied.
        FilterPendingTravelRequests(FilteredTravelRequest, LimitedApprover, SpendRequest."No.");

        // [THEN] "A" does not see the travel request.
        Assert.IsTrue(FilteredTravelRequest.IsEmpty(), RoutedRequestHiddenMsg);
    end;

    [Test]
    procedure RecallTravelRequestPageAction()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] The owner recalls a submitted travel request, which reopens it and clears its approver.
        Initialize();

        // [GIVEN] A submitted travel request.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestsAPI.SetRecord(SpendRequest);

        // [WHEN] The owner recalls it through the page procedure.
        TravelRequestsAPI.RecallTravelRequest(ActionContext, TravelerExpenseUser."No.");

        // [THEN] The travel request is open without an approver, and the recall is logged for the owner.
        Assert.AreEqual(Format(WebServiceActionResultCode::Updated), Format(ActionContext.GetResultCode()), ActionResultMsg);
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Open);
        SpendRequest.TestField("Approver Expense User No.", '');
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::Recalled, ExpenseActivityLogEntry), ActivityLoggedMsg);
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Submitter, ExpenseActivityLogEntry."Actor Role", ActorRoleMsg);
        Assert.AreEqual(TravelerExpenseUser.SystemId, ExpenseActivityLogEntry."Actor Record System ID", ActorMsg);
    end;

    [Test]
    procedure RecallTravelRequestRejectsOtherExpenseUser()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
    begin
        // [SCENARIO] Only the owner can recall a submitted travel request through the agent.
        Initialize();

        // [GIVEN] A submitted travel request and another expense user.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);

        // [WHEN] The other expense user recalls the travel request.
        SpendRequest.Get(SpendRequest."No.");
        asserterror TravelRequestApproval.Recall(SpendRequest, OtherExpenseUser."No.");

        // [THEN] The recall is rejected.
        Assert.ExpectedError(NotTravelRequestOwnerRecallErr);
    end;

    [Test]
    procedure ReopenApprovedTravelRequestRoutesAgain()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // [SCENARIO] An approver reopens an approved travel request, which starts a new approval.
        Initialize();

        // [GIVEN] An approved travel request.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        TravelRequestApproval.Approve(SpendRequest, Approver."No.");

        // [WHEN] The approver reopens the approved travel request.
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestApproval.ReopenApproved(SpendRequest, Approver."No.");

        // [THEN] The travel request waits for approval again, without the previous decision.
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Released);
        SpendRequest.TestField("Approval Expense User No.", '');
        Assert.AreEqual(Approver."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::ReopenedByApprover, ExpenseActivityLogEntry), ActivityLoggedMsg);
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Approver, ExpenseActivityLogEntry."Actor Role", ActorRoleMsg);
        Assert.AreEqual(Approver.SystemId, ExpenseActivityLogEntry."Actor Record System ID", ActorMsg);
    end;

    [Test]
    procedure RemoveApprovalRightsFailsForPendingTravelApprover()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
    begin
        // [SCENARIO] Approval rights cannot be removed from the approver of a pending travel request.
        Initialize();

        // [GIVEN] A travel request submitted to an approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [WHEN] Approval rights are removed from the approver.
        Approver.Get(Approver."No.");
        asserterror Approver.Validate("Can Approve", false);

        // [THEN] The change is rejected while the travel request is pending.
        Assert.ExpectedError(PendingTravelApproverErr);
    end;

    [Test]
    procedure RejectLogsReopeningAfterRejection()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        RejectedActivity: Record "Expense Activity Log Entry";
        ReopenedActivity: Record "Expense Activity Log Entry";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 641538] Rejecting a travel request reopens it and logs rejection before reopening for the same approver.
        Initialize();

        // [GIVEN] A submitted travel request assigned to an approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [WHEN] The assigned approver rejects the travel request.
        TravelRequestApproval.Reject(SpendRequest, Approver."No.", 'Missing travel details.');

        // [THEN] The request is open, retaining the rejection decision but clearing approval routing.
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Open);
        SpendRequest.TestField("Approval Expense User No.", Approver."No.");
        SpendRequest.TestField("Rejection Reason", 'Missing travel details.');
        SpendRequest.TestField("Approver Expense User No.", '');
        SpendRequest.TestField("Alternate Approver No.", '');
        SpendRequest.TestField("Primary Approver No.", '');

        // [THEN] Exactly one rejection precedes exactly one reopening, both attributed to the rejecting approver.
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::Rejected, RejectedActivity), ActivityLoggedMsg);
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::ReopenedByApprover, ReopenedActivity), ActivityLoggedMsg);
        Assert.IsTrue(RejectedActivity."Entry No." < ReopenedActivity."Entry No.", 'Rejection must be logged before reopening.');
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Approver, RejectedActivity."Actor Role", ActorRoleMsg);
        Assert.AreEqual(Enum::"Expense Activity Actor Role"::Approver, ReopenedActivity."Actor Role", ActorRoleMsg);
        Assert.AreEqual(Approver.SystemId, RejectedActivity."Actor Record System ID", ActorMsg);
        Assert.AreEqual(Approver.SystemId, ReopenedActivity."Actor Record System ID", ActorMsg);
        RejectedActivity.TestField(Comment, 'Missing travel details.');
        ReopenedActivity.TestField(Comment, '');
    end;

    [Test]
    procedure RejectByUnassignedApproverDoesNotLogReopening()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        OtherApprover: Record "Expense User";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 641538] An unassigned approver cannot reject a travel request or create rejection and reopening history.
        Initialize();

        // [GIVEN] A submitted travel request and another approver who is not assigned to it.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(OtherApprover);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");

        // [WHEN] The unassigned approver attempts to reject the request.
        Commit();
        asserterror TravelRequestApproval.Reject(SpendRequest, OtherApprover."No.", 'Unauthorized rejection.');

        // [THEN] Authorization fails and the request remains pending with its original approver.
        Assert.ExpectedError(NotTravelRequestApproverErr);
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Released);
        SpendRequest.TestField("Approver Expense User No.", Approver."No.");
        SpendRequest.TestField("Approval Expense User No.", '');
        SpendRequest.TestField("Rejection Reason", '');

        // [THEN] Neither rejection nor reopening is logged.
        Assert.AreEqual(0, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::Rejected, ExpenseActivityLogEntry), 'Unauthorized rejection must not be logged.');
        Assert.AreEqual(0, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::ReopenedByApprover, ExpenseActivityLogEntry), 'Unauthorized rejection must not log reopening.');
    end;

    [Test]
    procedure ResubmitRejectedRequestPreservesReopeningHistory()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        ReopenedActivity: Record "Expense Activity Log Entry";
        ResubmittedActivity: Record "Expense Activity Log Entry";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 641538] Resubmission clears the rejection decision while preserving the previous reopening history.
        Initialize();

        // [GIVEN] A submitted travel request rejected and reopened by its approver.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        TravelRequestApproval.Reject(SpendRequest, Approver."No.", 'Missing travel details.');

        // [WHEN] The owner resubmits the request with a justification.
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.", 'Travel details supplied.');

        // [THEN] The request is routed again without the previous rejection decision.
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Released);
        SpendRequest.TestField("Approver Expense User No.", Approver."No.");
        SpendRequest.TestField("Approval Expense User No.", '');
        SpendRequest.TestField("Rejection Reason", '');
        SpendRequest.TestField("Approved/Rejected At", 0DT);
        SpendRequest.TestField("Submitter Comment", 'Travel details supplied.');

        // [THEN] The original reopening remains before the resubmission without a duplicate reopening.
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::ReopenedByApprover, ReopenedActivity), ActivityLoggedMsg);
        Assert.AreEqual(1, FindTravelRequestActivity(SpendRequest, Enum::"Expense Activity Event Type"::Resubmitted, ResubmittedActivity), ActivityLoggedMsg);
        Assert.IsTrue(ReopenedActivity."Entry No." < ResubmittedActivity."Entry No.", 'Reopening must remain before resubmission.');
        Assert.AreEqual(Approver.SystemId, ReopenedActivity."Actor Record System ID", ActorMsg);
        Assert.AreEqual(TravelerExpenseUser.SystemId, ResubmittedActivity."Actor Record System ID", ActorMsg);
        ResubmittedActivity.TestField(Comment, 'Travel details supplied.');
    end;

    [Test]
    procedure AlternateApprovalSkipsApprovalLimit()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        Approver: Record "Expense User";
        LimitedAlternateApprover: Record "Expense User";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 641538] An alternate approver approves a delegated travel request without an approval limit check.
        Initialize();

        // [GIVEN] A travel request of 500 with unlimited approver "A" and alternate approver "C" limited to 100.
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(Approver);
        CreateApprover(LimitedAlternateApprover);
        SetApprovalLimit(LimitedAlternateApprover, 100);
        SetApprover(TravelerExpenseUser."No.", Approver."No.");
        CreateAlternateApproverCoverage(Approver."No.", LimitedAlternateApprover."No.", WorkDate(), 0D);

        // [GIVEN] The owner submits the travel request, which is delegated to "C".
        TravelRequestApproval.Submit(SpendRequest, TravelerExpenseUser."No.");
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(LimitedAlternateApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);

        // [WHEN] "C" approves the travel request.
        TravelRequestApproval.Approve(SpendRequest, LimitedAlternateApprover."No.");

        // [THEN] The travel request is approved, although it exceeds the approval limit of "C".
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Approved);
        SpendRequest.TestField("Approval Expense User No.", LimitedAlternateApprover."No.");
    end;

    [Test]
    procedure DelegationRoutesUnroutedTravelRequestByApprovalLimit()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        LimitedApprover: Record "Expense User";
        UnlimitedApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 641538] Delegating a travel request released in the client first escalates it to a primary approver who covers the amount.
        Initialize();

        // [GIVEN] A travel request of 500 released in the client, with approver "A" limited to 100, escalation to "B", and alternate approver "C" for "B".
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(LimitedApprover);
        SetApprovalLimit(LimitedApprover, 100);
        CreateApprover(UnlimitedApprover);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", LimitedApprover."No.");
        SetApprover(LimitedApprover."No.", UnlimitedApprover."No.");
        ReleaseSpendRequest.Release(SpendRequest);
        CreateAlternateApproverCoverage(UnlimitedApprover."No.", AlternateApprover."No.", WorkDate(), 0D);

        // [WHEN] The owner assigns the alternate approver.
        SpendRequest.Get(SpendRequest."No.");
        TravelRequestApproval.AssignAlternateApprover(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The travel request is escalated to "B" and delegated to "C".
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(UnlimitedApprover."No.", SpendRequest."Primary Approver No.", PrimaryApproverMsg);
        Assert.AreEqual(AlternateApprover."No.", SpendRequest."Alternate Approver No.", AlternateApproverMsg);
        Assert.AreEqual(AlternateApprover."No.", SpendRequest."Approver Expense User No.", ApproverAssignedMsg);

        // [THEN] "C" approves the travel request.
        TravelRequestApproval.Approve(SpendRequest, AlternateApprover."No.");
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Approved);
    end;

    [Test]
    procedure DelegationFailsWhenNoApproverCoversUnroutedTravelRequest()
    var
        SpendRequest: Record "Spend Request";
        TravelerExpenseUser: Record "Expense User";
        LimitedApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 641538] A travel request released in the client cannot be delegated when no primary approver covers the amount.
        Initialize();

        // [GIVEN] A travel request of 500 released in the client, with approver "A" limited to 100, no escalation, and alternate approver "C" for "A".
        CreateTravelRequest(SpendRequest, TravelerExpenseUser, 500);
        CreateApprover(LimitedApprover);
        SetApprovalLimit(LimitedApprover, 100);
        CreateApprover(AlternateApprover);
        SetApprover(TravelerExpenseUser."No.", LimitedApprover."No.");
        ReleaseSpendRequest.Release(SpendRequest);
        CreateAlternateApproverCoverage(LimitedApprover."No.", AlternateApprover."No.", WorkDate(), 0D);

        // [WHEN] The owner assigns the alternate approver.
        SpendRequest.Get(SpendRequest."No.");
        Commit();
        asserterror TravelRequestApproval.AssignAlternateApprover(SpendRequest, TravelerExpenseUser."No.");

        // [THEN] The delegation fails and asks for an approver in the approval setup.
        Assert.ExpectedError(ApproverRequiredErr);

        // [THEN] The travel request stays unrouted and is not delegated to "C".
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField("Approver Expense User No.", '');
        SpendRequest.TestField("Alternate Approver No.", '');
    end;

    local procedure Initialize()
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        ExpenseAlternateApprover: Record "Expense Alternate Approver";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Travel Request Approval Test");
        LibrarySetupStorage.Restore();
        // Clear approval mappings and alternate coverage together with the expense users between tests.
        ExpenseApprovalSetup.DeleteAll();
        ExpenseAlternateApprover.DeleteAll();
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify();

        // With the agent enabled, a released travel request waits for an approver instead of being approved automatically.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        ClearDefaultApprover();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Travel Request Approval Test");
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibrarySetupStorage.Save(Database::"Human Resources Setup");
        LibrarySetupStorage.Save(Database::"Source Code Setup");
        LibrarySetupStorage.Save(Database::"Expense Agent Setup");
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Travel Request Approval Test");
    end;

    local procedure CreateTravelRequest(var SpendRequest: Record "Spend Request"; var TravelerExpenseUser: Record "Expense User"; ExpectedAmount: Decimal)
    begin
        LibraryExpense.CreateExpenseUser(TravelerExpenseUser);
        LibraryExpense.CreateSpendRequest(SpendRequest);
        SpendRequest.Validate("Requested By", TravelerExpenseUser."Employee No.");
        SpendRequest.Validate("Requested For", TravelerExpenseUser."No.");
        SpendRequest.Validate("Expected Start Date", WorkDate());
        SpendRequest.Validate("Expected End Date", WorkDate() + 7);
        SpendRequest.Validate("Travel Policy Acknowledgment", true);
        SpendRequest.Modify(true);
        LibraryExpense.CreateSpendRequestDetail(SpendRequest."No.", ExpectedAmount);
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.TestField("Total Expected Amount (LCY)", ExpectedAmount);
    end;

    local procedure CreateApprover(var Approver: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(Approver);
        MakeApprover(Approver);
    end;

    local procedure MakeApprover(var ExpenseUser: Record "Expense User")
    begin
        // Enabling approval in the client also grants unlimited approval.
        ExpenseUser."Can Approve" := true;
        ExpenseUser."Unlimited Approval" := true;
        ExpenseUser."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(ExpenseUser."User Id For Approvals"));
        ExpenseUser.Modify(true);
    end;

    local procedure SetApprovalLimit(var Approver: Record "Expense User"; ApprovalLimit: Integer)
    begin
        Approver.Get(Approver."No.");
        Approver.Validate("Unlimited Approval", false);
        Approver.Validate("Approval Limit (LCY)", ApprovalLimit);
        Approver.Modify(true);
    end;

    local procedure SetApprover(ExpenseUserNo: Code[20]; ApproverNo: Code[20])
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        if ExpenseApprovalSetup.Get(ExpenseUserNo) then begin
            ExpenseApprovalSetup.Validate("Approver No.", ApproverNo);
            ExpenseApprovalSetup.Modify(true);
        end else
            LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUserNo, ApproverNo);
    end;

    local procedure ClearDefaultApprover()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Default Approver No.", '');
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure CreateAlternateApproverCoverage(PrimaryApproverNo: Code[20]; AlternateApproverNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        ExpenseAlternateApprover: Record "Expense Alternate Approver";
    begin
        ExpenseAlternateApprover.Init();
        ExpenseAlternateApprover.Validate("Primary Approver No.", PrimaryApproverNo);
        ExpenseAlternateApprover.Validate("Alternate Approver No.", AlternateApproverNo);
        ExpenseAlternateApprover.Validate("Effective Start Date", StartDate);
        ExpenseAlternateApprover.Validate("Effective End Date", EndDate);
        ExpenseAlternateApprover.Insert(true);
    end;

    local procedure RunDelegationReport(TravelRequestNo: Code[20])
    var
        ReportFilter: Record "Spend Request";
        DelegateTravelApprovalReq: Report "Delegate Travel Approval Req";
    begin
        ReportFilter.SetRange("No.", TravelRequestNo);
        DelegateTravelApprovalReq.SetTableView(ReportFilter);
        DelegateTravelApprovalReq.UseRequestPage(false);
        DelegateTravelApprovalReq.RunModal();
    end;

    local procedure FilterPendingTravelRequests(var FilteredTravelRequest: Record "Spend Request"; Approver: Record "Expense User"; TravelRequestNo: Code[20])
    begin
        FilteredTravelRequest.Reset();
        FilteredTravelRequest.SetRange("Document Type", FilteredTravelRequest."Document Type"::"Travel Request");
        FilteredTravelRequest.SetRange(Status, FilteredTravelRequest.Status::Released);
        TravelRequestApproval.ApplyApproverFilter(FilteredTravelRequest, Approver.SystemId);
        FilteredTravelRequest.SetRange("No.", TravelRequestNo);
    end;

    local procedure FindTravelRequestActivity(SpendRequest: Record "Spend Request"; EventType: Enum "Expense Activity Event Type"; var FoundExpenseActivityLogEntry: Record "Expense Activity Log Entry") EntryCount: Integer
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Spend Request");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", SpendRequest.SystemId);
        ExpenseActivityLogEntry.SetRange("Event Type", EventType);
        EntryCount := ExpenseActivityLogEntry.Count();
        if ExpenseActivityLogEntry.FindLast() then
            FoundExpenseActivityLogEntry := ExpenseActivityLogEntry;
    end;
}
