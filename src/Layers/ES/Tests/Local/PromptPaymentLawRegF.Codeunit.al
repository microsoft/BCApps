codeunit 147300 "Prompt Payment Law RegF"
{
    // Feature - Prompt Payment Law RegF
    // Purpose - Scenario Test Cases
    // Deliverable - TFS272016
    // 
    // Generic Test Case steps
    // 1. Setup payment terms, non-payment periods and payment days as per each specific scenario
    // 2. Create document with payment setup created above
    // 3. Check the Due Date
    // 
    // Documents:
    // 1. Sale Orders
    // 2. Purchase Orders
    // 3. Service Invoice
    // 4. Sales Journal
    // 5. Service Contract => Service Invoice by signing the contract
    // 6. Service Contract => Service Order by running the batch job 'Create Contract Service Orders'
    // 
    // --------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                      TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // PmtTermsOnVendLedgerEntryAfterPostingPurchOrder,PmtTermsOnCustLedgerEntryAfterPostingSalesOrder                         295950

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ConstDaysInMonth: Integer;
        IsInitialized: Boolean;
        PaymentTermsValidationError: Label 'The %1 exceeds the %2 defined on the %3.', Comment = '[%1] is fieldcaption,[%2] is fieldcaption,[%3] is tablecaption';
        ServiceOrderNotCreated: Label 'Service Order was not created from Service Contract No. %1.';
        UnexpectedErrorOccurred: Label 'Error [%1] was expected but error [%2] was thrown.';
        ValueNotGreaterThanZero: Label 'The value must be greater than or equal to 0.';
        PaymentTableNameOption: Option "Company Information",Customer,Vendor;
        ReqPageAction: Option;
        ReqPageContractNo: Code[20];
        ReqPageEndingDate: Date;
        ReqPageStartingDate: Date;

    [Test]
    [Scope('OnPrem')]
    procedure TestMaxNumOfDaysTillDueDateNegativeError()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTermsPage: TestPage "Payment Terms";
    begin
        Initialize();

        // Pre-Setup
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // Setup
        PaymentTermsPage.OpenEdit();
        PaymentTermsPage.GotoRecord(PaymentTerms);

        // Exercise and Verify
        asserterror PaymentTermsPage."Max. No. of Days till Due Date".SetValue(-1 * LibraryRandom.RandInt(3));
        Assert.IsTrue(StrPos(PaymentTermsPage.GetValidationError(1), ValueNotGreaterThanZero) > 0,
          StrSubstNo(UnexpectedErrorOccurred, ValueNotGreaterThanZero, PaymentTermsPage.GetValidationError(1)));

        // Cleanup
        PaymentTermsPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMaxNumOfDaysTillDueDatePositiveNoError()
    var
        PaymentTerms: Record "Payment Terms";
    begin
        Initialize();

        // Pre-Setup
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // Exercise and Verify
        PaymentTerms."Max. No. of Days till Due Date" := LibraryRandom.RandInt(3);
        PaymentTerms.Modify();

        // Cleanup
        PaymentTerms.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMaxNumOfDaysTillDueDateZeroNoError()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentTermsPage: TestPage "Payment Terms";
    begin
        Initialize();

        // Pre-Setup
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // Exercise and Verify
        PaymentTermsPage.OpenEdit();
        PaymentTermsPage.GotoRecord(PaymentTerms);

        PaymentTermsPage."Max. No. of Days till Due Date".SetValue(0);

        PaymentTermsPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario1a()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
    begin
        // TFS TC 277224
        // Test that Due Date is set correctly on Sales Order when Due-DocumentDate < Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario1b()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Due-DocumentDate = Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxEqualDueDate(PaymentTerms);

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario2a()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day before Non-payment period and before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodAfterPaymentDayBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:

        ValidateDueDatesOnPurchaseOrder(
          PurchaseHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', PurchaseHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario2b()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnStartOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        PurchaseHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario2c()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnEndOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        PurchaseHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario3()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day after Non-payment period and both before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforePaymentDayAndBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(
          PurchaseHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', PurchaseHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario4()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Non-payment period before Due Date and no Payment Day
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario5()
    var
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // TFS TC 277091
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and Payment Day is before the treshold
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateAfterPaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(
          PurchaseHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', PurchaseHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario6()
    var
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // TFS TC 277035
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and Payment Day is after the treshold
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateBeforePaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario7()
    var
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC 277183
        // Test Due Date - Document Date > Max_ No_Of_Days_till_Due_Date and closest available date is inside a Non Payment Period - No Payment Day is defined.
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, CalcDate('<-1D>', NonPaymentPeriod."From Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario8()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // TFS TC 277222
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and the maximum day is inside a non-payment period and Payment Day is before non-payment period
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period and Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(
          PurchaseHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', PurchaseHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario9()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // TFS TC 277221
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and the maximum day is inside a non-payment period and Payment Day is after non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayAfterNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario10()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // TFS TC 277223
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and max treshold and payment day are inside a non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforePaymentDayInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario11()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // TFS TC 277182
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and entire date range [Document Date, Document Date + Max. No. of Days till Dues Date] represents a non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodBeforeDueDate(PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario12()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Max No of Days till Due Date = 0
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        PaymentTerms."Max. No. of Days till Due Date" := 0;
        PaymentTerms.Modify();

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario13()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Test Due Date on Sales Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Payment Day < Non Payment Period End Date  < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForPaymentDayBeforeMaxInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Vendor, WorkDate());

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnPurchaseOrder(PurchaseHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario14()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Prepayment Due Date is set correctly on Purchase Order when Max No of Days till Due Date = 0
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        PaymentTerms."Max. No. of Days till Due Date" := 0;
        PaymentTerms.Modify();

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());
        PurchaseHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        PurchaseHeader.Modify();

        // Verify
        PurchaseHeader.TestField("Prepayment Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderScenario15()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Due Date is set correctly on Purchase Order when Max No of Days till Due Date < Due Date
        // No Payment Day and Non-Payment Period defined
        // Expected Result: Due Date set according to Max. No. of Days till Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);

        // Exercise:
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        PurchaseHeader.TestField("Due Date", CalcDate(StrSubstNo('<%1D>', PaymentTerms."Max. No. of Days till Due Date"), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderPostWhenDueDateOk()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());
        CreatePurchaseLine(PurchaseHeader);

        // Exercise: Update Max No. of Days till Due Date such that it will be greater than the Due Date Calculation days
        PaymentTerms.Validate("Max. No. of Days till Due Date", ConstDaysInMonth);
        PaymentTerms.Modify(true);

        // Verify:
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderPostWhenDueDateExceedsMaxLimit()
    var
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());
        CreatePurchaseLine(PurchaseHeader);

        // Update Max No. of Days till Due Date such that it will be smaller than the Due Date Calculation days
        PaymentTerms.Validate("Max. No. of Days till Due Date", 1);
        PaymentTerms.Modify(true);

        // Exercise:
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(
          StrSubstNo(
            PaymentTermsValidationError, PurchaseHeader.FieldCaption("Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PmtTermsOnVendLedgerEntriesAfterUpdatingPurchHeaderPmtTerms()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
        NewPaymentTermsCode: Code[10];
    begin
        Initialize();

        SetupPurchOrderWithOneLine(PurchaseHeader, FindPaymentMethodWithCreateBills());
        NewPaymentTermsCode := UpdatePurchHeaderWithNewPaymentTerms(PurchaseHeader);

        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyPaymentTermsCodeOnVendLedgEntries(PostedDocumentNo, NewPaymentTermsCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario1a()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        // Test that Due Date is set correctly on Sales Order when Due-DocumentDate < Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDatesOnSalesOrder(SalesHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario1b()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        // Test that Due Date is set correctly on Sales Order when Due-DocumentDate = Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxEqualDueDate(PaymentTerms);

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDatesOnSalesOrder(SalesHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario2a()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
    begin
        // Test that Due Date is set correctly on Sales Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day before Non-payment period and before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodAfterPaymentDayBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario2b()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Sales Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnStartOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        SalesHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario2c()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Sales Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnEndOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        SalesHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario3()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
    begin
        // Test Due Date on Sales Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day after Non-payment period and both before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforePaymentDayAndBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(
          SalesHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', SalesHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario4()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Test Due Date on Sales Order when Due Date - DocumentDate < Max No of Days till Due Date and Non-payment period before Due Date and no Payment Day
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario5()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        // TFS TC ID 276944
        // Test that Due Date is set correctly on Sales Order with  Payment Date < Max_ No_Of_Days_till_Due_Date < Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateAfterPaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(
          SalesHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', SalesHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario6()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        // TFS TC ID 276941
        // Test Due Date on Sales Order with  Max_ No_Of_Days_till_Due_Date < Payment Date < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateBeforePaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario7()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 276970
        // Test Due Date on Sales Order with  Max_ No_Of_Days_till_Due_Date <NonPaymentPeriod Start Date < NonPaymentPeriod End Date < Due Date and closest available date is inside a Non Payment Period - No Payment Day is defined
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, CalcDate('<-1D>', NonPaymentPeriod."From Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario8()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277177
        // Test Due Date on Sales Order with  Payment Date < Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Non Payment Period End Date < Due Date
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period and Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(
          SalesHeader, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', SalesHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario9()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277175
        // Test Due Date on Sales Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Non Payment Period End Date < Payment Day < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayAfterNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario10()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277184
        // Test Due Date on Sales Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Payment Day < Non Payment Period End Date  < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforePaymentDayInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario11()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 276954
        // Test Due Date on Sales Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Non Payment Period End Date < Payment Day < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodBeforeDueDate(PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario12()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Purchase Order when Max No of Days till Due Date = 0
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        PaymentTerms."Max. No. of Days till Due Date" := 0;
        PaymentTerms.Modify();

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDatesOnSalesOrder(SalesHeader, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario13()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Test Due Date on Sales Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Payment Day < Non Payment Period End Date  < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForPaymentDayBeforeMaxInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDatesOnSalesOrder(SalesHeader, 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario14()
    var
        SalesHeader: Record "Sales Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // TFS TC ID 276856
        // Test Prepayment Due Date is set correctly on Sales Order when Max No of Days till Due Date = 0
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        PaymentTerms."Max. No. of Days till Due Date" := 0;
        PaymentTerms.Modify();

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());
        SalesHeader."Prepmt. Payment Terms Code" := PaymentTerms.Code;
        SalesHeader.Modify();

        // Verify
        SalesHeader.TestField("Prepayment Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderScenario15()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        // Test Due Date is set correctly on Sales Order when Max No of Days till Due Date < Due Date
        // No Payment Day and Non-Payment Period defined
        // Expected Result: Due Date set according to Max. No. of Days till Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);

        // Exercise:
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        SalesHeader.TestField("Due Date", CalcDate(StrSubstNo('<%1D>', PaymentTerms."Max. No. of Days till Due Date"), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderPostWhenDueDateOk()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());
        CreateSalesLine(SalesHeader);

        // Exercise: Update Max No. of Days till Due Date such that it will be greater than the Due Date Calculation days
        PaymentTerms.Validate("Max. No. of Days till Due Date", ConstDaysInMonth);
        PaymentTerms.Modify(true);

        // Verify:
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestSalesOrderPostWhenDueDateExceedsMaxLimit()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());
        CreateSalesLine(SalesHeader);

        // Update Max No. of Days till Due Date such that it will be smaller than the Due Date Calculation days
        PaymentTerms.Validate("Max. No. of Days till Due Date", 1);
        PaymentTerms.Modify(true);

        // Exercise:
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(
          StrSubstNo(
            PaymentTermsValidationError, SalesHeader.FieldCaption("Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PmtTermsOnCustLedgerEntriesAfterUpdatingSalesHeaderPmtTerms()
    var
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
        NewPaymentTermsCode: Code[10];
    begin
        Initialize();

        SetupSalesOrderWithOneLine(SalesHeader, FindPaymentMethodWithCreateBills());
        NewPaymentTermsCode := UpdateSalesHeaderWithNewPaymentTerms(SalesHeader);

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyPaymentTermsCodeOnCustLedgEntries(PostedDocumentNo, NewPaymentTermsCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario1a()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that Due Date is set correctly on Journal Line when Due-DocumentDate < Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', '');

        // Verify
        GenJournalLine.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", GenJournalLine."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario1b()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Due Date is set correctly on Journal Line when Due-DocumentDate = Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxEqualDueDate(PaymentTerms);

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', '');

        // Verify
        GenJournalLine.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", GenJournalLine."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario2a()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day before Non-payment period and before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodAfterPaymentDayBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(
          GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, NonPaymentPeriod.Code);

        // Verify:

        GenJournalLine.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', GenJournalLine."Due Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario3()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day after Non-payment period and both before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforePaymentDayAndBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(
          GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', GenJournalLine."Due Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario4()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate < Max No of Days till Due Date
        // and Non-payment period before Due Date and no Payment Day
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario5()
    var
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate > Max No of Days till Due Date
        // and Payment Day is before the treshold
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateAfterPaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, '');

        // Verify:
        GenJournalLine.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', GenJournalLine."Due Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario6()
    var
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate > Max No of Days till Due Date
        // and Payment Day is after the treshold
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateBeforePaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, '');

        // Verify:
        GenJournalLine.TestField("Due Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario7()
    var
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277393
        // Test Due Date - Document Date > Max_ No_Of_Days_till_Due_Date and closest available date is inside a Non Payment Period - No Payment Day is defined.
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField("Due Date", CalcDate('<-1D>', NonPaymentPeriod."From Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario8()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate > Max No of Days till Due Date
        // and the maximum day is inside a non-payment period and Payment Day is before non-payment period
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period and Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(
          GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', GenJournalLine."Due Date")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario9()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate > Max No of Days till Due Date
        // and the maximum day is inside a non-payment period and Payment Day is after non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayAfterNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(
          GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField("Due Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario10()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate > Max No of Days till Due Date
        // and max treshold and payment day are inside a non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforePaymentDayInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(
          GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField("Due Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario11()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Due Date - DocumentDate > Max No of Days till Due Date
        // and entire date range [Document Date, Document Date + Max. No. of Days till Dues Date] represents a non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodBeforeDueDate(PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField("Due Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario12()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Journal Line when Max No of Days till Due Date = 0
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        PaymentTerms."Max. No. of Days till Due Date" := 0;
        PaymentTerms.Modify();

        // Exercise:
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', '');

        // Verify
        GenJournalLine.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalScenario13()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Test Due Date on Sales Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Payment Day < Non Payment Period End Date  < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForPaymentDayBeforeMaxInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        CreateGenJournalLine(
          GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, PaymentDay.Code, NonPaymentPeriod.Code);

        // Verify:
        GenJournalLine.TestField("Due Date", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalPostWhenDueDateOk()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Due Date on Sales Journal after modifying already set PaymentTerms on that way that Due Date is still before Max. No. of Days till Due Date
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', '');

        // Exercise:
        PaymentTerms.Validate("Max. No. of Days till Due Date", ConstDaysInMonth);
        PaymentTerms.Modify(true);

        // Verify:
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalPostWhenDueDateExceedsMaxLimit()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test Due Date on Sales Journal after modifying already set PaymentTerms on that way that Due Date is after Max. No. of Days till Due Date
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Invoice, '', '');

        // Exercise:
        PaymentTerms.Validate("Max. No. of Days till Due Date", 1);
        PaymentTerms.Modify(true);

        // Verify:
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Assert.ExpectedError(
          StrSubstNo(
            PaymentTermsValidationError, GenJournalLine.FieldCaption("Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalBug279717()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Payment, '', '');

        // Exercise:
        GenJournalLine.Validate(Amount, -1 * GenJournalLine.Amount);
        GenJournalLine.Validate(
          "Due Date",
          CalcDate(
            StrSubstNo('<%1D>', PaymentTerms."Max. No. of Days till Due Date" + LibraryRandom.RandInt(10)),
            GenJournalLine."Document Date"));
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::" ");
        GenJournalLine.Modify(true);

        // Verify:
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalBug279718Bill()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::Bill, '', '');

        // Verify:
        GenJournalLine.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", GenJournalLine."Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesJournalBug279718CreditMemo()
    var
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        CreateGenJournalLine(GenJournalLine, PaymentTerms.Code, GenJournalLine."Document Type"::"Credit Memo", '', '');

        // Verify:
        GenJournalLine.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", GenJournalLine."Document Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario1a()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
    begin
        // TFS TC ID 277400
        // Test Due Date is set correctly on Service Order when Due-DocumentDate < Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ServiceHeader.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario1b()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
    begin
        // TFS TC ID 277400
        // Test Due Date is set correctly on Service Order when Due-DocumentDate = Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxEqualDueDate(PaymentTerms);

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ServiceHeader.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario2a()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
    begin
        // TFS TC ID 277403
        // Test Due Date on Service Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day before Non-payment period and before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodAfterPaymentDayBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario2b()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        ServiceHeader: Record "Service Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Service Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnStartOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario2c()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        ServiceHeader: Record "Service Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Service Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnEndOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario3()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
    begin
        // Test Due Date on Service Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day after Non-payment period and both before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforePaymentDayAndBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', ServiceHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario4()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Test Due Date on Service Order when Due Date - DocumentDate < Max No of Days till Due Date and Non-payment period before Due Date and no Payment Day
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario5()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
    begin
        // TFS TC ID 277372
        // Test Due Date is set correctly on Service Order with  Payment Date < Max_ No_Of_Days_till_Due_Date < Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateAfterPaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', ServiceHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario6()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
    begin
        // TFS TC ID 277369
        // Test Due Date on Service Order with  Max_ No_Of_Days_till_Due_Date < Payment Date < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateBeforePaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario7()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277393
        // Test Due Date on Service Order with  Max_ No_Of_Days_till_Due_Date <NonPaymentPeriod Start Date < NonPaymentPeriod End Date < Due Date and closest available date is inside a Non Payment Period - No Payment Day is defined
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", CalcDate('<-1D>', NonPaymentPeriod."From Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario8()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277399
        // Test Due Date on Service Order with  Payment Date < Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Non Payment Period End Date < Due Date
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period and Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', ServiceHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario9()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277397
        // Test Due Date on Service Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Non Payment Period End Date < Payment Day < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayAfterNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario10()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277405
        // Test Due Date on Service Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Payment Day < Non Payment Period End Date  < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforePaymentDayInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario11()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // TFS TC ID 277378
        // Test Due Date on Service Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Non Payment Period End Date < Payment Day < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodBeforeDueDate(PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario12()
    var
        ServiceHeader: Record "Service Header";
        PaymentTerms: Record "Payment Terms";
    begin
        // Test Due Date is set correctly on Service Order when Max No of Days till Due Date = 0
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        PaymentTerms."Max. No. of Days till Due Date" := 0;
        PaymentTerms.Modify();

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ServiceHeader.TestField("Due Date", CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario13()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
    begin
        // Test Due Date on Service Order with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Payment Day < Non Payment Period End Date  < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForPaymentDayBeforeMaxInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ServiceHeader.TestField("Due Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderScenario15()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
    begin
        // Test Due Date is set correctly on Service Order when Max No of Days till Due Date < Due Date
        // No Payment Day and Non-Payment Period defined
        // Expected Result: Due Date set according to Max. No. of Days till Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);

        // Exercise:
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ServiceHeader.TestField("Due Date",
          CalcDate(StrSubstNo('<%1D>', PaymentTerms."Max. No. of Days till Due Date"), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderPostWhenDueDateOk()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', '', WorkDate());
        CreateServiceOrderLine(ServiceHeader);

        // Exercise: Update Max No. of Days till Due Date such that it will be greater than the Due Date Calculation days
        PaymentTerms.Validate("Max. No. of Days till Due Date", ConstDaysInMonth);
        PaymentTerms.Modify(true);

        // Verify:
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestServiceOrderPostWhenDueDateExceedsMaxLimit()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        SetupServiceOrder(ServiceHeader, PaymentTerms.Code, '', '', WorkDate());
        CreateServiceOrderLine(ServiceHeader);

        // Update Max No. of Days till Due Date such that it will be smaller than the Due Date Calculation days
        PaymentTerms.Validate("Max. No. of Days till Due Date", 1);
        PaymentTerms.Modify(true);

        // Exercise:
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        Assert.ExpectedError(
          StrSubstNo(
            PaymentTermsValidationError, ServiceHeader.FieldCaption("Due Date"),
            PaymentTerms.FieldCaption("Max. No. of Days till Due Date"), PaymentTerms.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario1a()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // TFS TC ID 277811
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due-DocumentDate < Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(
          ServiceContractNo, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario1b()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Service Invoice created from Contract Service when Due-DocumentDate = Max No of Days till Due Date
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxEqualDueDate(PaymentTerms);

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(
          ServiceContractNo, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario2a()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day before Non-payment period and before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodAfterPaymentDayBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(
          ServiceContractNo, CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario2b()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnStartOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo, 0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario2c()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Purchase Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day set to the start of Non-payment period and before Due Date
        // Expected Result: Due Date blank
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDatePaymentDayOnEndOfNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify:
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo, 0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario3()
    var
        ServiceHeader: Record "Service Header";
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Payment Day after Non-payment period and both before Due Date
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforePaymentDayAndBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());
        GetServiceHeaderCreatedFromServiceContract(ServiceHeader, ServiceContractNo);

        // Verify
        ServiceHeader.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', ServiceHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario4()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate < Max No of Days till Due Date
        // and Non-payment period before Due Date and no Payment Day
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforeDueDate(
          PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(
          ServiceContractNo, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario5()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        ServiceContractNo: Code[10];
    begin
        // TFS TC ID 277598
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and Payment Day is before the treshold
        // Expected Result: Due Date set to Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateAfterPaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, '', PaymentDay.Code, WorkDate());
        GetServiceHeaderCreatedFromServiceContract(ServiceHeader, ServiceContractNo);

        // Verify
        ServiceHeader.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', ServiceHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario6()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // TFS TC ID 277597
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and Payment Day is after the treshold
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforeDueDateBeforePaymentDay(PaymentTerms, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, '', PaymentDay.Code, WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo, 0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario8()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceHeader: Record "Service Header";
        ServiceContractNo: Code[10];
    begin
        // TFS TC ID 277810
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and the maximum day is inside a non-payment period and Payment Day is before non-payment period
        // Expected Result: update Due Date to the closest lower date with respect to the Non Payment Period and Payment Day
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());
        GetServiceHeaderCreatedFromServiceContract(ServiceHeader, ServiceContractNo);

        // Verify
        ServiceHeader.TestField(
          "Due Date", CalcDate(StrSubstNo('<-CM + %1D>', PaymentDay."Day of the month" - 1), CalcDate('<-CM>', ServiceHeader."Due Date")));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario9()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // TFS TC ID 277807
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and the maximum day is inside a non-payment period and Payment Day is after non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayAfterNonPaymentPeriod(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo, 0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario10()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and max treshold and payment day are inside a non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxBeforePaymentDayInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo, 0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario11()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // TFS TC ID 277601
        // Test Due Date is set correctly on Service Invoice created from Contract Service Order when Due Date - DocumentDate > Max No of Days till Due Date
        // and entire date range [Document Date, Document Date + Max. No. of Days till Dues Date] represents a non-payment period
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForMaxInNonPaymentPeriodBeforeDueDate(PaymentTerms, NonPaymentPeriod, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo, 0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario12()
    var
        NonPaymentPeriod: Record "Non-Payment Period";
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Service Invoice when Max No of Days till Due Date = 0
        // Expected Result: Due Date set according to the Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        PaymentTerms."Max. No. of Days till Due Date" := 0;
        PaymentTerms.Modify();

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, '', WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(
          ServiceContractNo, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario13()
    var
        PaymentDay: Record "Payment Day";
        PaymentTerms: Record "Payment Terms";
        NonPaymentPeriod: Record "Non-Payment Period";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date on Service Invoice with  Non Payment Period Start Date < Max_ No_Of_Days_till_Due_Date < Payment Day < Non Payment Period End Date  < Due Date
        // Expected Result: Due Date is empty
        Initialize();

        // Setup:
        CreateSetupForPaymentDayBeforeMaxInNonPaymentPeriodWithDueDateAfter(
          PaymentTerms, NonPaymentPeriod, PaymentDay, PaymentTableNameOption::Customer, WorkDate());

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, NonPaymentPeriod.Code, PaymentDay.Code, WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo, 0D);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler')]
    [Scope('OnPrem')]
    procedure TestServiceContractScenario15()
    var
        PaymentTerms: Record "Payment Terms";
        ServiceContractNo: Code[10];
    begin
        // Test Due Date is set correctly on Service Contract when Max No of Days till Due Date < Due Date
        // No Payment Day and Non-Payment Period defined
        // Expected Result: Due Date set according to Max. No. of Days till Due Date Calculation
        Initialize();

        // Setup:
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);

        // Exercise:
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, '', '', WorkDate());

        // Verify
        ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(
          ServiceContractNo, CalcDate(StrSubstNo('<%1D>', PaymentTerms."Max. No. of Days till Due Date"), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes,ServContrctTemplateListHandler,CreateContractServiceOrdersReqPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateContractServiceOrders()
    var
        PaymentTerms: Record "Payment Terms";
        SelectedAction: Option "Create Service Order","Print Only";
        ServiceContractNo: Code[20];
        OldCount: Integer;
    begin
        Initialize();

        // Setup
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);
        ServiceContractNo := CreateSignedServiceContract(PaymentTerms.Code, '', '', WorkDate());
        OldCount := NumberOfServiceOrders();

        // Exercise
        Commit();
        InitializeContractServiceOrders(
          CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()), SelectedAction::"Create Service Order", ServiceContractNo);
        REPORT.Run(REPORT::"Create Contract Service Orders");

        // Verify
        Assert.AreEqual(OldCount + 1, NumberOfServiceOrders(), StrSubstNo(ServiceOrderNotCreated, ServiceContractNo));
        ValidateServiceOrderCreatedFromContract(ServiceContractNo, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDatePurchWhenVendorWithoutPaymentDay()
    var
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Payment Day] [Due Date] [Purchase]
        // [SCENARIO 319582] When Posting Date is validated in Purchase Header then Due Date doesn't depend on Company Payment Day if Vendor Payment Day is not specified
        Initialize();
        PaymentDay.DeleteAll();

        // [GIVEN] Payment Day with Table Name = "Company Information", Code = Company Information "Payment Days Code" and "Day of the month" = 20
        CreateCompanyPaymentDay(PaymentDay, LibraryRandom.RandIntInRange(15, 25), WorkDate());

        // [GIVEN] Vendor "V" without Payment Day records but "Payment Days Code" is <non-blank>
        // [GIVEN] Purchase Header with "Buy-from Vendor No." = "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Validate Posting Date = "01/01/2018" in Purchase Header
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDate(LibraryRandom.RandIntInRange(30, 35)));

        // [THEN] Due Date = "01/01/2018" in Purchase Header
        PurchaseHeader.TestField("Due Date", PurchaseHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateSalesWhenCustomerWithoutPaymentDay()
    var
        PaymentDay: Record "Payment Day";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Payment Day] [Due Date] [Sales]
        // [SCENARIO 268487] When Posting Date is validated in Sales Header then Due Date doesn't depend on Company Payment Day if Customer Payment Day is not specified
        Initialize();
        PaymentDay.DeleteAll();

        // [GIVEN] Payment Day with Table Name = "Company Information", Code = Company Information "Payment Days Code" and "Day of the month" = 20
        CreateCompanyPaymentDay(PaymentDay, LibraryRandom.RandIntInRange(15, 25), WorkDate());

        // [GIVEN] Customer "C" without Payment Day records but "Payment Days Code" is <non-blank>
        // [GIVEN] Sales Header with "Sell-To Customer No." = "C"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [WHEN] Validate Posting Date = "01/01/2018" in Sales Header
        SalesHeader.Validate("Posting Date", LibraryRandom.RandDate(LibraryRandom.RandIntInRange(30, 35)));

        // [THEN] Due Date = "01/01/2018" in Sales Header
        SalesHeader.TestField("Due Date", SalesHeader."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDatePurchWhenVendorWithBlankPaymentDaysCode()
    var
        PaymentDay: Record "Payment Day";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Payment Days Code] [Due Date] [Purchase]
        // [SCENARIO 268487] When Posting Date is validated in Purchase Header then Due Date is adjusted with respect to Company Payment Day if Vendor has blank "Payment Days Code"
        Initialize();
        PaymentDay.DeleteAll();

        // [GIVEN] Payment Day with Table Name = "Company Information", Code = Company Information "Payment Days Code" and "Day of the month" = 20
        CreateCompanyPaymentDay(PaymentDay, LibraryRandom.RandIntInRange(15, 25), WorkDate());

        // [GIVEN] Vendor "V" with <blank> "Payment Days Code"
        // [GIVEN] Purchase Header with "Buy-from Vendor No." = "V"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorWithBlankPaymentDaysCode());

        // [WHEN] Validate Posting Date = "01/01/2018" in Purchase Header
        PurchaseHeader.Validate("Posting Date", LibraryRandom.RandDate(LibraryRandom.RandIntInRange(30, 35)));

        // [THEN] Due Date = "01/20/2018" in Purchase Header
        PurchaseHeader.TestField(
          "Due Date", CalcDate(StrSubstNo('<D%1>', PaymentDay."Day of the month"), PurchaseHeader."Posting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateSalesWhenCustomerWithBlankPaymentDaysCode()
    var
        PaymentDay: Record "Payment Day";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Payment Days Code] [Due Date] [Sales]
        // [SCENARIO 268487] When Posting Date is validated in Sales Header then Due Date doesn't depend on Company Payment Day if Customer has blank "Payment Days Code"
        Initialize();
        PaymentDay.DeleteAll();

        // [GIVEN] Payment Day with Table Name = "Company Information", Code = Company Information "Payment Days Code" and "Day of the month" = 20
        CreateCompanyPaymentDay(PaymentDay, LibraryRandom.RandIntInRange(15, 25), WorkDate());

        // [GIVEN] Customer "C" with <blank> "Payment Days Code"
        // [GIVEN] Sales Header with "Sell-To Customer No." = "C"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithBlankPaymentDaysCode());

        // [WHEN] Validate Posting Date = "01/01/2018" in Sales Header
        SalesHeader.Validate("Posting Date", LibraryRandom.RandDate(LibraryRandom.RandIntInRange(30, 35)));

        // [THEN] Due Date = "01/01/2018" in Sales Header
        SalesHeader.TestField("Due Date", SalesHeader."Posting Date");
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        ConstDaysInMonth := 28; // The least common denominator for days per month.
        InitializeContractServiceOrders(0D, 0D, 0, '');
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();

        if IsInitialized then
            exit;

        Commit();
    end;

    local procedure CalcDueDates(PaymentTerms: Record "Payment Terms"; DocumentDate: Date; var InitDueDate: Date; var MaxDueDate: Date)
    begin
        InitDueDate := CalcDate(PaymentTerms."Due Date Calculation", DocumentDate);
        MaxDueDate := CalcDate(StrSubstNo('<%1D>', PaymentTerms."Max. No. of Days till Due Date"), DocumentDate);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure FindPaymentMethodWithCreateBills(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Create Bills", true);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateContractServiceOrdersReqPageHandler(var CreateContractServiceOrders: TestRequestPage "Create Contract Service Orders")
    begin
        CreateContractServiceOrders.StartingDate.SetValue(ReqPageStartingDate);
        CreateContractServiceOrders.EndingDate.SetValue(ReqPageEndingDate);
        CreateContractServiceOrders.CreateServiceOrders.SetValue(ReqPageAction);
        CreateContractServiceOrders."Service Contract Header".SetFilter("Contract No.", ReqPageContractNo);
        CreateContractServiceOrders.OK().Invoke();
    end;

    local procedure CreateCustomer(PaymentTermCode: Code[10]; NonPaymentPeriodCode: Code[20]; PaymentDayCode: Code[20]): Code[10]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermCode);
        Customer.Validate("Non-Paymt. Periods Code", NonPaymentPeriodCode);
        Customer.Validate("Payment Days Code", PaymentDayCode);
        Customer.Modify(true);

        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithBlankPaymentDaysCode(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Days Code", '');
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PaymentTermsCode: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PaymentDayCode: Code[20]; NonPaymentPeriodCode: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);

        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CreateCustomer(PaymentTermsCode, NonPaymentPeriodCode, PaymentDayCode),
          LibraryRandom.RandDec(1000, 2));

        GenJournalLine.Validate("Payment Terms Code", PaymentTermsCode);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Sale);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateNonPaymentPeriod(var NonPaymentPeriod: Record "Non-Payment Period"; TableNameOption: Option; FromInterval: Integer; ToInterval: Integer; DocumentDate: Date; MaxDueDate: Date)
    begin
        NonPaymentPeriod."Table Name" := TableNameOption;
        NonPaymentPeriod.Validate(Code, LibraryUtility.GenerateRandomCode(NonPaymentPeriod.FieldNo(Code), DATABASE::"Non-Payment Period"));
        NonPaymentPeriod."From Date" := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(FromInterval)), DocumentDate);
        NonPaymentPeriod."To Date" := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(ToInterval)), MaxDueDate);
        NonPaymentPeriod.Insert(true);
    end;

    local procedure CreatePaymentTermMaxEqualDueDate(var PaymentTerms: Record "Payment Terms")
    var
        DueDateCalculationDays: Integer;
    begin
        // scenario 1a
        DueDateCalculationDays := LibraryRandom.RandInt(ConstDaysInMonth);
        CreatePaymentTerms(PaymentTerms, StrSubstNo('%1D', DueDateCalculationDays), DueDateCalculationDays)
    end;

    local procedure CreatePaymentTermMaxAfterDueDate(var PaymentTerms: Record "Payment Terms")
    var
        DueDateCalculationDays: Integer;
    begin
        // scenario 1b
        DueDateCalculationDays := LibraryRandom.RandIntInRange(2, ConstDaysInMonth / 2);
        CreatePaymentTerms(
          PaymentTerms, StrSubstNo('%1D', DueDateCalculationDays),
          LibraryRandom.RandIntInRange(DueDateCalculationDays + 1, ConstDaysInMonth));
    end;

    local procedure CreatePaymentTermMaxAfterDueDateAfterNonPaymentPeriod(var PaymentTerms: Record "Payment Terms")
    var
        DueDateCalculationDays: Integer;
    begin
        // scenario 4
        DueDateCalculationDays := LibraryRandom.RandInt(ConstDaysInMonth / 2) + 1;
        CreatePaymentTerms(
          PaymentTerms, StrSubstNo('%1D', DueDateCalculationDays),
          LibraryRandom.RandIntInRange(DueDateCalculationDays + 1, ConstDaysInMonth));
    end;

    local procedure CreatePaymentTermMaxBeforeDueDate(var PaymentTerms: Record "Payment Terms")
    var
        DueDateCalculationDays: Integer;
    begin
        DueDateCalculationDays := LibraryRandom.RandIntInRange(ConstDaysInMonth / 2, ConstDaysInMonth);
        CreatePaymentTerms(
          PaymentTerms,
          StrSubstNo('%1D', DueDateCalculationDays), LibraryRandom.RandIntInRange(1, DueDateCalculationDays - 1));
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms"; DueDateCalculation: Code[20]; MaxNoOfDaysTillDueDate: Integer)
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", DueDateCalculation);
        PaymentTerms.Validate("Due Date Calculation");
        PaymentTerms.Validate("Max. No. of Days till Due Date", MaxNoOfDaysTillDueDate);
        PaymentTerms.Modify(true)
    end;

    local procedure CreatePaymentDay(var PaymentDay: Record "Payment Day"; TableNameOption: Option; Interval: Integer; BaseDate: Date)
    begin
        PaymentDay.Validate("Table Name", TableNameOption);
        PaymentDay.Validate(Code, LibraryUtility.GenerateRandomCode(PaymentDay.FieldNo(Code), DATABASE::"Payment Day"));
        PaymentDay.Validate("Day of the month", Date2DMY(CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(Interval)), BaseDate), 1));
        PaymentDay.Insert(true);
    end;

    local procedure CreateCompanyPaymentDay(var PaymentDay: Record "Payment Day"; Interval: Integer; BaseDate: Date)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        PaymentDay.Validate("Table Name", PaymentTableNameOption::"Company Information");
        PaymentDay.Validate(Code, CompanyInformation."Payment Days Code");
        PaymentDay.Validate("Day of the month", Date2DMY(CalcDate(StrSubstNo('<-CM-1D+%1D>', Interval), BaseDate), 1));
        PaymentDay.Insert(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchLineWithUnitCost(var PurchaseHeader: Record "Purchase Header"; DirectUnitCost: Decimal)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesLineWithUnitPrice(var SalesHeader: Record "Sales Header"; UnitPrice: Decimal)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
    begin
        // Create a new Service Order - Service Header
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
    end;

    local procedure CreateServiceOrderLine(var ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Create a new Service Order Line - Service Item, Service Item Line
        LibrarySales.FindItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateSetupForMaxBeforeDueDateAfterPaymentDay(var PaymentTerms: Record "Payment Terms"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    begin
        // scenario 5
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CreatePaymentDay(PaymentDay, TableNameOption, PaymentTerms."Max. No. of Days till Due Date", DocumentDate);
    end;

    local procedure CreateSetupForMaxBeforeDueDateBeforePaymentDay(var PaymentTerms: Record "Payment Terms"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        InitDueDate: Date;
        MaxDueDate: Date;
    begin
        // scenario 6
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CalcDueDates(PaymentTerms, DocumentDate, InitDueDate, MaxDueDate);

        CreatePaymentDay(PaymentDay, TableNameOption, InitDueDate - MaxDueDate, MaxDueDate);
    end;

    local procedure CreateSetupForMaxAfterDueDateNonPaymentPeriodAfterPaymentDayBeforeDueDate(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        DeltaDays: Integer;
        DeltaDate: Date;
        InitDueDate: Date;
    begin
        // scenario 2a
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        InitDueDate := CalcDate(PaymentTerms."Due Date Calculation", DocumentDate);
        DeltaDays := LibraryRandom.RandInt(InitDueDate - DocumentDate - 1);
        DeltaDate := CalcDate(StrSubstNo('<%1D>', DeltaDays), DocumentDate);

        CreateNonPaymentPeriod(NonPaymentPeriod, TableNameOption, DeltaDays - 1, InitDueDate - DeltaDate - 1, DocumentDate + 1, DeltaDate);
        CreatePaymentDay(PaymentDay, TableNameOption, NonPaymentPeriod."From Date" - DocumentDate - 1, DocumentDate);
    end;

    local procedure CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforePaymentDayAndBeforeDueDate(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        DeltaDays: Integer;
        DeltaDate: Date;
        InitDueDate: Date;
    begin
        // scenario 3
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        InitDueDate := CalcDate(PaymentTerms."Due Date Calculation", DocumentDate);
        DeltaDays := LibraryRandom.RandInt(InitDueDate - DocumentDate - 1);
        DeltaDate := CalcDate(StrSubstNo('<%1D>', DeltaDays), DocumentDate);

        CreateNonPaymentPeriod(NonPaymentPeriod, TableNameOption, DeltaDays, InitDueDate - DeltaDate - 1, DocumentDate, DeltaDate);
        CreatePaymentDay(PaymentDay, TableNameOption, InitDueDate - NonPaymentPeriod."To Date", NonPaymentPeriod."To Date");
    end;

    local procedure CreateSetupForMaxAfterDueDateNonPaymentPeriodBeforeDueDate(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; TableNameOption: Option; DocumentDate: Date)
    var
        DeltaDays: Integer;
        DeltaDate: Date;
        InitDueDate: Date;
    begin
        // scenario 4
        CreatePaymentTermMaxAfterDueDateAfterNonPaymentPeriod(PaymentTerms);

        InitDueDate := CalcDate(PaymentTerms."Due Date Calculation", DocumentDate);
        DeltaDays := LibraryRandom.RandInt(InitDueDate - DocumentDate - 1);
        DeltaDate := CalcDate(StrSubstNo('<%1D>', DeltaDays), DocumentDate);

        CreateNonPaymentPeriod(NonPaymentPeriod, TableNameOption, DeltaDays, InitDueDate - DeltaDate - 1, DocumentDate, DocumentDate);
    end;

    local procedure CreateSetupForMaxAfterDueDatePaymentDayOnStartOfNonPaymentPeriod(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        DeltaDays: Integer;
        DeltaDate: Date;
        InitDueDate: Date;
    begin
        // scenario 2b
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        InitDueDate := CalcDate(PaymentTerms."Due Date Calculation", DocumentDate);
        DeltaDays := LibraryRandom.RandInt(InitDueDate - DocumentDate - 1);
        DeltaDate := CalcDate(StrSubstNo('<%1D>', DeltaDays), DocumentDate);

        CreateNonPaymentPeriod(NonPaymentPeriod, TableNameOption, DeltaDays - 1, InitDueDate - DeltaDate - 1, DocumentDate + 1, DeltaDate);
        CreatePaymentDay(PaymentDay, TableNameOption, 1, NonPaymentPeriod."From Date" - 1);
    end;

    local procedure CreateSetupForMaxAfterDueDatePaymentDayOnEndOfNonPaymentPeriod(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        DeltaDays: Integer;
        DeltaDate: Date;
        InitDueDate: Date;
    begin
        // scenario 2c
        CreatePaymentTermMaxAfterDueDate(PaymentTerms);

        InitDueDate := CalcDate(PaymentTerms."Due Date Calculation", DocumentDate);
        DeltaDays := LibraryRandom.RandInt(InitDueDate - DocumentDate - 1);
        DeltaDate := CalcDate(StrSubstNo('<%1D>', DeltaDays), DocumentDate);

        CreateNonPaymentPeriod(NonPaymentPeriod, TableNameOption, DeltaDays - 1, InitDueDate - DeltaDate - 1, DocumentDate + 1, DeltaDate);
        CreatePaymentDay(PaymentDay, TableNameOption, 1, NonPaymentPeriod."To Date" - 1);
    end;

    local procedure CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayBeforeNonPaymentPeriod(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        InitDueDate: Date;
        MaxDueDate: Date;
    begin
        // scenario 8
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CalcDueDates(PaymentTerms, DocumentDate, InitDueDate, MaxDueDate);

        CreateNonPaymentPeriod(
          NonPaymentPeriod, TableNameOption, PaymentTerms."Max. No. of Days till Due Date" - 1, InitDueDate - MaxDueDate, DocumentDate + 1,
          MaxDueDate);
        CreatePaymentDay(PaymentDay, TableNameOption, NonPaymentPeriod."From Date" - DocumentDate - 1, DocumentDate);
    end;

    local procedure CreateSetupForMaxInNonPaymentPeriodWithDueDateAfterAndPaymentDayAfterNonPaymentPeriod(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        InitDueDate: Date;
        MaxDueDate: Date;
    begin
        // scenario 9
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CalcDueDates(PaymentTerms, DocumentDate, InitDueDate, MaxDueDate);

        CreateNonPaymentPeriod(
          NonPaymentPeriod, TableNameOption, PaymentTerms."Max. No. of Days till Due Date", InitDueDate - MaxDueDate, DocumentDate,
          MaxDueDate);
        CreatePaymentDay(PaymentDay, TableNameOption, InitDueDate - NonPaymentPeriod."To Date", NonPaymentPeriod."To Date");
    end;

    local procedure CreateSetupForMaxInNonPaymentPeriodBeforeDueDate(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; TableNameOption: Option; DocumentDate: Date)
    var
        InitDueDate: Date;
        MaxDueDate: Date;
    begin
        // scenario 11
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CalcDueDates(PaymentTerms, DocumentDate, InitDueDate, MaxDueDate);
        CreateNonPaymentPeriod(NonPaymentPeriod, TableNameOption, 0, InitDueDate - MaxDueDate, DocumentDate - 1, MaxDueDate)
    end;

    local procedure CreateSetupForMaxBeforePaymentDayInNonPaymentPeriodWithDueDateAfter(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        InitDueDate: Date;
        MaxDueDate: Date;
    begin
        // scenario 10
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CalcDueDates(PaymentTerms, DocumentDate, InitDueDate, MaxDueDate);
        CreateNonPaymentPeriod(
          NonPaymentPeriod, TableNameOption, PaymentTerms."Max. No. of Days till Due Date", InitDueDate - MaxDueDate, DocumentDate,
          MaxDueDate);
        CreatePaymentDay(PaymentDay, TableNameOption, NonPaymentPeriod."To Date" - MaxDueDate, MaxDueDate);
    end;

    local procedure CreateSetupForPaymentDayBeforeMaxInNonPaymentPeriodWithDueDateAfter(var PaymentTerms: Record "Payment Terms"; var NonPaymentPeriod: Record "Non-Payment Period"; var PaymentDay: Record "Payment Day"; TableNameOption: Option; DocumentDate: Date)
    var
        InitDueDate: Date;
        MaxDueDate: Date;
    begin
        // scenario 13
        CreatePaymentTermMaxBeforeDueDate(PaymentTerms);
        CalcDueDates(PaymentTerms, DocumentDate, InitDueDate, MaxDueDate);
        CreateNonPaymentPeriod(
          NonPaymentPeriod, TableNameOption, PaymentTerms."Max. No. of Days till Due Date", InitDueDate - MaxDueDate, DocumentDate,
          MaxDueDate);
        CreatePaymentDay(PaymentDay, TableNameOption, MaxDueDate - NonPaymentPeriod."From Date", NonPaymentPeriod."From Date");
    end;

    local procedure CreateSignedServiceContract(PaymentTermCode: Code[10]; NonPaymentPeriodCode: Code[20]; PaymentDayCode: Code[20]; DocumentDate: Date): Code[10]
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        SignServContractDoc: Codeunit SignServContractDoc;
        CustomerNo: Code[10];
    begin
        // create service contract
        CustomerNo := CreateCustomer(PaymentTermCode, NonPaymentPeriodCode, PaymentDayCode);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);

        // create service contract line
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", 1000 * LibraryRandom.RandDec(10, 2));  // Use Random because value is not important.
        Evaluate(ServiceContractLine."Service Period", '1M');
        ServiceContractLine.Modify(true);

        // update service contract header
        ServiceContractHeader.Validate("Starting Date", DocumentDate);
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Modify(true);

        // sign contract
        SignServContractDoc.SignContract(ServiceContractHeader);

        exit(ServiceContractHeader."Contract No.");
    end;

    local procedure CreateVendor(PaymentTermCode: Code[10]; NonPaymentPeriodCode: Code[20]; PaymentDayCode: Code[20]): Code[10]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermCode);
        Vendor.Validate("Non-Paymt. Periods Code", NonPaymentPeriodCode);
        Vendor.Validate("Payment Days Code", PaymentDayCode);
        Vendor.Modify(true);

        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithBlankPaymentDaysCode(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Days Code", '');
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetServiceHeaderCreatedFromServiceContract(var ServiceHeader: Record "Service Header"; ServiceContractNo: Code[10])
    begin
        ServiceHeader.SetRange("Contract No.", ServiceContractNo);
        ServiceHeader.FindFirst();
    end;

    local procedure InitializeContractServiceOrders(StartingDate: Date; EndingDate: Date; "Action": Option; ContractNo: Code[20])
    begin
        ReqPageStartingDate := StartingDate;
        ReqPageEndingDate := EndingDate;
        ReqPageAction := Action;
        ReqPageContractNo := ContractNo;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        // dummy message handler
    end;

    local procedure NumberOfServiceOrders(): Integer
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetFilter("Document Type", '%1', ServiceHeader."Document Type"::Order);
        exit(ServiceHeader.Count);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServContrctTemplateListHandler(var ServiceContractTemplateHandler: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    local procedure SetupPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; PaymentTermCode: Code[10]; NonPaymentPeriodCode: Code[20]; PaymentDayCode: Code[20]; DocumentDate: Date)
    begin
        CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Validate("Pay-to Vendor No.", CreateVendor(PaymentTermCode, NonPaymentPeriodCode, PaymentDayCode));
        PurchaseHeader.Modify(true);
    end;

    local procedure SetupPurchOrderWithOneLine(var PurchaseHeader: Record "Purchase Header"; PaymentMethodCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SetupPurchaseOrder(PurchaseHeader, PaymentTerms.Code, '', '', WorkDate());
        PurchaseHeader.Validate("Payment Method Code", PaymentMethodCode);
        PurchaseHeader.Modify(true);
        CreatePurchLineWithUnitCost(PurchaseHeader, LibraryRandom.RandDec(1000, 2)); // take random value for unit cost
    end;

    local procedure SetupSalesOrder(var SalesHeader: Record "Sales Header"; PaymentTermCode: Code[10]; NonPaymentPeriodCode: Code[20]; PaymentDayCode: Code[20]; DocumentDate: Date)
    begin
        CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Validate("Bill-to Customer No.", CreateCustomer(PaymentTermCode, NonPaymentPeriodCode, PaymentDayCode));
        SalesHeader.Modify(true);
    end;

    local procedure SetupSalesOrderWithOneLine(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10])
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SetupSalesOrder(SalesHeader, PaymentTerms.Code, '', '', WorkDate());
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
        CreateSalesLineWithUnitPrice(SalesHeader, LibraryRandom.RandDec(1000, 2)); // take random value for unit price
    end;

    local procedure SetupServiceOrder(var ServiceHeader: Record "Service Header"; PaymentTermCode: Code[10]; NonPaymentPeriodCode: Code[20]; PaymentDayCode: Code[20]; DocumentDate: Date)
    begin
        CreateServiceOrder(ServiceHeader);
        ServiceHeader.Validate("Document Date", DocumentDate);
        ServiceHeader.Validate("Bill-to Customer No.", CreateCustomer(PaymentTermCode, NonPaymentPeriodCode, PaymentDayCode));
        ServiceHeader.Modify(true);
    end;

    local procedure UpdatePurchHeaderWithNewPaymentTerms(var PurchaseHeader: Record "Purchase Header"): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PurchaseHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        PurchaseHeader.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure UpdateSalesHeaderWithNewPaymentTerms(var SalesHeader: Record "Sales Header"): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure ValidateDueDateOnServiceInvoiceCreatedFromServiceContract(ServiceContractNo: Code[10]; ExpectedDueDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Contract No.", ServiceContractNo);
        ServiceHeader.FindFirst();
        ServiceHeader.TestField("Due Date", ExpectedDueDate);
    end;

    [Normal]
    local procedure ValidateDueDatesOnPurchaseOrder(PurchaseHeader: Record "Purchase Header"; ExpectedDueDate: Date)
    begin
        PurchaseHeader.TestField("Due Date", ExpectedDueDate);
        PurchaseHeader.TestField("Prepayment Due Date", ExpectedDueDate);
    end;

    [Normal]
    local procedure ValidateDueDatesOnSalesOrder(SalesHeader: Record "Sales Header"; ExpectedDueDate: Date)
    begin
        SalesHeader.TestField("Due Date", ExpectedDueDate);
        SalesHeader.TestField("Prepayment Due Date", ExpectedDueDate);
    end;

    local procedure ValidateServiceOrderCreatedFromContract(ServiceContractNo: Code[20]; ExpectedDueDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetFilter("Document Type", '%1', ServiceHeader."Document Type"::Order);
        ServiceHeader.SetFilter("Contract No.", '%1', ServiceContractNo);
        ServiceHeader.FindLast();
        ServiceHeader.TestField("Due Date", ExpectedDueDate);
    end;

    local procedure VerifyPaymentTermsCodeOnVendLedgEntries(DocumentNo: Code[20]; PaymentTermsCode: Code[10])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindSet();
        repeat
            VendorLedgerEntry.TestField("Payment Terms Code", PaymentTermsCode);
        until VendorLedgerEntry.Next() = 0;
    end;

    local procedure VerifyPaymentTermsCodeOnCustLedgEntries(DocumentNo: Code[20]; PaymentTermsCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.TestField("Payment Terms Code", PaymentTermsCode);
        until CustLedgerEntry.Next() = 0;
    end;
}

