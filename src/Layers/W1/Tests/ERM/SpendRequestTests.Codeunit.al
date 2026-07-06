namespace Microsoft.Finance.Tests.ERM;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SpendRequest;
using Microsoft.HumanResources.Employee;

codeunit 134241 "Spend Request Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Spend Request]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Spend Request Tests");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Spend Request Tests");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Spend Request Tests");
    end;

    local procedure CreateSpendRequest(var SpendRequest: Record "Spend Request")
    var
        GLAccount: Record "G/L Account";
        Employee: Record Employee;
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        LibraryERM.CreateGLAccount(GLAccount);

        SpendRequest.Init();
        SpendRequest.Insert(true);
        SpendRequest.Validate("Requested By", Employee."No.");
        SpendRequest.Validate("G/L Account No.", GLAccount."No.");
        SpendRequest.Validate(Purpose, LibraryUtility.GenerateGUID());
        SpendRequest.Modify(true);
    end;

    local procedure CreateSpendRequestWithAmount(var SpendRequest: Record "Spend Request"; Amount: Decimal)
    begin
        CreateSpendRequest(SpendRequest);
        SpendRequest.Validate("Total Expected Amount", Amount);
        SpendRequest.Modify(true);
    end;

    local procedure CreateSpendRequestDetail(var SpendRequestDetail: Record "Spend Request Detail"; SpendRequestNo: Code[20]; Amount: Decimal)
    begin
        SpendRequestDetail.Init();
        SpendRequestDetail."Spend Request No." := SpendRequestNo;
        SpendRequestDetail."Line No." := GetNextDetailLineNo(SpendRequestNo);
        SpendRequestDetail.Insert(true);
        SpendRequestDetail.Validate(Description, LibraryUtility.GenerateGUID());
        SpendRequestDetail.Validate("Expected Amount", Amount);
        SpendRequestDetail.Modify(true);
    end;

    local procedure GetNextDetailLineNo(SpendRequestNo: Code[20]): Integer
    var
        SpendRequestDetail: Record "Spend Request Detail";
    begin
        SpendRequestDetail.SetRange("Spend Request No.", SpendRequestNo);
        if SpendRequestDetail.FindLast() then
            exit(SpendRequestDetail."Line No." + 10000);
        exit(10000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSpendRequestAssignsNo()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Creating a spend request auto-assigns a number.
        Initialize();

        // [WHEN] A spend request is created.
        SpendRequest.Init();
        SpendRequest.Insert(true);

        // [THEN] The No. field is populated.
        Assert.AreNotEqual('', SpendRequest."No.", 'No. should be auto-assigned on insert.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSpendRequestDefaultStatusIsOpen()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] A new spend request has Status = Open by default.
        Initialize();

        // [WHEN] A spend request is created.
        CreateSpendRequest(SpendRequest);

        // [THEN] Status is Open.
        Assert.AreEqual(SpendRequest.Status::Open, SpendRequest.Status, 'Default status should be Open.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetTotalExpectedAmountUpdatesLCY()
    var
        SpendRequest: Record "Spend Request";
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO] Setting Total Expected Amount calculates Total Expected Amount (LCY).
        Initialize();
        ExpectedAmount := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] A spend request in Open status with no currency (LCY).
        CreateSpendRequest(SpendRequest);

        // [WHEN] Total Expected Amount is validated.
        SpendRequest.Validate("Total Expected Amount", ExpectedAmount);
        SpendRequest.Modify(true);

        // [THEN] Total Expected Amount (LCY) equals Total Expected Amount when currency is blank.
        Assert.AreEqual(ExpectedAmount, SpendRequest."Total Expected Amount (LCY)",
            'Total Expected Amount (LCY) should equal Total Expected Amount when no currency is set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotModifyReleasedSpendRequest()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Modifying a released spend request raises an error.
        Initialize();

        // [GIVEN] A spend request with Status = Released.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();

        // [WHEN] Attempting to modify the record.
        asserterror SpendRequest.Modify(true);

        // [THEN] An error is raised because Status is not Open.
        Assert.ExpectedTestFieldError(SpendRequest.FieldCaption(Status), Format(SpendRequest.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndDateBeforeStartDateErrors()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Setting Expected End Date before Expected Start Date raises an error.
        Initialize();

        // [GIVEN] A spend request with a start date.
        CreateSpendRequest(SpendRequest);
        SpendRequest.Validate("Expected Start Date", WorkDate());
        SpendRequest.Modify(true);

        // [WHEN] Expected End Date is set before the start date.
        asserterror SpendRequest.Validate("Expected End Date", CalcDate('<-1D>', WorkDate()));

        // [THEN] An error is raised.
        Assert.ExpectedError('Expected End Date cannot be before Expected Start Date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidStartAndEndDateSucceeds()
    var
        SpendRequest: Record "Spend Request";
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENARIO] Setting Expected End Date on or after Expected Start Date succeeds.
        Initialize();
        StartDate := WorkDate();
        EndDate := CalcDate('<+7D>', WorkDate());

        // [GIVEN] A spend request.
        CreateSpendRequest(SpendRequest);

        // [WHEN] Valid start and end dates are set.
        SpendRequest.Validate("Expected Start Date", StartDate);
        SpendRequest.Validate("Expected End Date", EndDate);
        SpendRequest.Modify(true);

        // [THEN] Both dates are stored correctly.
        Assert.AreEqual(StartDate, SpendRequest."Expected Start Date", 'Expected Start Date not stored.');
        Assert.AreEqual(EndDate, SpendRequest."Expected End Date", 'Expected End Date not stored.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotDeleteSpendRequestWithPostedExpenses()
    var
        SpendRequest: Record "Spend Request";
        SpendReqToGLLink: Record "Spend Request To G/L Link";
    begin
        // [SCENARIO] A spend request with posted expenses (G/L links with amounts) cannot be deleted.
        Initialize();

        // [GIVEN] A spend request with a G/L link record.
        CreateSpendRequest(SpendRequest);
        SpendReqToGLLink.Init();
        SpendReqToGLLink."Spend Request No." := SpendRequest."No.";
        SpendReqToGLLink."G/L Entry No." := 1;
        SpendReqToGLLink.Amount := LibraryRandom.RandDec(100, 2);
        SpendReqToGLLink.Insert();

        // [WHEN] Attempting to delete the spend request.
        asserterror SpendRequest.Delete(true);

        // [THEN] An error is raised because expenses are posted.
        Assert.ExpectedError('cannot delete a spend request that has expenses posted against it');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSpendRequestWithoutExpensesSucceeds()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        SpendRequestNo: Code[20];
    begin
        // [SCENARIO] A spend request without posted expenses can be deleted, along with its detail lines.
        Initialize();

        // [GIVEN] A spend request with a detail line but no G/L links.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequestNo := SpendRequest."No.";
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequestNo, SpendRequest."Total Expected Amount");

        // [WHEN] The spend request is deleted.
        SpendRequest.Delete(true);

        // [THEN] The spend request and its details are removed.
        Assert.IsFalse(SpendRequest.Get(SpendRequestNo), 'Spend request should be deleted.');
        SpendRequestDetail.SetRange("Spend Request No.", SpendRequestNo);
        Assert.IsTrue(SpendRequestDetail.IsEmpty(), 'Detail lines should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRemainingAmountLCYReturnsCorrectValue()
    var
        SpendRequest: Record "Spend Request";
        SpendReqToGLLink: Record "Spend Request To G/L Link";
        ExpectedAmount: Decimal;
        SpentAmount: Decimal;
    begin
        // [SCENARIO] GetRemainingAmountLCY returns expected minus spent.
        Initialize();
        ExpectedAmount := LibraryRandom.RandDecInRange(500, 1000, 2);
        SpentAmount := LibraryRandom.RandDec(400, 2);

        // [GIVEN] A spend request with expected amount and a G/L link with spent amount.
        CreateSpendRequestWithAmount(SpendRequest, ExpectedAmount);
        SpendReqToGLLink.Init();
        SpendReqToGLLink."Spend Request No." := SpendRequest."No.";
        SpendReqToGLLink."G/L Entry No." := 1;
        SpendReqToGLLink.Amount := SpentAmount;
        SpendReqToGLLink.Insert();

        // [WHEN] Total Spent Amount (LCY) is calculated.
        SpendRequest.CalcFields("Total Spent Amount (LCY)");

        // [THEN] The remaining amount is total expected minus total spent.
        Assert.AreEqual(ExpectedAmount - SpentAmount,
            SpendRequest."Total Expected Amount (LCY)" - SpendRequest."Total Spent Amount (LCY)",
            'Remaining amount should be expected minus spent.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLineInheritsGLAccountFromHeader()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
    begin
        // [SCENARIO] A new detail line inherits the G/L Account No. from the header.
        Initialize();

        // [GIVEN] A spend request with a G/L Account No. and expected amount.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));

        // [WHEN] A detail line is inserted.
        SpendRequestDetail.Init();
        SpendRequestDetail."Spend Request No." := SpendRequest."No.";
        SpendRequestDetail."Line No." := 10000;
        SpendRequestDetail.Insert(true);

        // [THEN] The G/L Account No. is copied from the header.
        Assert.AreEqual(SpendRequest."G/L Account No.", SpendRequestDetail."G/L Account No.",
            'Detail line should inherit G/L Account No. from header.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLineAmountUpdatesHeaderTotal()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        DetailAmount: Decimal;
    begin
        // [SCENARIO] Validating a detail line amount updates the header Total Expected Amount (LCY).
        Initialize();
        DetailAmount := LibraryRandom.RandDec(500, 2);

        // [GIVEN] A spend request with an expected amount large enough for the detail.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] A detail line is created with an amount.
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", DetailAmount);

        // [THEN] The header Total Expected Amount (LCY) is updated.
        SpendRequest.Get(SpendRequest."No.");
        Assert.IsTrue(SpendRequest."Total Expected Amount (LCY)" >= DetailAmount,
            'Header Total Expected Amount (LCY) should include detail amount.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLineDeletionUpdatesHeaderTotal()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        OriginalAmount: Decimal;
        DetailAmount: Decimal;
    begin
        // [SCENARIO] Deleting a detail line reduces the header Total Expected Amount (LCY).
        Initialize();
        OriginalAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        DetailAmount := LibraryRandom.RandDec(500, 2);

        // [GIVEN] A spend request with a detail line.
        CreateSpendRequestWithAmount(SpendRequest, OriginalAmount);
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", DetailAmount);

        SpendRequest.Get(SpendRequest."No.");
        OriginalAmount := SpendRequest."Total Expected Amount (LCY)";

        // [WHEN] The detail line is deleted.
        SpendRequestDetail.Delete(true);

        // [THEN] The header total is reduced by the detail amount.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(OriginalAmount - DetailAmount, SpendRequest."Total Expected Amount (LCY)",
            'Deleting detail should reduce header total.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotInsertDetailOnReleasedRequest()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
    begin
        // [SCENARIO] Cannot insert a detail line on a released spend request.
        Initialize();

        // [GIVEN] A released spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();

        // [WHEN] Attempting to insert a detail line.
        SpendRequestDetail.Init();
        SpendRequestDetail."Spend Request No." := SpendRequest."No.";
        SpendRequestDetail."Line No." := 10000;
        asserterror SpendRequestDetail.Insert(true);

        // [THEN] An error is raised because the request is not Open.
        Assert.ExpectedTestFieldError(SpendRequest.FieldCaption(Status), Format(SpendRequest.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotDeleteDetailOnApprovedRequest()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
    begin
        // [SCENARIO] Cannot delete a detail line on an approved spend request.
        Initialize();

        // [GIVEN] A spend request with a detail line that is then approved.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", SpendRequest."Total Expected Amount");
        SpendRequest.Status := SpendRequest.Status::Approved;
        SpendRequest.Modify();

        // [WHEN] Attempting to delete the detail line.
        asserterror SpendRequestDetail.Delete(true);

        // [THEN] An error is raised.
        Assert.ExpectedTestFieldError(SpendRequest.FieldCaption(Status), Format(SpendRequest.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReOpenFromReleasedSucceeds()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] A released spend request can be reopened.
        Initialize();

        // [GIVEN] A released spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();

        // [WHEN] Status is set back to Open.
        SpendRequest.Status := SpendRequest.Status::Open;
        SpendRequest.Modify();

        // [THEN] The status is Open.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Open, SpendRequest.Status, 'Status should be Open after reopen.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetTotalAmountLessThanSumOfLines()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        LineAmount: Decimal;
    begin
        // [SCENARIO] Cannot set Total Expected Amount to less than the sum of detail line amounts.
        Initialize();
        LineAmount := LibraryRandom.RandDecInRange(500, 1000, 2);

        // [GIVEN] A spend request with a detail line.
        CreateSpendRequestWithAmount(SpendRequest, LineAmount + LibraryRandom.RandDecInRange(100, 200, 2));
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", LineAmount);

        // [WHEN] Attempting to set the total amount less than the line sum.
        SpendRequest.Get(SpendRequest."No.");
        asserterror SpendRequest.Validate("Total Expected Amount", LineAmount - 1);

        // [THEN] An error is raised.
        Assert.ExpectedError('cannot specify an amount less than the total of the lines');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpendRequestTypeDefaultIsExpense()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] A new spend request defaults to Expense type.
        Initialize();

        // [WHEN] A spend request is created.
        CreateSpendRequest(SpendRequest);

        // [THEN] Type is Expense.
        Assert.AreEqual(SpendRequest.Type::Expense, SpendRequest.Type, 'Default type should be Expense.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLLinkCreationTracksSpending()
    var
        SpendRequest: Record "Spend Request";
        SpendReqToGLLink: Record "Spend Request To G/L Link";
        SpentAmount1: Decimal;
        SpentAmount2: Decimal;
    begin
        // [SCENARIO] Multiple G/L link records correctly sum up in Total Spent Amount (LCY).
        Initialize();
        SpentAmount1 := LibraryRandom.RandDec(200, 2);
        SpentAmount2 := LibraryRandom.RandDec(300, 2);

        // [GIVEN] A spend request with two G/L link entries.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDecInRange(1000, 2000, 2));

        SpendReqToGLLink.Init();
        SpendReqToGLLink."Spend Request No." := SpendRequest."No.";
        SpendReqToGLLink."G/L Entry No." := 1;
        SpendReqToGLLink.Amount := SpentAmount1;
        SpendReqToGLLink.Insert();

        SpendReqToGLLink.Init();
        SpendReqToGLLink."Spend Request No." := SpendRequest."No.";
        SpendReqToGLLink."G/L Entry No." := 2;
        SpendReqToGLLink.Amount := SpentAmount2;
        SpendReqToGLLink.Insert();

        // [WHEN] Total Spent Amount is calculated.
        SpendRequest.CalcFields("Total Spent Amount (LCY)");

        // [THEN] It equals the sum of linked amounts.
        Assert.AreEqual(SpentAmount1 + SpentAmount2, SpendRequest."Total Spent Amount (LCY)",
            'Total Spent Amount (LCY) should sum all G/L links.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalLineAmountFlowFieldCalculatesCorrectly()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // [SCENARIO] Total Line Amount (LCY) flow field sums all detail line amounts.
        Initialize();
        Amount1 := LibraryRandom.RandDec(300, 2);
        Amount2 := LibraryRandom.RandDec(400, 2);

        // [GIVEN] A spend request with two detail lines.
        CreateSpendRequestWithAmount(SpendRequest, Amount1 + Amount2 + LibraryRandom.RandDec(100, 2));
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", Amount1);
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", Amount2);

        // [WHEN] Total Line Amount is calculated.
        SpendRequest.CalcFields("Total Line Amount (LCY)");

        // [THEN] It equals the sum of all detail line amounts.
        Assert.AreEqual(Amount1 + Amount2, SpendRequest."Total Line Amount (LCY)",
            'Total Line Amount (LCY) should sum all detail lines.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpendRequestCardPageOpens()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] The Spend Request Card page opens correctly for a given spend request.
        Initialize();

        // [GIVEN] A spend request.
        CreateSpendRequest(SpendRequest);

        // [WHEN] The card page is opened.
        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [THEN] The fields show the correct values.
        Assert.AreEqual(SpendRequest."No.", Format(SpendRequestCard."No.".Value()),
            'Card page should show the correct No.');
        Assert.AreEqual(Format(SpendRequest.Status::Open), Format(SpendRequestCard.Status.Value()),
            'Card page should show Open status.');
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpendRequestListPageOpens()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestList: TestPage "Spend Request List";
    begin
        // [SCENARIO] The Spend Request List page opens and shows the spend request.
        Initialize();

        // [GIVEN] A spend request.
        CreateSpendRequest(SpendRequest);

        // [WHEN] The list page is opened.
        SpendRequestList.OpenView();
        SpendRequestList.GoToRecord(SpendRequest);

        // [THEN] The correct record is displayed.
        Assert.AreEqual(SpendRequest."No.", Format(SpendRequestList."No.".Value()),
            'List page should show the correct spend request.');
        SpendRequestList.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseActionSetsStatusToReleased()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] The Release action on the card page sets the status to Released.
        Initialize();

        // [GIVEN] An open spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [WHEN] The Release action is invoked.
        SpendRequestCard.Release.Invoke();

        // [THEN] The status is Released.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Released, SpendRequest.Status, 'Status should be Released.');
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApproveActionSetsStatusToApproved()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] The Approve action on the card page sets the status to Approved.
        Initialize();

        // [GIVEN] An open spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [WHEN] The Approve action is invoked.
        SpendRequestCard.Approve.Invoke();

        // [THEN] The status is Approved and approval metadata is set.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Approved, SpendRequest.Status, 'Status should be Approved.');
        Assert.AreNotEqual(0DT, SpendRequest."Approved/Rejected At", 'Approved At should be set.');
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectActionRequiresReleasedStatus()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] The Reject action requires the spend request to be in Released status.
        Initialize();

        // [GIVEN] An open spend request (not Released).
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [WHEN] The Reject action is invoked.
        asserterror SpendRequestCard.Reject.Invoke();

        // [THEN] An error is raised because Status is not Released.
        Assert.ExpectedTestFieldError(SpendRequest.FieldCaption(Status), Format(SpendRequest.Status::Released));
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RejectActionFromReleasedSucceeds()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] The Reject action succeeds when the spend request is in Released status.
        Initialize();

        // [GIVEN] A released spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();
        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [WHEN] The Reject action is invoked.
        SpendRequestCard.Reject.Invoke();

        // [THEN] The status is Rejected.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Rejected, SpendRequest.Status, 'Status should be Rejected.');
        Assert.AreNotEqual(0DT, SpendRequest."Approved/Rejected At", 'Rejected At should be set.');
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CloseActionSetsStatusToClosed()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Setting status to Closed marks the spend request as Closed.
        Initialize();

        // [GIVEN] An open spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));

        // [WHEN] The status is set to Closed.
        SpendRequest.Status := SpendRequest.Status::Closed;
        SpendRequest.Modify();

        // [THEN] The status is Closed.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Closed, SpendRequest.Status, 'Status should be Closed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReOpenActionSetsStatusToOpen()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] The ReOpen action sets a released spend request back to Open.
        Initialize();

        // [GIVEN] A released spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();
        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [WHEN] The ReOpen action is invoked.
        SpendRequestCard.ReOpen.Invoke();

        // [THEN] The status is Open.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(SpendRequest.Status::Open, SpendRequest.Status, 'Status should be Open after reopen.');
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReOpenClosedSpendRequest()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] A closed spend request cannot be reopened.
        Initialize();

        // [GIVEN] A closed spend request.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequest.Status := SpendRequest.Status::Closed;
        SpendRequest.Modify();
        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [WHEN] The ReOpen action is invoked.
        asserterror SpendRequestCard.ReOpen.Invoke();

        // [THEN] An error is raised.
        Assert.ExpectedError('closed spend request cannot be reopened');
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReOpenSpendRequestWithExpenses()
    var
        SpendRequest: Record "Spend Request";
        SpendReqToGLLink: Record "Spend Request To G/L Link";
        SpendRequestCard: TestPage "Spend Request Card";
    begin
        // [SCENARIO] A spend request with posted expenses cannot be reopened.
        Initialize();

        // [GIVEN] An approved spend request with posted expenses.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        SpendRequest.Status := SpendRequest.Status::Approved;
        SpendRequest.Modify();

        SpendReqToGLLink.Init();
        SpendReqToGLLink."Spend Request No." := SpendRequest."No.";
        SpendReqToGLLink."G/L Entry No." := 1;
        SpendReqToGLLink.Amount := LibraryRandom.RandDec(100, 2);
        SpendReqToGLLink.Insert();

        SpendRequestCard.OpenEdit();
        SpendRequestCard.GoToRecord(SpendRequest);

        // [WHEN] The ReOpen action is invoked.
        asserterror SpendRequestCard.ReOpen.Invoke();

        // [THEN] An error is raised because there are posted expenses.
        Assert.ExpectedError('posted expenses cannot be reopened');
        SpendRequestCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailLineValidateDescriptionChecksStatus()
    var
        SpendRequest: Record "Spend Request";
        SpendRequestDetail: Record "Spend Request Detail";
    begin
        // [SCENARIO] Validating Description on a detail line checks that the header is Open.
        Initialize();

        // [GIVEN] A spend request with a detail line that is then released.
        CreateSpendRequestWithAmount(SpendRequest, LibraryRandom.RandDec(1000, 2));
        CreateSpendRequestDetail(SpendRequestDetail, SpendRequest."No.", SpendRequest."Total Expected Amount");
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();

        // [WHEN] Attempting to validate Description on the detail line.
        asserterror SpendRequestDetail.Validate(Description, 'Updated');

        // [THEN] An error is raised.
        Assert.ExpectedTestFieldError(SpendRequest.FieldCaption(Status), Format(SpendRequest.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddToTotalExpectedAmountIncrementsHeader()
    var
        SpendRequest: Record "Spend Request";
        OriginalLCY: Decimal;
        Delta: Decimal;
    begin
        // [SCENARIO] AddToTotalExpectedAmount increments the header total by the given delta.
        Initialize();
        OriginalLCY := LibraryRandom.RandDecInRange(500, 1000, 2);
        Delta := LibraryRandom.RandDec(200, 2);

        // [GIVEN] A spend request with a total expected amount.
        CreateSpendRequestWithAmount(SpendRequest, OriginalLCY);

        // [WHEN] AddToTotalExpectedAmount is called with a delta.
        SpendRequest.AddToTotalExpectedAmount(Delta);

        // [THEN] The total expected amount (LCY) is incremented.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(OriginalLCY + Delta, SpendRequest."Total Expected Amount (LCY)",
            'Total Expected Amount (LCY) should be incremented by delta.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddToTotalExpectedAmountZeroDeltaDoesNothing()
    var
        SpendRequest: Record "Spend Request";
        OriginalLCY: Decimal;
    begin
        // [SCENARIO] AddToTotalExpectedAmount with zero delta does not modify the record.
        Initialize();
        OriginalLCY := LibraryRandom.RandDecInRange(500, 1000, 2);

        // [GIVEN] A spend request with a total expected amount.
        CreateSpendRequestWithAmount(SpendRequest, OriginalLCY);

        // [WHEN] AddToTotalExpectedAmount is called with zero.
        SpendRequest.AddToTotalExpectedAmount(0);

        // [THEN] The total expected amount (LCY) is unchanged.
        SpendRequest.Get(SpendRequest."No.");
        Assert.AreEqual(OriginalLCY, SpendRequest."Total Expected Amount (LCY)",
            'Total Expected Amount (LCY) should be unchanged.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpendRequestFieldTypeValidation()
    var
        SpendRequest: Record "Spend Request";
    begin
        // [SCENARIO] Validating the Type field checks that the request is Open.
        Initialize();

        // [GIVEN] A released spend request.
        CreateSpendRequest(SpendRequest);
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();

        // [WHEN] Attempting to validate the Type field.
        asserterror SpendRequest.Validate(Type, SpendRequest.Type::Expense);

        // [THEN] An error is raised because the status is not Open.
        Assert.ExpectedTestFieldError(SpendRequest.FieldCaption(Status), Format(SpendRequest.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpendRequestRequestedByValidation()
    var
        SpendRequest: Record "Spend Request";
        Employee: Record Employee;
    begin
        // [SCENARIO] Validating Requested By on a non-open request raises an error.
        Initialize();

        // [GIVEN] A released spend request.
        CreateSpendRequest(SpendRequest);
        SpendRequest.Status := SpendRequest.Status::Released;
        SpendRequest.Modify();

        LibraryHumanResource.CreateEmployee(Employee);

        // [WHEN] Attempting to validate Requested By.
        asserterror SpendRequest.Validate("Requested By", Employee."No.");

        // [THEN] An error is raised.
        Assert.ExpectedTestFieldError(SpendRequest.FieldCaption(Status), Format(SpendRequest.Status::Open));
    end;
}