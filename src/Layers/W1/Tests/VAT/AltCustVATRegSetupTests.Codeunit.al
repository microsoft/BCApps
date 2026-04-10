codeunit 134239 "Alt. Cust VAT Reg. Setup Tests"
{
    Subtype = Test;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        CountryCodeMatchesCustomerErr: Label 'You cannot have the same VAT Country/Region Code as the Customer Country/Region Code';
        InconsistentSetupErr: Label 'Not possible to have Alternative Customer VAT Registration with the same Customer No. and VAT Country/Region Code';
        ChangeCountryOfCustQst: Label 'There is an alternative customer VAT registration with the same country/region code that is not allowed. Do you want to change the country/region code in the customer card and remove the alternative customer VAT registration?';

    trigger OnRun()
    begin
        // [FEATURE] [Alternative Customer VAT Registration]
    end;

    [Test]
    procedure AltCustVATRegSameCountryRegionCodeAsCustomer()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        Customer: Record Customer;
    begin
        // [SCENARIO 525644] Stan cannot add an Alternative Customer VAT Registration with "VAT Country/Region Code" that equals the "Country/Region Code" of the customer

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Customer with "Country/Region Code" = ES
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Alternative Customer VAT Registration for the customer
        AltCustVATReg.Validate("Customer No.", Customer."No.");
        // [WHEN] Set "VAT Country/Region Code" = ES
        AltCustVATReg.Validate("VAT Country/Region Code", Customer."Country/Region Code");
        asserterror AltCustVATReg.Insert(true);
        // [THEN] Error message is shown
        Assert.ExpectedError(CountryCodeMatchesCustomerErr);
        Assert.ExpectedErrorCode('Dialog');
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure AltCustVATRegDiffCustomerNoAndVATCountryRegionCode()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        CustNo: Code[20];
    begin
        // [SCENARIO 525644] Stan can add an Alternative Customer VAT Registration with the different Customer No. and VAT Country/Region Code

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Customer "X"
        CustNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Alternative Customer VAT Reg. with Customer No. "X" and "VAT Country Region/Code" = ES is created
        AltCustVATReg.ID := GetNewAltCustVATRegID();
        AltCustVATReg.Validate("Customer No.", CustNo);
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        AltCustVATReg."VAT Registration No." := LibraryUtility.GenerateGUID(); // no validation to prevent validation error
        AltCustVATReg.Insert(true);

        AltCustVATReg.ID := GetNewAltCustVATRegID();
        AltCustVATReg.Validate("Customer No.", CustNo);
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        // [WHEN] Insert Alternative Customer VAT Reg. with Customer No. "X" and "VAT Country Region/Code" = GB
        AltCustVATReg.Insert(true);
        // [THEN] Two records in the Alternative Customer VAT Reg. table
        AltCustVATReg.SetRange("Customer No.", CustNo);
        Assert.RecordCount(AltCustVATReg, 2);
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure AltCustVATRegSameCustomerNoAndVATCountryRegionCode()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
    begin
        // [SCENARIO 525644] Stan cannot add Alternative Customer VAT Registration with the same Customer No. and VAT Country/Region Code

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Alternative Customer VAT Reg. with Customer No. "X" and "VAT Country Region/Code" = ES is created
        AltCustVATReg.ID := GetNewAltCustVATRegID();
        AltCustVATReg.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        AltCustVATReg."VAT Registration No." := LibraryUtility.GenerateGUID(); // no validation to prevent validation error
        AltCustVATReg.Insert(true);

        AltCustVATReg.ID := GetNewAltCustVATRegID();
        // [WHEN] Insert Alternative Customer VAT Reg. with Customer No. "X" and "VAT Country Region/Code" = ES
        asserterror AltCustVATReg.Insert(true);
        // [THEN] Error message is shown
        Assert.ExpectedError(InconsistentSetupErr);
        Assert.ExpectedErrorCode('Dialog');
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure ChangeCustomerInAltCustVATRegToDuplicatedRecord()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        CustNo: Code[20];
    begin
        // [SCENARIO 525644] Stan cannot change the "Customer No." if it leads to the duplicated record

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        CustNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Alternative Customer VAT Reg. with Customer No. "X" and "VAT Country Region/Code" = ES is created
        AltCustVATReg.ID := GetNewAltCustVATRegID();
        AltCustVATReg.Validate("Customer No.", CustNo);
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        AltCustVATReg."VAT Registration No." := LibraryUtility.GenerateGUID(); // no validation to prevent validation error
        AltCustVATReg.Insert(true);

        // [GIVEN] Alternative Customer VAT Reg. with Customer No. "Y" and "VAT Country Region/Code" = GB is created
        AltCustVATReg.ID := GetNewAltCustVATRegID();
        AltCustVATReg.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        // [WHEN] Change "Customer No." of this setup to "X"
        AltCustVATReg.Validate("Customer No.", CustNo);
        asserterror AltCustVATReg.Modify(true);
        // [THEN] Error message is shown
        Assert.ExpectedError(InconsistentSetupErr);
        Assert.ExpectedErrorCode('Dialog');
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure ChangeVATCountryRegionCodeInAltCustVATRegToDuplicatedRecord()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        CountryRegionCode: Code[10];
    begin
        // [SCENARIO 525644] Stan cannot change the "VAT Country/Region Code" if it leads to the duplicated record

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Alternative Customer VAT Reg. with Customer No. "X" and "VAT Country Region/Code" = ES is created
        CountryRegionCode := LibraryERM.CreateCountryRegion();
        AltCustVATReg.ID := GetNewAltCustVATRegID();
        AltCustVATReg.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        AltCustVATReg.Validate("VAT Country/Region Code", CountryRegionCode);
        AltCustVATReg."VAT Registration No." := LibraryUtility.GenerateGUID(); // no validation to prevent validation error
        AltCustVATReg.Insert(true);

        // [GIVEN] Alternative Customer VAT Reg. with Customer No. "X" and "VAT Country Region/Code" = GB is created
        AltCustVATReg.ID := GetNewAltCustVATRegID();
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        // [WHEN] Change "VAT Country Region/Code" of this setup to "ES"
        AltCustVATReg.Validate("VAT Country/Region Code", CountryRegionCode);
        asserterror AltCustVATReg.Modify(true);
        // [THEN] Error message is shown
        Assert.ExpectedError(InconsistentSetupErr);
        Assert.ExpectedErrorCode('Dialog');
        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CustomerWithSameCountryCodeAsAltCustVATRegDotNotConfirm()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        Customer: Record Customer;
    begin
        // [SCENARIO 525644] A change is reverted when Stan change the "Country/Region Code" of the customer if there is an Alternative Customer VAT Registration with the same "VAT Country/Region Code"
        // [SCENARIO 525644] and do not confirm this change

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Customer with "Country/Region Code" = ES
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Alternative Customer VAT Registration for the customer with "VAT Country/Region Code" = DK
        AltCustVATReg.Validate("Customer No.", Customer."No.");
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        AltCustVATReg.Insert(true);
        LibraryVariableStorage.Enqueue(ChangeCountryOfCustQst);
        LibraryVariableStorage.Enqueue(false);
        // [WHEN] Change "Country/Region Code" of the customer to DK
        asserterror Customer.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Error message is shown
        Assert.ExpectedError('');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CustomerWithSameCountryCodeAsAltCustVATRegConfirm()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        Customer: Record Customer;
    begin
        // [SCENARIO 543651] The Alternative VAT Registration is removed when Stan change the "Country/Region Code" of the customer if there is an Alternative setup with the same "VAT Country/Region Code"
        // [SCENARIO 543651] and confirms this change

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Customer with "Country/Region Code" = ES
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Alternative Customer VAT Registration for the customer with "VAT Country/Region Code" = DK
        AltCustVATReg.Validate("Customer No.", Customer."No.");
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        AltCustVATReg.Insert(true);
        LibraryVariableStorage.Enqueue(ChangeCountryOfCustQst);
        LibraryVariableStorage.Enqueue(true);
        // [WHEN] Change "Country/Region Code" of the customer to DK
        Customer.Validate("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] "Country/Region Code" is DK
        Customer.TestField("Country/Region Code", AltCustVATReg."VAT Country/Region Code");
        // [THEN] Alternative Customer VAT Registration is removed
        AltCustVATReg.SetRange("Customer No.", Customer."No.");
        AltCustVATReg.SetRange("VAT Country/Region Code", Customer."Country/Region Code");
        Assert.RecordCount(AltCustVATReg, 0);

        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CustomerWithSameCountryCodeAsAltCustVATRegValidateCity()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        // [SCENARIO 525644] A change is reverted when Stan change the City of the customer
        // [SCENARIO 525644] if there is an Alternative Customer VAT Registration with the same "VAT Country/Region Code" as customer country code in the post code

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Customer with "Country/Region Code" = ES
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Alternative Customer VAT Registration for the customer with "VAT Country/Region Code" = DK
        AltCustVATReg.Validate("Customer No.", Customer."No.");
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        AltCustVATReg.Insert(true);

        // [GIVEN] Post Code with City = Copenhagen and "Country/Region Code" = DK
        LibraryERM.CreatePostCode(PostCode);
        PostCode."Country/Region Code" := AltCustVATReg."VAT Country/Region Code";
        PostCode.Modify(true);
        LibraryVariableStorage.Enqueue(ChangeCountryOfCustQst);
        LibraryVariableStorage.Enqueue(false);
        // [WHEN] Change City of the customer to Copenhagen
        asserterror Customer.Validate(City, PostCode.City);
        // [THEN] Error message is shown
        Assert.ExpectedError('');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();

        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CustomerWithSameCountryCodeAsAltCustVATRegValidatePostCode()
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        // [SCENARIO 525644] A change is reverted when Stan change the Post Code of the customer
        // [SCENARIO 525644] if there is an Alternative Customer VAT Registration with the same "VAT Country/Region Code" as customer country code in the post code

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        // [GIVEN] Customer with "Country/Region Code" = ES
        LibrarySales.CreateCustomerWithCountryCodeAndVATRegNo(Customer);
        // [GIVEN] Alternative Customer VAT Registration for the customer with "VAT Country/Region Code" = DK
        AltCustVATReg.Validate("Customer No.", Customer."No.");
        AltCustVATReg.Validate("VAT Country/Region Code", LibraryERM.CreateCountryRegion());
        AltCustVATReg.Insert(true);

        // [GIVEN] Post Code with Code = 1000-2999 and "Country/Region Code" = DK
        LibraryERM.CreatePostCode(PostCode);
        PostCode."Country/Region Code" := AltCustVATReg."VAT Country/Region Code";
        PostCode.Modify(true);
        LibraryVariableStorage.Enqueue(ChangeCountryOfCustQst);
        LibraryVariableStorage.Enqueue(false);
        // [WHEN] Change "Post Code" of the customer to 1000-2999
        asserterror Customer.Validate("Post Code", PostCode.Code);
        // [THEN] Error message is shown
        Assert.ExpectedError('');
        Assert.ExpectedErrorCode('Dialog');
        LibraryVariableStorage.AssertEmpty();

        LibraryVariableStorage.AssertEmpty();

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Alt. Cust VAT Reg. Setup Tests");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Alt. Cust VAT Reg. Setup Tests");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Alt. Cust VAT Reg. Setup Tests");
    end;

    local procedure GetNewAltCustVATRegID(): Integer
    var
        AltCustVATReg: Record "Alt. Cust. VAT Reg.";
    begin
        if AltCustVATReg.FindLast() then
            exit(AltCustVATReg.ID + 1);
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}