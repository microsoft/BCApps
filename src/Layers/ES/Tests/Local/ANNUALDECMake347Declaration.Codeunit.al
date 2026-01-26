codeunit 147307 "ANNUALDEC-Make347 Declaration"
{
    // // [FEATURE] [Make 347 Declaration]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Test347DeclarationParameter: Record "Test 347 Declaration Parameter";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        Library347Declaration: Codeunit "Library - 347 Declaration";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ESTxt: Label 'ES';
        PTTxt: Label 'PT';
        DETxt: Label 'DE';
        USTxt: Label 'US';
        IgnoreIn347ReportMessage: Label 'The account has entries and/or Balance. Changing the value of this field may cause inconsistencies report 347.';
        MissingTelephoneNumberError: Label 'Telephone Number must be 9 digits without spaces or special characters.';
        MissingContactNameError: Label 'Contact Name must be entered.';
        MissingCustomerPostCodeError: Label 'Postal Code is missing on customer card %1.';
        MissingDeclarationNumberError: Label 'Declaration Number must be entered.';
        MissingVendorPostCodeError: Label 'Postal Code is missing on vendor card %1';
        NoRecordFoundMessage: Label 'No records were found to be included in the declaration. The process has been aborted. No file will be created.';
        UsingIgnoredGLAccountErr: Label 'At least one of the G/L Accounts selected for payments in cash is set up to be ignored in 347 report.';
        IgnoreDuplicateVatRegNoErr: Label 'This VAT registration number has already been entered for the following';
        CustomerOrVendorWithoutVATRegistrationNoQst: Label 'At least one Customer/Vendor does not have any value in the VAT Registration No. field. \Only customers or vendors with a value for VAT Registration No. will be included in the file. \\Do you still want to create the 347 Declaration file?';
        EmptySymbolExpectedErr: Label 'Empty symbol expected';

    [Test]
    [HandlerFunctions('IgnoreIn347ReportMessageHandler')]
    [Scope('OnPrem')]
    procedure TestIgnoreIn347ReportFieldIsUpdatedOnGLAccount()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        GLAccountNo: Code[20];
    begin
        // Verify system throws message when "Ignore in 347 Report" is updated.
        // Setup.
        Initialize();
        GLAccountNo := Library347Declaration.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ESTxt);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLAccount.Get(GLAccountNo);
        GLAccount.CalcFields(Balance);

        // Exercise.
        GLAccount.Validate("Ignore in 347 Report", true);

        // Verify: Verify program throws message when "Ignore in 347 Report" is updated.
        // verification has been done in message handler IgnoreIn347ReportMessageHandler.

        // Teardown: Remove VAT registration number from Vendor.
        Library347Declaration.RemoveVATRegistrationNumberFromVendor(PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithoutContactName()
    begin
        // Verify whether system throws error message when Contact Name is not filled in.
        Initialize();
        Test347DeclarationParameter.ContactName := '';
        RunMake347DeclarationReportExpectError(MissingContactNameError);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithoutDeclarationNumber()
    begin
        // Verify whether system throws error message when Declaration Number is not filled in.
        Initialize();
        Test347DeclarationParameter.DeclarationNumber := '';
        RunMake347DeclarationReportExpectError(MissingDeclarationNumberError);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithIncompleteTelephoneNumber()
    begin
        // Verify whether system throws error message when no Telephone Number is filled in.
        Initialize();
        Test347DeclarationParameter.TelephoneNumber := '';
        RunMake347DeclarationReportExpectError(MissingTelephoneNumberError);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPostCodeIsBlankOnCustomer()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Setup Demo Data.
        Initialize();

        // Excercise.
        Library347Declaration.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, ESTxt);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Test347DeclarationParameter.PostingDate := SalesHeader."Posting Date";

        // Verify : Run Make 347 Declaration Report when Post Code is blank on Customer card.
        RunMake347DeclarationReportExpectError(StrSubstNo(MissingCustomerPostCodeError, SalesHeader."Sell-to Customer No."));

        // Teardown: Remove VAT registration number from Customer.
        Library347Declaration.RemoveVATRegistrationNumberFromCustomer(SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPostCodeIsBlankOnVendor()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Setup Demo Data.
        Initialize();

        // Excercise.
        Library347Declaration.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, ESTxt);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Test347DeclarationParameter.PostingDate := PurchaseHeader."Posting Date";

        // Verify : Run Make 347 Declaration Report when Post Code is blank on Vendor card.
        RunMake347DeclarationReportExpectError(StrSubstNo(MissingVendorPostCodeError, PurchaseHeader."Buy-from Vendor No."));

        // Teardown: Remove VAT registration number from Vendor.
        Library347Declaration.RemoveVATRegistrationNumberFromVendor(PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemoVendorOutsideEU()
    var
        VendorNo: Code[20];
        AccountNo: Code[20];
        Amount: Decimal;
        FileName: Text[1024];
        Line: Text[500];
    begin
        // [SCENARIO] Invoice outside EU are picked up in the 347 file
        Initialize();

        // [GIVEN] An invoice has been posted for a vendor in the US
        VendorNo := Library347Declaration.CreateVendorWithCountryCode(USTxt);
        AccountNo := Library347Declaration.CreateGLAccount();

        Amount := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForGLAccount(VendorNo, AccountNo, Amount);

        // [WHEN] Report 347 is run
        FileName := RunMake347DeclarationReport();

        // [THEN] The invoice is included in the 347 file
        Line := Library347Declaration.ReadLineWithCustomerOrVendorOutsideES(FileName, VendorNo);

        // [THEN] The Province code is 99 in the 347 file
        Assert.AreEqual('99', CopyStr(Line, 77, 2), '');

        // [THEN] VAT Registration No. is blank in the 347 file
        Assert.AreEqual('         ', CopyStr(Line, 18, 9), '');

        // [THEN] Country Code is US in the 347 file
        Assert.AreEqual(Format(USTxt), CopyStr(Line, 79, 2), '');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseCreditMemoVendorInEU()
    var
        VendorNo: Code[20];
        AccountNo: Code[20];
        Amount: Decimal;
        FileName: Text[1024];
    begin
        // [SCENARIO] Invoice inside EU are not picked up in the 347 file
        Initialize();

        // [GIVEN] An invoice has been posted for a vendor in DE
        VendorNo := Library347Declaration.CreateVendorWithCountryCode(DETxt);
        AccountNo := Library347Declaration.CreateGLAccount();

        Amount := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForGLAccount(VendorNo, AccountNo, Amount);

        // [WHEN] Report 347 is run
        FileName := RunMake347DeclarationReport();

        // [THEN] No entries for the vendor is included in the 347 file
        Library347Declaration.ValidateFileHasNoLineForCustomerOutsideES(FileName, VendorNo);
    end;

    [Test]
    [HandlerFunctions('NoRecordsFoundMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestForPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify system throws message when purchase credit memo is posted without any payment applied.
        // Setup: Post Purchase Credit Memo without Payment.
        Initialize();
        Test347DeclarationParameter.PostingDate := Library347Declaration.GetNewWorkDate();
        Library347Declaration.CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", ESTxt);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Run 347 Make Declaration Report.
        RunMake347DeclarationReport();

        // Verify: Verify program throws message.
        // verification has been done in message handler NoRecordsFoundMessageHandler.

        // Teardown: Remove VAT registration number from Vendor.
        Library347Declaration.RemoveVATRegistrationNumberFromVendor(PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('NoRecordsFoundMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestForSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify system throws message when sales credit memo is posted without any payment applied.
        // Setup: Post Sales Credit Memo without Payment.
        Initialize();
        Test347DeclarationParameter.PostingDate := Library347Declaration.GetNewWorkDate();
        Library347Declaration.CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", ESTxt);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Run 347 Make Declaration Report.
        RunMake347DeclarationReport();

        // Verify: Verify program throws message.
        // verification has been done in message handler NoRecordsFoundMessageHandler.

        // Teardown: Remove VAT registration number from Customer.
        Library347Declaration.RemoveVATRegistrationNumberFromCustomer(SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('NoRecordsFoundMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestForServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify system throws message when service credit memo is posted without any payment applied.
        // Setup: Post Service Credit Memo without Payment.
        Initialize();
        Test347DeclarationParameter.PostingDate := Library347Declaration.GetNewWorkDate();
        Library347Declaration.CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ESTxt);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Exercise: Run 347 Make Declaration Report.
        RunMake347DeclarationReport();

        // Verify: Verify program throws message.
        // verification has been done in message handler NoRecordsFoundMessageHandler.

        // Teardown: Remove VAT registration number from Vendor.
        Library347Declaration.RemoveVATRegistrationNumberFromCustomer(ServiceHeader."Customer No.");
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithCustomerValidation()
    var
        Customer: Record Customer;
        FileName: Text[1024];
        custNo: Code[20];
    begin
        // Setup: Setup Demo Data.
        Initialize();
        SetRandomCompanyName();

        // Create a Customer
        custNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        Customer.Get(custNo);

        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo, 3000 + LibraryRandom.RandDec(1000, 2));

        // Exercise: Run 347 Make Declaration Report.
        FileName := RunMake347DeclarationReport();

        // Verify: that the produced file gives the expected format.
        ValidateFormat347File(Test347DeclarationParameter, FileName, 'B', Customer."No.", Customer.Name);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithCustomerShortVatRegNo()
    var
        Customer: Record Customer;
        FileName: Text[1024];
        custNo: Code[20];
    begin
        // Setup: Setup Demo Data.
        Initialize();
        SetRandomCompanyName();

        // Create a Customer with at VatRegno that needs padding
        custNo := Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.CreateShortVATRegNo(ESTxt));
        Customer.Get(custNo);

        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo, 3000 + LibraryRandom.RandDec(1000, 2));

        // Exercise: Run 347 Make Declaration Report.
        FileName := RunMake347DeclarationReport();

        // Verify: that the produced file gives the expected format.
        ValidateFormat347File(Test347DeclarationParameter, FileName, 'B', Customer."No.", Customer.Name);
    end;

    [Test]
    [HandlerFunctions('IgnoreDuplicateVatRegNoMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithCustomersSameVatRegNo()
    var
        FileName1: Text[1024];
        FileName2: Text[1024];
        custNo1: Code[20];
        custNo2: Code[20];
        VatRegNo: Text[20];
        Amount1: Decimal;
        Amount2: Decimal;
        CombinedAmount: Decimal;
        Line: Text[1024];
    begin
        // Setup: Setup Demo Data.
        Initialize();

        // Create two Customers with the same Vat Registration No.
        VatRegNo := Library347Declaration.CreateShortVATRegNo(ESTxt);
        custNo1 := Library347Declaration.CreateCustomerWithPostCode(VatRegNo);
        custNo2 := Library347Declaration.CreateCustomerWithPostCode(VatRegNo);

        // Excercise1: Run Make 347 declaration report.
        Amount1 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo1, Amount1);
        FileName1 := RunMake347DeclarationReport();

        // Verify1: that the produced file has the amount for the customer1
        Line := ReadLineWithCustomerOrVendor(FileName1, custNo1);
        Assert.IsTrue(ReadEntryAmount(Line) >= Amount1 * 100, 'Amount for customer1 is wrong');

        // Excercise2: Run Make 347 declaration report with two customers having the same VatRegNo.
        Amount2 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo2, Amount2);
        FileName2 := RunMake347DeclarationReport();

        // Verify: that the produced file has the combined amount for the customers with the same Vat Reg No
        Line := ReadLineWithCustomerOrVendor(FileName2, custNo1);
        CombinedAmount := ReadEntryAmount(Line);
        Assert.IsTrue(CombinedAmount >= (Amount1 + Amount2) * 100, 'Combined Amount is wrong, reading from customer 1');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithCustomerIgnore347()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        FileName: Text[1024];
        custNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        Line: Text[1024];
        account1: Code[20];
        account2: Code[20];
        LineAmount: Decimal;
    begin
        // Verifies that Model 347 file does not contain the Amount which marked as 'Ignore in 347 Report' on a G/L account

        // Setup
        Initialize();

        // Create customer
        custNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));

        // Create a G/L account
        account1 := Library347Declaration.CreateGLAccount();
        GLAccount1.Get(account1);

        // Create a G/L account with Ignore in 347 Report
        account2 := Library347Declaration.CreateGLAccount();
        GLAccount2.Get(account2);
        GLAccount2.Validate("Ignore in 347 Report", true);
        GLAccount2.Modify(true);

        Amount1 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo, Amount1);

        // Post amount on G/L account
        Amount2 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForGLAccount(custNo, GLAccount1."No.", Amount2);

        // Post amount on the other G/L account, this amount should not be included in the report
        Amount3 := 10000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForGLAccount(custNo, GLAccount2."No.", Amount3);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, custNo);
        Line := ReadLineWithCustomerOrVendor(FileName, custNo);
        // Verify that line has the right has amount: Amount1 + Amount2 (plus any VAT), but does not include Amount3
        LineAmount := ReadEntryAmount(Line);
        Assert.IsTrue(LineAmount >= (Amount1 + Amount2) * 100, 'Combined Amount is wrong');
        Assert.IsTrue(LineAmount < (Amount1 + Amount2 + Amount3) * 100, 'Combined Amount is wrong');
    end;

    [Test]
    [HandlerFunctions('IgnoreDuplicateVatRegNoMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithSameCustomerIgnore347()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        FileName: Text[1024];
        custNo1: Code[20];
        custNo2: Code[20];
        VatRegNo: Text[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        Line: Text[1024];
        account1: Code[20];
        account2: Code[20];
        LineAmount: Decimal;
    begin
        // Verifies that Model 347 file does not contain the Amount which marked as 'Ignore in 347 Report' on a G/L account
        // when muti-customers have the same VAT Registration No.

        // Setup
        Initialize();

        // Create two customers with the same vat registration number
        VatRegNo := Library347Declaration.CreateShortVATRegNo(ESTxt);
        custNo1 := Library347Declaration.CreateCustomerWithPostCode(VatRegNo);
        custNo2 := Library347Declaration.CreateCustomerWithPostCode(VatRegNo);

        // Create a G/L account
        account1 := Library347Declaration.CreateGLAccount();
        GLAccount1.Get(account1);

        // Create a G/L account with Ignore in 347 Report
        account2 := Library347Declaration.CreateGLAccount();
        GLAccount2.Get(account2);
        GLAccount2.Validate("Ignore in 347 Report", true);
        GLAccount2.Modify(true);

        Amount1 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo2, Amount1);

        // Post amount on G/L account
        Amount2 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForGLAccount(custNo2, GLAccount1."No.", Amount2);

        // Post amount on the other G/L account, this amount should not be included in the report
        Amount3 := 10000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForGLAccount(custNo1, GLAccount2."No.", Amount3);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, custNo2);
        Line := ReadLineWithCustomerOrVendor(FileName, custNo2);
        // Verify that line has the right has amount: Amount1 + Amount2 (plus any VAT), but does not include Amount3
        LineAmount := ReadEntryAmount(Line);
        Assert.IsTrue(LineAmount >= (Amount1 + Amount2) * 100, 'Combined Amount is wrong');
        Assert.IsTrue(LineAmount < (Amount1 + Amount2 + Amount3) * 100, 'Combined Amount is wrong');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithVendorValidation()
    var
        Vendor: Record Vendor;
        FileName: Text[1024];
        vendorNo: Code[20];
    begin
        // Setup: Setup Demo Data.
        Initialize();
        SetRandomCompanyName();

        // Create a Vendor
        vendorNo :=
          Library347Declaration.CreateVendorWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        Vendor.Get(vendorNo);

        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendorNo, 3000 + LibraryRandom.RandDec(1000, 2));

        // Excercise: Run Make 347 declaration report.
        FileName := RunMake347DeclarationReport();

        // Verify: that the produced file gives the expected format.
        ValidateFormat347File(Test347DeclarationParameter, FileName, 'A', Vendor."No.", Vendor.Name);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithVendorShortVatRegNo()
    var
        Vendor: Record Vendor;
        FileName: Text[1024];
        vendorNo: Code[20];
    begin
        // Setup: Setup Demo Data.
        Initialize();
        SetRandomCompanyName();

        // Create a Vendor
        vendorNo := Library347Declaration.CreateVendorWithPostCode(Library347Declaration.CreateShortVATRegNo(ESTxt));
        Vendor.Get(vendorNo);

        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendorNo, 3000 + LibraryRandom.RandDec(1000, 2));

        // Excercise: Run Make 347 declaration report.
        FileName := RunMake347DeclarationReport();

        // Verify: that the produced file gives the expected format.
        ValidateFormat347File(Test347DeclarationParameter, FileName, 'A', Vendor."No.", Vendor.Name);
    end;

    [Test]
    [HandlerFunctions('IgnoreDuplicateVatRegNoMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithVendordSameVatRegNo()
    var
        FileName1: Text[1024];
        FileName2: Text[1024];
        vendorNo1: Code[20];
        vendorNo2: Code[20];
        VatRegNo: Text[20];
        Amount1: Decimal;
        Amount2: Decimal;
        CombinedAmount: Decimal;
        Line: Text[1024];
    begin
        // Setup: Setup Demo Data.
        Initialize();

        // Create two Vendors with the same Vat Registration No.
        VatRegNo := Library347Declaration.CreateShortVATRegNo(ESTxt);
        vendorNo1 := Library347Declaration.CreateVendorWithPostCode(VatRegNo);
        vendorNo2 := Library347Declaration.CreateVendorWithPostCode(VatRegNo);

        // Excercise1: Run Make 347 declaration report.
        Amount1 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendorNo1, Amount1);
        FileName1 := RunMake347DeclarationReport();

        // Verify1: that the produced file has the amount for the customer1
        Line := ReadLineWithCustomerOrVendor(FileName1, vendorNo1);
        Assert.IsTrue(ReadEntryAmount(Line) >= Amount1 * 100, 'Amount for vendor1 is wrong');

        // Excercise2: Run Make 347 declaration report with two vendors having the same VatRegNo.
        Amount2 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendorNo2, Amount2);
        FileName2 := RunMake347DeclarationReport();

        // Verify: that the produced file has the combined amount for the vendors with the same Vat Reg No
        Line := ReadLineWithCustomerOrVendor(FileName2, vendorNo1);
        CombinedAmount := ReadEntryAmount(Line);
        Assert.IsTrue(CombinedAmount >= (Amount1 + Amount2) * 100, 'Combined Amount is wrong, reading from vendor1');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithVendorIgnore347()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        FileName: Text[1024];
        vendorNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        Line: Text[1024];
        account1: Code[20];
        account2: Code[20];
        LineAmount: Decimal;
    begin
        // Verifies that Model 347 file does not contain the Amount which marked as 'Ignore in 347 Report' on a G/L account

        // Setup
        Initialize();

        // Create vendor
        vendorNo :=
          Library347Declaration.CreateVendorWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));

        // Create a G/L account
        account1 := Library347Declaration.CreateGLAccount();
        GLAccount1.Get(account1);

        // Create a G/L account with Ignore in 347 Report
        account2 := Library347Declaration.CreateGLAccount();
        GLAccount2.Get(account2);
        GLAccount2.Validate("Ignore in 347 Report", true);
        GLAccount2.Modify(true);

        Amount1 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendorNo, Amount1);

        // Post amount on G/L account
        Amount2 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForGLAccount(vendorNo, GLAccount1."No.", Amount2);

        // Post amount on the other G/L account, this amount should not be included in the report
        Amount3 := 10000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForGLAccount(vendorNo, GLAccount2."No.", Amount3);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, vendorNo);
        Line := ReadLineWithCustomerOrVendor(FileName, vendorNo);
        // Verify that line has the right has amount: Amount1 + Amount2 (plus any VAT), but does not include Amount3
        LineAmount := ReadEntryAmount(Line);
        Assert.IsTrue(LineAmount >= (Amount1 + Amount2) * 100, 'Combined Amount is wrong');
        Assert.IsTrue(LineAmount < (Amount1 + Amount2 + Amount3) * 100, 'Combined Amount is wrong');
    end;

    [Test]
    [HandlerFunctions('IgnoreDuplicateVatRegNoMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithSameVendorIgnore347()
    var
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        FileName: Text[1024];
        vendorNo1: Code[20];
        vendorNo2: Code[20];
        VatRegNo: Text[20];
        Amount1: Decimal;
        Amount2: Decimal;
        Amount3: Decimal;
        Line: Text[1024];
        account1: Code[20];
        account2: Code[20];
        LineAmount: Decimal;
    begin
        // Verifies that Model 347 file does not contain the Amount which marked as 'Ignore in 347 Report' on a G/L account
        // when muti-vendors have the same VAT Registration No.

        // Setup
        Initialize();

        // Create two vendors with the same vat registration number
        VatRegNo := Library347Declaration.CreateShortVATRegNo(ESTxt);
        vendorNo1 := Library347Declaration.CreateVendorWithPostCode(VatRegNo);
        vendorNo2 := Library347Declaration.CreateVendorWithPostCode(VatRegNo);

        // Create a G/L account
        account1 := Library347Declaration.CreateGLAccount();
        GLAccount1.Get(account1);

        // Create a G/L account with Ignore in 347 Report
        account2 := Library347Declaration.CreateGLAccount();
        GLAccount2.Get(account2);
        GLAccount2.Validate("Ignore in 347 Report", true);
        GLAccount2.Modify(true);

        Amount1 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendorNo2, Amount1);

        // Post amount on G/L account
        Amount2 := 3000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForGLAccount(vendorNo2, GLAccount1."No.", Amount2);

        // Post amount on the other G/L account, this amount should not be included in the report
        Amount3 := 10000 + LibraryRandom.RandDec(1000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForGLAccount(vendorNo1, GLAccount1."No.", Amount2);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, vendorNo2);
        Line := ReadLineWithCustomerOrVendor(FileName, vendorNo2);
        // Verify that line has the right has amount: Amount1 + Amount2 (plus any VAT), but does not include Amount3
        LineAmount := ReadEntryAmount(Line);
        Assert.IsTrue(LineAmount >= (Amount1 + Amount2) * 100, 'Combined Amount is wrong');
        Assert.IsTrue(LineAmount < (Amount1 + Amount2 + Amount3) * 100, 'Combined Amount is wrong');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithIgnoredGLAccount()
    var
        GLAccount: Record "G/L Account";
    begin
        // Verify system throws message "At least one of the GL Accounts selected for payments in cash is setup to be ignored in 347 report."

        // Setup: create GL Account which has "Ignore in 347 report = true"
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Ignore in 347 Report", true);
        GLAccount.Modify();
        Commit();

        Test347DeclarationParameter.GLAccForPaymentsInCash := GLAccount."No.";

        // Excercise: Run Make 347 declaration report.
        RunMake347DeclarationReportExpectError(UsingIgnoredGLAccountErr);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithTooLowAmount()
    var
        CustNo: Code[20];
        FileName: Text[1024];
        ThresholdAmount: Decimal;
    begin
        // Verify that if a customer has transactions below the MinAmount, then the customer won't be listed in the report output

        // Setup
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        ThresholdAmount := LibraryRandom.RandDec(5000, 2);
        Test347DeclarationParameter.MinAmount := ThresholdAmount;

        // Exercise: Generate report when customer has too low amount
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(CustNo, ThresholdAmount - 1);
        FileName := RunMake347DeclarationReport();

        // Validate
        ValidateFileHasNoLineForCustomer(FileName, CustNo);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithHighEnoughAmount()
    var
        CustNo: Code[20];
        FileName: Text[1024];
        ThresholdAmount: Decimal;
    begin
        // Verify that if a customer has transactions at the MinAmount, then the customer will be listed in the report output

        // Setup
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        ThresholdAmount := LibraryRandom.RandDec(5000, 2);
        Test347DeclarationParameter.MinAmount := ThresholdAmount;

        // Exercise: Generate report when customer has just high enough amount
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(CustNo, ThresholdAmount);
        FileName := RunMake347DeclarationReport();

        // Validate
        ValidateFileHasLineForCustomer(FileName, CustNo);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoicesInDifferentQuarters()
    var
        Item: Record Item;
        CustNo: Code[20];
        FileName: Text[1024];
        Line: Text[500];
        AmountQuarter1: Decimal;
        AmountQuarter2: Decimal;
        AmountQuarter3: Decimal;
        AmountQuarter4: Decimal;
        Year: Integer;
        DateQuarter1: Date;
        DateQuarter2: Date;
        DateQuarter3: Date;
        DateQuarter4: Date;
    begin
        // Verify that sales invoices for different quarters are reported correctly

        // Setup
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        Library347Declaration.CreateItemWithZeroVAT(Item, CustNo);
        Year := Date2DMY(WorkDate(), 3);

        // Setup: Post invoice for 1st quarter
        DateQuarter1 := DMY2Date(15, 2, Year);
        AmountQuarter1 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForItem(CustNo, Item, AmountQuarter1, DateQuarter1);

        // Setup: Post invoice for 2nd quarter
        DateQuarter2 := DMY2Date(15, 5, Year);
        AmountQuarter2 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForItem(CustNo, Item, AmountQuarter2, DateQuarter2);

        // Setup: Post invoice for 3rd quarter
        DateQuarter3 := DMY2Date(15, 8, Year);
        AmountQuarter3 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForItem(CustNo, Item, AmountQuarter3, DateQuarter3);

        // Setup: Post invoice for 4th quarter
        DateQuarter4 := DMY2Date(15, 11, Year);
        AmountQuarter4 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostSalesInvoiceForItem(CustNo, Item, AmountQuarter4, DateQuarter4);

        // Exercise: Generate report
        FileName := RunMake347DeclarationReport();

        // Validate
        ValidateFileHasLineForCustomer(FileName, CustNo);
        Line := ReadLineWithCustomerOrVendor(FileName, CustNo);
        Assert.AreEqual(PadInteger((AmountQuarter1 + AmountQuarter2 + AmountQuarter3 + AmountQuarter4) * 100, 15),
          ReadTotalInvoicedAmount(Line), 'Wrong total invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter1 * 100, 15), ReadInvoicedAmountForQuarter1(Line), 'Wrong q1 invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter2 * 100, 15), ReadInvoicedAmountForQuarter2(Line), 'Wrong q2 invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter3 * 100, 15), ReadInvoicedAmountForQuarter3(Line), 'Wrong q3 invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter4 * 100, 15), ReadInvoicedAmountForQuarter4(Line), 'Wrong q4 invoice amount');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseOrdersInDifferentQuarters()
    var
        Item: Record Item;
        VendNo: Code[20];
        FileName: Text[1024];
        Line: Text[500];
        AmountQuarter1: Decimal;
        AmountQuarter2: Decimal;
        AmountQuarter3: Decimal;
        AmountQuarter4: Decimal;
        Year: Integer;
        DateQuarter1: Date;
        DateQuarter2: Date;
        DateQuarter3: Date;
        DateQuarter4: Date;
    begin
        // Verify that purchase orders for different quarters are reported correctly

        // Setup
        Initialize();
        VendNo :=
          Library347Declaration.CreateVendorWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        Library347Declaration.CreateItemWithZeroVAT(Item, VendNo);
        Year := Date2DMY(WorkDate(), 3);

        // Setup: Post invoice for 1st quarter
        DateQuarter1 := DMY2Date(15, 2, Year);
        AmountQuarter1 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForItem(VendNo, Item, AmountQuarter1, DateQuarter1);

        // Setup: Post invoice for 2nd quarter
        DateQuarter2 := DMY2Date(15, 5, Year);
        AmountQuarter2 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForItem(VendNo, Item, AmountQuarter2, DateQuarter2);

        // Setup: Post invoice for 3rd quarter
        DateQuarter3 := DMY2Date(15, 8, Year);
        AmountQuarter3 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForItem(VendNo, Item, AmountQuarter3, DateQuarter3);

        // Setup: Post invoice for 4th quarter
        DateQuarter4 := DMY2Date(15, 11, Year);
        AmountQuarter4 := LibraryRandom.RandDec(5000, 2);
        Library347Declaration.CreateAndPostPurchaseOrderForItem(VendNo, Item, AmountQuarter4, DateQuarter4);

        // Exercise: Generate report
        FileName := RunMake347DeclarationReport();

        // Validate
        ValidateFileHasLineForCustomer(FileName, VendNo);
        Line := ReadLineWithCustomerOrVendor(FileName, VendNo);
        Assert.AreEqual(PadInteger((AmountQuarter1 + AmountQuarter2 + AmountQuarter3 + AmountQuarter4) * 100, 15),
          ReadTotalInvoicedAmount(Line), 'Wrong total invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter1 * 100, 15), ReadInvoicedAmountForQuarter1(Line), 'Wrong q1 invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter2 * 100, 15), ReadInvoicedAmountForQuarter2(Line), 'Wrong q2 invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter3 * 100, 15), ReadInvoicedAmountForQuarter3(Line), 'Wrong q3 invoice amount');
        Assert.AreEqual(PadInteger(AmountQuarter4 * 100, 15), ReadInvoicedAmountForQuarter4(Line), 'Wrong q4 invoice amount');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestValidatePartialAppliedCash()
    var
        CustLedgerEntryPayment: Record "Cust. Ledger Entry";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        GLAccount: Record "G/L Account";
        GenJournalLinePayment: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        CashAmount: Decimal;
        CustNo: Code[20];
        InvoiceNo: Code[20];
        FileName: Text[1024];
        Line: Text[500];
    begin
        // Verifies that if insufficient cash is received and applied to a posted sales invoice, then the
        // correct amounts (invoice and cash) will be shown on the report.

        // Setup
        Initialize();
        CashAmount := LibraryRandom.RandDec(5000, 2);
        InvoiceAmount := CashAmount + LibraryRandom.RandDec(2000, 2);

        // Setup: create customer and post sales invoice
        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        InvoiceNo := Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(CustNo, InvoiceAmount);

        // Setup: post cash receipt for the customer
        LibraryERM.CreateGLAccount(GLAccount);
        Test347DeclarationParameter.GLAccForPaymentsInCash := GLAccount."No.";
        Library347Declaration.CreateAndPostCashReceiptJournal(GenJournalLinePayment, GLAccount, CustNo, CashAmount);

        // Setup: apply cash receipt to sales invoice
        // - find the Invoice customer ledger entry
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice,
          InvoiceNo);
        // - find the Payment customer ledger entry
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryPayment, CustLedgerEntryPayment."Document Type"::Payment,
          GenJournalLinePayment."Document No.");
        // - apply the payment to the invoice
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryInvoice, CashAmount);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryPayment);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntryInvoice);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, CustNo);
        Line := ReadLineWithCustomerOrVendor(FileName, CustNo);
        // Check that the line has the right invoice amount
        Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
        // Check that the line has the right cash amount
        Assert.AreEqual(Format(Date2DMY(WorkDate(), 3)), ReadYearForCashReceipt(Line), 'Record has wrong year for cash receipt');
        Assert.AreEqual(PadInteger(CashAmount * 100, 15), ReadAmountReceivedInCash(Line), 'Wrong cash amount');
    end;

    [Test]
    [HandlerFunctions('CustomerOrVendorWithoutVATRegistrationNoConfirmHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerWithoutVATRegNoLeadsToConfirmDialog()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        FileName: Text[1024];
        CustNo: Code[20];
        VatRegNo: Code[20];
    begin
        // Verifies that if we have a customer without a VAT Registration No, the report warns the user that there is such
        // a customer and that it won't be listed in the report

        // Setup: create customer without VAT Registration No.
        Initialize();
        VatRegNo := Library347Declaration.GetUniqueVATRegNo(ESTxt);
        CustNo := Library347Declaration.CreateCustomerWithPostCode(VatRegNo);
        Customer.Get(CustNo);
        Customer.Validate("VAT Registration No.", '');
        Customer.Modify(true);

        // Setup: post sales invoice for the customer
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(CustNo, LibraryRandom.RandDec(5000, 2) + 1);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasNoLineForCustomer(FileName, CustNo);

        // Teardown: put a VAT Registration No. back, otherwise subsequent test cases will ALSO need to handle the confirm dialog
        Customer.Validate("VAT Registration No.", VatRegNo);
        Customer.Modify(true);
        VATEntry.SetRange("Bill-to/Pay-to No.", CustNo);
        VATEntry.ModifyAll("VAT Registration No.", Customer."VAT Registration No.", false);
    end;

    [Test]
    [HandlerFunctions('CustomerOrVendorWithoutVATRegistrationNoConfirmHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestVendorWithoutVATRegNoLeadsToConfirmDialog()
    var
        Vendor: Record Vendor;
        VATEntry: Record "VAT Entry";
        FileName: Text[1024];
        VendNo: Code[20];
        VATRegNo: Code[20];
    begin
        // Verifies that if we have a vendor without a VAT Registration No, the report warns the user that there is such
        // a vendor and that it won't be listed in the report

        // Setup: create vendor without VAT Registration No.
        Initialize();
        VATRegNo := Library347Declaration.GetUniqueVATRegNo(ESTxt);
        VendNo := Library347Declaration.CreateVendorWithPostCode(VATRegNo);
        Vendor.Get(VendNo);
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Modify(true);

        // Setup: post purchase invoice for the vendor
        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(VendNo, LibraryRandom.RandDec(5000, 2) + 1);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasNoLineForCustomer(FileName, VendNo);

        // Teardown: put a VAT Registration No. back, otherwise subsequent test cases will ALSO need to handle the confirm dialog
        Vendor.Validate("VAT Registration No.", VATRegNo);
        Vendor.Modify(true);
        VATEntry.SetRange("Bill-to/Pay-to No.", VendNo);
        VATEntry.ModifyAll("VAT Registration No.", Vendor."VAT Registration No.", false);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceLinesWithNoTaxableVAT()
    var
        FileName: Text[1024];
        CustNo: Code[20];
        InvoiceAmount: Decimal;
        Line: Text[500];
        VATRegNo: Code[20];
    begin
        // Verifies that if we have a sales invoice with VAT Prod. Posting Group = No Taxable VAT, then
        // the report still shows the invoice correctly. No Taxable VAT is different from 0 VAT in that no
        // VAT entries are created, and the report code has special code for this case.

        // Setup: create customer
        Initialize();
        VATRegNo := Library347Declaration.GetUniqueVATRegNo(ESTxt);
        CustNo := Library347Declaration.CreateCustomerWithPostCode(VATRegNo);
        InvoiceAmount := LibraryRandom.RandDec(5000, 2) + 1;

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostSalesInvoiceWithNoTaxableVAT(CustNo, InvoiceAmount);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, CustNo);
        Line := ReadLineWithCustomerOrVendor(FileName, CustNo);
        Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
    end;

    [Test]
    [HandlerFunctions('IgnoreDuplicateVatRegNoMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceLinesWithNoTaxableVATTwoCustomersWithSameVATRegNo()
    var
        FileName: Text[1024];
        VATRegNo: Text[20];
        CustNo2: Code[20];
        InvoiceAmount: Decimal;
        Line: Text[500];
    begin
        // Verifies that if we have a sales invoice with VAT Prod. Posting Group = No Taxable VAT, and we're posting
        // it to customer2, and customer1 and customer2 have the same VAT Registration No., then the report
        // will be generated correctly. No Taxable VAT is different from 0 VAT in that no VAT entries are created, and
        // the report code has special code for this case.

        // Setup
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(5000, 2) + 1;
        VATRegNo := Library347Declaration.GetUniqueVATRegNo(ESTxt);

        // Setup: create customers with identical VAT Registration Nos
        Library347Declaration.CreateCustomerWithPostCode(VATRegNo);
        CustNo2 := Library347Declaration.CreateCustomerWithPostCode(VATRegNo);

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostSalesInvoiceWithNoTaxableVAT(CustNo2, InvoiceAmount);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, CustNo2);
        Line := ReadLineWithCustomerOrVendor(FileName, CustNo2);
        Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceLinesWithNoTaxableVATForForeignCustomer()
    var
        FileName: Text[1024];
        CustNo: Code[20];
    begin
        // Verifies that if we have a sales invoice with VAT Prod. Posting Group = No Taxable VAT, and we
        // sell to a foreign customer, then it will not be listed on the report.

        // Setup: create Portuguese customer
        Initialize();
        CustNo := Library347Declaration.CreateCustomerInPortugalWithPostCode(PTTxt);

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostSalesInvoiceWithNoTaxableVAT(CustNo, LibraryRandom.RandDec(5000, 2) + 1);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasNoLineForCustomer(FileName, CustNo);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceLinesWithNoTaxableVAT()
    var
        FileName: Text[1024];
        VendNo: Code[20];
        InvoiceAmount: Decimal;
        Line: Text[500];
    begin
        // Verifies that if we have a purchase invoice with VAT Prod. Posting Group = No Taxable VAT, then
        // the report still shows the invoice correctly. No Taxable VAT is different from 0 VAT in that no
        // VAT entries are created, and the report code has special code for this case.

        // Setup: create vendor
        Initialize();
        VendNo :=
          Library347Declaration.CreateVendorWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        InvoiceAmount := LibraryRandom.RandDec(5000, 2) + 1;

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostPurchaseOrderWithNoTaxableVAT(VendNo, InvoiceAmount);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, VendNo);
        Line := ReadLineWithCustomerOrVendor(FileName, VendNo);
        Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
    end;

    [Test]
    [HandlerFunctions('IgnoreDuplicateVatRegNoMessageHandler,Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceLinesWithNoTaxableVATTwoVendorsWithSameVATRegNo()
    var
        FileName: Text[1024];
        VATRegNo: Text[20];
        VendNo2: Code[20];
        InvoiceAmount: Decimal;
        Line: Text[500];
    begin
        // Verifies that if we have a purchase invoice with VAT Prod. Posting Group = No Taxable VAT, and we're posting
        // it to vendor2, and vendor1 and vendor2 have the same VAT Registration No., then the report will be
        // generated correctly. No Taxable VAT is different from 0 VAT in that no VAT entries are created, and the report
        // code has special code for this case.

        // Setup
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(5000, 2) + 1;
        VATRegNo := Library347Declaration.GetUniqueVATRegNo(ESTxt);

        // Setup: create two vendors with identical VAT Registration Nos
        Library347Declaration.CreateVendorWithPostCode(VATRegNo);
        VendNo2 := Library347Declaration.CreateVendorWithPostCode(VATRegNo);

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostPurchaseOrderWithNoTaxableVAT(VendNo2, InvoiceAmount);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, VendNo2);
        Line := ReadLineWithCustomerOrVendor(FileName, VendNo2);
        Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoiceLinesWithNoTaxableVATForForeignVendor()
    var
        FileName: Text[1024];
        VendNo: Code[20];
        InvoiceAmount: Decimal;
    begin
        // Verifies that if we have a purchase invoice with VAT Prod. Posting Group = No Taxable VAT, and we
        // buy from a foreign vendor, then it will not be listed on the reort.

        // Setup: create vendor
        Initialize();
        VendNo := Library347Declaration.CreateVendorInPortugalWithPostCode(PTTxt);
        InvoiceAmount := LibraryRandom.RandDec(5000, 2) + 1;

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostPurchaseOrderWithNoTaxableVAT(VendNo, InvoiceAmount);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasNoLineForCustomer(FileName, VendNo);
    end;

    local procedure RunTestWithShipToAddress(CustNo: Code[20]; ShipToAddressCode: Code[10]; ExpectedToGenerateLine: Boolean)
    var
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        Line: Text[500];
    begin
        // Setup
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(5000, 2) + 1;

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostSalesInvoiceWithShipToAddress(CustNo, InvoiceAmount, ShipToAddressCode);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        if ExpectedToGenerateLine then begin
            ValidateFileHasLineForCustomer(FileName, CustNo);
            Line := ReadLineWithCustomerOrVendor(FileName, CustNo);
            Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
        end else
            ValidateFileHasNoLineForCustomer(FileName, CustNo);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithShipToAddressESCustomerESShipToAddress()
    var
        CustNo: Code[20];
        ShipToAddressCode: Code[10];
    begin
        Initialize();

        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        ShipToAddressCode := Library347Declaration.CreateShipToAddress(CustNo, ESTxt);
        RunTestWithShipToAddress(CustNo, ShipToAddressCode, true);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithShipToAddressESCustomerPTShipToAddress()
    var
        CustNo: Code[20];
        ShipToAddressCode: Code[10];
    begin
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        ShipToAddressCode := Library347Declaration.CreateShipToAddress(CustNo, PTTxt);
        RunTestWithShipToAddress(CustNo, ShipToAddressCode, true);
        // note: in the original manual test case CRETE 62880, it was expected to not generate a report, but
        // we concluded that it was the test case that was wrong
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithShipToAddressPTCustomerESShipToAddress()
    var
        CustNo: Code[20];
        ShipToAddressCode: Code[10];
    begin
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerInPortugalWithPostCode(Library347Declaration.GetUniqueVATRegNo(PTTxt));
        ShipToAddressCode := Library347Declaration.CreateShipToAddress(CustNo, ESTxt);
        RunTestWithShipToAddress(CustNo, ShipToAddressCode, false);
        // note: in the original manual test case CRETE 62881, it was expected to generate a report, but
        // we concluded that it was the test case that was wrong
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithShipToAddressPTCustomerPTShipToAddress()
    var
        CustNo: Code[20];
        ShipToAddressCode: Code[10];
    begin
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerInPortugalWithPostCode(Library347Declaration.GetUniqueVATRegNo(PTTxt));
        ShipToAddressCode := Library347Declaration.CreateShipToAddress(CustNo, PTTxt);
        RunTestWithShipToAddress(CustNo, ShipToAddressCode, false);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithShipToAddressPTCustomerDEShipToAddress()
    var
        CustNo: Code[20];
        ShipToAddressCode: Code[10];
    begin
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerInPortugalWithPostCode(Library347Declaration.GetUniqueVATRegNo(PTTxt));
        ShipToAddressCode := Library347Declaration.CreateShipToAddress(CustNo, DETxt);
        RunTestWithShipToAddress(CustNo, ShipToAddressCode, false);
    end;

    local procedure RunTestWithOrderAddress(VendNo: Code[20]; OrderAddressCode: Code[10]; ExpectedToGenerateLine: Boolean)
    var
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        Line: Text[500];
    begin
        // Setup
        Initialize();
        InvoiceAmount := LibraryRandom.RandDec(5000, 2) + 1;

        // Setup: post sales invoice
        Library347Declaration.CreateAndPostPurchaseInvoiceWithOrderAddress(VendNo, InvoiceAmount, OrderAddressCode);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        if ExpectedToGenerateLine then begin
            ValidateFileHasLineForCustomer(FileName, VendNo);
            Line := ReadLineWithCustomerOrVendor(FileName, VendNo);
            Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
        end else
            ValidateFileHasNoLineForCustomer(FileName, VendNo);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithOrderAddressESVendorESOrderAddress()
    var
        VendNo: Code[20];
        OrderAddressCode: Code[10];
    begin
        VendNo := Library347Declaration.CreateVendorWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        OrderAddressCode := Library347Declaration.CreateOrderAddress(VendNo, ESTxt);
        RunTestWithOrderAddress(VendNo, OrderAddressCode, true);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithOrderAddressPTVendorESOrderAddress()
    var
        VendNo: Code[20];
        OrderAddressCode: Code[10];
    begin
        VendNo := Library347Declaration.CreateVendorInPortugalWithPostCode(Library347Declaration.GetUniqueVATRegNo(PTTxt));
        OrderAddressCode := Library347Declaration.CreateOrderAddress(VendNo, ESTxt);
        RunTestWithOrderAddress(VendNo, OrderAddressCode, false);
        // note: in the original manual test case CRETE 62885, it was expected to generate a report, but
        // we concluded that it was the test case that was wrong
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithOrderAddressESVendorPTOrderAddress()
    var
        VendNo: Code[20];
        OrderAddressCode: Code[10];
    begin
        VendNo := Library347Declaration.CreateVendorWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        OrderAddressCode := Library347Declaration.CreateOrderAddress(VendNo, PTTxt);
        RunTestWithOrderAddress(VendNo, OrderAddressCode, true);
        // note: in the original manual test case CRETE 62886, it was expected to not generate a report, but
        // we concluded that it was the test case that was wrong
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithOrderAddressPTVendorPTOrderAddress()
    var
        VendNo: Code[20];
        OrderAddressCode: Code[10];
    begin
        VendNo :=
          Library347Declaration.CreateVendorInPortugalWithPostCode(Library347Declaration.GetUniqueVATRegNo(PTTxt));
        OrderAddressCode := Library347Declaration.CreateOrderAddress(VendNo, PTTxt);
        RunTestWithOrderAddress(VendNo, OrderAddressCode, false);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestWithOrderAddressPTVendorDEOrderAddress()
    var
        VendNo: Code[20];
        OrderAddressCode: Code[10];
    begin
        VendNo :=
          Library347Declaration.CreateVendorInPortugalWithPostCode(Library347Declaration.GetUniqueVATRegNo(PTTxt));
        OrderAddressCode := Library347Declaration.CreateOrderAddress(VendNo, DETxt);
        RunTestWithOrderAddress(VendNo, OrderAddressCode, false);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLineForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text[1024];
        CustNo: Code[20];
        DebitAmount: Decimal;
        Line: Text[500];
    begin
        // Verifies that if we post a General Journal Line for a customer, then it shows on the report.

        // Setup
        Initialize();
        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        DebitAmount := LibraryRandom.RandDec(5000, 2) + 1;

        // Setup: Create and post an Invoice journal line for the customer
        Library347Declaration.CreateAndPostGeneralJournalLine(GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustNo, DebitAmount, 0);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, CustNo);
        Line := ReadLineWithCustomerOrVendor(FileName, CustNo);
        Assert.AreEqual(PadInteger(DebitAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestPostGeneralJournalLineForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text[1024];
        VendNo: Code[20];
        CreditAmount: Decimal;
        Line: Text[500];
    begin
        // Verifies that if we post a General Journal Line for a customer, then it shows on the report.

        // Setup
        Initialize();
        VendNo :=
          Library347Declaration.CreateVendorWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        CreditAmount := LibraryRandom.RandDec(5000, 2) + 1;

        // Setup: Create and post an Invoice journal line for the customer
        Library347Declaration.CreateAndPostGeneralJournalLine(GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendNo, 0, CreditAmount);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify
        ValidateFileHasLineForCustomer(FileName, VendNo);
        Line := ReadLineWithCustomerOrVendor(FileName, VendNo);
        Assert.AreEqual(PadInteger(CreditAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomersWithSameVatRegNoInDifferentCasing()
    var
        custNo1: Code[20];
        custNo2: Code[20];
        VatRegNoUpperCased: Text[20];
        VatRegNoLowerCased: Text[20];
        Amount1: Decimal;
        Amount2: Decimal;
        FileName: Text[1024];
        Line: Text[500];
    begin
        // Verifies that two customers with the same VAT Reg No - except for casing - are still combined in the report.

        // Setup: Setup Demo Data.
        Initialize();

        // Create two Customers with the same Vat Registration No.
        VatRegNoUpperCased := UpperCase(Library347Declaration.CreateShortVATRegNo(ESTxt));
        VatRegNoLowerCased := LowerCase(VatRegNoUpperCased);
        custNo1 := Library347Declaration.CreateCustomerWithPostCode(VatRegNoUpperCased);
        custNo2 := Library347Declaration.CreateCustomerWithPostCode(VatRegNoLowerCased);

        // Setup: Post sales invoice for customer 1 who has the upper-cased VAT Registration No.
        Amount1 := LibraryRandom.RandDec(1000, 2) + 1;
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo1, Amount1);

        // Setup: Post sales invoice for customer 2 who has the lower-cased VAT Registration No.
        Amount2 := LibraryRandom.RandDec(1000, 2) + 1;
        Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(custNo2, Amount2);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify: the produced file should have only 1 line for the two customers, and it should contain the combined amount
        // (note that the file reading utility searches case-insensitive so it's not trivial to test that there is no line for the other case)
        ValidateFileHasLineForCustomer(FileName, custNo1);
        Line := ReadLineWithCustomerOrVendor(FileName, custNo1);
        Assert.AreEqual(PadInteger((Amount1 + Amount2) * 100, 15), ReadTotalInvoicedAmount(Line),
          'Combined Amount is wrong, reading from customer 1');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestVendorsWithSameVatRegNoInDifferentCasing()
    var
        vendNo1: Code[20];
        vendNo2: Code[20];
        VatRegNoUpperCased: Text[20];
        VatRegNoLowerCased: Text[20];
        Amount1: Decimal;
        Amount2: Decimal;
        FileName: Text[1024];
        Line: Text[500];
    begin
        // Verifies that two vendors with the same VAT Reg No - except for casing - are still combined in the report.

        // Setup: Setup Demo Data.
        Initialize();

        // Create two Vendors with the same Vat Registration No.
        VatRegNoUpperCased := UpperCase(Library347Declaration.CreateShortVATRegNo(ESTxt));
        VatRegNoLowerCased := LowerCase(VatRegNoUpperCased);
        vendNo1 := Library347Declaration.CreateVendorWithPostCode(VatRegNoUpperCased);
        vendNo2 := Library347Declaration.CreateVendorWithPostCode(VatRegNoLowerCased);

        // Setup: Post purchase order for vendor 1 who has the upper-cased VAT Registration No.
        Amount1 := LibraryRandom.RandDec(1000, 2) + 1;
        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendNo1, Amount1);

        // Setup: Post purchase order for vendor 2 who has the lower-cased VAT Registration No.
        Amount2 := LibraryRandom.RandDec(1000, 2) + 1;
        Library347Declaration.CreateAndPostPurchaseOrderWithNoVAT(vendNo2, Amount2);

        // Exercise
        FileName := RunMake347DeclarationReport();

        // Verify: the produced file should have only 1 line for the two vendors, and it should contain the combined amount
        // (note that the file reading utility searches case-insensitive so it's not trivial to test that there is no line for the other case)
        ValidateFileHasLineForCustomer(FileName, vendNo1);
        Line := ReadLineWithCustomerOrVendor(FileName, vendNo1);
        Assert.AreEqual(PadInteger((Amount1 + Amount2) * 100, 15), ReadTotalInvoicedAmount(Line),
          'Combined Amount is wrong, reading from vendor 1');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure TestValidateInvoiceAmountForBankCash()
    var
        CustLedgerEntryPayment: Record "Cust. Ledger Entry";
        CustLedgerEntryInvoice: Record "Cust. Ledger Entry";
        GLAccount: Record "G/L Account";
        GenJournalLinePayment: Record "Gen. Journal Line";
        GLAccount1: Record "G/L Account";
        InvoiceAmount: Decimal;
        CashAmount: Decimal;
        CustNo: Code[20];
        InvoiceNo: Code[20];
        FileName: Text[1024];
        Line: Text[500];
    begin
        // [SCENARIO 463364] The G/L Acc. for Payments in Cash is not always respected if you run the Make 347 Declaration in the Spanish version.

        // [GIVEN] Setup Initialize, create a G/L account, and set initial random cash and invoice amount
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount1);
        CashAmount := LibraryRandom.RandDec(5000, 2);
        InvoiceAmount := CashAmount + LibraryRandom.RandDec(2000, 2);

        // [GIVEN] Setup: create customer and post sales invoice
        CustNo :=
          Library347Declaration.CreateCustomerWithPostCode(Library347Declaration.GetUniqueVATRegNo(ESTxt));
        InvoiceNo := Library347Declaration.CreateAndPostSalesInvoiceWithoutVAT(CustNo, InvoiceAmount);

        // [GIVEN] Setup: post cash receipt for the customer
        LibraryERM.CreateGLAccount(GLAccount);
        Test347DeclarationParameter.GLAccForPaymentsInCash := GLAccount1."No.";
        Library347Declaration.CreateAndPostCashReceiptJournal(GenJournalLinePayment, GLAccount, CustNo, CashAmount);
        CreateAndPostGeneralJournalLine(GenJournalLinePayment."Document Type"::Payment,
            GenJournalLinePayment."Account Type"::"G/L Account", GLAccount1."No.", CashAmount / 2, 0);

        // [THEN] Setup: apply cash receipt to sales invoice
        // - find the Invoice customer ledger entry
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryInvoice, CustLedgerEntryInvoice."Document Type"::Invoice,
          InvoiceNo);
        // - find the Payment customer ledger entry
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryPayment, CustLedgerEntryPayment."Document Type"::Payment,
          GenJournalLinePayment."Document No.");
        // - apply the payment to the invoice
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryInvoice, CashAmount);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryPayment);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntryInvoice);

        // [WHEN] Exercise
        FileName := RunMake347DeclarationReport();

        // [VERIFY] Verify: 
        ValidateFileHasLineForCustomer(FileName, CustNo);
        Line := ReadLineWithCustomerOrVendor(FileName, CustNo);
        // Check that the line has the right invoice amount
        Assert.AreEqual(PadInteger(InvoiceAmount * 100, 15), ReadTotalInvoicedAmount(Line), 'Wrong invoice amount');
        // Check that the line has the right cash amount
        Assert.AreEqual(PadInteger(0, 15), ReadAmountReceivedInCash(Line), 'Wrong cash amount');
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryVariableStorage.Clear();
        Library347Declaration.Init347DeclarationParameters(Test347DeclarationParameter);
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        Library347Declaration.CreateAndPostSalesInvoiceToEnsureAReportGetsGenerated();
        InventorySetup.Get();
        LibrarySetupStorage.SaveCompanyInformation();
        IsInitialized := true;
        Commit();
    end;

    local procedure RunMake347DeclarationReport(): Text[1024]
    begin
        exit(Library347Declaration.RunMake347DeclarationReport(Test347DeclarationParameter, LibraryVariableStorage));
    end;

    local procedure RunMake347DeclarationReportExpectError(ExpectedError: Text[1024])
    begin
        Commit();
        // Excercise: Run Make 347 declaration report.
        asserterror RunMake347DeclarationReport();

        // Verify: Program throws error.
        Assert.ExpectedError(ExpectedError);
    end;

    local procedure PadInteger(Number: Decimal; DesiredStringLength: Integer): Text
    var
        NumberAsText: Text;
        NoOfCharactersToPad: Integer;
        I: Integer;
    begin
        // The input is of type Decimal, but we expect it to have no decimal values e.g. 1234,00.
        NumberAsText := Format(Number);
        NumberAsText := DelChr(NumberAsText, '=', '.,-');
        NoOfCharactersToPad := DesiredStringLength - StrLen(NumberAsText);

        for I := 1 to NoOfCharactersToPad do
            NumberAsText := '0' + NumberAsText;

        exit(NumberAsText);
    end;

    local procedure ReadAmountReceivedInCash(Line: Text[500]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 101, 15));
    end;

    local procedure ReadCashAmount(Line: Text[1024]): Integer
    var
        CashAmount: Integer;
    begin
        Evaluate(CashAmount, LibraryTextFileValidation.ReadValue(Line, 101, 15));
        exit(CashAmount);
    end;

    local procedure ReadCompanyName(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 18, 40));
    end;

    local procedure ReadContactName(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 68, 40));
    end;

    local procedure ReadDeclarationNumber(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 108, 13));
    end;

    local procedure ReadEntryAmount(Line: Text[1024]): Integer
    var
        EntryAmount: Integer;
    begin
        Evaluate(EntryAmount, LibraryTextFileValidation.ReadValue(Line, 84, 15));
        exit(EntryAmount);
    end;

    local procedure ReadEntryName(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 36, 40));
    end;

    local procedure ReadFiscalYear(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 5, 4));
    end;

    local procedure ReadFixedMarker(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 76, 1));
    end;

    local procedure ReadInvoicedAmountForQuarter1(Line: Text[500]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 137, 15));
    end;

    local procedure ReadInvoicedAmountForQuarter2(Line: Text[500]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 169, 15));
    end;

    local procedure ReadInvoicedAmountForQuarter3(Line: Text[500]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 201, 15));
    end;

    local procedure ReadInvoicedAmountForQuarter4(Line: Text[500]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 233, 15));
    end;

    local procedure ReadMediumType(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 58, 1));
    end;

    local procedure ReadNumberOfCompanies(Line: Text[1024]): Integer
    var
        NoOfCompanies: Integer;
    begin
        Evaluate(NoOfCompanies, LibraryTextFileValidation.ReadValue(Line, 136, 9));
        exit(NoOfCompanies);
    end;

    local procedure ReadRecordFormat(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 1, 4));
    end;

    local procedure ReadRecordPadding1(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 27, 9));
    end;

    local procedure ReadRecordPadding2(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 99, 2));
    end;

    local procedure ReadRecordType(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 82, 1));
    end;

    local procedure ReadTelephoneNumber(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 59, 9));
    end;

    local procedure ReadTotalAmount(Line: Text[1024]): Integer
    var
        TotalAmount: Integer;
    begin
        Evaluate(TotalAmount, LibraryTextFileValidation.ReadValue(Line, 146, 15));
        exit(TotalAmount);
    end;

    local procedure ReadTotalInvoicedAmount(Line: Text[500]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 84, 15));
    end;

    local procedure ReadVATRegNo(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 9, 9));
    end;

    local procedure ReadYearAmount(Line: Text[1024]): Integer
    var
        YearAmount: Integer;
    begin
        Evaluate(YearAmount, LibraryTextFileValidation.ReadValue(Line, 137, 15));
        exit(YearAmount);
    end;

    local procedure ReadYearForCashReceipt(Line: Text[500]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 132, 4));
    end;

    local procedure ReadSignSymbol(Line: Text[1024]): Text
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 170, 1));
    end;

    local procedure ValidateFormat347File(Test347DeclarationParameter: Record "Test 347 Declaration Parameter"; FileName: Text[1024]; RecordFormat: Text[2]; CustOrVendNo: Code[20]; ExpectedName: Text[100])
    var
        CompanyInfo: Record "Company Information";
        Make347Declaration: Report "Make 347 Declaration";
        FiscalYear: Text;
        VatRegNo: Text[20];
        Line: Text[1024];
        CompanyName: Text;
        ContactName: Text;
        TelephoneNumber: Text;
        NoOfCompanies: Integer;
        TotalAmount: Integer;
        YearAmount: Integer;
        EntryAmount: Integer;
    begin
        // 1. Validate Header

        // Read Header line
        Line := LibraryTextFileValidation.ReadLine(FileName, 1);

        // Setup expected data
        CompanyInfo.Get();
        FiscalYear := Format(Date2DMY(Test347DeclarationParameter.PostingDate, 3));
        VatRegNo := Library347Declaration.FormatVATRegNo(CompanyInfo."VAT Registration No.");
        CompanyName := PadStr(Make347Declaration.FormatTextName(CompanyInfo.Name), 40, ' ');
        ContactName := PadStr(Make347Declaration.FormatTextName(Test347DeclarationParameter.ContactName), 40, ' ');
        ExpectedName := PadStr(Make347Declaration.FormatTextName(ExpectedName, false), 40, ' ');
        TelephoneNumber := Test347DeclarationParameter.TelephoneNumber;

        // Validate header data
        Assert.AreEqual(StrLen(Line), 500, 'Header record has wrong length');
        Assert.AreEqual(ReadRecordFormat(Line), '1347', 'Header record has wrong format');
        Assert.AreEqual(ReadFiscalYear(Line), FiscalYear, 'Header record has wrong fiscal year');
        Assert.AreEqual(ReadVATRegNo(Line), VatRegNo, 'Header record has wrong VatRegNo');
        Assert.AreEqual(ReadCompanyName(Line), CompanyName, 'Wrong Company Name');
        Assert.AreEqual(ReadMediumType(Line), 'T', 'Header record has wrong Medium');
        Assert.AreEqual(ReadTelephoneNumber(Line), TelephoneNumber, 'Header record has wrong Phone number');
        Assert.AreEqual(ReadContactName(Line), ContactName, 'Wrong Contact name');
        Assert.AreEqual(
          ReadDeclarationNumber(Line), PadStr(Test347DeclarationParameter.DeclarationNumber, 13, '0'), 'Wrong Declaration number');
        NoOfCompanies := ReadNumberOfCompanies(Line);
        Assert.IsTrue(NoOfCompanies >= 1, 'Wrong number of companies, there must at least be one');
        TotalAmount := ReadTotalAmount(Line);
        Assert.IsTrue(TotalAmount >= 3000, 'Total amount is always greater than 3000');
        Assert.AreEqual(ReadSignSymbol(Line), ' ', EmptySymbolExpectedErr);

        // 2. Validate Customer/Vendor Record
        Line := ReadLineWithCustomerOrVendor(FileName, CustOrVendNo);
        Assert.AreNotEqual('', Line, 'Expected line was not found in report');
        Assert.AreEqual(StrLen(Line), 500, 'Record has wrong length');
        Assert.AreEqual(ReadRecordFormat(Line), '2347', 'Record has wrong format');
        Assert.AreEqual(ReadFiscalYear(Line), FiscalYear, 'Header record has wrong fiscal year');
        Assert.AreEqual(ReadVATRegNo(Line), VatRegNo, 'Header record has wrong VatRegNo');
        Assert.AreEqual(ReadRecordPadding1(Line), PadStr('', 9, ' '), 'expected 9 blanks');
        Assert.AreEqual(ReadEntryName(Line), ExpectedName, 'Wrong customer/vendor name');
        Assert.AreEqual(ReadFixedMarker(Line), 'D', 'Format expected a "D" here');
        Assert.AreEqual(ReadRecordType(Line), RecordFormat, 'Wrong "Record 2" format');
        EntryAmount := ReadEntryAmount(Line);
        Assert.IsTrue(EntryAmount >= 3000, 'Amount is always greater than 3000');
        Assert.IsTrue(TotalAmount >= EntryAmount, 'Total amount for the report should be greater or equal to this entry');
        Assert.AreEqual(ReadRecordPadding2(Line), PadStr('', 2, ' '), 'expected 2 blanks');
        Assert.AreEqual(ReadCashAmount(Line), 0, 'No Cash amount for this entry');

        // Read year amount, in this case it should be the same as entry amount
        YearAmount := ReadYearAmount(Line);
        Assert.AreEqual(EntryAmount, YearAmount, 'The entry amount and the year amount should be the same in this case');
    end;

    local procedure SetRandomCompanyName()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Name := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify();
    end;

    local procedure ValidateFileHasNoLineForCustomer(FileName: Text[1024]; CustOrVendNo: Code[20])
    begin
        Library347Declaration.ValidateFileHasNoLineForCustomer(FileName, CustOrVendNo);
    end;

    local procedure ValidateFileHasLineForCustomer(FileName: Text[1024]; CustOrVendNo: Code[20])
    begin
        Library347Declaration.ValidateFileHasLineForCustomer(FileName, CustOrVendNo);
    end;

    procedure CreateAndPostGeneralJournalLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal)
    var
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create G/L Account
        //LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateBankAccount(BankAccount);

        // Setup: Find a Cash Receipts journal template
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        // Setup: Create new journal batch
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);

        // Setup: Create Invoice journal line for the customer and with the right Debit amount
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, 0);
        if DebitAmount > 0 then
            GenJournalLine.Validate("Debit Amount", DebitAmount)
        else
            GenJournalLine.Validate("Credit Amount", CreditAmount);
        GenJournalLine.Modify(true);
        Commit();

        // Setup: Post the journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure IgnoreIn347ReportMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, IgnoreIn347ReportMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure IgnoreDuplicateVatRegNoMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, IgnoreDuplicateVatRegNoErr) > 0, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make347DeclarationReportHandler(var Make347Declaration: TestRequestPage "Make 347 Declaration")
    var
        FiscalYear: Variant;
        MinAmount: Variant;
        MinAmountInCash: Variant;
        ContactName: Variant;
        TelephoneNumber: Variant;
        DeclarationNumber: Variant;
        GLAccForPaymentsInCash: Variant;
        DeclarationMediaType: Option Telematic,"CD-R";
    begin
        LibraryVariableStorage.Dequeue(FiscalYear);
        LibraryVariableStorage.Dequeue(MinAmount);
        LibraryVariableStorage.Dequeue(MinAmountInCash);
        LibraryVariableStorage.Dequeue(GLAccForPaymentsInCash);
        LibraryVariableStorage.Dequeue(ContactName);
        LibraryVariableStorage.Dequeue(TelephoneNumber);
        LibraryVariableStorage.Dequeue(DeclarationNumber);
        Make347Declaration.FiscalYear.SetValue(FiscalYear);
        Make347Declaration.MinAmount.SetValue(MinAmount);
        Make347Declaration.MinAmountInCash.SetValue(MinAmountInCash);
        Make347Declaration.GLAccForPaymentsInCash.SetValue(GLAccForPaymentsInCash);
        Make347Declaration.ContactName.SetValue(ContactName);
        Make347Declaration.TelephoneNumber.SetValue(TelephoneNumber);
        Make347Declaration.DeclarationNumber.SetValue(DeclarationNumber);
        Make347Declaration.DeclarationMediaType.SetValue(DeclarationMediaType::Telematic);
        Make347Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NoRecordsFoundMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, NoRecordFoundMessage) > 0, Message);
    end;

    local procedure ReadLineWithCustomerOrVendor(FileName: Text[1024]; CustOrVendNo: Code[20]): Text[500]
    begin
        exit(Library347Declaration.ReadLineWithCustomerOrVendor(FileName, CustOrVendNo));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CustomerOrVendorWithoutVATRegistrationNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CustomerOrVendorWithoutVATRegistrationNoQst) > 0, Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy
    end;
}

