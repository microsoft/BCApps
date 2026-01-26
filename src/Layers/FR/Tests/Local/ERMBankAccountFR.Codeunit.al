codeunit 144011 "ERM Bank Account FR"
{
    // 1. Purpose of the test is to Post Payment Slip and verify created GL Entry for Customer Bank Account Code.
    // 2. Purpose of the test is to Post Payment Slip and verify created GL Entry for Vendor Bank Account Code.
    // 
    // Covers Test Cases for WI - 344163
    // ---------------------------------------------
    // Test Function Name                   TFS ID
    // ---------------------------------------------
    // PaymentSlipPostForCustomer           161444
    // PaymentSlipPostForVendor             161443

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryFRLocalization: Codeunit "Library - FR Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        BankBranchNoTxt: Label '12000';
        AgencyCodeTxt: Label '03100';
        BankAccountNoTxt: Label '00012123003';
        DocumentNoErr: Label 'Document No. must %1 in %2.', Comment = '%1= Field Value, %2= Table Name.';

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentClassListPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipPostForCustomer()
    var
        GLEntry: Record "G/L Entry";
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to Post Payment Slip and verify created GL Entry for Customer Bank Account Code.

        // Setup And Exercise.
        Initialize();
        PaymentSlipPost(PaymentHeader, PaymentLine."Account Type"::Customer, CreateCustomer(), PaymentClass.Suggestions::Customer);

        // Verify.
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();
        GLEntry.SetRange("Document No.", PaymentLine."Document No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, PaymentLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentClassListPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentSlipPostForVendor()
    var
        GLEntry: Record "G/L Entry";
        PaymentClass: Record "Payment Class";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        // Purpose of the test is to Post Payment Slip and verify created GL Entry for Vendor Bank Account Code.

        // Setup And Exercise.
        Initialize();
        PaymentSlipPost(PaymentHeader, PaymentLine."Account Type"::Vendor, CreateVendor(), PaymentClass.Suggestions::Vendor);

        // Verify.
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindFirst();
        GLEntry.SetRange("Document No.", PaymentLine."Document No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -PaymentLine.Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler')]
    procedure LastNoUsedUpdatesOnPaymentSlipLinesEnteredManually()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentClass: Record "Payment Class";
        NoSeriesMgt: Codeunit "No. Series";
        NoSeriesCode: Code[20];
    begin
        // [SCENARIO 575798] The Last No. Used in No. Series Line does update when the Payment Slip Lines are entered manually.

        // [GIVEN] Create a Payment Header.
        CreatePaymentHeader(PaymentHeader, PaymentClass.Suggestions::Vendor);

        // [GIVEN] Create a Payment Line and Validate Account Type, Account No. and Amount.
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
        PaymentLine.Validate("Account Type", PaymentLine."Account Type"::Vendor);
        PaymentLine.Validate("Account No.", CreateVendor());
        PaymentLine.Validate(Amount, LibraryRandom.RandDec(10, 2));
        PaymentLine.Modify(true);

        // [GIVEN] Find Payment Class.
        PaymentClass.Get(PaymentHeader."Payment Class");

        // [GIVEN] Find and store Last No. Used.
        NoSeriesCode := NoSeriesMgt.GetLastNoUsed(PaymentClass."Line No. Series");

        // [THEN] Document No. in Payment Line must be same as Last No. Used.
        Assert.AreEqual(
            NoSeriesCode,
            PaymentLine."Document No.",
            StrSubstNo(
                DocumentNoErr,
                NoSeriesCode,
                PaymentLine.TableName()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentClassListPageHandler')]
    procedure LastNoUsedUpdatesOnPaymentSlipLinesEnteredManuallyWhenPosting()
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
        PaymentClass: Record "Payment Class";
        NoSeriesMgt: Codeunit "No. Series";
        PaymentSlip: TestPage "Payment Slip";
        VendorNo: Code[20];
    begin
        // [SCENARIO 603695] The Last No. Used in No. Series Line does update when the Payment Slip Lines are entered manually when posting.
        VendorNo := CreateVendor();

        // [GIVEN] Create a Payment Header.
        CreatePaymentHeader(PaymentHeader, PaymentClass.Suggestions::Vendor);

        // [GIVEN] Create two Payment Lines for the Payment Header.
        CreatePaymentLine(PaymentHeader, PaymentLine."Account Type"::Vendor, VendorNo);
        CreatePaymentLine(PaymentHeader, PaymentLine."Account Type"::Vendor, VendorNo);

        // [GIVEN] Find and store Last No. Used before Posting.
        PaymentLine.SetRange("No.", PaymentHeader."No.");
        PaymentLine.FindLast();

        // [WHEN] Open Payment Slip and Post.
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("No.", PaymentHeader."No.");
        PaymentSlip.Post.Invoke();

        // [GIVEN] Find Payment Class.
        PaymentClass.Get(PaymentHeader."Payment Class");

        // [THEN] Document No. in Payment Line must be same as Last No. Used.
        Assert.AreEqual(
            NoSeriesMgt.GetLastNoUsed(PaymentClass."Line No. Series"),
            PaymentLine."Document No.",
            StrSubstNo(
                DocumentNoErr,
                PaymentLine."Document No.",
                PaymentLine.TableName()));
    end;

    local procedure PaymentSlipPost(var PaymentHeader: Record "Payment Header"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Suggestions: Option)
    var
        PaymentSlip: TestPage "Payment Slip";
    begin
        // Setup.
        CreatePaymentHeader(PaymentHeader, Suggestions);
        CreatePaymentLine(PaymentHeader, AccountType, AccountNo);
        PaymentSlip.OpenEdit();
        PaymentSlip.FILTER.SetFilter("No.", PaymentHeader."No.");

        // Exercise.
        PaymentSlip.Post.Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryFRLocalization.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);
        UpdateCustomerBankAccount(CustomerBankAccount);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
        UpdateVendorBankAccount(VendorBankAccount);
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentHeader(var PaymentHeader: Record "Payment Header"; Suggestions: Option)
    var
        PaymentClass: Record "Payment Class";
    begin
        PaymentClass.SetRange(Suggestions, Suggestions);
        PaymentClass.FindFirst();
        LibraryVariableStorage.Enqueue(PaymentClass.Code);
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        PaymentHeader.Validate("Payment Class", PaymentClass.Code);
        PaymentHeader.Validate("No. Series", PaymentClass."Header No. Series");
        PaymentHeader.Validate("Posting Date", WorkDate());
        PaymentHeader.Validate("Document Date", WorkDate());
        PaymentHeader.Validate("RIB Checked", true);
        PaymentHeader.Modify(true);
    end;

    local procedure CreatePaymentLine(PaymentHeader: Record "Payment Header"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        PaymentLine: Record "Payment Line";
    begin
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
        PaymentLine.Validate("Account Type", AccountType);
        PaymentLine.Validate("Account No.", AccountNo);
        PaymentLine.Validate(Amount, LibraryRandom.RandDec(10, 2));  // Using Random for Amount;
        PaymentLine.Modify(true);
    end;

    local procedure UpdateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        // Using hardcode for Bank Branch No.,Agency Code,Bank Account No. and RIB Key due to fixed nature to return 0.
        VendorBankAccount.Validate("Bank Branch No.", BankBranchNoTxt);
        VendorBankAccount.Validate("Agency Code", AgencyCodeTxt);
        VendorBankAccount.Validate("Bank Account No.", BankAccountNoTxt);
        VendorBankAccount.Validate("RIB Key", 7);
        VendorBankAccount.Modify();
    end;

    local procedure UpdateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account")
    begin
        // Using hardcode for Bank Branch No.,Agency Code,Bank Account No. and RIB Key due to fixed nature to return 0.
        CustomerBankAccount.Validate("Bank Branch No.", BankBranchNoTxt);
        CustomerBankAccount.Validate("Agency Code", AgencyCodeTxt);
        CustomerBankAccount.Validate("Bank Account No.", BankAccountNoTxt);
        CustomerBankAccount.Validate("RIB Key", 7);
        CustomerBankAccount.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentClassListPageHandler(var PaymentClassList: TestPage "Payment Class List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        PaymentClassList.FILTER.SetFilter(Code, Code);
        PaymentClassList.OK().Invoke();
    end;
}

