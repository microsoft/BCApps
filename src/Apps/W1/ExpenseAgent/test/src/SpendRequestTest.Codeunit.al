// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SpendRequest;
using Microsoft.HumanResources.Employee;

codeunit 148339 "Spend Request Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        CloseConfirmReply: Boolean;
        CloseConfirmCount: Integer;
        SpendReqPreviewShown: Boolean;
        NotTravelerErr: Label 'is not a traveler on Travel Request', Locked = true;
        PolicyErr: Label 'acknowledge the travel policy', Locked = true;
        NoTravelersErr: Label 'add at least one traveler', Locked = true;
        FieldRequiredErr: Label 'You must specify', Locked = true;
        StatusNotOpenErr: Label 'must have the status', Locked = true;
        DestinationErr: Label 'is required for international travel', Locked = true;
        CloseConfirmTok: Label 'want to close', Locked = true;
        ClosePromptOnceMsg: Label 'The close spend request confirmation should be shown exactly once.';
        SpendReqClosedMsg: Label 'The spend request should be closed after posting.';
        SpendReqNotClosedMsg: Label 'The spend request should not be closed when the confirmation is declined.';
        HeaderSpendReqRemainsApprovedMsg: Label 'The header spend request should remain approved when a line overrides it.';
        ClosedByDocMsg: Label 'Closed By Document No. should be set on the closed spend request.';
        SpendReqReleasedMsg: Label 'The spend request should be Released.';
        SpendReqApprovedMsg: Label 'The spend request should be approved automatically when the agent is disabled.';
        ExpenseReportCreatedMsg: Label 'One expense report should be created for the approved travel request.';
        ExpenseReportUserMsg: Label 'The expense report should be created for the requested expense user.';
        ExpenseReportDescriptionMsg: Label 'The expense report description should match the travel request purpose.';
        TravelRequestSystemIdMsg: Label 'The expense report should reference the travel request by SystemId.';
        TravelRequestActionResultMsg: Label 'The travel request page action should return an updated result.';
        TravelRequestRejectedMsg: Label 'The travel request should be rejected through the page action.';
        TravelRequestRejectionUserMsg: Label 'The rejecting user should be recorded.';
        TravelRequestRejectionExpenseUserMsg: Label 'The rejecting expense user should be recorded.';
        TravelRequestRejectionReasonMsg: Label 'The rejection reason should be recorded.';
        TravelRequestRejectionDateMsg: Label 'The page action rejection date and time should be recorded.';
        AssignedTravelRequestVisibleMsg: Label 'The assigned approver should see the travel request.';
        UnassignedTravelRequestHiddenMsg: Label 'The approver should not see a travel request assigned to another approver.';
        DefaultTravelRequestVisibleMsg: Label 'The default approver should see travel requests without an assigned approver.';
        ApproverWithoutRequestsMsg: Label 'An approver without assigned travel requests should receive an empty result.';
        SpendReqNoSetMsg: Label 'The Spend Request No. should be assigned to the expense report line.';
        HeaderSpendReqNoSetMsg: Label 'The Spend Request No. should be assigned to the expense report header.';
        HeaderCloseFlagMsg: Label 'The header should store the confirmed close flag.';
        SpendReqSpentAmountMsg: Label 'The spend request Total Spent Amount (LCY) should reflect the posted amount.';
        SpendReqLinkExistsMsg: Label 'A Spend Request To G/L Link entry should be created when the expense report is posted.';
        SpendReqClearedMsg: Label 'The Spend Request No. should be cleared when the line becomes non-refundable.';
        SpendReqCloseClearedMsg: Label 'The Spend Request Close flag should be cleared when the line becomes non-refundable.';
        SpendReqLinkPreviewMsg: Label 'The Spend Request To G/L Link entries should be shown in the expense report posting preview.';
        BlankSpendReqReleasedMsg: Label 'A blank spend request should release without the travel prerequisites and without agent auto-approval.';
        CategoryStoredMsg: Label 'The expense category should be stored on the Category line.';
        CategoryClearedMsg: Label 'The expense category should be cleared when the line is not a Category line.';
        MixedTypesMsg: Label 'Category and Lump Sum lines should coexist on the same travel request.';
        CategoryLineOnlyErr: Label 'You can select an %1 only when %2 is %3.', Locked = true;
        AutomaticApprovalNotAllowedErr: Label 'Automatic travel request approval can be used only when the Expense Agent is disabled.', Locked = true;
        NotTravelRequestOwnerErr: Label 'did not create it', Locked = true;
        TravelRequestMustBeApprovedErr: Label 'Travel request %1 must be approved before an expense report can be created.', Comment = '%1 = Travel Request No.', Locked = true;
        ExpenseReportAlreadyLinkedErr: Label 'Expense user %1 already has expense report %2 linked to travel request %3.', Comment = '%1 = Expense User No., %2 = Expense Report No., %3 = Travel Request No.', Locked = true;
        PostedReportAlreadyLinkedErr: Label 'Expense user %1 already has posted expense report %2 linked to travel request %3.', Comment = '%1 = Expense User No., %2 = Posted Expense Report No., %3 = Travel Request No.', Locked = true;
        OwnerScopeRequiredErr: Label 'The create expense report action must be invoked through the owning expense user.', Locked = true;
        NotTravelRequestApproverErr: Label 'is not authorized', Locked = true;
        LinkedExpenseReportExistsErr: Label 'because it is linked to an expense report.', Locked = true;
        InvalidTravelRequestDatesErr: Label 'Expected End Date cannot be before Expected Start Date.', Locked = true;
        EmployeeNotLinkedErr: Label 'No expense user is linked to employee %1.', Comment = '%1 = Employee No.', Locked = true;
        DuplicateTravelerMappingErr: Label 'is already on this travel request', Locked = true;

    [Test]
    procedure EmployeeExpenseUserFilterIncludesOnlyLinkedEmployees()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        UnlinkedEmployee: Record Employee;
        LibraryHumanResource: Codeunit "Library - Human Resource";
    begin
        // [SCENARIO] The API source field filters both linked and unlinked employees without HTTP.
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryHumanResource.CreateEmployee(UnlinkedEmployee);

        Employee.SetRange("Is Expense User", true);
        Employee.SetRange("No.", ExpenseUser."Employee No.");
        Assert.RecordIsNotEmpty(Employee);
        Employee.SetRange("No.", UnlinkedEmployee."No.");
        Assert.RecordIsEmpty(Employee);

        Employee.SetRange("Is Expense User", false);
        Assert.RecordIsNotEmpty(Employee);
        Employee.SetRange("No.", ExpenseUser."Employee No.");
        Assert.RecordIsEmpty(Employee);
    end;

    [Test]
    procedure TravelerEmployeeNumberMapsToExpenseUser()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
    begin
        // [SCENARIO] The same validation used by the API stores an Expense User and reads back an employee.
        Initialize();
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Assert.AreNotEqual(ExpenseUser."No.", ExpenseUser."Employee No.", 'The fixture must distinguish employee and Expense User identifiers.');
        Traveler.Validate("Spend Request No.", SpendRequest."No.");
        Traveler."Line No." := 10000;

        Traveler.ValidateEmployeeNo(ExpenseUser."Employee No.");
        Traveler.Insert(true);

        Traveler.Get(SpendRequest."No.", 10000);
        Traveler.TestField("Expense User No.", ExpenseUser."No.");
        Traveler.CalcFields("Employee No.");
        Traveler.TestField("Employee No.", ExpenseUser."Employee No.");
    end;

    [Test]
    procedure TravelerEmployeeNumberRejectsUnlinkedEmployee()
    var
        SpendRequest: Record "Spend Request";
        Employee: Record Employee;
        Traveler: Record Traveler;
        LibraryHumanResource: Codeunit "Library - Human Resource";
    begin
        // [SCENARIO] An employee without an Expense User cannot be added as a traveler.
        Initialize();
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryHumanResource.CreateEmployee(Employee);
        Traveler.Validate("Spend Request No.", SpendRequest."No.");
        Traveler."Line No." := 10000;

        asserterror Traveler.ValidateEmployeeNo(Employee."No.");

        Assert.ExpectedError(StrSubstNo(EmployeeNotLinkedErr, Employee."No."));
        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordIsEmpty(Traveler);
    end;

    [Test]
    procedure TravelerEmployeeNumberRejectsBlank()
    var
        SpendRequest: Record "Spend Request";
        UnlinkedExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
    begin
        // [SCENARIO] A blank employee number must not resolve to an unlinked Expense User.
        Initialize();
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateExpenseUser(UnlinkedExpenseUser);
        UnlinkedExpenseUser.Validate("Employee No.", '');
        UnlinkedExpenseUser.Modify(true);
        Traveler.Validate("Spend Request No.", SpendRequest."No.");
        Traveler."Line No." := 10000;

        asserterror Traveler.ValidateEmployeeNo('');

        Assert.ExpectedError(StrSubstNo(EmployeeNotLinkedErr, ''));
        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordIsEmpty(Traveler);
    end;

    [Test]
    procedure TravelerEmployeeNumberPreservesValidationRules()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
    begin
        // [SCENARIO] Employee-based writes retain the duplicate-traveler and open-status guards.
        Initialize();
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        Traveler.Validate("Spend Request No.", SpendRequest."No.");
        Traveler."Line No." := 20000;

        asserterror Traveler.ValidateEmployeeNo(ExpenseUser."Employee No.");
        Assert.ExpectedError(DuplicateTravelerMappingErr);

        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);
        asserterror Traveler.ValidateEmployeeNo(ExpenseUser."Employee No.");
        Assert.ExpectedError(StatusNotOpenErr);

        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordCount(Traveler, 1);
    end;

    [Test]
    procedure TravelRequestEmployeeQueryReturnsOnlyItsTravelers()
    var
        SpendRequest: Record "Spend Request";
        OtherSpendRequest: Record "Spend Request";
        EmptySpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        AdditionalExpenseUser: Record "Expense User";
        TravelRequestEmployees: Query "Travel Request Employees";
        ExpectedEmployees: List of [Code[20]];
    begin
        // [SCENARIO] Employee navigation uses the request SystemId and excludes other requests' travelers.
        Initialize();
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        CreateReleasableSpendRequest(OtherSpendRequest, OtherExpenseUser);
        LibraryExpense.CreateExpenseUser(AdditionalExpenseUser);
        LibraryExpense.CreateTraveler(SpendRequest."No.", AdditionalExpenseUser."No.");
        LibraryExpense.CreateSpendRequest(EmptySpendRequest);
        ExpectedEmployees.Add(ExpenseUser."Employee No.");
        ExpectedEmployees.Add(AdditionalExpenseUser."Employee No.");

        TravelRequestEmployees.SetRange(travelRequestSystemId, SpendRequest.SystemId);
        TravelRequestEmployees.Open();
        while TravelRequestEmployees.Read() do
            Assert.IsTrue(ExpectedEmployees.Remove(TravelRequestEmployees.employeeNo), 'Navigation must return each expected employee once and no unrelated employees.');
        TravelRequestEmployees.Close();
        Assert.AreEqual(0, ExpectedEmployees.Count(), 'Both travelers must be included in employee navigation.');

        TravelRequestEmployees.SetRange(travelRequestSystemId, OtherSpendRequest.SystemId);
        TravelRequestEmployees.Open();
        Assert.IsTrue(TravelRequestEmployees.Read(), 'The other request must return its traveler.');
        Assert.AreEqual(OtherExpenseUser."Employee No.", TravelRequestEmployees.employeeNo, 'Navigation must use the selected request SystemId.');
        Assert.IsFalse(TravelRequestEmployees.Read(), 'The other request must not return the first request''s travelers.');
        TravelRequestEmployees.Close();

        TravelRequestEmployees.SetRange(travelRequestSystemId, EmptySpendRequest.SystemId);
        TravelRequestEmployees.Open();
        Assert.IsFalse(TravelRequestEmployees.Read(), 'A request without travelers must not return all employees.');
        TravelRequestEmployees.Close();
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure ValidateSpendReqNoSucceedsWhenApproved()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO 616928] An approved spend request can be selected on a refundable line when the user is a traveler.
        Initialize();

        // [GIVEN] A refundable expense report line for an expense user.
        CreateExpenseReportWithRefundableLine(ExpenseReportLine, ExpenseUser, true);

        // [GIVEN] An approved spend request with the user as a traveler.
        CreateSpendRequestWithTraveler(SpendRequest, ExpenseUser."No.", SpendRequest.Status::Approved);

        // [WHEN] The spend request is selected on the line.
        ExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");
        ExpenseReportLine.Modify(true);

        // [THEN] The spend request is assigned to the line.
        Assert.AreEqual(SpendRequest."No.", ExpenseReportLine."Spend Request No.", SpendReqNoSetMsg);
    end;

    [Test]
    procedure ValidateSpendReqNoFailsWhenNotRefundable()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO 616928] A spend request cannot be selected on a non-refundable line.
        Initialize();

        // [GIVEN] A non-refundable expense report line for an expense user.
        CreateExpenseReportWithRefundableLine(ExpenseReportLine, ExpenseUser, false);

        // [GIVEN] An approved spend request with the user as a traveler.
        CreateSpendRequestWithTraveler(SpendRequest, ExpenseUser."No.", SpendRequest.Status::Approved);

        // [WHEN] The spend request is selected on the non-refundable line.
        asserterror ExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");

        // [THEN] Validation fails because the line must be refundable.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure ValidateSpendReqNoFailsWhenNotTraveler()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO 616928] A spend request cannot be selected when the line's expense user is not a traveler.
        Initialize();

        // [GIVEN] A refundable expense report line for an expense user.
        CreateExpenseReportWithRefundableLine(ExpenseReportLine, ExpenseUser, true);

        // [GIVEN] An approved spend request WITHOUT the user as a traveler.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateSpendRequestDetail(SpendRequest."No.", LibraryRandom.RandIntInRange(100000, 100000));
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);

        // [WHEN] The spend request is selected on the line.
        asserterror ExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");

        // [THEN] Validation fails because the user is not a traveler.
        Assert.ExpectedError(NotTravelerErr);
    end;

    [Test]
    procedure ValidateSpendReqNoFailsWhenNotApproved()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO 616928] A spend request that is not Approved cannot be selected on a line.
        Initialize();

        // [GIVEN] A refundable expense report line for an expense user.
        CreateExpenseReportWithRefundableLine(ExpenseReportLine, ExpenseUser, true);

        // [GIVEN] A Release (not approved) spend request with the user as a traveler.
        CreateSpendRequestWithTraveler(SpendRequest, ExpenseUser."No.", SpendRequest.Status::Released);

        // [WHEN] The spend request is selected on the line.
        asserterror ExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");

        // [THEN] Validation fails because only approved spend requests are selectable.
        Assert.ExpectedErrorCode('DB:NothingInsideFilter');
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure SetRefundableFalseClearsLinkedSpendReq()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO 616928] Making a line non-refundable clears its linked spend request.
        Initialize();

        // [GIVEN] A refundable expense report line for an expense user.
        CreateExpenseReportWithRefundableLine(ExpenseReportLine, ExpenseUser, true);

        // [GIVEN] An approved spend request with the user as a traveler.
        CreateSpendRequestWithTraveler(SpendRequest, ExpenseUser."No.", SpendRequest.Status::Approved);

        // [GIVEN] The spend request is linked to the line.
        ExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");
        ExpenseReportLine.Modify(true);

        // [WHEN] The line is set to non-refundable.
        ExpenseReportLine.Validate(Refundable, false);

        // [THEN] The spend request link is cleared from the line.
        Assert.AreEqual('', ExpenseReportLine."Spend Request No.", SpendReqClearedMsg);
        Assert.IsFalse(ExpenseReportLine."Spend Request Close", SpendReqCloseClearedMsg);
    end;

    [Test]
    procedure ReleaseSpendReqFailsMissingRequestedFor()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] Releasing an expense spend request without "Requested For" fails.
        Initialize();

        // [GIVEN] An expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] An open spend request with valid dates and the travel policy acknowledged, but no Requested For.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        SpendRequest.Validate("Expected Start Date", WorkDate());
        SpendRequest.Validate("Expected End Date", WorkDate() + 7);
        SpendRequest.Validate("Travel Policy Acknowledgment", true);
        SpendRequest.Modify(true);

        // [WHEN] The spend request is Released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because Requested For is required.
        Assert.ExpectedError(FieldRequiredErr);
    end;

    [Test]
    procedure ReleaseSpendReqFailsMissingExpectedStartDate()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] Releasing an expense spend request without "Expected Start Date" fails.
        Initialize();

        // [GIVEN] A releasable spend request.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [GIVEN] Its expected start date is cleared.
        SpendRequest."Expected Start Date" := 0D;
        SpendRequest.Modify();

        // [WHEN] The spend request is Released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because Expected Start Date is required.
        Assert.ExpectedError(FieldRequiredErr);
    end;

    [Test]
    procedure ReleaseSpendReqFailsMissingExpectedEndDate()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] Releasing an expense spend request without "Expected End Date" fails.
        Initialize();

        // [GIVEN] A releasable spend request.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [GIVEN] Its expected end date is cleared.
        SpendRequest."Expected End Date" := 0D;
        SpendRequest.Modify();

        // [WHEN] The spend request is Released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because Expected End Date is required.
        Assert.ExpectedError(FieldRequiredErr);
    end;

    [Test]
    procedure ReleaseSpendReqFailsPolicyNotAcknowledged()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] Releasing an expense spend request without acknowledging the travel policy fails.
        Initialize();

        // [GIVEN] A releasable spend request.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [GIVEN] The travel policy acknowledgment is cleared.
        SpendRequest.Validate("Travel Policy Acknowledgment", false);
        SpendRequest.Modify(true);

        // [WHEN] The spend request is Released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because the travel policy must be acknowledged.
        Assert.ExpectedError(PolicyErr);
    end;

    [Test]
    procedure ReleaseSpendReqFailsIntlNoDestination()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] Releasing an international expense spend request without a destination country fails.
        Initialize();

        // [GIVEN] A releasable spend request.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [GIVEN] It is flagged as international travel with no destination country.
        SpendRequest.Validate("International Travel", true);
        SpendRequest.Modify(true);

        // [WHEN] The spend request is Released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because a destination country is required for international travel.
        Assert.ExpectedError(DestinationErr);
    end;

    [Test]
    procedure ReleaseSpendReqFailsNoTravelers()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] Releasing an expense spend request without any travelers fails.
        Initialize();

        // [GIVEN] A releasable spend request.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [GIVEN] Its travelers are removed.
        DeleteTravelers(SpendRequest."No.");

        // [WHEN] The spend request is Released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because at least one traveler is required.
        Assert.ExpectedError(NoTravelersErr);
    end;

    [Test]
    procedure ReleaseSpendReqAutoApprovesWhenAgentDisabled()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] With the agent disabled, releasing an expense spend request that meets all prerequisites approves it automatically.
        Initialize();

        // [GIVEN] A releasable spend request with every prerequisite satisfied.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [WHEN] The spend request is Released.
        ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] The spend request is approved automatically because there is no agent to approve it.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Approved, SpendRequest.Status, SpendReqApprovedMsg);

        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.AreEqual(1, ExpenseReportHeader.Count(), ExpenseReportCreatedMsg);
        ExpenseReportHeader.FindFirst();
        Assert.AreEqual(ExpenseUser."No.", ExpenseReportHeader."Expense User No.", ExpenseReportUserMsg);
    end;

    [Test]
    procedure ReleaseSpendReqStaysReleasedWhenAgentEnabled()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] With the agent enabled, releasing an expense spend request leaves it Released for the agent to approve.
        Initialize();
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        // [GIVEN] A releasable spend request with every prerequisite satisfied.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [WHEN] The spend request is Released.
        ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] The spend request stays Released.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Released, SpendRequest.Status, SpendReqReleasedMsg);
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordIsEmpty(ExpenseReportHeader);
    end;

    [Test]
    procedure DeleteTravelRequestWithReportIsBlocked()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        Traveler: Record Traveler;
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO] A travel request cannot be deleted while an expense report references it.
        Initialize();

        // [GIVEN] An automatically approved travel request with a detail, traveler, and linked report.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", 0);
        ReleaseSpendRequest.Release(SpendRequest);
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.FindFirst();

        // [WHEN] The request is deleted.
        asserterror SpendRequest.Delete(true);

        // [THEN] The request, report, details, and travelers remain intact.
        Assert.ExpectedError(LinkedExpenseReportExistsErr);
        Assert.ExpectedError(SpendRequest."No.");
        Assert.IsTrue(SpendRequest.Get(SpendRequest."No."), 'The linked travel request must not be deleted.');
        Assert.RecordIsNotEmpty(ExpenseReportHeader);
        Assert.IsTrue(SpendRequestDetail.Get(SpendRequest."No.", SpendRequestDetail."Line No."), 'The request detail must remain.');
        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordIsNotEmpty(Traveler);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure DeleteTravelRequestWithPostedReportIsBlocked()
    var
        SpendRequest: Record "Spend Request";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        // [SCENARIO] Posted report references prevent deletion even when the net spent amount is zero.
        Initialize();

        // [GIVEN] A normally posted report with offsetting amounts and a header-level request link.
        CreatePostedTravelRequestReport(SpendRequest, PostedExpenseReportHeader, true);
        PostedExpenseReportHeader.TestField("Spend Request No.", SpendRequest."No.");

        // [WHEN] The request is deleted.
        asserterror SpendRequest.Delete(true);

        // [THEN] Both the request and posted history remain intact.
        Assert.ExpectedError(LinkedExpenseReportExistsErr);
        Assert.IsTrue(SpendRequest.Get(SpendRequest."No."), 'A request referenced by posted history must remain.');
        Assert.IsTrue(PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No."), 'Posted history must never be cascade-deleted.');
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure DeleteTravelRequestWithPostedLineIsBlocked()
    var
        SpendRequest: Record "Spend Request";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        // [SCENARIO] A posted line can link a request independently of its report header.
        Initialize();

        // [GIVEN] Normal posting produces line-only references and zero net spend.
        CreatePostedTravelRequestReport(SpendRequest, PostedExpenseReportHeader, false);
        PostedExpenseReportHeader.TestField("Spend Request No.", '');
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLine.SetRange("Spend Request No.", SpendRequest."No.");
        PostedExpenseReportLine.FindFirst();

        // [WHEN] The request is deleted.
        asserterror SpendRequest.Delete(true);

        // [THEN] Line-only references are protected without removing posted records.
        Assert.ExpectedError(LinkedExpenseReportExistsErr);
        Assert.IsTrue(SpendRequest.Get(SpendRequest."No."), 'The line-linked request must remain.');
        Assert.IsTrue(PostedExpenseReportLine.Get(PostedExpenseReportHeader."No.", PostedExpenseReportLine."Line No."), 'The posted line must remain.');
        Assert.IsTrue(PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No."), 'The posted header must remain.');
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure DeleteTravelRequestWithUnpostedLineIsBlocked()
    var
        SpendRequest: Record "Spend Request";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [SCENARIO] An unposted line's independent travel-request reference prevents deletion.
        Initialize();

        // [GIVEN] Only an expense report line references the travel request.
        CreateAndPostExpenseReportWithSpendRequest(ExpenseReportHeader, SpendRequest, 1);
        ExpenseReportHeader.TestField("Spend Request No.", '');
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportLine.FindFirst();

        // [WHEN] The request is deleted.
        asserterror SpendRequest.Delete(true);

        // [THEN] The request and the referencing line remain intact.
        Assert.ExpectedError(LinkedExpenseReportExistsErr);
        Assert.IsTrue(SpendRequest.Get(SpendRequest."No."), 'The line-linked request must remain.');
        Assert.IsTrue(ExpenseReportLine.Get(ExpenseReportHeader."No.", ExpenseReportLine."Line No."), 'The report line must remain.');
    end;

    [Test]
    procedure DeleteTravelRequestWithoutReportRemovesDependents()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        ExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
        TravelRequestNo: Code[20];
    begin
        // [SCENARIO] A travel request without a linked report can still be deleted with its dependents.
        Initialize();

        // [GIVEN] An open travel request with a detail and an automatically created traveler.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", 0);
        TravelRequestNo := SpendRequest."No.";

        // [WHEN] The request is deleted.
        SpendRequest.Delete(true);

        // [THEN] The request and its dependent details and travelers are removed.
        Assert.IsFalse(SpendRequest.Get(TravelRequestNo), 'The unlinked travel request must be deleted.');
        SpendRequestDetail.SetRange("Spend Request No.", TravelRequestNo);
        Assert.RecordIsEmpty(SpendRequestDetail);
        Traveler.SetRange("Spend Request No.", TravelRequestNo);
        Assert.RecordIsEmpty(Traveler);
    end;

    [Test]
    procedure TravelRequestInsertPreservesAPIDates()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Explicit API dates survive insertion; only omitted dates receive defaults.
        Initialize();

        // [GIVEN] A request supplying a future date pair.
        PrepareTravelRequestWithAPIDates(SpendRequest, WorkDate() + 30, WorkDate() + 33, true, true);

        // [WHEN] The table's insert triggers run.
        SpendRequest.Insert(true);

        // [THEN] The supplied dates are persisted.
        SpendRequest.Get(SpendRequest."No.");
        AssertTravelRequestDates(SpendRequest, WorkDate() + 30, WorkDate() + 33);

        // [WHEN] The same record variable inserts again without any date inputs.
        SpendRequest.Init();
        SpendRequest."No." := '';
        SpendRequest."Document Type" := SpendRequest."Document Type"::"Travel Request";
        SpendRequest.Insert(true);

        // [THEN] The previous override was consumed and normal defaults apply.
        AssertTravelRequestDates(SpendRequest, WorkDate(), WorkDate());

        // [WHEN] Only an end date is supplied on another insertion.
        PrepareTravelRequestWithAPIDates(SpendRequest, 0D, WorkDate() + 7, false, true);
        SpendRequest.Insert(true);

        // [THEN] The start defaults and the supplied end is preserved.
        AssertTravelRequestDates(SpendRequest, WorkDate(), WorkDate() + 7);

        // [WHEN] Only a start date is supplied on another insertion.
        PrepareTravelRequestWithAPIDates(SpendRequest, WorkDate() - 7, 0D, true, false);
        SpendRequest.Insert(true);

        // [THEN] The end defaults and the supplied start is preserved.
        AssertTravelRequestDates(SpendRequest, WorkDate() - 7, WorkDate());
    end;

    [Test]
    procedure TravelRequestDatePairMovesLaterAndEarlier()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Complete date ranges can move past the old end or before the old start.
        Initialize();

        // [GIVEN] An open request with its default date pair.
        LibraryExpense.CreateSpendRequest(SpendRequest);

        // [WHEN] Both dates move past the old end.
        SpendRequest.ApplyExpectedDatesFromAPI(WorkDate() + 30, WorkDate() + 33, true, true);
        SpendRequest.Modify(true);

        // [THEN] The complete later pair is accepted.
        SpendRequest.Get(SpendRequest."No.");
        AssertTravelRequestDates(SpendRequest, WorkDate() + 30, WorkDate() + 33);

        // [WHEN] Both dates move before the old start.
        SpendRequest.ApplyExpectedDatesFromAPI(WorkDate() - 33, WorkDate() - 30, true, true);
        SpendRequest.Modify(true);

        // [THEN] The complete earlier pair is accepted.
        SpendRequest.Get(SpendRequest."No.");
        AssertTravelRequestDates(SpendRequest, WorkDate() - 33, WorkDate() - 30);
    end;

    [Test]
    procedure TravelRequestDateChangesPreserveOmittedFields()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Partial date updates use stored values for omitted fields.
        Initialize();

        // [GIVEN] An open request with its default date pair.
        LibraryExpense.CreateSpendRequest(SpendRequest);

        // [WHEN] Only the end date is changed.
        SpendRequest.ApplyExpectedDatesFromAPI(0D, WorkDate() + 20, false, true);
        SpendRequest.Modify(true);

        // [THEN] The start remains unchanged.
        AssertTravelRequestDates(SpendRequest, WorkDate(), WorkDate() + 20);

        // [WHEN] Only the start is changed, followed by a request omitting both dates.
        SpendRequest.ApplyExpectedDatesFromAPI(WorkDate() + 10, 0D, true, false);
        SpendRequest.ApplyExpectedDatesFromAPI(0D, 0D, false, false);
        SpendRequest.Modify(true);

        // [THEN] The effective date pair is preserved.
        SpendRequest.Get(SpendRequest."No.");
        AssertTravelRequestDates(SpendRequest, WorkDate() + 10, WorkDate() + 20);
    end;

    [Test]
    procedure TravelRequestAPIDatesKeepValidation()
    var
        SpendRequest: Record "Spend Request";
        InvalidRequest: Record "Spend Request";
    begin
        // [SCENARIO] Deferred validation still rejects invalid ranges and edits to released requests.
        Initialize();

        // [GIVEN] An open request with its default date pair.
        LibraryExpense.CreateSpendRequest(SpendRequest);

        // [WHEN] A start-only update exceeds the stored end.
        asserterror SpendRequest.ApplyExpectedDatesFromAPI(WorkDate() + 1, 0D, true, false);

        // [THEN] The range is rejected and stored dates are unchanged.
        Assert.ExpectedError(InvalidTravelRequestDatesErr);
        SpendRequest.Get(SpendRequest."No.");
        AssertTravelRequestDates(SpendRequest, WorkDate(), WorkDate());

        // [WHEN] An invalid complete pair is supplied.
        asserterror SpendRequest.ApplyExpectedDatesFromAPI(WorkDate() + 10, WorkDate() + 5, true, true);

        // [THEN] The final invalid pair is rejected.
        Assert.ExpectedError(InvalidTravelRequestDatesErr);
        SpendRequest.Get(SpendRequest."No.");

        // [WHEN] A new request supplies an invalid pair.
        PrepareTravelRequestWithAPIDates(InvalidRequest, WorkDate() + 10, WorkDate() + 5, true, true);
        asserterror InvalidRequest.Insert(true);

        // [THEN] Insertion fails rather than replacing the inputs with valid defaults.
        Assert.ExpectedError(InvalidTravelRequestDatesErr);

        // [WHEN] A released request receives a valid new pair.
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);
        asserterror SpendRequest.ApplyExpectedDatesFromAPI(WorkDate() + 30, WorkDate() + 33, true, true);

        // [THEN] The existing status guard still rejects the edit.
        Assert.ExpectedError(StatusNotOpenErr);
    end;

    [Test]
    procedure AutomaticTravelRequestApprovalRequiresDisabledAgent()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        // [SCENARIO] Automatic approval is rejected while the Expense Agent is enabled.
        Initialize();

        // [GIVEN] A released travel request with the Expense Agent enabled.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);

        // [WHEN] Automatic approval is attempted.
        asserterror TravelRequestApproval.ApproveAutomatically(SpendRequest);

        // [THEN] Approval fails because the agent must be disabled.
        Assert.ExpectedError(AutomaticApprovalNotAllowedErr);
    end;

    [Test]
    procedure ApproveTravelRequestCreatesExpenseReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
        TravelRequestApproval: Codeunit "Travel Request Approval";
        ExpectedDescription: Text[100];
        TravelRequestPurpose: Text[150];
    begin
        // [SCENARIO] Approving a travel request creates a linked report for its requested user.
        Initialize();

        // [GIVEN] A released travel request with a long purpose and an assigned approver.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        TravelRequestPurpose := PadStr('Customer conference ', MaxStrLen(TravelRequestPurpose), 'x');
        ExpectedDescription := CopyStr(TravelRequestPurpose, 1, MaxStrLen(ExpectedDescription));
        SpendRequest.Validate(Purpose, TravelRequestPurpose);
        SpendRequest.Modify(true);
        ReleaseSpendRequest.Release(SpendRequest);
        CreateApproverForExpenseUser(ApproverExpenseUser, ExpenseUser);

        // [WHEN] The assigned approver approves the request.
        TravelRequestApproval.Approve(SpendRequest, ApproverExpenseUser."No.");

        // [THEN] One linked report is created with the requested user and truncated purpose.
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.AreEqual(1, ExpenseReportHeader.Count(), ExpenseReportCreatedMsg);
        ExpenseReportHeader.FindFirst();
        Assert.AreEqual(ExpenseUser."No.", ExpenseReportHeader."Expense User No.", ExpenseReportUserMsg);
        Assert.AreEqual(ExpectedDescription, ExpenseReportHeader.Description, ExpenseReportDescriptionMsg);
        ExpenseReportHeader.CalcFields("Travel Request SystemId");
        Assert.AreEqual(SpendRequest.SystemId, ExpenseReportHeader."Travel Request SystemId", TravelRequestSystemIdMsg);
    end;

    [Test]
    procedure ApproveTravelRequestPageAction()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] The approval page procedure approves the request and records the approving user.
        Initialize();

        // [GIVEN] A released travel request and its assigned approver.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        CreateApproverForExpenseUser(ApproverExpenseUser, ExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);
        TravelRequestsAPI.SetRecord(SpendRequest);

        // [WHEN] The page procedure is invoked directly, without an HTTP request.
        TravelRequestsAPI.ApproveTravelRequest(ActionContext, ApproverExpenseUser."No.");

        // [THEN] The request is approved with its audit fields and a linked report.
        Assert.AreEqual(WebServiceActionResultCode::Updated, ActionContext.GetResultCode(), TravelRequestActionResultMsg);
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Approved, SpendRequest.Status, 'The travel request should be approved through the page action.');
        Assert.AreEqual(UserSecurityId(), SpendRequest."Approved/Rejected by User ID", 'The approving user should be recorded.');
        Assert.AreEqual(ApproverExpenseUser."No.", SpendRequest."Approval Expense User No.", 'The approving expense user should be recorded.');
        Assert.AreNotEqual(0DT, SpendRequest."Approved/Rejected At", 'The page action approval date and time should be recorded.');
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordIsNotEmpty(ExpenseReportHeader);
    end;

    [Test]
    procedure CreateExpenseReportPageActionRecreatesDeletedReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] An approved travel request can recreate its deleted expense report through the API action.
        Initialize();

        // [GIVEN] An approved travel request whose automatically created report was deleted.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);
        ExpenseReportHeader.CreateFromApprovedTravelRequest(SpendRequest);
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.Delete(true);
        SetOwnerScopedTravelRequest(TravelRequestsAPI, SpendRequest, ExpenseUser.SystemId);

        // [WHEN] The create expense report action is invoked.
        TravelRequestsAPI.CreateExpenseReport(ActionContext);

        // [THEN] A new linked report is returned for the requested Expense User.
        Assert.AreEqual(WebServiceActionResultCode::Created, ActionContext.GetResultCode(), 'The action must return a created result.');
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.TestField("Expense User No.", ExpenseUser."No.");
    end;

    [Test]
    procedure CreateExpenseReportPageActionRequiresApprovedTravelRequest()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] A report cannot be recreated before the travel request is approved.
        Initialize();

        // [GIVEN] An open travel request with a requested Expense User.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        SetOwnerScopedTravelRequest(TravelRequestsAPI, SpendRequest, ExpenseUser.SystemId);

        // [WHEN] The create expense report action is invoked.
        asserterror TravelRequestsAPI.CreateExpenseReport(ActionContext);

        // [THEN] The action explains that approval is required.
        Assert.ExpectedError(StrSubstNo(TravelRequestMustBeApprovedErr, SpendRequest."No."));
    end;

    [Test]
    procedure CreateExpenseReportPageActionRejectsExistingLinkedReport()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        UnrelatedExpenseReport: Record "Expense Report Header";
        OtherTravelerExpenseReport: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] A second report cannot be created while one is already linked.
        Initialize();

        // [GIVEN] Earlier reports for another request and another traveler must not be used in the error.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        LibraryExpense.CreateTraveler(SpendRequest."No.", OtherExpenseUser."No.");
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);
        LibraryExpense.CreateExpenseReport(UnrelatedExpenseReport, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReport(OtherTravelerExpenseReport, OtherExpenseUser."No.", '', '');
        OtherTravelerExpenseReport.SetHideValidationDialog(true);
        OtherTravelerExpenseReport.Validate("Spend Request No.", SpendRequest."No.");
        OtherTravelerExpenseReport.Modify(true);

        // [GIVEN] The requested user also has a report linked to this request.
        ExpenseReportHeader.CreateFromApprovedTravelRequest(SpendRequest);
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.SetRange("Expense User No.", SpendRequest."Requested For");
        ExpenseReportHeader.FindFirst();
        SetOwnerScopedTravelRequest(TravelRequestsAPI, SpendRequest, ExpenseUser.SystemId);

        // [WHEN] The create expense report action is invoked.
        asserterror TravelRequestsAPI.CreateExpenseReport(ActionContext);

        // [THEN] The action identifies the Expense User, existing report, and travel request.
        Assert.ExpectedError(
            StrSubstNo(ExpenseReportAlreadyLinkedErr, ExpenseUser."No.", ExpenseReportHeader."No.", SpendRequest."No."));
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure CreateExpenseReportRejectsPostedHeader()
    begin
        // [SCENARIO] Posting a linked report must not permit recreation for the same traveler.
        Initialize();
        AssertPostedReportPreventsRecreation(true);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure CreateExpenseReportRejectsPostedLine()
    begin
        // [SCENARIO] A posted line-only travel request link also prevents recreation.
        Initialize();
        AssertPostedReportPreventsRecreation(false);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure CreateExpenseReportAllowsOtherPostedTraveler()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] A posted report for another traveler does not prevent a Requested For report.
        Initialize();
        CreatePostedTravelRequestReport(SpendRequest, PostedExpenseReportHeader, true);
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Open);
        SpendRequest.Validate("Requested For", OtherExpenseUser."No.");
        SpendRequest.Modify(true);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);
        SetOwnerScopedTravelRequest(TravelRequestsAPI, SpendRequest, ExpenseUser.SystemId);

        TravelRequestsAPI.CreateExpenseReport(ActionContext);

        Assert.AreEqual(WebServiceActionResultCode::Created, ActionContext.GetResultCode(), 'A different traveler must be able to create a report.');
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.FindFirst();
        ExpenseReportHeader.TestField("Expense User No.", OtherExpenseUser."No.");
        Assert.IsTrue(PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No."), 'The other traveler''s posted report must remain.');
    end;

    local procedure AssertPostedReportPreventsRecreation(AssignOnHeader: Boolean)
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        CreatePostedTravelRequestReport(SpendRequest, PostedExpenseReportHeader, AssignOnHeader);
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");
        SpendRequest.TestField(Status, SpendRequest.Status::Approved);
        if AssignOnHeader then
            PostedExpenseReportHeader.TestField("Spend Request No.", SpendRequest."No.")
        else
            PostedExpenseReportHeader.TestField("Spend Request No.", '');
        ExpenseReportHeader.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordIsEmpty(ExpenseReportHeader);
        SetOwnerScopedTravelRequest(TravelRequestsAPI, SpendRequest, ExpenseUser.SystemId);

        asserterror TravelRequestsAPI.CreateExpenseReport(ActionContext);

        Assert.ExpectedError(StrSubstNo(
            PostedReportAlreadyLinkedErr, ExpenseUser."No.", PostedExpenseReportHeader."No.", SpendRequest."No."));
        Assert.RecordIsEmpty(ExpenseReportHeader);
        Assert.IsTrue(PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No."), 'Posted history must remain unchanged.');
    end;

    [Test]
    procedure CreateExpenseReportPageActionRequiresOwnerScope()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] Report recreation cannot be invoked through an unscoped travel request route.
        Initialize();

        // [GIVEN] An approved travel request without an owner-scoped API filter.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);
        TravelRequestsAPI.SetRecord(SpendRequest);

        // [WHEN] The create expense report action is invoked.
        asserterror TravelRequestsAPI.CreateExpenseReport(ActionContext);

        // [THEN] The action requires the owning Expense User route.
        Assert.ExpectedError(OwnerScopeRequiredErr);
    end;

    [Test]
    procedure CreateExpenseReportPageActionRequiresRequestedFor()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] A report cannot be created without a requested Expense User.
        Initialize();

        // [GIVEN] An approved owner-scoped travel request without Requested For.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        SpendRequest."Requested For" := '';
        SpendRequest.Modify();
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);
        SetOwnerScopedTravelRequest(TravelRequestsAPI, SpendRequest, ExpenseUser.SystemId);

        // [WHEN] The create expense report action is invoked.
        asserterror TravelRequestsAPI.CreateExpenseReport(ActionContext);

        // [THEN] The action requires Requested For.
        Assert.ExpectedError(FieldRequiredErr);
    end;

    [Test]
    procedure CreateExpenseReportPageActionRejectsDifferentOwnerScope()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        DifferentExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] A report cannot be created through another Expense User's route.
        Initialize();

        // [GIVEN] An approved travel request scoped through a different Expense User.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.CreateExpenseUser(DifferentExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);
        SetOwnerScopedTravelRequest(TravelRequestsAPI, SpendRequest, DifferentExpenseUser.SystemId);

        // [WHEN] The create expense report action is invoked.
        asserterror TravelRequestsAPI.CreateExpenseReport(ActionContext);

        // [THEN] The action rejects the mismatched owner.
        Assert.ExpectedError(DifferentExpenseUser."Employee No.");
    end;

    [Test]
    procedure SubmitTravelRequestPageAction()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
    begin
        // [SCENARIO] The submission page procedure releases the request and records its submitter.
        Initialize();

        // [GIVEN] A releasable travel request with the Expense Agent enabled.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        TravelRequestsAPI.SetRecord(SpendRequest);

        // [WHEN] The page procedure is invoked directly, without an HTTP request.
        TravelRequestsAPI.SubmitTravelRequest(ActionContext, ExpenseUser."No.");

        // [THEN] The request is released with its submission audit fields.
        Assert.AreEqual(WebServiceActionResultCode::Updated, ActionContext.GetResultCode(), TravelRequestActionResultMsg);
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Released, SpendRequest.Status, 'The travel request should be released through the page action.');
        Assert.AreEqual(ExpenseUser."No.", SpendRequest."Submitted By Expense User No.", 'The submitting expense user should be recorded.');
        Assert.AreNotEqual(0DT, SpendRequest."Submitted At", 'The page action submission date and time should be recorded.');
    end;

    [Test]
    procedure SubmitTravelRequestRejectsDifferentOwner()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        DifferentExpenseUser: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        // [SCENARIO] A different expense user cannot submit another employee's travel request.
        Initialize();

        // [GIVEN] A releasable request and an expense user other than its owner.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        LibraryExpense.CreateExpenseUser(DifferentExpenseUser);

        // [WHEN] The other expense user attempts to submit the request.
        asserterror TravelRequestApproval.Submit(SpendRequest, DifferentExpenseUser."No.");

        // [THEN] Submission is rejected because the submitter is not the owner.
        Assert.ExpectedError(NotTravelRequestOwnerErr);
    end;

    [Test]
    procedure ApproveTravelRequestRejectsUnassignedApprover()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        AssignedApprover: Record "Expense User";
        DifferentApprover: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        // [SCENARIO] An approver cannot approve a travel request assigned to someone else.
        Initialize();

        // [GIVEN] A released request with an assigned approver and another approver.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        CreateApproverForExpenseUser(AssignedApprover, ExpenseUser);
        CreateApprover(DifferentApprover);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);

        // [WHEN] The unassigned approver attempts to approve the request.
        asserterror TravelRequestApproval.Approve(SpendRequest, DifferentApprover."No.");

        // [THEN] Approval is rejected because the approver is not authorized.
        Assert.ExpectedError(NotTravelRequestApproverErr);
    end;

    [Test]
    procedure RejectTravelRequestStoresReason()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
        RejectReason: Text;
    begin
        // [SCENARIO] Rejecting a travel request records the approver and rejection reason.
        Initialize();

        // [GIVEN] A released request, its assigned approver, and a rejection reason.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        CreateApproverForExpenseUser(ApproverExpenseUser, ExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);
        RejectReason := 'The destination is outside the approved travel policy.';

        // [WHEN] The approver rejects the request.
        TravelRequestApproval.Reject(SpendRequest, ApproverExpenseUser."No.", RejectReason);

        // [THEN] The request is rejected and retains the approver and reason.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Rejected, SpendRequest.Status, 'The travel request should be rejected.');
        Assert.AreEqual(ApproverExpenseUser."No.", SpendRequest."Approval Expense User No.", 'The rejecting expense user should be recorded.');
        Assert.AreEqual(RejectReason, SpendRequest."Rejection Reason", 'The rejection reason should be recorded.');
    end;

    [Test]
    procedure RejectTravelRequestPageAction()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        TravelRequestsAPI: Page "Travel Requests API";
        ActionContext: WebServiceActionContext;
        RejectReason: Text;
    begin
        // [SCENARIO] The rejection page procedure records the rejecting user, reason, and timestamp.
        Initialize();

        // [GIVEN] A released request, its assigned approver, and a rejection reason.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        CreateApproverForExpenseUser(ApproverExpenseUser, ExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);
        RejectReason := 'The destination is outside the approved travel policy.';
        TravelRequestsAPI.SetRecord(SpendRequest);

        // [WHEN] The page procedure is invoked directly, without an HTTP request.
        TravelRequestsAPI.RejectTravelRequest(ActionContext, ApproverExpenseUser."No.", RejectReason);

        // [THEN] The action returns Updated and the request records the rejection details.
        Assert.AreEqual(WebServiceActionResultCode::Updated, ActionContext.GetResultCode(), TravelRequestActionResultMsg);
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Rejected, SpendRequest.Status, TravelRequestRejectedMsg);
        Assert.AreEqual(UserSecurityId(), SpendRequest."Approved/Rejected by User ID", TravelRequestRejectionUserMsg);
        Assert.AreEqual(ApproverExpenseUser."No.", SpendRequest."Approval Expense User No.", TravelRequestRejectionExpenseUserMsg);
        Assert.AreEqual(RejectReason, SpendRequest."Rejection Reason", TravelRequestRejectionReasonMsg);
        Assert.AreNotEqual(0DT, SpendRequest."Approved/Rejected At", TravelRequestRejectionDateMsg);
    end;

    [Test]
    procedure OwnerFilterUsesExpenseUserSystemId()
    var
        SpendRequest: Record "Spend Request";
        FilteredTravelRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
        OwnerSystemId: Guid;
        NewExpenseUserNo: Code[20];
    begin
        // [SCENARIO] A stable owner identity resolves to the employee number used by the base table.
        Initialize();

        // [GIVEN] A request owned by an expense user's employee, followed by renaming the expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseUser(OtherExpenseUser);
        LibraryExpense.CreateSpendRequest(SpendRequest);
        SpendRequest.Validate("Requested By", ExpenseUser."Employee No.");
        SpendRequest.Modify(true);
        OwnerSystemId := ExpenseUser.SystemId;
        NewExpenseUserNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(NewExpenseUserNo));
        ExpenseUser.Rename(NewExpenseUserNo);

        // [WHEN] The original GUID is used to resolve the owner.
        TravelRequestApproval.ApplyOwnerFilter(FilteredTravelRequest, OwnerSystemId);
        FilteredTravelRequest.SetRange("No.", SpendRequest."No.");

        // [THEN] The owned request remains visible despite the business-number change.
        Assert.IsFalse(FilteredTravelRequest.IsEmpty(), 'Renaming the expense user must not break owner navigation.');
        Assert.AreEqual(
            ExpenseUser."Employee No.", FilteredTravelRequest.GetRangeMin("Requested By"),
            'Owner scoping must still use the linked employee, not the Expense User number.');

        // [WHEN] The same request is scoped to a different expense user.
        TravelRequestApproval.ApplyOwnerFilter(FilteredTravelRequest, OtherExpenseUser.SystemId);

        // [THEN] Another user cannot see the original owner's request.
        Assert.IsTrue(FilteredTravelRequest.IsEmpty(), 'The GUID scope must not expose another employee''s request.');
    end;

    [Test]
    procedure OwnerFilterRejectsUnknownExpenseUser()
    var
        FilteredTravelRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        // [SCENARIO] An unknown owner GUID fails instead of falling back to an unscoped query.
        Initialize();

        // [WHEN] A nonexistent expense user is used as the owner scope.
        asserterror TravelRequestApproval.ApplyOwnerFilter(FilteredTravelRequest, CreateGuid());

        // [THEN] The missing-record error is propagated.
        Assert.ExpectedErrorCode('DB:RecordNotFound');
        Assert.ExpectedError(ExpenseUser.TableCaption());
    end;

    [Test]
    procedure ApproverFilterReturnsAssignedTravelRequests()
    var
        AssignedTravelRequest: Record "Spend Request";
        OtherTravelRequest: Record "Spend Request";
        FilteredTravelRequest: Record "Spend Request";
        AssignedExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        AssignedApprover: Record "Expense User";
        OtherApprover: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
        ApproverSystemId: Guid;
    begin
        // [SCENARIO] The approver filter includes assigned requests and excludes other approvers' requests.
        Initialize();

        // [GIVEN] Two released travel requests assigned to different approvers.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateReleasableSpendRequest(AssignedTravelRequest, AssignedExpenseUser);
        CreateApproverForExpenseUser(AssignedApprover, AssignedExpenseUser);
        LibraryExpense.SetSpendRequestStatus(AssignedTravelRequest, AssignedTravelRequest.Status::Released);
        CreateReleasableSpendRequest(OtherTravelRequest, OtherExpenseUser);
        CreateApproverForExpenseUser(OtherApprover, OtherExpenseUser);
        LibraryExpense.SetSpendRequestStatus(OtherTravelRequest, OtherTravelRequest.Status::Released);

        // [GIVEN] The assigned approver is renamed without changing its stable identity.
        ApproverSystemId := AssignedApprover.SystemId;
        AssignedApprover.Rename(CopyStr(Format(CreateGuid()), 1, MaxStrLen(AssignedApprover."No.")));

        // [WHEN] The first approver's filter is applied to pending travel requests.
        FilteredTravelRequest.SetRange("Document Type", FilteredTravelRequest."Document Type"::"Travel Request");
        FilteredTravelRequest.SetRange(Status, FilteredTravelRequest.Status::Released);
        TravelRequestApproval.ApplyApproverFilter(FilteredTravelRequest, ApproverSystemId);

        // [THEN] Only the request assigned to that approver is visible.
        FilteredTravelRequest.SetRange("No.", AssignedTravelRequest."No.");
        Assert.IsFalse(FilteredTravelRequest.IsEmpty(), AssignedTravelRequestVisibleMsg);
        FilteredTravelRequest.SetRange("No.", OtherTravelRequest."No.");
        Assert.IsTrue(FilteredTravelRequest.IsEmpty(), UnassignedTravelRequestHiddenMsg);
    end;

    [Test]
    procedure ApproverFilterReturnsDefaultApproverTravelRequests()
    begin
        // [SCENARIO] The default approver sees requests without an explicit approval assignment.
        VerifyDefaultApproverFilter('', '');
    end;

    [Test]
    procedure DefaultApproverFilterQuotesWildcardUserNo()
    begin
        // [SCENARIO] A literal wildcard user number must not expose another approver's requests.
        VerifyDefaultApproverFilter('*', 'TR-OTHER');
    end;

    [Test]
    procedure DefaultApproverFilterQuotesPipeUserNo()
    begin
        // [SCENARIO] A pipe in a user number must not become an OR filter for other users.
        VerifyDefaultApproverFilter('TR-A|TR-B', 'TR-A');
    end;

    [Test]
    procedure ApproverFilterReturnsEmptyForApproverWithoutRequests()
    var
        SpendRequest: Record "Spend Request";
        FilteredTravelRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        AssignedApprover: Record "Expense User";
        ApproverWithoutRequests: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        // [SCENARIO] An approver without assigned requests receives an empty filtered set.
        Initialize();

        // [GIVEN] A released request assigned to someone else and no default approver.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        SetDefaultApprover('');
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        CreateApproverForExpenseUser(AssignedApprover, ExpenseUser);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);
        CreateApprover(ApproverWithoutRequests);

        // [WHEN] The unassigned approver's filter is applied to pending travel requests.
        FilteredTravelRequest.SetRange("Document Type", FilteredTravelRequest."Document Type"::"Travel Request");
        FilteredTravelRequest.SetRange(Status, FilteredTravelRequest.Status::Released);
        TravelRequestApproval.ApplyApproverFilter(FilteredTravelRequest, ApproverWithoutRequests.SystemId);

        // [THEN] No requests are visible.
        Assert.IsTrue(FilteredTravelRequest.IsEmpty(), ApproverWithoutRequestsMsg);
    end;

    [Test]
    procedure ReleaseBlankSpendRequestSkipsTravelPrereqs()
    var
        SpendRequest: Record "Spend Request";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 647134] A blank (non-travel) spend request releases without the travel prerequisites the agent enforces on travel requests.
        Initialize();

        // [GIVEN] A blank spend request with no Requested For, dates, travel policy, or travelers.
        SpendRequest.Init();
        SpendRequest.Insert(true);

        // [WHEN] The spend request is released.
        ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] It releases without the travel prerequisites, and stays released because the agent auto-approval is travel-only.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Released, SpendRequest.Status, BlankSpendReqReleasedMsg);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure PostReportClosesSpendReqWhenConfirmed()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        SpendRequest: Record "Spend Request";
        SpendRequestToGLLink: Record "Spend Request To G/L Link";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedSpentLCY: Decimal;
    begin
        // [SCENARIO 616928] When the close is confirmed while selecting the spend request on the line, posting the report closes it.
        Initialize();

        // [GIVEN] The close is confirmed when the spend request is selected on entry.
        CloseConfirmReply := true;

        // [GIVEN] An expense report with a refundable line linked to a Released spend request.
        CreateAndPostExpenseReportWithSpendRequest(ExpenseReportHeader, SpendRequest, 1);

        // [GIVEN] The refundable amount that is expected to be spent against the spend request.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.FindFirst();
        ExpectedSpentLCY := ExpenseReportLine."Refundable Amount (LCY)";

        // [WHEN] The report is Released and posted.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The close was prompted once (at entry) and the spend request is closed.
        Assert.AreEqual(1, CloseConfirmCount, ClosePromptOnceMsg);
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Closed, SpendRequest.Status, SpendReqClosedMsg);
        Assert.AreNotEqual('', SpendRequest."Closed By Document No.", ClosedByDocMsg);

        // [THEN] The posted amount is recorded on the spend request through a Spend Request To G/L Link entry.
        SpendRequestToGLLink.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.IsFalse(SpendRequestToGLLink.IsEmpty(), SpendReqLinkExistsMsg);
        SpendRequest.CalcFields("Total Spent Amount (LCY)");
        Assert.AreEqual(ExpectedSpentLCY, SpendRequest."Total Spent Amount (LCY)", SpendReqSpentAmountMsg);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure PostReportKeepsSpendReqWhenDeclined()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 616928] When the close is declined on entry, posting the report leaves the spend request approved.
        Initialize();

        // [GIVEN] The close is declined when the spend request is selected on entry.
        CloseConfirmReply := false;

        // [GIVEN] An expense report with a refundable line linked to an approved spend request.
        CreateAndPostExpenseReportWithSpendRequest(ExpenseReportHeader, SpendRequest, 1);

        // [WHEN] The report is Released and posted.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The close was prompted once and the spend request remains approved.
        Assert.AreEqual(1, CloseConfirmCount, ClosePromptOnceMsg);
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Approved, SpendRequest.Status, SpendReqNotClosedMsg);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure PostReportMultipleLinesClosesSpendReqOnce()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        SpendRequest: Record "Spend Request";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedSpentLCY: Decimal;
    begin
        // [SCENARIO 616928] A header-level spend request applies to every line; the close is prompted once, posting closes it, and the spent amount sums all refundable lines.
        Initialize();

        // [GIVEN] The close is confirmed when the spend request is selected on the header.
        CloseConfirmReply := true;

        // [GIVEN] An expense report whose header references a spend request, with two refundable lines.
        CreateAndPostExpenseReportWithSpendRequestAssignedOnHeader(ExpenseReportHeader, SpendRequest, 2);

        // [GIVEN] The total refundable amount expected to be spent across both lines.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.CalcSums("Refundable Amount (LCY)");
        ExpectedSpentLCY := ExpenseReportLine."Refundable Amount (LCY)";

        // [WHEN] The report is Released and posted.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The close was prompted once and the spend request is closed exactly once.
        Assert.AreEqual(1, CloseConfirmCount, ClosePromptOnceMsg);
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Closed, SpendRequest.Status, SpendReqClosedMsg);

        // [THEN] The spent amount reflects the sum of both refundable lines.
        SpendRequest.CalcFields("Total Spent Amount (LCY)");
        Assert.AreEqual(ExpectedSpentLCY, SpendRequest."Total Spent Amount (LCY)", SpendReqSpentAmountMsg);
    end;

    [Test]
    procedure RequestedForAutoAddsTraveler()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
    begin
        // [SCENARIO 616928] Setting "Requested For" on an open expense spend request automatically adds that user as a traveler.
        Initialize();

        // [GIVEN] An expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] An open expense spend request.
        LibraryExpense.CreateSpendRequest(SpendRequest);

        // [WHEN] The user is set as "Requested For".
        SpendRequest.Validate("Requested For", ExpenseUser."No.");
        SpendRequest.Modify(true);

        // [THEN] A traveler is created for that user.
        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Traveler.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(Traveler, 1);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure ChangeRequestedForReplacesTraveler()
    var
        SpendRequest: Record "Spend Request";
        FirstExpenseUser: Record "Expense User";
        SecondExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
    begin
        // [SCENARIO 616928] Changing "Requested For" replaces the auto-added traveler when the user confirms.
        Initialize();

        // [GIVEN] Two expense users.
        LibraryExpense.CreateExpenseUser(FirstExpenseUser);
        LibraryExpense.CreateExpenseUser(SecondExpenseUser);

        // [GIVEN] An open spend request whose Requested For is the first user (auto-added as traveler).
        LibraryExpense.CreateSpendRequest(SpendRequest);
        SpendRequest.Validate("Requested For", FirstExpenseUser."No.");
        SpendRequest.Modify(true);

        // [WHEN] "Requested For" is changed to the second user and the replacement is confirmed.
        SpendRequest.Validate("Requested For", SecondExpenseUser."No.");
        SpendRequest.Modify(true);

        // [THEN] The first user's traveler is removed and the second user's traveler is added.
        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Traveler.SetRange("Expense User No.", FirstExpenseUser."No.");
        Assert.RecordCount(Traveler, 0);
        Traveler.SetRange("Expense User No.", SecondExpenseUser."No.");
        Assert.RecordCount(Traveler, 1);
    end;

    [Test]
    procedure AddDuplicateTravelerFails()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 616928] The same expense user cannot be added as a traveler twice on the same spend request.
        Initialize();

        // [GIVEN] An expense user and an open spend request.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateSpendRequest(SpendRequest);

        // [GIVEN] The user is already added as a traveler.
        LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUser."No.");

        // [WHEN] The same user is added again.
        asserterror LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUser."No.");

        // [THEN] It fails because the traveler already exists.
        Assert.ExpectedError('is already on this');
    end;

    [Test]
    procedure AddTravelerFailsWhenSpendRequestNotOpen()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 616928] A traveler cannot be added when the spend request is no longer open.
        Initialize();

        // [GIVEN] An expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] A Released spend request.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);

        // [WHEN] A traveler is added.
        asserterror LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUser."No.");

        // [THEN] It fails because the spend request is not open.
        Assert.ExpectedError(StatusNotOpenErr);
    end;

    [Test]
    procedure DeleteSpendRequestDeletesTravelers()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
    begin
        // [SCENARIO 616928] Deleting a spend request removes its travelers.
        Initialize();

        // [GIVEN] An expense user and an open spend request.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateSpendRequest(SpendRequest);

        // [GIVEN] The user is added as a traveler.
        LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUser."No.");
        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Assert.RecordCount(Traveler, 1);

        // [WHEN] The spend request is deleted.
        SpendRequest.Delete(true);

        // [THEN] Its travelers are removed.
        Assert.RecordCount(Traveler, 0);
    end;

    [Test]
    procedure RequestedForBeforeInsertAddsTravelerAfterInsert()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        Traveler: Record Traveler;
    begin
        Initialize();
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        SpendRequest.Init();
        SpendRequest."Document Type" := SpendRequest."Document Type"::"Travel Request";

        SpendRequest.Validate("Requested For", ExpenseUser."No.");
        SpendRequest.Insert(true);

        Traveler.SetRange("Spend Request No.", SpendRequest."No.");
        Traveler.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(Traveler, 1);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure ValidateHeaderSpendReqStoresCloseFlagWhenConfirmed()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 616928] Selecting an approved spend request on the header stores the confirmed close flag on the header.
        Initialize();
        CloseConfirmReply := true;

        // [GIVEN] An expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] An approved spend request with the user as a traveler.
        CreateSpendRequestWithTraveler(SpendRequest, ExpenseUser."No.", SpendRequest.Status::Approved);

        // [GIVEN] An expense report header for that user.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [WHEN] The spend request is set on the header and the close is confirmed.
        ExpenseReportHeader.Validate("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.Modify(true);

        // [THEN] The header stores the request and the confirmed close flag.
        Assert.AreEqual(SpendRequest."No.", ExpenseReportHeader."Spend Request No.", HeaderSpendReqNoSetMsg);
        Assert.IsTrue(ExpenseReportHeader."Spend Request Close", HeaderCloseFlagMsg);
    end;

    [Test]
    procedure ValidateHeaderSpendReqFailsWhenNotTraveler()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 616928] A spend request cannot be set on the header when the report's expense user is not a traveler.
        Initialize();

        // [GIVEN] An expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] An approved spend request WITHOUT the user as a traveler.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);

        // [GIVEN] An expense report header for that user.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [WHEN] The spend request is set on the header.
        asserterror ExpenseReportHeader.Validate("Spend Request No.", SpendRequest."No.");

        // [THEN] It fails because the expense user is not a traveler.
        Assert.ExpectedError(NotTravelerErr);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure PostReportLineSpendReqOverridesHeader()
    var
        HeaderSpendRequest: Record "Spend Request";
        LineSpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 616928] A line-level spend request overrides the header's; only the line's request is closed on posting.
        Initialize();
        CloseConfirmReply := true;

        // [GIVEN] An expense user whose posting group has an expense account set up.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] An expense category and a payment method.
        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Two approved spend requests (header and line) with the user as traveler on both.
        CreateSpendRequestWithTraveler(HeaderSpendRequest, ExpenseUser."No.", HeaderSpendRequest.Status::Approved);
        CreateSpendRequestWithTraveler(LineSpendRequest, ExpenseUser."No.", LineSpendRequest.Status::Approved);

        // [GIVEN] An expense report whose header references the header spend request.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        ExpenseReportHeader.Validate("Spend Request No.", HeaderSpendRequest."No.");
        ExpenseReportHeader.Modify(true);

        // [GIVEN] A refundable line that references the line spend request instead.
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', LibraryRandom.RandIntInRange(100, 1000));
        ExpenseReportLine.Validate("Spend Request No.", LineSpendRequest."No.");
        ExpenseReportLine.Modify(true);

        // [WHEN] The report is Released and posted.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The line's spend request is closed and the header's remains approved.
        LineSpendRequest.Get(LineSpendRequest."No.");
        Assert.AreEqual(LineSpendRequest.Status::Closed, LineSpendRequest.Status, SpendReqClosedMsg);
        HeaderSpendRequest.Get(HeaderSpendRequest."No.");
        Assert.AreEqual(HeaderSpendRequest.Status::Approved, HeaderSpendRequest.Status, HeaderSpendReqRemainsApprovedMsg);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler')]
    procedure PostReportMixedLinesSpendsRefundableOnly()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedSpentLCY: Decimal;
    begin
        // [SCENARIO 616928] In a report with both refundable and non-refundable lines, only the refundable line contributes to the spend request's spent amount.
        Initialize();
        CloseConfirmReply := true;

        // [GIVEN] A report with a refundable line linked to a Released spend request and a non-refundable line.
        ExpectedSpentLCY := CreateReportWithRefundableAndNonRefundableLines(ExpenseReportHeader, SpendRequest);

        // [WHEN] The report is Released and posted.
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] The spent amount reflects only the refundable line.
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.CalcFields("Total Spent Amount (LCY)");
        Assert.AreEqual(ExpectedSpentLCY, SpendRequest."Total Spent Amount (LCY)", SpendReqSpentAmountMsg);
    end;

    [Test]
    [HandlerFunctions('SpendReqConfirmHandler,SpendReqGLPostingPreviewHandler')]
    procedure SpendReqLinkShownInExpenseReportPostingPreview()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO 616928] Preview posting an expense report linked to a spend request lists its Spend Request To G/L Link entries.
        Initialize();
        CloseConfirmReply := true;

        // [GIVEN] An expense report with a refundable line linked to a Released spend request.
        CreateAndPostExpenseReportWithSpendRequest(ExpenseReportHeader, SpendRequest, 1);

        // [GIVEN] The report is Released and the transaction is committed so it can be previewed.
        ExpenseReportHeader.PerformManualRelease();
        Commit();

        // [WHEN] The expense report is preview posted.
        asserterror ExpenseReportHeader.Preview(ExpenseReportHeader);

        // [THEN] The preview lists the Spend Request To G/L Link entries (asserted in the page handler).
        // Posting preview intentionally exits with Error(''); the handler proves the expected entries were shown.
        Assert.ExpectedError('');
        Assert.IsTrue(SpendReqPreviewShown, SpendReqLinkPreviewMsg);
    end;

    [Test]
    procedure TravelReqCategoryLineAcceptsExpenseCategory()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        ExpenseCategory: Record "Expense Category";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 647188] A Category line accepts an expense category.
        Initialize();

        // [GIVEN] An open travel request and an active expense category.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] A line whose type is Category.
        LibraryExpense.CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", 0);
        SpendRequestDetail.Validate(Type, SpendRequestDetail.Type::Category);

        // [WHEN] An expense category is assigned to the line.
        SpendRequestDetail.Validate("Expense Category Code", ExpenseCategory.Code);
        SpendRequestDetail.Modify(true);

        // [THEN] The expense category is stored on the line.
        Assert.AreEqual(ExpenseCategory.Code, SpendRequestDetail."Expense Category Code", CategoryStoredMsg);
    end;

    [Test]
    procedure TravelReqLumpSumLineRejectsExpenseCategory()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        ExpenseCategory: Record "Expense Category";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 647188] A Lump Sum line cannot carry an expense category.
        Initialize();

        // [GIVEN] An open travel request, an expense category, and a Lump Sum line.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", 0);
        SpendRequestDetail.Validate(Type, SpendRequestDetail.Type::"Lump Sum");

        // [WHEN] Assigning an expense category to the Lump Sum line.
        asserterror SpendRequestDetail.Validate("Expense Category Code", ExpenseCategory.Code);

        // [THEN] It fails because a category is only allowed on a Category line.
        Assert.ExpectedError(StrSubstNo(CategoryLineOnlyErr, SpendRequestDetail.FieldCaption("Expense Category Code"), SpendRequestDetail.FieldCaption(Type), SpendRequestDetail.Type::Category));
    end;

    [Test]
    procedure TravelReqLumpSumTypeClearsExpenseCategory()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        ExpenseCategory: Record "Expense Category";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 647188] Switching a Category line to Lump Sum clears its expense category.
        Initialize();

        // [GIVEN] A Category line with an expense category assigned.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", 0);
        SpendRequestDetail.Validate(Type, SpendRequestDetail.Type::Category);
        SpendRequestDetail.Validate("Expense Category Code", ExpenseCategory.Code);
        SpendRequestDetail.Modify(true);

        // [WHEN] The line type is changed to Lump Sum.
        SpendRequestDetail.Validate(Type, SpendRequestDetail.Type::"Lump Sum");

        // [THEN] The expense category is cleared.
        Assert.AreEqual('', SpendRequestDetail."Expense Category Code", CategoryClearedMsg);
    end;

    [Test]
    procedure TravelReqSupportsMixedLineTypes()
    var
        SpendRequest: Record "Spend Request";
        CategoryLine: Record "Spend Request Detail";
        LumpSumLine: Record "Spend Request Detail";
        ExpenseCategory: Record "Expense Category";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 647188] Category and Lump Sum lines coexist within the same travel request.
        Initialize();

        // [GIVEN] An open travel request and an expense category.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] A Category line with a category.
        LibraryExpense.CreateSpendRequestDetail(CategoryLine, SpendRequest."No.", 0);
        CategoryLine.Validate(Type, CategoryLine.Type::Category);
        CategoryLine.Validate("Expense Category Code", ExpenseCategory.Code);
        CategoryLine.Modify(true);

        // [WHEN] A Lump Sum line is added to the same request.
        LibraryExpense.CreateSpendRequestDetail(LumpSumLine, SpendRequest."No.", 0);
        LumpSumLine.Validate(Type, LumpSumLine.Type::"Lump Sum");
        LumpSumLine.Modify(true);

        // [THEN] Both lines keep their own type and category rule.
        Assert.AreEqual(CategoryLine.Type::Category, CategoryLine.Type, MixedTypesMsg);
        Assert.AreEqual(LumpSumLine.Type::"Lump Sum", LumpSumLine.Type, MixedTypesMsg);
        Assert.AreEqual(ExpenseCategory.Code, CategoryLine."Expense Category Code", CategoryStoredMsg);
        Assert.AreEqual('', LumpSumLine."Expense Category Code", CategoryClearedMsg);
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Spend Request Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        CloseConfirmCount := 0;
        CloseConfirmReply := false;
        SpendReqPreviewShown := false;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify();

        LibraryExpense.UpdateEnableAgentInAgentSetup(false);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Spend Request Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Spend Request Test");
    end;

    local procedure CreateExpenseReportWithRefundableLine(var ExpenseReportLine: Record "Expense Report Line"; var ExpenseUser: Record "Expense User"; Refundable: Boolean)
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, Refundable, '', LibraryRandom.RandIntInRange(100, 1000));
    end;

    local procedure CreateSpendRequestWithTraveler(var SpendRequest: Record "Spend Request"; ExpenseUserNo: Code[20]; NewStatus: Enum "Spend Request Status")
    begin
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateSpendRequestDetail(SpendRequest."No.", LibraryRandom.RandIntInRange(100000, 100000));
        LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUserNo);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, NewStatus);
    end;

    local procedure PrepareTravelRequestWithAPIDates(var SpendRequest: Record "Spend Request"; StartDate: Date; EndDate: Date; StartDateProvided: Boolean; EndDateProvided: Boolean)
    begin
        Clear(SpendRequest);
        SpendRequest.Init();
        SpendRequest."Document Type" := SpendRequest."Document Type"::"Travel Request";
        SpendRequest.SetExpectedDatesForAPIInsert(StartDate, EndDate, StartDateProvided, EndDateProvided);
    end;

    local procedure AssertTravelRequestDates(SpendRequest: Record "Spend Request"; StartDate: Date; EndDate: Date)
    begin
        Assert.AreEqual(StartDate, SpendRequest."Expected Start Date", 'The expected start date must match the effective input.');
        Assert.AreEqual(EndDate, SpendRequest."Expected End Date", 'The expected end date must match the effective input.');
    end;

    local procedure CreateReleasableSpendRequest(var SpendRequest: Record "Spend Request"; var ExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateSpendRequest(SpendRequest);

        SpendRequest.Validate("Requested By", ExpenseUser."Employee No.");
        SpendRequest.Validate("Requested For", ExpenseUser."No.");
        SpendRequest.Validate("Expected Start Date", WorkDate());
        SpendRequest.Validate("Expected End Date", WorkDate() + 7);
        SpendRequest.Validate("Travel Policy Acknowledgment", true);
        SpendRequest.Modify(true);
    end;

    local procedure CreateApproverForExpenseUser(var ApproverExpenseUser: Record "Expense User"; ExpenseUser: Record "Expense User")
    var
        ExpenseApprovalSetup: Record "Expense Approval Setup";
    begin
        CreateApprover(ApproverExpenseUser);
        if ExpenseApprovalSetup.Get(ExpenseUser."No.") then begin
            ExpenseApprovalSetup.Validate("Approver No.", ApproverExpenseUser."No.");
            ExpenseApprovalSetup.Modify(true);
        end else
            LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, ExpenseUser."No.", ApproverExpenseUser."No.");
    end;

    local procedure CreateApprover(var ApproverExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(ApproverExpenseUser);
        ApproverExpenseUser."Can Approve" := true;
        ApproverExpenseUser."User Id For Approvals" := CopyStr(UserId(), 1, MaxStrLen(ApproverExpenseUser."User Id For Approvals"));
        ApproverExpenseUser.Modify(true);
    end;

    local procedure SetDefaultApprover(ApproverExpenseUserNo: Code[20])
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Default Approver No.", ApproverExpenseUserNo);
        ExpenseAgentSetup.Modify(true);
    end;

    local procedure VerifyDefaultApproverFilter(DefaultExpenseUserNo: Code[20]; OtherExpenseUserNo: Code[20])
    var
        DefaultTravelRequest: Record "Spend Request";
        OtherTravelRequest: Record "Spend Request";
        FilteredTravelRequest: Record "Spend Request";
        DefaultExpenseUser: Record "Expense User";
        OtherExpenseUser: Record "Expense User";
        DefaultApprover: Record "Expense User";
        OtherApprover: Record "Expense User";
        TravelRequestApproval: Codeunit "Travel Request Approval";
    begin
        Initialize();

        // [GIVEN] A default approver, an unassigned request, and a request assigned to another approver.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);
        CreateApprover(DefaultApprover);
        SetDefaultApprover(DefaultApprover."No.");
        CreateReleasableSpendRequest(DefaultTravelRequest, DefaultExpenseUser);
        if DefaultExpenseUserNo <> '' then begin
            DefaultExpenseUser.Rename(DefaultExpenseUserNo);
            DefaultTravelRequest.Get(DefaultTravelRequest."No.");
            DefaultTravelRequest.TestField("Requested For", DefaultExpenseUserNo);
        end;
        LibraryExpense.SetSpendRequestStatus(DefaultTravelRequest, DefaultTravelRequest.Status::Released);
        CreateReleasableSpendRequest(OtherTravelRequest, OtherExpenseUser);
        if OtherExpenseUserNo <> '' then begin
            OtherExpenseUser.Rename(OtherExpenseUserNo);
            OtherTravelRequest.Get(OtherTravelRequest."No.");
            OtherTravelRequest.TestField("Requested For", OtherExpenseUserNo);
        end;
        CreateApproverForExpenseUser(OtherApprover, OtherExpenseUser);
        LibraryExpense.SetSpendRequestStatus(OtherTravelRequest, OtherTravelRequest.Status::Released);

        // [WHEN] The default approver's filter is applied to pending travel requests.
        FilteredTravelRequest.SetRange("Document Type", FilteredTravelRequest."Document Type"::"Travel Request");
        FilteredTravelRequest.SetRange(Status, FilteredTravelRequest.Status::Released);
        TravelRequestApproval.ApplyApproverFilter(FilteredTravelRequest, DefaultApprover.SystemId);

        // [THEN] Only the literal unassigned user's request is visible, not the other approver's request.
        FilteredTravelRequest.SetRange("No.", DefaultTravelRequest."No.");
        Assert.IsFalse(FilteredTravelRequest.IsEmpty(), DefaultTravelRequestVisibleMsg);
        FilteredTravelRequest.SetRange("No.", OtherTravelRequest."No.");
        Assert.IsTrue(FilteredTravelRequest.IsEmpty(), UnassignedTravelRequestHiddenMsg);
    end;

    local procedure CreatePostedTravelRequestReport(var SpendRequest: Record "Spend Request"; var PostedExpenseReportHeader: Record "Posted Expense Report Header"; AssignOnHeader: Boolean)
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        BalancingExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        if AssignOnHeader then
            CreateAndPostExpenseReportWithSpendRequestAssignedOnHeader(ExpenseReportHeader, SpendRequest, 1)
        else
            CreateAndPostExpenseReportWithSpendRequest(ExpenseReportHeader, SpendRequest, 1);

        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.FindFirst();
        LibraryExpense.CreateExpenseReportLine(
            BalancingExpenseReportLine, ExpenseReportHeader, ExpenseReportHeader."Expense User No.",
            ExpenseReportLine."Expense Category", ExpenseReportLine."Payment Method Code", true,
            ExpenseReportLine."Expense Currency Code", -ExpenseReportLine.Amount);
        if not AssignOnHeader then begin
            BalancingExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");
            BalancingExpenseReportLine.Modify(true);
        end;

        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        PostedExpenseReportHeader.Get(ExpenseReportHeader."Posting No.");
        SpendRequest.Get(SpendRequest."No.");
        SpendRequest.CalcFields("Total Spent Amount (LCY)");
        Assert.AreEqual(0, SpendRequest."Total Spent Amount (LCY)", 'Offsetting posted amounts must leave zero net spend.');
    end;

    local procedure CreateAndPostExpenseReportWithSpendRequest(var ExpenseReportHeader: Record "Expense Report Header"; var SpendRequest: Record "Spend Request"; NumberOfLines: Integer)
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportLine: Record "Expense Report Line";
        Index: Integer;
    begin
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        LibraryExpense.CreateSpendRequestDetail(SpendRequest."No.", LibraryRandom.RandIntInRange(100000, 100000));
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        for Index := 1 to NumberOfLines do begin
            LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', LibraryRandom.RandIntInRange(100, 1000));
            ExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");
            ExpenseReportLine.Modify(true);
        end;
    end;

    local procedure CreateAndPostExpenseReportWithSpendRequestAssignedOnHeader(var ExpenseReportHeader: Record "Expense Report Header"; var SpendRequest: Record "Spend Request"; NumberOfLines: Integer)
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportLine: Record "Expense Report Line";
        Index: Integer;
    begin
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        LibraryExpense.CreateSpendRequestDetail(SpendRequest."No.", LibraryRandom.RandIntInRange(100000, 100000));
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Approved);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        // The spend request is set once on the header; every line inherits it during posting.
        ExpenseReportHeader.Validate("Spend Request No.", SpendRequest."No.");
        ExpenseReportHeader.Modify(true);

        for Index := 1 to NumberOfLines do
            LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', LibraryRandom.RandIntInRange(100, 1000));
    end;

    local procedure CreateReportWithRefundableAndNonRefundableLines(var ExpenseReportHeader: Record "Expense Report Header"; var SpendRequest: Record "Spend Request") RefundableAmountLCY: Decimal
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // An expense user whose posting group has an expense account set up.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // A refundable category and a payment method.
        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // An approved spend request with the user as a traveler.
        CreateSpendRequestWithTraveler(SpendRequest, ExpenseUser."No.", SpendRequest.Status::Approved);

        // A report with a refundable line linked to the spend request; capture its refundable amount.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, ExpensePaymentMethod.Code, true, '', LibraryRandom.RandIntInRange(100, 1000));
        ExpenseReportLine.Validate("Spend Request No.", SpendRequest."No.");
        ExpenseReportLine.Modify(true);
        RefundableAmountLCY := ExpenseReportLine."Refundable Amount (LCY)";

        // A non-refundable line on the same report.
        AddNonRefundableLine(ExpenseReportHeader, ExpenseUser."No.");
    end;

    local procedure AddNonRefundableLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20])
    var
        NonRefundableCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        LibraryExpense.CreateExpensePostingGroup(ExpensePostingGroup);
        LibraryExpense.CreateExpenseCategoryWithSubCategory(NonRefundableCategory, NonRefundableCategory."Reimbursement Type"::"Company Paid", NonRefundableCategory."Expense Detail Required"::" ", false);
        NonRefundableCategory.Validate("Posting Group", ExpensePostingGroup.Code);
        NonRefundableCategory.Modify(true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUserNo, NonRefundableCategory.Code, ExpensePaymentMethod.Code, false, '', LibraryRandom.RandIntInRange(100, 1000));
    end;

    local procedure DeleteTravelers(SpendRequestNo: Code[20])
    var
        Traveler: Record Traveler;
    begin
        Traveler.SetRange("Spend Request No.", SpendRequestNo);
        Traveler.DeleteAll();
    end;

    local procedure SetOwnerScopedTravelRequest(var TravelRequestsAPI: Page "Travel Requests API"; var SpendRequest: Record "Spend Request"; ExpenseUserSystemId: Guid)
    var
        OriginalFilterGroup: Integer;
    begin
        OriginalFilterGroup := SpendRequest.FilterGroup(4);
        SpendRequest.SetRange("Requested By User Id Filter", ExpenseUserSystemId);
        SpendRequest.FilterGroup(OriginalFilterGroup);
        TravelRequestsAPI.SetTableView(SpendRequest);
        TravelRequestsAPI.SetRecord(SpendRequest);
    end;

    [PageHandler]
    procedure SpendReqGLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Spend Request To G/L Link"));
        Assert.IsTrue(GLPostingPreview.First(), SpendReqLinkPreviewMsg);
        SpendReqPreviewShown := true;
        GLPostingPreview.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure SpendReqConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, CloseConfirmTok) > 0 then begin
            CloseConfirmCount += 1;
            Reply := CloseConfirmReply;
        end else
            Reply := true;
    end;
}
