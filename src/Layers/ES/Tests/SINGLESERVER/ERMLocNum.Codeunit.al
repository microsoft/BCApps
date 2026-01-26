codeunit 144161 "ERM Loc Num"
{
    // // [FEATURE] [Payment Journal]
    // 1. Verify error message while using Print Check on Payment Journal Page.
    // 2. Verify error message while using Print Check on Payment Journal Page with Vendor Blocked Payment.
    // 3. Verify error message while using Print Check on Payment Journal Page with Vendor Blocked All.
    // 4. Verify error message while using Print Check on Payment Journal Page with Customer Blocked All.
    // 
    // Covers Test Cases for WI - 351178
    // -----------------------------------------------------------------------
    // Test Function Name                                               TFS ID
    // -----------------------------------------------------------------------
    // PrintCheckPaymentJournalError                                    151235
    // PrintCheckPaymentJournalVendorBlockedPaymentError                154770
    // PrintCheckPaymentJournalVendorBlockedAllError                    154770
    // PrintCheckPaymentJournalCustomerBlockedAllError                  154772

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        AmountMustPositiveErr: Label 'The total amount of check %1 is -%2. The amount must be positive.', Comment = '%1= Field Value, %2 = Field value';
        BlockedMustNotAllVendorErr: Label 'Blocked must not be All for Vendor';
        BlockedMustNotPaymentVendorErr: Label 'Blocked must not be Payment for Vendor';
        BlockedMustNotAllCustomerErr: Label 'Blocked must not be All for Customer';

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCheckPaymentJournalError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Print] [Check] [UI] [Vendor]
        // [SCENARIO] Verify error message while using Print Check on Payment Journal Page.
        Initialize();

        // [GIVEN] Payment journal with vendor and negative amount
        CreatePaymentJournal(PaymentJournal, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());
        BankAccount.Get(PaymentJournal."Bal. Account No.".Value);

        // [WHEN] Print Check
        asserterror PaymentJournal.PrintCheck.Invoke();  // Opens CheckRequestPageHandler.

        // [THEN] There is an error: "The total amount of check is Negative. The amount must be positive"
        Assert.ExpectedError(
          StrSubstNo(AmountMustPositiveErr, IncStr(BankAccount."Last Check No."), PaymentJournal."Credit Amount".Value));
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCheckPaymentJournalVendorBlockedPaymentError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Print] [Check] [UI] [Vendor]
        // [SCENARIO] Verify error message while using Print Check on Payment Journal Page with Vendor Blocked Payment.
        Initialize();

        // [GIVEN] Payment journal with vendor having Vendor."Blocked" = "Payment"
        CreatePaymentJournal(PaymentJournal, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());
        UpdateVendor(PaymentJournal."Account No.".Value, Vendor.Blocked::Payment);

        // [WHEN] Print Check
        asserterror PaymentJournal.PrintCheck.Invoke();  // Opens CheckRequestPageHandler.

        // [THEN] There is an error: "Blocked must not be Payment for Vendor"
        Assert.ExpectedError(BlockedMustNotPaymentVendorErr);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCheckPaymentJournalVendorBlockedAllError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Print] [Check] [UI] [Vendor]
        // [SCENARIO] Verify error message while using Print Check on Payment Journal Page with Vendor Blocked All.
        Initialize();

        // [GIVEN] Payment journal with vendor having Vendor."Blocked" = "All"
        CreatePaymentJournal(PaymentJournal, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo());
        UpdateVendor(PaymentJournal."Account No.".Value, Vendor.Blocked::All);

        // [WHEN] Print Check
        asserterror PaymentJournal.PrintCheck.Invoke();  // Opens CheckRequestPageHandler.

        // [THEN] There is an error: "Blocked must not be All for Vendor"
        Assert.ExpectedError(BlockedMustNotAllVendorErr);
    end;

    [Test]
    [HandlerFunctions('CheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCheckPaymentJournalCustomerBlockedAllError()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Print] [Check] [UI] [Customer]
        // [SCENARIO] Verify error message while using Print Check on Payment Journal Page with Customer Blocked All.
        Initialize();

        // [GIVEN] Payment journal with customer having Customer."Blocked" = "All"
        CreatePaymentJournal(PaymentJournal, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo());
        UpdateCustomer(PaymentJournal."Account No.".Value, Customer.Blocked::All);

        // [WHEN] Print Check
        asserterror PaymentJournal.PrintCheck.Invoke();  // Opens CheckRequestPageHandler.

        // [THEN] There is an error: "Blocked must not be All for Customer"
        Assert.ExpectedError(BlockedMustNotAllCustomerErr);
    end;

    [Test]
    [HandlerFunctions('VoidElectronicPaymentsRPH,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VoidElectronicVendorPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Electronic Payments] [Void] [Vendor] [Payment]
        // [SCENARIO 202894] Exported electronic vendor payment can be voided
        Initialize();

        // [GIVEN] Exported vendor payment journal line:
        // [GIVEN] "Document Type" = "Payment"
        // [GIVEN] "Account Type" = "Vendor"
        // [GIVEN] "Bank Payment Type" = "Electronic Payment"
        // [GIVEN] "Exported to Payment File" = TRUE
        CreateElectronicPmtJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, CreateVendorWithElectronicPmtSetup(), -1);

        // [WHEN] Perform "Electronic Payments" -> "Void" action from the payment journal
        RunVoidElectronicPayments(GenJournalLine);

        // [THEN] The payment journal line has been voided and PmtJournalLine."Exported to Payment File" = FALSE
        GenJournalLine.Find();
        Assert.AreEqual(false, GenJournalLine."Exported to Payment File", GenJournalLine.FieldCaption("Exported to Payment File"));
    end;

    [Test]
    [HandlerFunctions('VoidElectronicPaymentsRPH,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VoidElectronicCustomerRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Electronic Payments] [Void] [Customer] [Refund]
        // [SCENARIO 202894] Exported electronic customer refund can be voided
        Initialize();

        // [GIVEN] Exported customer payment journal line:
        // [GIVEN] "Document Type" = "Refund"
        // [GIVEN] "Account Type" = "Customer"
        // [GIVEN] "Bank Payment Type" = "Electronic Payment"
        // [GIVEN] "Exported to Payment File" = TRUE
        CreateElectronicPmtJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, CreateCustomerWithElectronicPmtSetup(), 1);

        // [WHEN] Perform "Electronic Payments" -> "Void" action from the payment journal
        RunVoidElectronicPayments(GenJournalLine);

        // [THEN] The payment journal line has been voided and PmtJournalLine."Exported to Payment File" = FALSE
        GenJournalLine.Find();
        Assert.AreEqual(false, GenJournalLine."Exported to Payment File", GenJournalLine.FieldCaption("Exported to Payment File"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateElecPmtForVendPmtJnlLineInCaseOfUseForElecPmtIsTrue()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Electronic Payments] [Vendor] [Payment]
        // [SCENARIO 205188] "Bank Payment Type" can be validated with "Electronic Payment" value for the vendor payment journal line in case of vendor bank account having "Use For Electronic Payments" = TRUE
        Initialize();
        // [GIVEN] Vendor with vendor bank account having "Use For Electronic Payments" = TRUE
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorBankAccountNo(VendorNo, true);
        // [GIVEN] Payment journal line for the vendor payment: "Document Type" = "Payment", "Account Type" = "Vendor", "Bal. Account Type" = "Bank Account"
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), 0);
        // [WHEN] Validate "Bank Payment Type" = "Electronic Payment"
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Modify(true);
        // [THEN] Payment journal line's "Bank Payment Type" has been validated with "Electronic Payment" value
        Assert.AreEqual(GenJournalLine."Bank Payment Type"::"Electronic Payment", GenJournalLine."Bank Payment Type", GenJournalLine.FieldCaption("Bank Payment Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateElecPmtForVendPmtJnlLineInCaseOfUseForElecPmtIsFalse()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Electronic Payments] [Vendor] [Payment]
        // [SCENARIO 205188] "Bank Payment Type" can not be validated with "Electronic Payment" value for the vendor payment journal line in case of vendor bank account having "Use For Electronic Payments" = FALSE
        Initialize();
        // [GIVEN] Vendor with vendor bank account having "Use For Electronic Payments" = FALSE
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorBankAccountNo(VendorNo, false);
        // [GIVEN] Payment journal line for the vendor payment: "Document Type" = "Payment", "Account Type" = "Vendor", "Bal. Account Type" = "Bank Account"
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), 0);
        // [WHEN] Validate "Bank Payment Type" = "Electronic Payment"
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        asserterror GenJournalLine.Modify(true);
        // [THEN] There is an error : "In order to use Electronic Payments, one of the Bank Accounts for the vendor must have the field Use For Electronic Payments selected."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          'In order to use Electronic Payments, one of the Bank Accounts for' +
          ' the vendor must have the field Use For Electronic Payments selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateElectronicPaymentForCustomerRefundJnlLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Electronic Payments] [Customer] [Refund]
        // [SCENARIO 205188] "Bank Payment Type" can be validated with "Electronic Payment" value for the customer refund journal line
        Initialize();
        // [GIVEN] Customer with customer bank account
        CustomerNo := CreateCustomerWithElectronicPmtSetup();
        CreateCustomerBankAccountNo(CustomerNo);
        // [GIVEN] Payment journal line for the customer refund: "Document Type" = "Refund", "Account Type" = "Customer", "Bal. Account Type" = "Bank Account"
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), 0);
        // [WHEN] Validate "Bank Payment Type" = "Electronic Payment"
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Modify(true);
        // [THEN] Payment journal line's "Bank Payment Type" has been validated with "Electronic Payment" value
        Assert.AreEqual(GenJournalLine."Bank Payment Type"::"Electronic Payment", GenJournalLine."Bank Payment Type", GenJournalLine.FieldCaption("Bank Payment Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertElecPmtJnlLineForVendorInCaseOfUseForElecPmtIsTrue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Electronic Payments] [Vendor] [Payment]
        // [SCENARIO 205188] Payment Journal Line with "Bank Payment Type" = "Electronic Payment" with can be inserted for the vendor payment in case of vendor bank account having "Use For Electronic Payments" = TRUE
        Initialize();
        // [GIVEN] Vendor with vendor bank account having "Use For Electronic Payments" = TRUE
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorBankAccountNo(VendorNo, true);
        // [GIVEN] A new payment journal line for the vendor payment: "Document Type" = "Payment", "Account Type" = "Vendor", "Bal. Account Type" = "Bank Account", "Bank Payment Type" = "Electronic Payment"
        InitElecPmtJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo);
        // [WHEN] Insert the payment journal line
        GenJournalLine.Insert(true);
        // [THEN] Payment journal line has been inserted and "Bank Payment Type" has been validated with "Electronic Payment" value
        Assert.AreEqual(GenJournalLine."Bank Payment Type"::"Electronic Payment", GenJournalLine."Bank Payment Type", GenJournalLine.FieldCaption("Bank Payment Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertElecPmtJnlLineForVendorInCaseOfUseForElecPmtIsFalse()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Electronic Payments] [Vendor] [Payment]
        // [SCENARIO 205188] Payment Journal Line with "Bank Payment Type" = "Electronic Payment" with can not be inserted for the vendor payment in case of vendor bank account having "Use For Electronic Payments" = FALSE
        Initialize();
        // [GIVEN] Vendor with vendor bank account having "Use For Electronic Payments" = FALSE
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorBankAccountNo(VendorNo, false);
        // [GIVEN] A new payment journal line for the vendor payment: "Document Type" = "Payment", "Account Type" = "Vendor", "Bal. Account Type" = "Bank Account", "Bank Payment Type" = "Electronic Payment"
        InitElecPmtJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo);
        // [WHEN] Insert the payment journal line
        asserterror GenJournalLine.Insert(true);
        // [THEN] There is an error : "In order to use Electronic Payments, one of the Bank Accounts for the vendor must have the field Use For Electronic Payments selected."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          'In order to use Electronic Payments, one of the Bank Accounts for' +
          ' the vendor must have the field Use For Electronic Payments selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertElecPmtJnlLineForCustomerRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Electronic Payments] [Customer] [Refund]
        // [SCENARIO 205188] Payment Journal Line with "Bank Payment Type" = "Electronic Payment" with can be inserted for the customer refund
        Initialize();
        // [GIVEN] Customer with customer bank account
        CustomerNo := CreateCustomerWithElectronicPmtSetup();
        CreateCustomerBankAccountNo(CustomerNo);
        // [GIVEN] A new payment journal line for the customer refund: "Document Type" = "Refund", "Account Type" = "Customer", "Bal. Account Type" = "Bank Account", "Bank Payment Type" = "Electronic Payment"
        InitElecPmtJournalLine(GenJournalLine, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, CustomerNo);
        // [WHEN] Insert the payment journal line
        GenJournalLine.Insert(true);
        // [THEN] Payment journal line has been inserted and "Bank Payment Type" has been validated with "Electronic Payment" value
        Assert.AreEqual(GenJournalLine."Bank Payment Type"::"Electronic Payment", GenJournalLine."Bank Payment Type", GenJournalLine.FieldCaption("Bank Payment Type"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Check No.", Format(LibraryRandom.RandInt(100)));
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomerWithElectronicPmtSetup(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccountNo(CustomerNo: Code[20])
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
    end;

    local procedure CreatePaymentJournal(var PaymentJournal: TestPage "Payment Journal"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.DeleteAll();
        Commit();  // COMMIT is required here.
        PaymentJournal.OpenEdit();
        PaymentJournal."Document No.".SetValue(LibraryUtility.GenerateGUID());
        PaymentJournal."Account Type".SetValue(AccountType);
        PaymentJournal."Account No.".SetValue(AccountNo);
        PaymentJournal."Credit Amount".SetValue(LibraryRandom.RandDec(100, 2));
        PaymentJournal."Bal. Account Type".SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");
        PaymentJournal."Bal. Account No.".SetValue(CreateBankAccount());
        PaymentJournal."Bank Payment Type".SetValue(GenJournalLine."Bank Payment Type"::"Computer Check");
        PaymentJournal.Close();
        Commit();  // COMMIT is required here.

        PaymentJournal.OpenEdit();
        PaymentJournal.FILTER.SetFilter("Account No.", PaymentJournal."Account No.".Value);
        LibraryVariableStorage.Enqueue(PaymentJournal."Bal. Account No.".Value);  // Enqueue for CheckRequestPageHandler.
    end;

    local procedure CreateVendorWithElectronicPmtSetup() VendorNo: Code[20]
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        CreateVendorBankAccountNo(VendorNo, true);
    end;

    local procedure CreateVendorBankAccountNo(VendorNo: Code[20]; UseForElectronicPayments: Boolean)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Use For Electronic Payments", UseForElectronicPayments);
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateElectronicPmtJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Sign: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            DocumentType, AccountType, AccountNo,
            GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(),
            Sign * LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("Exported to Payment File", true);
        GenJournalLine.Modify(true);
    end;

    local procedure InitElecPmtJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Line No.", LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No.")));
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document Type", DocumentType);
        GenJournalLine.Validate("Account Type", AccountType);
        GenJournalLine.Validate("Account No.", AccountNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
    end;

    local procedure UpdateCustomer(CustomerNo: Code[20]; Blocked: Enum "Customer Blocked")
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate(Blocked, Blocked);
        Customer.Modify(true);
        Commit();  // COMMIT is required here.
    end;

    local procedure UpdateVendor(VendorNo: Code[20]; Blocked: Enum "Vendor Blocked")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate(Blocked, Blocked);
        Vendor.Modify(true);
        Commit();  // COMMIT is required here.
    end;

    local procedure RunVoidElectronicPayments(GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRecFilter();
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");
        Commit();
        REPORT.Run(REPORT::"Void Electronic Payments", true, false, GenJournalLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequestPageHandler(var Check: TestRequestPage Check)
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        Check.BankAccount.SetValue(BankAccountNo);
        Check.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VoidElectronicPaymentsRPH(var VoidElectronicPayments: TestRequestPage "Void Electronic Payments")
    begin
        VoidElectronicPayments."BankAccount.""No.""".SetValue(LibraryVariableStorage.DequeueText());
        VoidElectronicPayments.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

