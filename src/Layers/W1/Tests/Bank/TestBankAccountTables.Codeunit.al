codeunit 132561 "Test Bank Account Tables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Account]        
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        NotExpectedBankActNoErr: Label 'The GetBankAccountNoWithCheck does not return the expected information';
        MissingBankInfoErr: Label 'You must specify either a %1 or an %2.';

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoReturnsIBANWhenIsNotEmpty_BankAccount()
    var
        BankAccount1: Record "Bank Account";
        BankAccount2: Record "Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 1] GetBankAccountNoWithCheck returns IBAN when the IBAN field is filled.
        Initialize();

        // [GIVEN] Bank Account with non empty values on both Bank Account No. and IBAN fields.
        LibraryERM.CreateBankAccount(BankAccount1);
        BankAccount1."Bank Account No." := LibraryUtility.GenerateRandomCode(BankAccount1.FieldNo("Bank Account No."),
            DATABASE::"Bank Account");
        BankAccount1.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        BankAccount1.Modify();

        LibraryERM.CreateBankAccount(BankAccount2);
        BankAccount2."Bank Account No." := '';
        BankAccount2.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        BankAccount2.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        // [THEN] The function returns IBAN.
        Assert.AreEqual(BankAccount1.IBAN, BankAccount1.GetBankAccountNoWithCheck(), NotExpectedBankActNoErr);
        Assert.AreEqual(BankAccount2.IBAN, BankAccount2.GetBankAccountNoWithCheck(), NotExpectedBankActNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoReturnsBankaccountNoWhenIBANIsEmpty_BankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 2] GetBankAccountNoWithCheck returns Bank Account No. field value when the IBAN field is empty.
        Initialize();

        // [GIVEN] Bank Account with empty IBAN field and non empty value on the Bank Account No. field.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Branch No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Branch No."),
            DATABASE::"Bank Account");
        BankAccount."Bank Account No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Account No."),
            DATABASE::"Bank Account");
        BankAccount.IBAN := '';
        BankAccount.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        // [THEN] The function returns value on the Bank Account No. field.
        Assert.IsTrue(StrPos(BankAccount.GetBankAccountNoWithCheck(), BankAccount."Bank Account No.") > 0, NotExpectedBankActNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoThrowsErrorIfBothIBANAndBankAcoountNoAreEmpty_BankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 3] GetBankAccountNoWithCheck throws an error when both Bank Account No. and IBAN fields have empty value.
        Initialize();

        // [GIVEN] Bank Account with empty values on both Bank Account No. and IBAN fields.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Account No." := '';
        BankAccount.IBAN := '';
        BankAccount.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        asserterror BankAccount.GetBankAccountNoWithCheck();
        // [THEN] The function throws an exception.
        Assert.ExpectedError(StrSubstNo(MissingBankInfoErr, BankAccount.FieldCaption("Bank Account No."),
            BankAccount.FieldCaption(IBAN)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoReturnsIBANWhenIsNotEmpty_CustomerBankAccount()
    var
        CustomerBankAccount1: Record "Customer Bank Account";
        CustomerBankAccount2: Record "Customer Bank Account";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer Bank Account] [UT]
        // [SCENARIO 4] GetBankAccountNoWithCheck returns IBAN when the IBAN field is filled.
        Initialize();

        // [GIVEN] Customer Bank Account with non empty values on both Bank Account No. and IBAN fields.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount1, Customer."No.");
        CustomerBankAccount1."Bank Account No." := LibraryUtility.GenerateRandomCode(CustomerBankAccount1.FieldNo("Bank Account No."),
            DATABASE::"Customer Bank Account");
        CustomerBankAccount1.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        CustomerBankAccount1.Modify();

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount2, Customer."No.");
        CustomerBankAccount2."Bank Account No." := '';
        CustomerBankAccount2.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        CustomerBankAccount2.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        // [THEN] The function returns IBAN.
        Assert.AreEqual(CustomerBankAccount1.IBAN, CustomerBankAccount1.GetBankAccountNoWithCheck(), NotExpectedBankActNoErr);
        Assert.AreEqual(CustomerBankAccount2.IBAN, CustomerBankAccount2.GetBankAccountNoWithCheck(), NotExpectedBankActNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoReturnsBankaccountNoWhenIBANIsEmpty_CustomerBankAccount()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer Bank Account] [UT]
        // [SCENARIO 5] GetBankAccountNoWithCheck returns Bank Account No. field value when the IBAN field is empty.
        Initialize();

        // [GIVEN] Customer Bank Account with empty IBAN field and non empty value on the Bank Account No. field.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount."Bank Branch No." := LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Branch No."),
            DATABASE::"Customer Bank Account");
        CustomerBankAccount."Bank Account No." := LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("Bank Account No."),
            DATABASE::"Customer Bank Account");
        CustomerBankAccount.IBAN := '';
        CustomerBankAccount.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        // [THEN] The function returns value on the Bank Account No. field.
        Assert.IsTrue(StrPos(CustomerBankAccount.GetBankAccountNoWithCheck(), CustomerBankAccount."Bank Account No.") > 0,
          NotExpectedBankActNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoThrowsErrorIfBothIBANAndBankAcoountNoAreEmpty_CustomerBankAccount()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer Bank Account] [UT]
        // [SCENARIO 6] GetBankAccountNoWithCheck throws an error when both Bank Account No. and IBAN fields have empty value.
        Initialize();

        // [GIVEN] Customer Bank Account with empty values on both Bank Account No. and IBAN fields.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount."Bank Account No." := '';
        CustomerBankAccount.IBAN := '';
        CustomerBankAccount.Modify();

        // [WHEN] GetBankAccountNoWithCheck funciton is called.
        asserterror CustomerBankAccount.GetBankAccountNoWithCheck();
        // [THEN] The function throws an exception.
        Assert.ExpectedError(
          StrSubstNo(MissingBankInfoErr, CustomerBankAccount.FieldCaption("Bank Account No."), CustomerBankAccount.FieldCaption(IBAN)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoReturnsIBANWhenIsNotEmpty_VendorBankAccount()
    var
        VendorBankAccount1: Record "Vendor Bank Account";
        VendorBankAccount2: Record "Vendor Bank Account";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor Bank Account] [UT]
        // [SCENARIO 7] GetBankAccountNoWithCheck returns IBAN when the IBAN field is filled.
        Initialize();

        // [GIVEN] Vendor Bank Account with non empty values on both Bank Account No. and IBAN fields.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount1, Vendor."No.");
        VendorBankAccount1."Bank Account No." := LibraryUtility.GenerateRandomCode(VendorBankAccount1.FieldNo("Bank Account No."),
            DATABASE::"Vendor Bank Account");
        VendorBankAccount1.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        VendorBankAccount1.Modify();

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount2, Vendor."No.");
        VendorBankAccount2."Bank Account No." := '';
        VendorBankAccount2.IBAN := LibraryUtility.GenerateMOD97CompliantCode();
        VendorBankAccount2.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        // [THEN] The function returns IBAN.
        Assert.AreEqual(VendorBankAccount1.IBAN, VendorBankAccount1.GetBankAccountNoWithCheck(), NotExpectedBankActNoErr);
        Assert.AreEqual(VendorBankAccount2.IBAN, VendorBankAccount2.GetBankAccountNoWithCheck(), NotExpectedBankActNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoReturnsBankaccountNoWhenIBANIsEmpty_VendorBankAccount()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor Bank Account] [UT]
        // [SCENARIO 8] GetBankAccountNoWithCheck returns Bank Account No. field value when the IBAN field is empty.
        Initialize();

        // [GIVEN] Vendor Bank Account with empty IBAN field and non empty value on the Bank Account No. field.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount."Bank Branch No." := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Bank Branch No."),
            DATABASE::"Vendor Bank Account");
        VendorBankAccount."Bank Account No." := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo("Bank Account No."),
            DATABASE::"Vendor Bank Account");
        VendorBankAccount.IBAN := '';
        VendorBankAccount.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        // [THEN] The function returns value on the Bank Account No. field.
        Assert.IsTrue(StrPos(VendorBankAccount.GetBankAccountNoWithCheck(), VendorBankAccount."Bank Account No.") > 0,
          NotExpectedBankActNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetBankAccountNoThrowsErrorIfBothIBANAndBankAcoountNoAreEmpty_VendorBankAccount()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor Bank Account] [UT]
        // [SCENARIO 9] GetBankAccountNoWithCheck throws an error when both Bank Account No. and IBAN fields have empty value.
        Initialize();

        // [GIVEN] Vendor Bank Account with empty values on both Bank Account No. and IBAN fields.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount."Bank Account No." := '';
        VendorBankAccount.IBAN := '';
        VendorBankAccount.Modify();

        // [WHEN] GetBankAccountNoWithCheck function is called.
        asserterror VendorBankAccount.GetBankAccountNoWithCheck();
        // [THEN] The function throws an exception.
        Assert.ExpectedError(StrSubstNo(MissingBankInfoErr, VendorBankAccount.FieldCaption("Bank Account No."),
            VendorBankAccount.FieldCaption(IBAN)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastPaymentStatementNoMustContainANumber()
    var
        BankAccount: Record "Bank Account";
        InputString: Text[20];
    begin
        // [FEATURE] [Last Payment Statement No.] [UT]
        // [SCENARIO 108830] Bank Statement Import - when typing letters in "Last Payment Statement No." on the Bank Account, it blocks bank statement import
        Initialize();

        // [GIVEN] Bank Account
        LibraryERM.CreateBankAccount(BankAccount);

        // [WHEN] entering a value with no digits into "Last Payment Statement No."
        InputString := 'a' + DelChr(LibraryUtility.GenerateRandomText(9), '=', '0123456789');
        // [THEN] you get a validation error, because this value cannot be incremented.
        asserterror BankAccount.Validate("Last Payment Statement No.", InputString);
        Assert.ExpectedError(
          StrSubstNo('The value in the %1 field must have a number so that we can assign the next number in the series.',
            BankAccount.FieldCaption("Last Payment Statement No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastPaymentStatementNoWithANumberIsValid()
    var
        BankAccount: Record "Bank Account";
        InputString: Text[20];
    begin
        // [FEATURE] [Last Payment Statement No.] [UT]
        // [SCENARIO 108830] Bank Statement Import - when typing letters in "Last Payment Statement No." on the Bank Account, it blocks bank statement import
        Initialize();

        // [GIVEN] Bank Account
        LibraryERM.CreateBankAccount(BankAccount);
        // [WHEN] entering a value with digits into "Last Payment Statement No."
        InputString := InsStr(LibraryUtility.GenerateRandomText(9), '1', 1);
        // [THEN] you get no validation error, because this value can be incremented.
        BankAccount.Validate("Last Payment Statement No.", InputString);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustFieldPreferredBankAccountBlankWhenDeletingCustBankAccount()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [Customer][Customer Bank Account][UT]
        // [SCENARIO 377811] Field "Preferred Bank Account Code" of Customer should be empty after deleting Customer Bank Account
        Initialize();

        // [GIVEN] Customer with Customer Bank Account
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        Customer."Preferred Bank Account Code" := CustomerBankAccount.Code;
        Customer.Modify();

        // [WHEN] Delete Customer Bank Account
        CustomerBankAccount.Delete(true);

        // [THEN] Customer."Preferred Bank Account Code" is empty
        Customer.Get(Customer."No.");
        Customer.TestField("Preferred Bank Account Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValuePreferredBankAccountAfterDeletingCustBankAccount()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        ExpectedCode: Code[20];
    begin
        // [FEATURE] [Customer][Customer Bank Account][UT]
        // [SCENARIO 377811] Field "Preferred Bank Account Code" of Customer should contains value when deleting not-assined Customer Bank Account
        Initialize();

        // [GIVEN] Customer with two Customer Bank Accounts - "X1" and "X2"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        // [GIVEN] Customer."Preferred Bank Account Code" = "X1"
        Customer."Preferred Bank Account Code" := CustomerBankAccount.Code;
        Customer.Modify();
        ExpectedCode := CustomerBankAccount.Code;
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // [WHEN] Delete Customer Bank Account "X2"
        CustomerBankAccount.Delete(true);

        // [THEN] Customer."Preferred Bank Account Code" = "X1"
        Customer.Get(Customer."No.");
        Customer.TestField("Preferred Bank Account Code", ExpectedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendFieldPreferredBankAccountBlankWhenDeletingVendBankAccount()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [Vendor][Vendor Bank Account][UT]
        // [SCENARIO 377811] Field "Preferred Bank Account Code" of Vendor should be empty after deleting Vendor Bank Account
        Initialize();

        // [GIVEN] Vendor with Vendor Bank Account
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify();

        // [WHEN] Delete Vendor Bank Account
        VendorBankAccount.Delete(true);

        // [THEN] Vendor."Preferred Bank Account Code" is empty
        Vendor.Get(Vendor."No.");
        Vendor.TestField("Preferred Bank Account Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValuePreferredBankAccountAfterDeletingVendBankAccount()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        ExpectedCode: Code[20];
    begin
        // [FEATURE] [Vendor][Vendor Bank Account][UT]
        // [SCENARIO 377811] Field "Preferred Bank Account Code" of Vendor should contains value when deleting not-assined Vendor Bank Account
        Initialize();

        // [GIVEN] Vendor with two Vendor Bank Accounts - "X1" and "X2"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        // [GIVEN] Vendor."Preferred Bank Account Code" = "X1"
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify();
        ExpectedCode := VendorBankAccount.Code;
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        // [WHEN] Delete Vendor Bank Account "X2"
        VendorBankAccount.Delete(true);

        // [THEN] Vendor."Preferred Bank Account Code" = "X1"
        Vendor.Get(Vendor."No.");
        Vendor.TestField("Preferred Bank Account Code", ExpectedCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccountLinkingActionNotVisible()
    var
        BankAccount: Record "Bank Account";
        BankAccountList: TestPage "Bank Account List";
        BankAccountCard: TestPage "Bank Account Card";
    begin
        // [FEATURE] [Link Online Bank Account] [UT]
        Initialize();

        // [GIVEN] Bank Account
        LibraryERM.CreateBankAccount(BankAccount);

        // [WHEN] There are no statement services
        // [THEN] The bank account linking actions are not visible.
        BankAccountList.OpenView();
        Assert.IsFalse(BankAccountList.LinkToOnlineBankAccount.Visible(), 'list');

        BankAccountCard.OpenView();
        BankAccountCard.GotoRecord(BankAccount);
        Assert.IsFalse(BankAccountList.LinkToOnlineBankAccount.Visible(), 'card');
    end;

    local procedure Initialize()
    var
        IsInitialized: Boolean;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Bank Account Tables");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Bank Account Tables");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Bank Account Tables");
    end;
}

