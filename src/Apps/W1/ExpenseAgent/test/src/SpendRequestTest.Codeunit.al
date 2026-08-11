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

codeunit 148338 "Spend Request Test"
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
        NotTravelerErr: Label 'is not a traveler on Spend Request', Locked = true;
        PolicyErr: Label 'acknowledge the travel policy', Locked = true;
        NoTravelersErr: Label 'add at least one traveler', Locked = true;
        DestinationErr: Label 'is required for international travel', Locked = true;
        CloseConfirmTok: Label 'close spend request', Locked = true;
        ClosePromptOnceMsg: Label 'The close spend request confirmation should be shown exactly once.';
        SpendReqClosedMsg: Label 'The spend request should be closed after posting.';
        SpendReqNotClosedMsg: Label 'The spend request should not be closed when the confirmation is declined.';
        HeaderSpendReqRemainsApprovedMsg: Label 'The header spend request should remain approved when a line overrides it.';
        ClosedByDocMsg: Label 'Closed By Document No. should be set on the closed spend request.';
        SpendReqReleasedMsg: Label 'The spend request should be released.';
        SpendReqApprovedMsg: Label 'The spend request should be approved automatically when the agent is disabled.';
        SpendReqNoSetMsg: Label 'The Spend Request No. should be assigned to the expense report line.';
        HeaderSpendReqNoSetMsg: Label 'The Spend Request No. should be assigned to the expense report header.';
        HeaderCloseFlagMsg: Label 'The header should store the confirmed close flag.';
        SpendReqSpentAmountMsg: Label 'The spend request Total Spent Amount (LCY) should reflect the posted amount.';
        SpendReqLinkExistsMsg: Label 'A Spend Request To G/L Link entry should be created when the expense report is posted.';
        SpendReqClearedMsg: Label 'The Spend Request No. should be cleared when the line becomes non-refundable.';
        SpendReqCloseClearedMsg: Label 'The Spend Request Close flag should be cleared when the line becomes non-refundable.';
        SpendReqLinkPreviewMsg: Label 'The Spend Request To G/L Link entries should be shown in the expense report posting preview.';

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

        // [GIVEN] A released (not approved) spend request with the user as a traveler.
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

        // [WHEN] The spend request is released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because Requested For is required.
        Assert.ExpectedErrorCode('TestField');
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

        // [WHEN] The spend request is released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because Expected Start Date is required.
        Assert.ExpectedErrorCode('TestField');
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

        // [WHEN] The spend request is released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because Expected End Date is required.
        Assert.ExpectedErrorCode('TestField');
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

        // [WHEN] The spend request is released.
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

        // [WHEN] The spend request is released.
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

        // [WHEN] The spend request is released.
        asserterror ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] Release fails because at least one traveler is required.
        Assert.ExpectedError(NoTravelersErr);
    end;

    [Test]
    procedure ReleaseSpendReqAutoApprovesWhenAgentDisabled()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] With the agent disabled, releasing an expense spend request that meets all prerequisites approves it automatically.
        Initialize();

        // [GIVEN] A releasable spend request with every prerequisite satisfied.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [WHEN] The spend request is released.
        ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] The spend request is approved automatically because there is no agent to approve it.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Approved, SpendRequest.Status, SpendReqApprovedMsg);
    end;

    [Test]
    procedure ReleaseSpendReqStaysReleasedWhenAgentEnabled()
    var
        SpendRequest: Record "Spend Request";
        ExpenseUser: Record "Expense User";
        ReleaseSpendRequest: Codeunit "Release Spend Request";
    begin
        // [SCENARIO 616928] With the agent enabled, releasing an expense spend request leaves it released for the agent to approve.
        Initialize();
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        // [GIVEN] A releasable spend request with every prerequisite satisfied.
        CreateReleasableSpendRequest(SpendRequest, ExpenseUser);

        // [WHEN] The spend request is released.
        ReleaseSpendRequest.Release(SpendRequest);

        // [THEN] The spend request stays released.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Released, SpendRequest.Status, SpendReqReleasedMsg);
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

        // [GIVEN] An expense report with a refundable line linked to a released spend request.
        CreateAndPostExpenseReportWithSpendRequest(ExpenseReportHeader, SpendRequest, 1);

        // [GIVEN] The refundable amount that is expected to be spent against the spend request.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.FindFirst();
        ExpectedSpentLCY := ExpenseReportLine."Refundable Amount (LCY)";

        // [WHEN] The report is released and posted.
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

        // [WHEN] The report is released and posted.
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

        // [WHEN] The report is released and posted.
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

        // [GIVEN] A released spend request.
        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.SetSpendRequestStatus(SpendRequest, SpendRequest.Status::Released);

        // [WHEN] A traveler is added.
        asserterror LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUser."No.");

        // [THEN] It fails because the spend request is not open.
        Assert.ExpectedErrorCode('TestField');
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

        // [WHEN] The report is released and posted.
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

        // [GIVEN] A report with a refundable line linked to a released spend request and a non-refundable line.
        ExpectedSpentLCY := CreateReportWithRefundableAndNonRefundableLines(ExpenseReportHeader, SpendRequest);

        // [WHEN] The report is released and posted.
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

        // [GIVEN] An expense report with a refundable line linked to a released spend request.
        CreateAndPostExpenseReportWithSpendRequest(ExpenseReportHeader, SpendRequest, 1);

        // [GIVEN] The report is released and the transaction is committed so it can be previewed.
        ExpenseReportHeader.PerformManualRelease();
        Commit();

        // [WHEN] The expense report is preview posted.
        asserterror ExpenseReportHeader.Preview(ExpenseReportHeader);

        // [THEN] The preview lists the Spend Request To G/L Link entries (asserted in the page handler).
        Assert.ExpectedError('');
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

    local procedure CreateReleasableSpendRequest(var SpendRequest: Record "Spend Request"; var ExpenseUser: Record "Expense User")
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateSpendRequest(SpendRequest);

        SpendRequest.Validate("Requested For", ExpenseUser."No.");
        SpendRequest.Validate("Expected Start Date", WorkDate());
        SpendRequest.Validate("Expected End Date", WorkDate() + 7);
        SpendRequest.Validate("Travel Policy Acknowledgment", true);
        SpendRequest.Modify(true);
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
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateSpendRequestDetail(SpendRequest."No.", LibraryRandom.RandIntInRange(100000, 100000));
        LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUser."No.");
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
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        LibraryExpense.CreateSpendRequest(SpendRequest);
        LibraryExpense.CreateSpendRequestDetail(SpendRequest."No.", LibraryRandom.RandIntInRange(100000, 100000));
        LibraryExpense.CreateTraveler(SpendRequest."No.", ExpenseUser."No.");
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

    [PageHandler]
    procedure SpendReqGLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Spend Request To G/L Link"));
        Assert.IsTrue(GLPostingPreview.First(), SpendReqLinkPreviewMsg);
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
