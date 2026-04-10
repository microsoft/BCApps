codeunit 134824 "UT Vendor Table"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Vendor] [Find Vendor] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        VendNotRegisteredTxt: Label 'This vendor is not registered. To continue, choose one of the following options:';
        YouMustSelectVendorErr: Label 'You must select an existing vendor.';
        VendorNameWithFilterCharsTxt: Label '&V*e|n(d''o)&r*';
        DummyValueForAddressTxt: Label 'Dummy address';
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        DeleteVendorPurchaseDocExistsErr: Label 'You cannot delete %1 %2 because there is at least one outstanding Purchase %3 for this vendor.';
        DialogErr: Label 'Dialog';
        PhoneNoCannotContainLettersErr: Label '%1 must not contain letters in %2 %3=''%4''.';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByExactNo()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text[50];
        RandomText2: Text[50];
    begin
        Initialize();

        // Setup
        RandomText1 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2), 1, MaxStrLen(RandomText1));
        RandomText2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2), 1, MaxStrLen(RandomText2));

        CreateVendorFromNo(Vendor1, RandomText1);
        CreateVendorFromNo(Vendor2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor1."No.", Vendor1.GetVendorNo(RandomText1), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectionFirstVendorFromVendorListModalPageHandler')]
    procedure TestGetVendorNoGetVendorByStartNo()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2 - 1), 1, MaxStrLen(RandomText1));
        RandomText2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2), 1, MaxStrLen(RandomText2));

        CreateVendorFromNo(Vendor1, RandomText1);
        CreateVendorFromNo(Vendor2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor1."No.", Vendor1.GetVendorNo(CopyStr(RandomText1, 1, 8)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendortNoGetVendorByPartNo()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2 - 2);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2);

        CreateVendorFromNo(Vendor1, RandomText1);
        CreateVendorFromNo(Vendor2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor2."No.", Vendor2.GetVendorNo(CopyStr(RandomText2, 2, 8)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByExactName()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text[50];
        RandomText2: Text[50];
    begin
        Initialize();

        // Setup
        RandomText1 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1.Name) / 2), 1, MaxStrLen(RandomText1));
        RandomText2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1.Name) / 2), 1, MaxStrLen(RandomText2));

        CreateVendorFromName(Vendor1, RandomText1 + RandomText2);
        CreateVendorFromName(Vendor2, RandomText1);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor2."No.", Vendor2.GetVendorNo(RandomText1), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectionFirstVendorFromVendorListModalPageHandler')]
    procedure TestGetVendorNoGetVendorByStartOfName()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1.Name) / 2), 1, MaxStrLen(RandomText1));
        RandomText2 := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1.Name) / 2), 1, MaxStrLen(RandomText2));

        CreateVendorFromName(Vendor1, RandomText1 + RandomText2);
        CreateVendorFromName(Vendor2, RandomText1);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor1."No.", Vendor1.GetVendorNo(CopyStr(RandomText1, 1, 10)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByPartOfName()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1.Name) / 2);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1.Name) / 2);

        CreateVendorFromName(Vendor1, RandomText1 + RandomText2);
        CreateVendorFromName(Vendor2, RandomText1);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor1."No.", Vendor1.GetVendorNo(CopyStr(RandomText2, 5, 10)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByPartOfCity()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(City, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.City)));
        Vendor.Modify(true);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor."No.", Vendor.GetVendorNo(CopyStr(Vendor.City, 5, 10)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByPartOfContact()
    var
        Vendor: Record Vendor;
        RandomText: Text;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        RandomText := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Contact) / 2 - 1);
        Vendor.Validate(Contact, CopyStr(RandomText + '  ' + RandomText, 1, MaxStrLen(Vendor.Contact)));
        Vendor.Modify(true);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor."No.", Vendor.GetVendorNo(CopyStr(Vendor.Contact, 5, 10)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByPartOfPhoneNo()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Vendor.Modify(true);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor."No.", Vendor.GetVendorNo(CopyStr(Vendor."Phone No.", 5, 10)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByPartOfPostCode()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Post Code", LibraryUtility.GenerateRandomText(MaxStrLen(Vendor."Post Code")));
        Vendor.Modify(true);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor."No.", Vendor.GetVendorNo(CopyStr(Vendor."Post Code", 5, 10)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByPartOfNameIncludingFilterChars()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        CreateVendorFromName(Vendor, VendorNameWithFilterCharsTxt);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor."No.", Vendor.GetVendorNo(VendorNameWithFilterCharsTxt), 'Vendor not found');
    end;

    [Test]
    [HandlerFunctions('VendorNotRegisteredStrMenuHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByNoInputOverflow()
    var
        Vendor: Record Vendor;
    begin
        Initialize();
        // Offset the random
        LibraryUtility.GenerateRandomText(1);

        // Setup
        CreateVendorFromNo(Vendor, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor."No.")));

        // Exercise
        asserterror Vendor.GetVendorNo(Vendor."No." + 'Extra Text');
        Assert.ExpectedError(YouMustSelectVendorErr);
    end;

    [Test]
    [HandlerFunctions('VendorNotRegisteredStrMenuHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestGetVendorNoPromptCreateVendor()
    var
        Vendor: Record Vendor;
        NoneExistingVendorNo: Code[20];
    begin
        Initialize();

        // Setup
        NoneExistingVendorNo := LibraryPurchase.CreateVendorNo();
        Vendor.Get(NoneExistingVendorNo);
        Vendor.Delete();

        // Exercise and Verify None Existing Vendor
        asserterror Vendor.GetVendorNo(NoneExistingVendorNo);
        Assert.ExpectedError(YouMustSelectVendorErr);
        // Confirm handler will verify the confirm and skip creation of Vendor
    end;

    [Test]
    [HandlerFunctions('CancelSelectionOfVendorFromVendorListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetVendorNoPromptPickVendor()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2 - 3);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2);

        CreateVendorFromNo(Vendor1, RandomText1);
        CreateVendorFromNo(Vendor2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Vendor
        asserterror Vendor1.GetVendorNo(CopyStr(RandomText1, 2, 10));
        Assert.ExpectedError(YouMustSelectVendorErr);
        // Confirm handler will verify the Vendor list opens and cancel selection of Vendor
    end;

    [Test]
    [HandlerFunctions('SelectionFirstVendorFromVendorListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetVendorNoSelectVendorFromPickVendor()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2 - 3);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Vendor1."No.") / 2);

        CreateVendorFromNo(Vendor1, RandomText1);
        CreateVendorFromNo(Vendor2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Vendor
        Assert.AreEqual(Vendor1."No.", Vendor1.GetVendorNo(CopyStr(RandomText1, 2, 10)), 'Vendor not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasAddressForAddress()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Address := DummyValueForAddressTxt;

        // Exercise
        Assert.IsTrue(Vendor.HasAddress(), 'The Vendor should have an address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasAddressForAddress2()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Address 2" := DummyValueForAddressTxt;

        // Exercise
        Assert.IsTrue(Vendor.HasAddress(), 'The Vendor should have an address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasAddressForCity()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.City := DummyValueForAddressTxt;

        // Exercise
        Assert.IsTrue(Vendor.HasAddress(), 'The Vendor should have an address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasAddressForCounty()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.County := DummyValueForAddressTxt;

        // Exercise
        Assert.IsTrue(Vendor.HasAddress(), 'The Vendor should have an address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasAddressForPostCode()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Post Code" := DummyValueForAddressTxt;

        // Exercise
        Assert.IsTrue(Vendor.HasAddress(), 'The Vendor should have an address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHasAddressForContact()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Contact := DummyValueForAddressTxt;

        // Exercise
        Assert.IsTrue(Vendor.HasAddress(), 'The Vendor should have an address');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorValidateContactWithEmptyBusRelationCode()
    var
        MarketingSetup: Record "Marketing Setup";
        Vendor: Record Vendor;
        ExpectedContact: Text[50];
        ExpectedPrimaryContactNo: Code[20];
    begin
        // [FEATURE] [Contact] [Marketing Setup]
        // [SCENARIO 231916] When "Bus. Relation Code" is empty in Marketing Setup and random text is inserted into Vendor Contact field then "Primary Contact No." and Contact fields are not cleared.
        Initialize();
        ExpectedPrimaryContactNo := LibraryUtility.GenerateGUID();

        // [GIVEN] "Bus. Relation Code" = '' in Marketing Setup
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", '');
        MarketingSetup.Modify(true);

        // [GIVEN] Vendor with empty Contact field and "YY" in "Primary Contact No." field.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Primary Contact No." := ExpectedPrimaryContactNo;
        Vendor.Contact := '';
        Vendor.Modify();

        // [GIVEN] Text[50] = "XX"
        ExpectedContact := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);

        // [WHEN] Update Contact field with "XX" value
        Vendor.Validate(Contact, ExpectedContact);

        // [THEN] Contact = "XX"
        Vendor.TestField(Contact, ExpectedContact);

        // [THEN] "Primary Contact No." = "YY"
        Vendor.TestField("Primary Contact No.", ExpectedPrimaryContactNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDeleteErrorWhenInvoiceExists()
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 235731] The error is shown when trying to delete Vendor with outstanding Purchase Invoice.
        Initialize();

        // [GIVEN] Purchase Invoice for Vendor "V"
        // [WHEN] Trying to delete "V"
        // [THEN] Error is shown: 'You cannot delete Vendor "V" because there is at least one outstanding Purchase Invoice for this vendor.'
        ErrorOnDeleteVendorIfOutstandingDocExists("Purchase Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDeleteErrorWhenQuoteExists()
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO 235731] The error is shown when trying to delete Vendor with outstanding Purchase Quote.
        Initialize();

        // [GIVEN] Purchase Quote for Vendor "V"
        // [WHEN] Trying to delete "V"
        // [THEN] Error is shown: 'You cannot delete Vendor "V" because there is at least one outstanding Purchase Quote for this vendor.'
        ErrorOnDeleteVendorIfOutstandingDocExists("Purchase Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDeleteErrorWhenCreditMemoExists()
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 235731] The error is shown when trying to delete Vendor with outstanding Purchase Credit Memo.
        Initialize();

        // [GIVEN] Purchase Credit Memo for Vendor "V"
        // [WHEN] Trying to delete "V"
        // [THEN] Error is shown: 'You cannot delete Vendor "V" because there is at least one outstanding Purchase Credit Memo for this vendor.'
        ErrorOnDeleteVendorIfOutstandingDocExists("Purchase Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDeleteErrorWhenOrderExists()
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 235731] The error is shown when trying to delete Vendor with outstanding Purchase Order.
        Initialize();

        // [GIVEN] Purchase Order for Vendor "V"
        // [WHEN] Trying to delete "V"
        // [THEN] Error is shown: 'You cannot delete Vendor "V" because there is at least one outstanding Purchase Order for this vendor.'
        ErrorOnDeleteVendorIfOutstandingDocExists("Purchase Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDeleteErrorWhenReturnOrderExists()
    begin
        // [FEATURE] [Purchase] [Return Order]
        // [SCENARIO 235731] The error is shown when trying to delete Vendor with outstanding Purchase Return Order.
        Initialize();

        // [GIVEN] Purchase Return Order for Vendor "V"
        // [WHEN] Trying to delete "V"
        // [THEN] Error is shown: 'You cannot delete Vendor "V" because there is at least one outstanding Purchase Return Order for this vendor.'
        ErrorOnDeleteVendorIfOutstandingDocExists("Purchase Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDeleteErrorWhenBlanketOrderExists()
    begin
        // [FEATURE] [Purchase] [Blanket Order]
        // [SCENARIO 235731] The error is shown when trying to delete Vendor with outstanding Purchase Blanket Order.
        Initialize();

        // [GIVEN] Purchase Blanket Order for Vendor "V"
        // [WHEN] Trying to delete "V"
        // [THEN] Error is shown: 'You cannot delete Vendor "V" because there is at least one outstanding Purchase Blanket Order for this vendor.'
        ErrorOnDeleteVendorIfOutstandingDocExists("Purchase Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPhoneNoValidation()
    var
        Vendor: Record Vendor;
    begin
        // [SCENARIO 321935] The error is shown when trying to enter letters in the Phone No. field.
        Initialize();

        // [GIVEN] Created a Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Trying to enter letters in the Phone No. field
        asserterror Vendor.Validate("Phone No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Vendor."Phone No."), 1));

        // [THEN] Error is shown: 'Phone No. must not contain letters in Vendor  No.='
        Assert.ExpectedError(
          StrSubstNo(
            PhoneNoCannotContainLettersErr, Vendor.FieldCaption("Phone No."), Vendor.TableCaption(),
            Vendor.FieldCaption("No."), Vendor."No."));
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendorNoGetVendorByName_CaseSensitive_Blocked()
    var
        Vendor: array[4] of Record Vendor;
        RandomText1: Text[100];
        RandomText2: Text[100];
    begin
        Initialize();

        RandomText1 := 'aaa';
        RandomText2 := 'AAA';

        CreateVendorFromNameAndBlocked(Vendor[1], RandomText1, Vendor[1].Blocked::All);
        CreateVendorFromNameAndBlocked(Vendor[2], RandomText1, Vendor[2].Blocked::" ");
        CreateVendorFromNameAndBlocked(Vendor[3], RandomText2, Vendor[3].Blocked::All);
        CreateVendorFromNameAndBlocked(Vendor[4], RandomText2, Vendor[4].Blocked::" ");

        Assert.AreEqual(Vendor[2]."No.", Vendor[1].GetVendorNo(RandomText1), '');
        Assert.AreEqual(Vendor[4]."No.", Vendor[1].GetVendorNo(RandomText2), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithSemicolon()
    var
        Vendor: Record Vendor;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Vendor table in case it contains multiple e-mail addresses, separated by ;

        // [WHEN] Validate E-Mail field of Vendor table, when it contains multiple email addresses in cases, separated by ;
        Vendor.Validate("E-Mail", 'test1@test.com; test2@test.com; test3@test.com');

        // [THEN] String is validated without errors.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldOnEmptyEmailAddress()
    var
        Vendor: Record Vendor;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Vendor table in case it's empty.

        // [WHEN] Validate E-Mail field of Vendor table on empty value.
        Vendor.Validate("E-Mail", '');

        // [THEN] String is validated without errors.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithComma()
    var
        Vendor: Record Vendor;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Vendor table in case it contains multiple e-mail addresses, separated by ,
        MultipleAddressesTxt := 'test1@test.com, test2@test.com, test3@test.com';

        // [WHEN] Validate E-Mail field of Vendor table, when it contains multiple email addresses, separated by ,
        asserterror Vendor.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid.', MultipleAddressesTxt));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithVerticalBar()
    var
        Vendor: Record Vendor;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Vendor table in case it contains multiple e-mail addresses, separated by |
        MultipleAddressesTxt := 'test1@test.com| test2@test.com| test3@test.com';

        // [WHEN] Validate E-Mail field of Vendor table, when it contains multiple email addresses, separated by |
        asserterror Vendor.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid.', MultipleAddressesTxt));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithSpace()
    var
        Vendor: Record Vendor;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Vendor table in case it contains multiple e-mail addresses, separated by space.
        MultipleAddressesTxt := 'test1@test.com test2@test.com test3@test.com';

        // [WHEN] Validate E-Mail field of Vendor table, when it contains multiple email addresses, separated by space.
        asserterror Vendor.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid.', MultipleAddressesTxt));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithInvalidEmail()
    var
        Vendor: Record Vendor;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Vendor table in case it contains multiple e-mail addresses; one of them is not valid.
        MultipleAddressesTxt := 'test1@test.com; test2.com; test3@test.com';

        // [WHEN] Validate E-Mail field of Vendor table, when it contains multiple email addresses, one of them is not a valid email address.
        asserterror Vendor.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError('The email address "test2.com" is not valid.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    var
        Vendor: Record Vendor;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT Vendor Table");
        Vendor.DeleteAll();
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"UT Vendor Table");

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"UT Vendor Table");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelSelectionOfVendorFromVendorListModalPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.Cancel().Invoke();
    end;

    local procedure CreatePurchaseDocument(PurchaseDocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseDocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandInt(10));
    end;

    local procedure CreateVendorFromNo(var Vendor: Record Vendor; No: Text)
    begin
        Vendor.Validate("No.", CopyStr(No, 1, MaxStrLen(Vendor."No.")));
        Vendor.Insert(true);
    end;

    local procedure CreateVendorFromName(var Vendor: Record Vendor; Name: Text)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, CopyStr(Name, 1, MaxStrLen(Vendor.Name)));
        Vendor.Modify(true);
    end;

    local procedure CreateVendorFromNameAndBlocked(var Vendor: Record Vendor; Name: Text; VendorBlocked: Enum "Vendor Blocked")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, CopyStr(Name, 1, MaxStrLen(Vendor.Name)));
        Vendor.Validate(Blocked, VendorBlocked);
        Vendor.Modify(true);
    end;

    local procedure ErrorOnDeleteVendorIfOutstandingDocExists(DocType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
    begin
        UpdatePurchasesPayablesSetupNoS();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(DocType, Vendor."No.");

        asserterror Vendor.Delete(true);

        Assert.ExpectedError(
          StrSubstNo(
            DeleteVendorPurchaseDocExistsErr, Vendor.TableCaption(), Vendor."No.", DocType));

        Assert.ExpectedErrorCode(DialogErr);
    end;

    local procedure UpdatePurchasesPayablesSetupNoS()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Validate("Quote Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Blanket Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Vendor Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectionFirstVendorFromVendorListModalPageHandler(var VendorList: TestPage "Vendor List")
    begin
        VendorList.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure VendorNotRegisteredStrMenuHandlerCancel(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.ExpectedMessage(VendNotRegisteredTxt, Instruction);
        Choice := 0;
    end;
}

