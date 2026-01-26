codeunit 144126 "UT TAB Miscellaneous"
{
    // 1.  Purpose of the test is to validate OnValidate - DirectComponentsAmount Trigger of Table Before Start Item Cost(12133).
    // 2.  Purpose of the test is to validate OnValidate - SubcontractedAmount Trigger of Table Before Start Item Cost(12133).
    // 3.  Purpose of the test is to validate OnValidate - DirectRoutingAmount Trigger of Table Before Start Item Cost(12133).
    // 4.  Purpose of the test is to validate OnValidate - OverheadRoutingAmount Trigger of Table Before Start Item Cost(12133).
    // 5.  Purpose of the test is to validate OnDelete Trigger of Table Bill(12180).
    // 6.  Purpose of the test is to validate OnDelete Trigger of Table Contribution Bracket(12108).
    // 7.  Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173).
    // 8.  Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173) when To-Date conflicts with another period.
    // 9.  Purpose of the test is to validate OnDelete Trigger of Table Contribution Code(12106).
    // 10. Purpose of the test is to validate OnDelete Trigger of Table Withhold Code(12104).
    // 11. Purpose of the test is to validate OnValidate - SourceWithholdingTax Trigger of Table Withhold Code(12104).
    // 12. Purpose of the test is to validate OnValidate - RecipientMayReportIncome Trigger of Table Withhold Code(12104).
    // 13. Purpose of the test is to validate OnAfterGetRecord - CustomerBill Trigger of Report List of Bank Receipts(12170).
    // 14. Purpose of the test is to validate OnValidate - DueDatePaymentLine Trigger of Table Payment Line(12170).
    // 15. Purpose of the test is to validate OnValidate - PrepmtDueDatePaymentLine Trigger of Table Payment Line(12170).
    // 16. Purpose of the test is to validate OnValidate - BankAccountNo Trigger of Table Vendor Bill Header(12181).
    // 17. Purpose of the test is to validate OnValidate - ListDate Trigger of Table Vendor Bill Header(12181).
    // 18. Purpose of the test is to validate OnValidate - CurrencyCode Trigger of Table Vendor Bill Header(12181).
    // 
    // Covers Test Cases for WI - 345563
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                               TFS ID
    // -------------------------------------------------------------------------------------------------------
    // OnValidateDirectCompsAmtBeforeStartItemCost, OnValidateSubContrdAmtBeforeStartItemCost
    // OnValidateDirectRoutingAmtBeforeStartItemCost, OnValidateOverheadRoutingAmtBeforeStartItemCost    278245
    // OnDeleteBillError                                                                                 278236
    // OnDeleteContributionBracket                                                                       278105
    // OnInsertDeferringDueDatesError, OnInsertToDateDeferringDueDatesError                              278369
    // OnDeleteContributionCode                                                                          278487
    // OnDeleteWithholdCode, OnValidateSourceWithholdingTaxWithholdCode                                  279350
    // OnValidateRecipientMayReportIncomeWithholdCode                                                    278157
    // OnAfterGetRecordCustomerBillLineListOfBankRcpt                                                    278275
    // OnValidateDueDatePaymentLineError, OnValidatePrepmtDueDatePaymentLineError                        278748
    // OnValidateBankAccountNoVendorBillHeaderError                                                      279687
    // OnValidateListDateVendorBillHeaderError                                                           279682
    // OnValidateCurrencyCodeVendorBillHeaderError                                                       279511

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DialogCap: Label 'Dialog';
        DisablingFieldMsg: Label 'Disabling the Source-Withholding Tax field will also disable the Recipient May Report Income field. Do you want to continue?';
        RecipientMayReportMsg: Label 'You cannot set the Recipient May Report Income field if the Source-Withholding Tax field is disabled.';
        RecordExistErr: Label 'Record must not exist.';
        ValueMatchErr: Label 'Values must match.';
        LibraryTablesUT: Codeunit "Library - Tables UT";
        ValidatePostingDateQst: Label 'Operation Occurred Date will be modified according to Posting Date. Do you want to continue?';
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDirectCompsAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - DirectComponentsAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize();
        BeforeStartItemCost."Direct Routing Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Direct Components Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Direct Components Amount" + BeforeStartItemCost."Direct Routing Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSubContrdAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - SubcontractedAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize();
        BeforeStartItemCost."Direct Components Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Subcontracted Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Direct Components Amount" + BeforeStartItemCost."Subcontracted Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDirectRoutingAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - DirectRoutingAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize();
        BeforeStartItemCost."Overhead Routing Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Direct Routing Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Overhead Routing Amount" + BeforeStartItemCost."Direct Routing Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateOverheadRoutingAmtBeforeStartItemCost()
    var
        BeforeStartItemCost: Record "Before Start Item Cost";
    begin
        // Purpose of the test is to validate OnValidate - OverheadRoutingAmount Trigger of Table Before Start Item Cost(12133).
        // Setup.
        Initialize();
        BeforeStartItemCost."Subcontracted Amount" := LibraryRandom.RandDec(100, 2);

        // Exercise.
        BeforeStartItemCost.Validate("Overhead Routing Amount", LibraryRandom.RandDec(100, 2));

        // Verify.
        BeforeStartItemCost.TestField(
          "Production Amount", BeforeStartItemCost."Overhead Routing Amount" + BeforeStartItemCost."Subcontracted Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteBillError()
    var
        Bill: Record Bill;
        PaymentMethod: Record "Payment Method";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Bill(12180).
        // Setup.
        Initialize();
        Bill.Code := LibraryUTUtility.GetNewCode();
        Bill.Insert();
        PaymentMethod.Code := LibraryUTUtility.GetNewCode10();
        PaymentMethod."Bill Code" := Bill.Code;
        PaymentMethod.Insert();

        // Exercise.
        asserterror Bill.Delete(true);

        // Verify actual error: "You cannot delete Bill because there are one or more payment methods for this code."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteContributionBracket()
    var
        ContributionBracketLine: Record "Contribution Bracket Line";
        ContributionBracket: Record "Contribution Bracket";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Contribution Bracket(12108).
        // Setup.
        Initialize();
        ContributionBracket.Code := LibraryUTUtility.GetNewCode10();
        ContributionBracket.Insert();
        ContributionBracketLine.Code := ContributionBracket.Code;
        ContributionBracketLine.Insert();

        // Exercise.
        ContributionBracket.Delete(true);

        // Verify: Verify ContributionBracketLine is deleted successfully.
        ContributionBracketLine.SetRange(Code, ContributionBracket.Code);
        Assert.IsTrue(ContributionBracketLine.IsEmpty, RecordExistErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertDeferringDueDatesError()
    var
        DeferringDueDates: Record "Deferring Due Dates";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173).
        // Setup.
        Initialize();
        DeferringDueDates."No." := CreateDeferringDueDates();
        DeferringDueDates."From-Date" := WorkDate();

        // Exercise.
        asserterror DeferringDueDates.Insert(true);

        // Verify actual error: "From-Date conflicts with another period in Deferring Due Dates."
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnInsertToDateDeferringDueDatesError()
    var
        DeferringDueDates: Record "Deferring Due Dates";
    begin
        // Purpose of the test is to validate OnInsert Trigger of Table Deferring Due Dates(12173) when To-Date conflicts with another period.
        // Setup.
        Initialize();
        DeferringDueDates."No." := CreateDeferringDueDates();
        DeferringDueDates."From-Date" := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        DeferringDueDates."To-Date" := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());

        // Exercise.
        asserterror DeferringDueDates.Insert(true);

        // Verify actual error: "To-Date conflicts with another period in Deferring Due Dates."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteContributionCode()
    var
        ContributionCode: Record "Contribution Code";
        ContributionCodeLine: Record "Contribution Code Line";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Contribution Code(12106).
        // Setup.
        Initialize();
        ContributionCode.Code := LibraryUTUtility.GetNewCode();
        ContributionCode.Insert();
        ContributionCodeLine.Code := ContributionCode.Code;
        ContributionCodeLine.Insert();

        // Exercise.
        ContributionCode.Delete(true);

        // Verify: Verify ContributionCodeLine is deleted successfully.
        ContributionCodeLine.SetRange(Code, ContributionCode.Code);
        Assert.IsTrue(ContributionCodeLine.IsEmpty, RecordExistErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table Withhold Code(12104).
        // Setup.
        Initialize();
        WithholdCode.Code := LibraryUTUtility.GetNewCode();
        WithholdCode.Insert();
        WithholdCodeLine."Withhold Code" := WithholdCode.Code;
        WithholdCodeLine.Insert();

        // Exercise.
        WithholdCode.Delete(true);

        // Verify: Verify WithholdCodeLine is deleted successfully.
        WithholdCodeLine.SetRange("Withhold Code", WithholdCode.Code);
        Assert.IsTrue(WithholdCodeLine.IsEmpty, RecordExistErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSourceWithholdingTaxWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
    begin
        // Purpose of the test is to validate OnValidate - SourceWithholdingTax Trigger of Table Withhold Code(12104).
        // Setup.
        Initialize();
        WithholdCode.Code := LibraryUTUtility.GetNewCode();
        WithholdCode."Recipient May Report Income" := true;

        // Exercise.
        WithholdCode.Validate("Source-Withholding Tax", false);

        // Verify: Verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateRecipientMayReportIncomeWithholdCode()
    var
        WithholdCode: Record "Withhold Code";
    begin
        // Purpose of the test is to validate OnValidate - RecipientMayReportIncome Trigger of Table Withhold Code(12104).
        // Setup.
        Initialize();
        WithholdCode.Code := LibraryUTUtility.GetNewCode();

        // Exercise.
        WithholdCode.Validate("Recipient May Report Income", true);

        // Verify: Verification done in MessageHandler.
    end;

    [Test]
    [HandlerFunctions('ListOfBankReceiptsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerBillLineListOfBankRcpt()
    var
        CustomerBillLine: Record "Customer Bill Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - CustomerBill Trigger of Report List of Bank Receipts(12170).
        // Setup.
        Initialize();
        CreateCustomerBill(CustomerBillLine);
        LibraryVariableStorage.Enqueue(CustomerBillLine."Customer Bill No.");  // Enqueue for ListOfBankReceiptsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"List of Bank Receipts");

        // Verify: Verify values of No_CustBillHdr, CustNo_CustBillLine on Report List of Bank Receipts(12170).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_CustBillHdr', CustomerBillLine."Customer Bill No.");
        LibraryReportDataset.AssertElementWithValueExists('CustNo_CustBillLine', CustomerBillLine."Customer No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateDueDatePaymentLineError()
    var
        PaymentLines: Record "Payment Lines";
    begin
        // Purpose of the test is to validate OnValidate - DueDatePaymentLine Trigger of Table Payment Line(12170).
        // Setup.
        Initialize();
        CreatePaymentLine(PaymentLines, PaymentLines."Sales/Purchase"::Sales, CreateSalesHeader());

        // Exercise.
        asserterror PaymentLines.Validate("Due Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Verify actual error: "Due Date must be greater than or equal to Document Date."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePrepmtDueDatePaymentLineError()
    var
        PaymentLines: Record "Payment Lines";
    begin
        // Purpose of the test is to validate OnValidate - PrepmtDueDatePaymentLine Trigger of Table Payment Line(12170).
        // Setup.
        Initialize();
        CreatePaymentLine(PaymentLines, PaymentLines."Sales/Purchase"::Purchase, CreatePurchaseHeader());

        // Exercise.
        asserterror
          PaymentLines.Validate("Pmt. Discount Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Verify actual error: "Pmt. Discount Date must be greater than or equal to Document Date."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBankAccountNoVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnValidate - BankAccountNo Trigger of Table Vendor Bill Header(12181).
        // Setup.
        Initialize();
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode();

        // Exercise.
        asserterror VendorBillHeader.Validate("Bank Account No.", CreateBankAccount(true));  // Blocekd as True.

        // Verify actual error: "Bank Account No. is blocked."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateListDateVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnValidate - ListDate Trigger of Table Vendor Bill Header(12181).
        // Setup.
        Initialize();
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        VendorBillHeader."Posting Date" := WorkDate();

        // Exercise.
        asserterror VendorBillHeader.Validate("List Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Verify actual error: "List Date must not be greater than Posting Date."
        Assert.ExpectedErrorCode(DialogCap);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCurrencyCodeVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnValidate - CurrencyCode Trigger of Table Vendor Bill Header(12181).
        // Setup.
        Initialize();
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode();

        // Exercise.
        asserterror VendorBillHeader.Validate("Currency Code", LibraryUTUtility.GetNewCode10());

        // Verify actual error: "It's not possible to change Currency Code because there are Vendor Bill Line associated to this Vendor Bill Header."
        Assert.ExpectedErrorCode('DB:PrimRecordNotFound');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccountLengthOfSalesInvoiceHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 304160] Length of "Sales Invoice Header"."Bank Account" must be equal to lenght of "Sales Header"."Bank Account"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          SalesHeader, SalesHeader.FieldNo("Bank Account"),
          SalesInvoiceHeader, SalesInvoiceHeader.FieldNo("Bank Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccountLengthOfServiceInvoiceHeader()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 304160] Length of "Service Invoice Header"."Bank Account" must be equal to lenght of "Service Header"."Bank Account"
        Initialize();

        LibraryTablesUT.CompareFieldTypeAndLength(
          ServiceHeader, ServiceHeader.FieldNo("Bank Account"),
          ServiceInvoiceHeader, ServiceInvoiceHeader.FieldNo("Bank Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateSalesDisabled()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [UI] [Sales]
        // [SCENARIO 326053] When the option is disabled in Sales & Recievables Setup and Posting Date is validated to a date later than Operation Occurred Date - no confirm
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was disabled in setup
        SetOccurredDateChangeNotifySales(false);

        // [GIVEN] Sales Header with Posting date and Operation Occurred Date = 15.01.2000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 20.01.2000.
        SalesHeader.Validate("Posting Date", SalesHeader."Posting Date" + LibraryRandom.RandInt(10));

        // [THEN] The value of Operation Occurred Date is changed
        SalesHeader.TestField("Operation Occurred Date", SalesHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateSalesConfirmed()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [UI] [Sales]
        // [SCENARIO 326053] When the option is enabled in Sales & Recievables Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when yes - Validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was enabled in setup
        SetOccurredDateChangeNotifySales(true);

        // [GIVEN] Sales Header with Posting date and Operation Occurred Date = 15.01.2000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 20.01.2000. YES is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Validate("Posting Date", SalesHeader."Posting Date" + LibraryRandom.RandInt(10));
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] The value of Operation Occurred Date is changed
        SalesHeader.TestField("Operation Occurred Date", SalesHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateSalesNotConfirmed()
    var
        SalesHeader: Record "Sales Header";
        OldOperationOccurredDate: Date;
    begin
        // [UI] [Sales]
        // [SCENARIO 326053] When the option is enabled in Sales & Recievables Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when No - don't validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was enabled in setup
        SetOccurredDateChangeNotifySales(true);

        // [GIVEN] Sales Header with Posting date and Operation Occurred Date = 15.01.2000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        OldOperationOccurredDate := SalesHeader."Operation Occurred Date";

        // [WHEN] Validate Posting Date to 20.01.2000. NO is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(false);
        SalesHeader.Validate("Posting Date", SalesHeader."Posting Date" + LibraryRandom.RandInt(10));
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] The value of Operation Occurred Date is not changed
        SalesHeader.TestField("Operation Occurred Date", OldOperationOccurredDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDatePurchDisabled()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [UI] [Purchase]
        // [SCENARIO 326053] When the option is disabled in Purchases & Payables Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when yes - Validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was disabled in setup
        SetOccurredDateChangeNotifyPurchase(false);

        // [GIVEN] Purchase Header with Posting date and Operation Occurred Date = 15.01.2000
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 20.01.2000. YES is clicked in confirm
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Posting Date" + LibraryRandom.RandInt(10));

        // [THEN] The value of Operation Occurred Date is changed
        PurchaseHeader.TestField("Operation Occurred Date", PurchaseHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDatePurchConfirmed()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [UI] [Purchase]
        // [SCENARIO 326053] When the option is enabled in Purchases & Payables Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when yes - Validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was enabled in setup
        SetOccurredDateChangeNotifyPurchase(true);

        // [GIVEN] Purchase Header with Posting date and Operation Occurred Date = 15.01.2000
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 20.01.2000. YES is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(true);
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Posting Date" + LibraryRandom.RandInt(10));
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] The value of Operation Occurred Date is changed
        PurchaseHeader.TestField("Operation Occurred Date", PurchaseHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDatePurchNotConfirmed()
    var
        PurchaseHeader: Record "Purchase Header";
        OldOperationOccurredDate: Date;
    begin
        // [UI] [Purchases]
        // [SCENARIO 326053] When the option is enabled in Purchases & Payables Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when No - don't validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was enabled in setup
        SetOccurredDateChangeNotifyPurchase(true);

        // [GIVEN] Purchase Header with Posting date and Operation Occurred Date = 15.01.2000
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        OldOperationOccurredDate := PurchaseHeader."Operation Occurred Date";

        // [WHEN] Validate Posting Date to 20.01.2000. NO is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(false);
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Posting Date" + LibraryRandom.RandInt(10));
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] The value of Operation Occurred Date is not changed
        PurchaseHeader.TestField("Operation Occurred Date", OldOperationOccurredDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateServiceDisabled()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [UI] [Service]
        // [SCENARIO 326053] When the option is disabled in Service Management Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when yes - Validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify disabled was enabled in setup
        SetOccurredDateChangeNotifyService(false);

        // [GIVEN] Service Header with Posting date and Operation Occurred Date = 15.01.2000
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 20.01.2000. YES is clicked in confirm
        ServiceHeader.Validate("Posting Date", ServiceHeader."Posting Date" + LibraryRandom.RandInt(10));

        // [THEN] The value of Operation Occurred Date is changed
        ServiceHeader.TestField("Operation Occurred Date", ServiceHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateServiceConfirmed()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [UI] [Service]
        // [SCENARIO 326053] When the option is enabled in Service Management Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when yes - Validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was enabled in setup
        SetOccurredDateChangeNotifyService(true);

        // [GIVEN] Service Header with Posting date and Operation Occurred Date = 15.01.2000
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 20.01.2000. YES is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(true);
        ServiceHeader.Validate("Posting Date", ServiceHeader."Posting Date" + LibraryRandom.RandInt(10));
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] The value of Operation Occurred Date is changed
        ServiceHeader.TestField("Operation Occurred Date", ServiceHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateServiceNotConfirmed()
    var
        ServiceHeader: Record "Service Header";
        OldOperationOccurredDate: Date;
    begin
        // [UI] [Service]
        // [SCENARIO 326053] When the option is enabled in Service Management Setup and Posting Date is validated to a date later than Operation Occurred Date - confirm pops up, when No - don't validate
        Initialize();

        // [GIVEN] Occurred Date Change Notify option was enabled in setup
        SetOccurredDateChangeNotifyService(true);

        // [GIVEN] Service Header with Posting date and Operation Occurred Date = 15.01.2000
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');
        OldOperationOccurredDate := ServiceHeader."Operation Occurred Date";

        // [WHEN] Validate Posting Date to 20.01.2000. NO is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(false);
        ServiceHeader.Validate("Posting Date", ServiceHeader."Posting Date" + LibraryRandom.RandInt(10));
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] The value of Operation Occurred Date is not changed
        ServiceHeader.TestField("Operation Occurred Date", OldOperationOccurredDate);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateSalesToEarlierDateConfirmed()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [UI] [Sales]
        // [SCENARIO 326053] When Posting Date is validated to a date earlier than Operation Occurred Date - confirm pops up, when yes - Validate
        Initialize();

        // [GIVEN] Sales Header with Posting date and Operation Occurred Date = 15.01.2000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 10.01.2000. YES is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader."Document Date" := SalesHeader."Posting Date" - LibraryRandom.RandInt(10);
        SalesHeader.Validate("Posting Date", SalesHeader."Document Date");
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] The value of Operation Occurred Date is changed
        SalesHeader.TestField("Operation Occurred Date", SalesHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithDequeue')]
    [Scope('OnPrem')]
    procedure NotificationOnValidatePostingDateSalesToEarlierDateNotConfirmed()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [UI] [Sales]
        // [SCENARIO 326053] When Posting Date is validated to a date earlier than Operation Occurred Date - confirm pops up, when no - Error
        Initialize();

        // [GIVEN] Sales Header with Posting date and Operation Occurred Date = 15.01.2000
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] Validate Posting Date to 10.01.2000. NO is clicked in confirm
        LibraryVariableStorage.Enqueue(ValidatePostingDateQst);
        LibraryVariableStorage.Enqueue(false);
        SalesHeader."Document Date" := SalesHeader."Posting Date" - LibraryRandom.RandInt(10);
        asserterror SalesHeader.Validate("Posting Date", SalesHeader."Document Date");
        // UI handled by ConfirmHandlerWithDequeue

        // [THEN] There is a validation error
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('Posting Date cannot be less than Operation Occurred Date.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRemainingAmountFunctionOfSalesInvHeaderReturnsTotalForMultipleDocuments()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustNo: Code[20];
        DocNo: Code[20];
        i: Integer;
        Amount: Decimal;
        ExpectedAmount: Decimal;
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 454530] GetRemainingAmount function of Sales Invoice Header tables returns the totals of all customer ledger entries by customer, document no. and posting date

        Initialize();
        CustNo := LibrarySales.CreateCustomerNo();
        DocNo := LibraryUTUtility.GetNewCode();
        // [GIVEN] Three customer ledger entries with customer "X", Posting Date = 01.01.2022, "Document No." = "Y". Total amount of all entries is 100
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do begin
            Amount := LibraryRandom.RandDec(100, 2);
            MockInvCustLedgEntry(CustNo, WorkDate(), DocNo, Amount);
            ExpectedAmount += Amount;
        end;
        // [GIVEN] Customer ledger entry with customer "XX", Posting Date = 01.01.2022, "Document No." = "Y" and amount = 10
        MockInvCustLedgEntry(LibrarySales.CreateCustomerNo(), WorkDate(), DocNo, LibraryRandom.RandDec(100, 2));
        // [GIVEN] Customer ledger entry with customer "X", Posting Date = 02.01.2022, "Document No." = "Y" and amount = 20
        MockInvCustLedgEntry(CustNo, WorkDate() + 1, DocNo, LibraryRandom.RandDec(100, 2));
        // [GIVEN] Customer ledger entry with customer "X", Posting Date = 01.01.2022, "Document No." = "YY" and amount = 30
        MockInvCustLedgEntry(CustNo, WorkDate(), LibraryUTUtility.GetNewCode(), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Sales invoice header has customer "X", Posting Date = 01.01.2022, "Document No." = "Y"
        SalesInvoiceHeader."No." := DocNo;
        SalesInvoiceHeader."Bill-to Customer No." := CustNo;
        SalesInvoiceHeader."Posting Date" := WorkDate();

        // [WHEN] Get the result of GetRemainingAmount function of Sales Invoice Header table
        ActualAmount := SalesInvoiceHeader.GetRemainingAmount();

        // [THEN] The result is 100
        Assert.AreEqual(ExpectedAmount, ActualAmount, '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(Blocked: Boolean): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Blocked := Blocked;
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBill(var CustomerBillLine: Record "Customer Bill Line")
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        CustomerBillHeader."No." := LibraryUTUtility.GetNewCode();
        CustomerBillHeader."Bank Account No." := CreateBankAccount(false);  // Blocked as false.
        CustomerBillHeader.Insert();
        CustomerBillLine."Customer Bill No." := CustomerBillHeader."No.";
        CustomerBillLine."Customer No." := CreateCustomer();
        CustomerBillLine.Insert();
    end;

    local procedure CreateDeferringDueDates(): Code[20]
    var
        DeferringDueDates: Record "Deferring Due Dates";
    begin
        DeferringDueDates."No." := LibraryUTUtility.GetNewCode();
        DeferringDueDates."From-Date" := WorkDate();
        DeferringDueDates."To-Date" := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Use random Date.
        DeferringDueDates.Insert();
        exit(DeferringDueDates."No.");
    end;

    local procedure CreatePaymentLine(var PaymentLines: Record "Payment Lines"; SalesPurchase: Option; "Code": Code[20])
    begin
        PaymentLines."Sales/Purchase" := SalesPurchase;
        PaymentLines.Type := PaymentLines.Type::Order;
        PaymentLines.Code := Code;
        PaymentLines.Insert();
    end;

    local procedure CreatePurchaseHeader(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Document Date" := WorkDate();
        PurchaseHeader.Insert();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateSalesHeader(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Document Date" := WorkDate();
        SalesHeader.Insert();
        exit(SalesHeader."No.");
    end;

    local procedure SetOccurredDateChangeNotifySales(NewValue: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Notify On Occur. Date Change", NewValue);
        SalesReceivablesSetup.Modify();
    end;

    local procedure SetOccurredDateChangeNotifyPurchase(NewValue: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Notify On Occur. Date Change", NewValue);
        PurchasesPayablesSetup.Modify();
    end;

    local procedure SetOccurredDateChangeNotifyService(NewValue: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Notify On Occur. Date Change", NewValue);
        ServiceMgtSetup.Modify();
    end;

    local procedure MockInvCustLedgEntry(CustNo: Code[20]; PostingDate: Date; DocNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustNo;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := DocNo;
        CustLedgerEntry.Insert();
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(Question, StrSubstNo(DisablingFieldMsg), ValueMatchErr);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(Message, StrSubstNo(RecipientMayReportMsg), ValueMatchErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ListOfBankReceiptsRequestPageHandler(var ListOfBankReceipts: TestRequestPage "List of Bank Receipts")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ListOfBankReceipts."Customer Bill Header".SetFilter("No.", No);
        ListOfBankReceipts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithDequeue(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, ValueMatchErr);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

