codeunit 134826 "UT Contact Table"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Contact] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        DateFilterErr: Label 'Date Filter does not match expected value';
        PhoneNoCannotContainLettersErr: Label '%1 must not contain letters in Contact No.=''%2''', Comment = '%1 - Field Caption, like Phone No.; %2 - Contact No.';
        PhoneNoContactCardValidationErr: Label 'Validation error for Field: %1', Comment = '%1 - Field Caption, like Phone No.';

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsMobileForClientPhone()
    var
        Contact: Record Contact;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [CLIENTTYPE::Phone]
        LibraryLowerPermissions.SetO365Basic();
        // [GIVEN] Client is "Phone"
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [GIVEN] Contact, where "Phone No." = 'X', "Mobile Phone No." = 'Y'
        Contact.Init();
        Contact."Phone No." := '111111';
        Contact."Mobile Phone No." := '222222';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Mobile Phone No.", Contact.GetDefaultPhoneNo(), 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'Y'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsMobileIfPhoneBlankForClientWindows()
    var
        Contact: Record Contact;
    begin
        LibraryLowerPermissions.SetO365Basic();
        // [GIVEN] Contact, where "Phone No." = <blank>, "Mobile Phone No." = 'Y'
        Contact.Init();
        Contact."Mobile Phone No." := '222222';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Mobile Phone No.", Contact.GetDefaultPhoneNo(), 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'Y'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsPhoneForClientWindows()
    var
        Contact: Record Contact;
    begin
        LibraryLowerPermissions.SetO365Basic();
        // [GIVEN] Contact, where "Phone No." = 'X', "Mobile Phone No." = 'Y'
        Contact.Init();
        Contact."Phone No." := '111111';
        Contact."Mobile Phone No." := '222222';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Phone No.", Contact.GetDefaultPhoneNo(), 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'X'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsPhoneIfMobileBalnkForClientPhone()
    var
        Contact: Record Contact;
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        // [FEATURE] [CLIENTTYPE::Phone]
        LibraryLowerPermissions.SetO365Basic();
        // [GIVEN] Client is "Phone"
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Phone);
        // [GIVEN] Contact, where "Phone No." = 'X', "Mobile Phone No." = <blank>
        Contact.Init();
        Contact."Phone No." := '111111';

        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual(Contact."Phone No.", Contact.GetDefaultPhoneNo(), 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns 'X'
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDefaultPhoneIsBlankIfNoneNumbersFilled()
    var
        Contact: Record Contact;
    begin
        LibraryLowerPermissions.SetO365Basic();
        // [GIVEN] Contact, where both "Phone No." and "Mobile Phone No." are <blank>
        Contact.Init();
        // [WHEN] call GetDefaultPhoneNo()
        Assert.AreEqual('', Contact.GetDefaultPhoneNo(), 'GetDefaultPhoneNo()');
        // [THEN] GetDefaultPhoneNo() returns ''
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewContactPersonTypeWithCompanyNoInRMCONTPermissions()
    var
        Contact: Record Contact;
        CompanyContact: Record Contact;
    begin
        // [SCENARIO 379620] User with "RM-CONT, Edit" permissions can set "Company No." field
        LibraryLowerPermissions.SetOppMGT();

        CompanyContact.Init();
        CompanyContact.Insert(true);
        CompanyContact.Validate(Type, Contact.Type::Company);
        CompanyContact.Modify(true);

        Contact.Init();
        Contact.Insert(true);
        Contact.Validate(Type, Contact.Type::Person);
        Contact.Validate("Company No.", CompanyContact."No.");
        Contact.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteContactTypePerson()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 197375] Stan can delete Contact with Type = Person under "D365 Customer, EDIT" permission set
        LibraryLowerPermissions.SetOppMGT();

        MockContact(Contact, Contact.Type::Person);

        LibraryLowerPermissions.SetCustomerEdit();

        Contact.Delete(true);
        VerifyContactRelatedRecordsDeleted(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteContactTypeCompany()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 197375] Stan can delete Contact with Type = Company under "D365 Customer, EDIT" permission set
        LibraryLowerPermissions.SetOppMGT();

        MockContact(Contact, Contact.Type::Company);

        LibraryLowerPermissions.SetCustomerEdit();

        Contact.Delete(true);
        VerifyContactRelatedRecordsDeleted(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerUpdateContactWhenContactNameIsBlank()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 275658] Contact automatically created from Customer gets synced on Customer modification, if Contact "Name" is blank.

        // [GIVEN] Customer record created with blank fields
        Customer.Init();
        Customer.Insert(true);

        // [GIVEN] Contact with blank Name created for Customer automatically
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Customer, Customer."No."));
        Contact.TestField(Name, '');

        // [WHEN] Update Customer Name to 'AAA'
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer.Modify(true);

        // [THEN] Contact Name is updated to 'AAA' respectively
        Contact.Find();
        Contact.TestField(Name, Customer.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerDoNotUpdateContactWhenContactNameIsNotBlank()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContactName: Text;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 275658] Contact automatically created from Customer gets no update on Customer modification, if Contact "Name" is filled.

        // [GIVEN] Customer record with name 'AAA' created
        Customer.Init();
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer.Insert(true);

        // [GIVEN] Contact with name 'AAA' created automatically for Customer
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Customer, Customer."No."));
        Contact.TestField(Name, Customer.Name);

        // [GIVEN] Contact Name is updated to 'XXX'
        ContactName := LibraryUtility.GenerateGUID();
        Contact.Name := CopyStr(ContactName, 1, MaxStrLen(Contact.Name));
        Contact.Modify(true);
        Contact.TestField(Name, ContactName);

        // [WHEN] Customer Priority is set to 11 and Customer record is modified
        Customer.Validate(Priority, LibraryRandom.RandInt(10));
        Customer.Modify(true);

        // [THEN] Contact still have name 'XXX'
        Contact.Find();
        Contact.TestField(Name, ContactName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorUpdateContactWhenContactNameIsBlank()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 275658] Contact automatically created from Vendor gets synced on Customer modification, if Contact "Name" is blank.

        // [GIVEN] Vendor record created with blank fields
        Vendor.Init();
        Vendor.Insert(true);

        // [GIVEN] Contact with blank Name created for Vendor automatically
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Vendor, Vendor."No."));
        Contact.TestField(Name, '');

        // [WHEN] Update Vendor Name to 'AAA'
        Vendor.Name := LibraryUtility.GenerateGUID();
        Vendor.Modify(true);

        // [THEN] Contact Name is updated to 'AAA' respectively
        Contact.Find();
        Contact.TestField(Name, Vendor.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDoNotUpdateContactWhenContactNameIsNotBlank()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContactName: Text;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 275658] Contact automatically created from Vendor gets no update on Customer modification, if Contact "Name" is filled.

        // [GIVEN] Vendor record with name 'AAA' created
        Vendor.Init();
        Vendor.Name := LibraryUtility.GenerateGUID();
        Vendor.Insert(true);

        // [GIVEN] Contact with name 'AAA' created automatically for Vendor
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::Vendor, Vendor."No."));
        Contact.TestField(Name, Vendor.Name);

        // [GIVEN] Contact Name is updated to 'XXX'
        ContactName := LibraryUtility.GenerateGUID();
        Contact.Name := CopyStr(ContactName, 1, MaxStrLen(Contact.Name));
        Contact.Modify(true);
        Contact.TestField(Name, ContactName);

        // [WHEN] Vendor Priority is set to 11 and Vendor record is modified
        Vendor.Validate(Priority, LibraryRandom.RandInt(10));
        Vendor.Modify(true);

        // [THEN] Contact still have name 'XXX'
        Contact.Find();
        Contact.TestField(Name, ContactName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccUpdateContactWhenContactNameIsBlank()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 275658] Contact automatically created from Vendor gets synced on Customer modification, if Contact "Name" is blank.

        // [GIVEN] Bank Account record created with blank fields
        BankAccount.Init();
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount.Insert(true);

        // [GIVEN] Contact with blank Name created for Bank Account automatically
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::"Bank Account", BankAccount."No."));
        Contact.TestField(Name, '');

        // [WHEN] Update Bank Account Name to 'AAA'
        BankAccount.Name := LibraryUtility.GenerateGUID();
        BankAccount.Modify(true);

        // [THEN] Contact Name is updated to 'AAA' respectively
        Contact.Find();
        Contact.TestField(Name, BankAccount.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankAccDoNotUpdateContactWhenContactNameIsNotBlank()
    var
        BankAccount: Record "Bank Account";
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContactName: Text;
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 275658] Contact automatically created from Bank Account gets no update on Customer modification, if Contact "Name" is filled.

        // [GIVEN] Bank Account record with name 'AAA' created
        BankAccount.Init();
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount.Name := LibraryUtility.GenerateGUID();
        BankAccount.Insert(true);

        // [GIVEN] Contact with name 'AAA' created automatically for Bank Account
        Contact.Get(GetContactNoFromContBusRelations(ContBusRel."Link to Table"::"Bank Account", BankAccount."No."));
        Contact.TestField(Name, BankAccount.Name);

        // [GIVEN] Contact Name is updated to 'XXX'
        ContactName := LibraryUtility.GenerateGUID();
        Contact.Name := CopyStr(ContactName, 1, MaxStrLen(Contact.Name));
        Contact.Modify(true);
        Contact.TestField(Name, ContactName);

        // [WHEN] Bank Account "Bank Branch No." is changed and Bank Account record is modified
        BankAccount.Validate("Bank Branch No.", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);

        // [THEN] Contact still have name 'XXX'
        Contact.Find();
        Contact.TestField(Name, ContactName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeHelper_GetHMS_ZeroTime()
    var
        TypeHelper: Codeunit "Type Helper";
        TimeSource: Time;
        Hour: Integer;
        Minute: Integer;
        Second: Integer;
    begin
        // [FEATURE] [Time Zone]
        TimeSource := 000000T;
        TypeHelper.GetHMSFromTime(Hour, Minute, Second, TimeSource);

        Assert.AreEqual(0, Hour, 'Hour');
        Assert.AreEqual(0, Minute, 'Minute');
        Assert.AreEqual(0, Second, 'Second');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TypeHelper_GetHMS_NonZeroTime()
    var
        TypeHelper: Codeunit "Type Helper";
        TimeSource: Time;
        Hour: Integer;
        Minute: Integer;
        Second: Integer;
    begin
        // [FEATURE] [Time Zone]
        TimeSource := 235521T;
        TypeHelper.GetHMSFromTime(Hour, Minute, Second, TimeSource);

        Assert.AreEqual(23, Hour, 'Hour');
        Assert.AreEqual(55, Minute, 'Minute');
        Assert.AreEqual(21, Second, 'Second');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Contact_GetLastDateTimeModified_01()
    var
        Contact: Record "Contact";
        ExpectedDateTime: DateTime;
    begin
        // [FEATURE] [Time Zone]
        // [SCENARIO 351072] Contact.SetLastDateTimeModified() takes into account the time zone specified in User Personalization table
        CleanUserPersonalizationTable();
        SetTimeZoneInUserPersonalizationTable(GetCustomTimeZone());

        Assert.AreEqual(0DT, Contact.GetLastDateTimeModified(), '');

        ExpectedDateTime := CurrentDateTime;
        Contact.SetLastDateTimeModified();

        Assert.AreEqual(ExpectedDateTime, Contact.GetLastDateTimeModified(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Contact_GetLastDateTimeModified_02()
    var
        Contact: Record "Contact";
        ExpectedDateTime: DateTime;
        LocalTimeZoneOffset: Duration;
    begin
        // [FEATURE] [Time Zone]
        // [SCENARIO 351072] Contact.GetLastDateTimeModified() takes into account the time zone specified in User Personalization table
        CleanUserPersonalizationTable();
        SetTimeZoneInUserPersonalizationTable(GetCustomTimeZone());

        Contact."Last Date Modified" := DT2Date(CurrentDateTime);
        Contact."Last Time Modified" := 000000T;

        Evaluate(LocalTimeZoneOffset, '9hours');

        ExpectedDateTime := CreateDateTime(Contact."Last Date Modified", Contact."Last Time Modified") + LocalTimeZoneOffset;
        Assert.AreEqual(ExpectedDateTime, Contact.GetLastDateTimeModified(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCard_LastDateTimeModified()
    var
        Contact: Record "Contact";
        ContactCard: TestPage "Contact Card";
        ExpectedDateTime: DateTime;
        LocalTimeZoneOffset: Duration;
    begin
        // [FEATURE] [Time Zone] [UI]
        // [SCENARIO 351072] Contact Card shows the returned value of the Contact.GetLastDateTimeModified() function
        CleanUserPersonalizationTable();
        SetTimeZoneInUserPersonalizationTable(GetCustomTimeZone());

        Contact.Init();
        Contact."No." := LibraryUtility.GenerateGUID();
        Contact."Last Date Modified" := DT2Date(CurrentDateTime());
        Contact."Last Time Modified" := 000000T;
        Contact.Insert();

        Evaluate(LocalTimeZoneOffset, '9hours');
        ExpectedDateTime := CreateDateTime(Contact."Last Date Modified", Contact."Last Time Modified") + LocalTimeZoneOffset;

        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        ContactCard.LastDateTimeModified.AssertEquals(ExpectedDateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Contact_GetLastDateTimeModified_01_WithoutUserPersonalization()
    var
        Contact: Record "Contact";
        ExpectedDateTime: DateTime;
    begin
        // [FEATURE] [Time Zone]
        // [SCENARIO 351072] Contact.SetLastDateTimeModified() takes into account the server time zone when User Personalization is not present
        CleanUserPersonalizationTable();

        Assert.AreEqual(0DT, Contact.GetLastDateTimeModified(), '');

        ExpectedDateTime := CurrentDateTime;
        Contact.SetLastDateTimeModified();

        Assert.AreEqual(ExpectedDateTime, Contact.GetLastDateTimeModified(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Contact_GetLastDateTimeModified_02_WithoutUserPersonalization()
    var
        Contact: Record "Contact";
        TypeHelper: Codeunit "Type Helper";
        ExpectedDateTime: DateTime;
        LocalTimeZoneOffset: Duration;
    begin
        // [FEATURE] [Time Zone]
        // [SCENARIO 351072] Contact.GetLastDateTimeModified() takes into account the server time zone when User Personalization is not present
        CleanUserPersonalizationTable();

        Contact."Last Date Modified" := DT2Date(CurrentDateTime);
        Contact."Last Time Modified" := 000000T;

        TypeHelper.GetTimezoneOffset(LocalTimeZoneOffset, GetStandardTimeZone());

        ExpectedDateTime := CreateDateTime(Contact."Last Date Modified", Contact."Last Time Modified") + LocalTimeZoneOffset;
        Assert.AreEqual(ExpectedDateTime, Contact.GetLastDateTimeModified(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactCard_LastDateTimeModified_WithoutUserPersonalization()
    var
        Contact: Record "Contact";
        TypeHelper: Codeunit "Type Helper";
        ContactCard: TestPage "Contact Card";
        ExpectedDateTime: DateTime;
        LocalTimeZoneOffset: Duration;
    begin
        // [FEATURE] [Time Zone] [UI]
        // [SCENARIO 351072] Contact Card shows the returned value of the Contact.GetLastDateTimeModified() function without User Personalization setup
        CleanUserPersonalizationTable();

        Contact.Init();
        Contact."No." := LibraryUtility.GenerateGUID();
        Contact."Last Date Modified" := DT2Date(CurrentDateTime());
        Contact."Last Time Modified" := 000000T;
        Contact.Insert();

        TypeHelper.GetTimezoneOffset(LocalTimeZoneOffset, GetStandardTimeZone());
        ExpectedDateTime := CreateDateTime(Contact."Last Date Modified", Contact."Last Time Modified") + LocalTimeZoneOffset;

        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("No.", Contact."No.");
        ContactCard.LastDateTimeModified.AssertEquals(ExpectedDateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetContNoGetContactByName_CaseSensitive()
    var
        Contact: array[2] of Record Contact;
        RandomText1: Text[100];
        RandomText2: Text[100];
    begin
        RandomText1 := 'aaa';
        RandomText2 := 'AAA';

        MockContactWithName(Contact[1], RandomText1);
        MockContactWithName(Contact[2], RandomText2);

        Assert.AreEqual(Contact[1]."No.", Contact[1].GetContNo(RandomText1), '');
        Assert.AreEqual(Contact[2]."No.", Contact[1].GetContNo(RandomText2), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithSemicolon()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Contact table in case it contains multiple e-mail addresses, separated by ;

        // [WHEN] Validate E-Mail field of Contact table, when it contains multiple email addresses in cases, separated by ;
        Contact.Validate("E-Mail", 'test1@test.com; test2@test.com; test3@test.com');

        // [THEN] String is validated without errors.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldOnEmptyEmailAddress()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Contact table in case it's empty.

        // [WHEN] Validate E-Mail field of Contact table on empty value.
        Contact.Validate("E-Mail", '');

        // [THEN] String is validated without errors.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithComma()
    var
        Contact: Record Contact;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Contact table in case it contains multiple e-mail addresses, separated by ,
        MultipleAddressesTxt := 'test1@test.com, test2@test.com, test3@test.com';

        // [WHEN] Validate E-Mail field of Contact table, when it contains multiple email addresses, separated by ,
        asserterror Contact.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid.', MultipleAddressesTxt));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithVerticalBar()
    var
        Contact: Record Contact;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Contact table in case it contains multiple e-mail addresses, separated by |
        MultipleAddressesTxt := 'test1@test.com| test2@test.com| test3@test.com';

        // [WHEN] Validate E-Mail field of Contact table, when it contains multiple email addresses, separated by |
        asserterror Contact.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid.', MultipleAddressesTxt));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithSpace()
    var
        Contact: Record Contact;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Contact table in case it contains multiple e-mail addresses, separated by space.
        MultipleAddressesTxt := 'test1@test.com test2@test.com test3@test.com';

        // [WHEN] Validate E-Mail field of Contact table, when it contains multiple email addresses, separated by space.
        asserterror Contact.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError(StrSubstNo('The email address "%1" is not valid.', MultipleAddressesTxt));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateEmailFieldMultipleEmailAddressesWithInvalidEmail()
    var
        Contact: Record Contact;
        MultipleAddressesTxt: Text;
    begin
        // [SCENARIO 341841] Validate E-Mail field of Contact table in case it contains multiple e-mail addresses; one of them is not valid.
        MultipleAddressesTxt := 'test1@test.com; test2.com; test3@test.com';

        // [WHEN] Validate E-Mail field of Contact table, when it contains multiple email addresses, one of them is not a valid email address.
        asserterror Contact.Validate("E-Mail", MultipleAddressesTxt);

        // [THEN] The error "The email address is not valid." is thrown.
        Assert.ExpectedError('The email address "test2.com" is not valid.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetLastDateTimeFilter_EmptyDate()
    var
        Contact: Record Contact;
        EmptyDateTime: DateTime;
    begin
        // [Feature] [DateTime]
        // [SCENARIO 370714] SetLastDateTimeFilter correctly processes empty DateTime input value
        // [WHEN] Contact table method SetLastDateTimeFilter input DateTime parameter is empty
        Contact.SetLastDateTimeFilter(EmptyDateTime);
        // [THEN] The method runs without error. "Last Date Modified" filter = ">=''"
        Assert.AreEqual('>=''''', Contact.GetFilter(SystemModifiedAt), 'Wrong filter value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetLastDateTimeFilter_ZeroDate()
    var
        Contact: Record Contact;
        ZeroDateTime: DateTime;
    begin
        // [Feature] [DateTime]
        // [SCENARIO 370714] SetLastDateTimeFilter correctly processes zero DateTime input value
        // [WHEN] Contact table method SetLastDateTimeFilter input DateTime parameter is 0DT
        ZeroDateTime := 0DT;
        Contact.SetLastDateTimeFilter(ZeroDateTime);
        // [THEN] The method runs without error. "Last Date Modified" filter = ">=''"
        Assert.AreEqual('>=''''', Contact.GetFilter(SystemModifiedAt), 'Wrong filter value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenCustomerPageFromContactHasDateFilter()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        ContactBusinessRelation: Record "Contact Business Relation";
        CustomerCard: TestPage "Customer Card";
        DateFilter: Text;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 378030] When Customer Card page is open from Contact it has filter for Due Date already set

        // [GIVEN] Customer created
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Contact exists for this customer
        Contact.Get(GetContactNoFromContBusRelations(ContactBusinessRelation."Link to Table"::Customer, Customer."No."));

        // [WHEN] Call "ShowCustVendBank" for this contact
        CustomerCard.Trap();
        Contact.ShowBusinessRelation("Contact Business Relation Link To Table"::" ", false);

        // [THEN] Customer Card has Date Filter which is equal to "before today"
        DateFilter := StrSubstNo('''''..%1', WorkDate());
        Assert.AreEqual(DateFilter, CustomerCard.FILTER.GetFilter("Date Filter"), DateFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenVendorPageFromContactHasDateFilter()
    var
        Contact: Record Contact;
        Vendor: Record Vendor;
        ContactBusinessRelation: Record "Contact Business Relation";
        VendorCard: TestPage "Vendor Card";
        DateFilter: Text;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 378030] When Vendor Card page is open from Contact it has filter for Due Date already set

        // [GIVEN] Vendor created
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Contact exists for this Vendor
        Contact.Get(GetContactNoFromContBusRelations(ContactBusinessRelation."Link to Table"::Vendor, Vendor."No."));

        // [WHEN] Call "ShowCustVendBank" for this contact
        VendorCard.Trap();
        Contact.ShowBusinessRelation("Contact Business Relation Link To Table"::" ", false);
        ;

        // [THEN] Vendor Card has Date Filter which is equal to "before today"
        DateFilter := StrSubstNo('''''..%1', WorkDate());
        Assert.AreEqual(DateFilter, VendorCard.FILTER.GetFilter("Date Filter"), DateFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenBankPageFromContactHasDateFilter()
    var
        Contact: Record Contact;
        BankAccount: Record "Bank Account";
        ContactBusinessRelation: Record "Contact Business Relation";
        BankAccountCard: TestPage "Bank Account Card";
        DateFilter: Text;
    begin
        // [FEATURE] [Bank Account]
        // [SCENARIO 378030] When Bank Account Card page is open from Contact it has filter for Due Date already set

        // [GIVEN] Bank Account created
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Contact exists for this Bank Account
        Contact.Get(GetContactNoFromContBusRelations(ContactBusinessRelation."Link to Table"::"Bank Account", BankAccount."No."));

        // [WHEN] Call "ShowCustVendBank" for this contact
        BankAccountCard.Trap();
        Contact.ShowBusinessRelation("Contact Business Relation Link To Table"::" ", false);

        // [THEN] Bank Account Card has Date Filter which is equal to "before today"
        DateFilter := StrSubstNo('''''..%1', WorkDate());
        Assert.AreEqual(DateFilter, BankAccountCard.FILTER.GetFilter("Date Filter"), DateFilterErr);
    end;

    [Test]
    procedure PhoneNoValidateDigitsOnly()
    var
        Contact: Record Contact;
        PhoneNo: Text[30];
    begin
        // [SCENARIO 423817] Validate Contact's Phone No. with digits only.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Validate Phone No. with "0814655", i.e. try to write digits to Phone No.
        PhoneNo := '0814655';
        Contact.Validate("Phone No.", PhoneNo);

        // [THEN] Phone No. was set to "0814655".
        Contact.TestField("Phone No.", PhoneNo);
    end;

    [Test]
    procedure PhoneNoValidateDigitsAndNonLetterChars()
    var
        Contact: Record Contact;
        PhoneNo: Text[30];
    begin
        // [SCENARIO 423817] Validate Contact's Phone No. with digits and non-letter chars.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Validate Phone No. with "+-0814 655=&?", i.e. try to write non-letter chars to Phone No.
        PhoneNo := '+-0814 655=&?';
        Contact.Validate("Phone No.", PhoneNo);

        // [THEN] Phone No. was set to "+-0814 655=&?".
        Contact.TestField("Phone No.", PhoneNo);
    end;

    [Test]
    procedure PhoneNoValidateDigitsAndLetterChars()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 423817] Validate Contact's Phone No. with digits and letter chars.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Validate Phone No. with "A1234b", i.e. try to write letters to Phone No.
        asserterror Contact.Validate("Phone No.", 'A1234b');

        // [THEN] Phone No. was not set, error is thrown.
        Contact.TestField("Phone No.", '');
        Assert.ExpectedError(StrSubstNo(PhoneNoCannotContainLettersErr, Contact.FieldCaption("Phone No."), Contact."No."));
        Assert.ExpectedErrorCode('TableErrorStr');
    end;

    [Test]
    procedure PhoneNoSetLetterOnContactCard()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 423817] Set letter to Phone No. on Contact Card.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Opened Contact Card.
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Set 'a' as Phone No. on Contact Card.
        asserterror ContactCard."Phone No.".SetValue('a');

        // [THEN] Phone No. was not set, error is thrown.
        Contact.TestField("Phone No.", '');
        Assert.ExpectedError(StrSubstNo(PhoneNoContactCardValidationErr, Contact.FieldCaption("Phone No.")));
        Assert.ExpectedErrorCode('TestValidation');
    end;

    [Test]
    procedure MobilePhoneNoValidateDigitsOnly()
    var
        Contact: Record Contact;
        MobilePhoneNo: Text[30];
    begin
        // [SCENARIO 423817] Validate Contact's Mobile Phone No. with digits only.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Validate Mobile Phone No. with "0814655", i.e. try to write digits to Mobile Phone No.
        MobilePhoneNo := '0814655';
        Contact.Validate("Mobile Phone No.", MobilePhoneNo);

        // [THEN] Mobile Phone No. was set to "0814655".
        Contact.TestField("Mobile Phone No.", MobilePhoneNo);
    end;

    [Test]
    procedure MobilePhoneNoValidateDigitsAndNonLetterChars()
    var
        Contact: Record Contact;
        MobilePhoneNo: Text[30];
    begin
        // [SCENARIO 423817] Validate Contact's Mobile Phone No. with digits and non-letter chars.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Validate Mobile Phone No. with "+-0814 655=&?", i.e. try to write non-letter chars to Mobile Phone No.
        MobilePhoneNo := '+-0814 655=&?';
        Contact.Validate("Mobile Phone No.", MobilePhoneNo);

        // [THEN] Mobile Phone No. was set to "+-0814 655=&?".
        Contact.TestField("Mobile Phone No.", MobilePhoneNo);
    end;

    [Test]
    procedure MobilePhoneNoValidateDigitsAndLetterChars()
    var
        Contact: Record Contact;
    begin
        // [SCENARIO 423817] Validate Contact's Mobile Phone No. with digits and letter chars.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [WHEN] Validate Mobile Phone No. with "A1234b", i.e. try to write letters to Mobile Phone No.
        asserterror Contact.Validate("Mobile Phone No.", 'A1234b');

        // [THEN] Mobile Phone No. was not set, error is thrown.
        Contact.TestField("Mobile Phone No.", '');
        Assert.ExpectedError(StrSubstNo(PhoneNoCannotContainLettersErr, Contact.FieldCaption("Mobile Phone No."), Contact."No."));
        Assert.ExpectedErrorCode('TableErrorStr');
    end;

    [Test]
    procedure MobilePhoneNoSetLetterOnContactCard()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO 423817] Set letter to Mobile Phone No. on Contact Card.

        // [GIVEN] Contact.
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Opened Contact Card.
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Set 'a' as Mobile Phone No. on Contact Card.
        asserterror ContactCard."Mobile Phone No.".SetValue('a');

        // [THEN] Mobile Phone No. was not set, error is thrown.
        Contact.TestField("Mobile Phone No.", '');
        Assert.ExpectedError(StrSubstNo(PhoneNoContactCardValidationErr, Contact.FieldCaption("Mobile Phone No.")));
        Assert.ExpectedErrorCode('TestValidation');
    end;

    local procedure GetContactNoFromContBusRelations(LinkOption: Enum "Contact Business Relation Link To Table"; CodeNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkOption);
        ContactBusinessRelation.SetRange("No.", CodeNo);
        ContactBusinessRelation.FindFirst();
        exit(ContactBusinessRelation."Contact No.");
    end;

    local procedure MockContact(var Contact: Record Contact; ContactType: Enum "Contact Type")
    var
        ContactMailingGroup: Record "Contact Mailing Group";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        ContactAltAddress: Record "Contact Alt. Address";
        ContactAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        Contact.Init();
        Contact.Insert(true);
        Contact.Validate(Type, ContactType);
        Contact.Validate(
          Name, CopyStr(LibraryUtility.GenerateRandomText(20), 1, MaxStrLen(Contact.Name)));
        Contact.Modify(true);

        ContactMailingGroup.Init();
        ContactMailingGroup."Contact No." := Contact."No.";
        ContactMailingGroup.Insert(true);

        RlshpMgtCommentLine.Init();
        RlshpMgtCommentLine."Table Name" := RlshpMgtCommentLine."Table Name"::Contact;
        RlshpMgtCommentLine."No." := Contact."No.";
        RlshpMgtCommentLine.Insert(true);

        ContactAltAddress.Init();
        ContactAltAddress."Contact No." := Contact."No.";
        ContactAltAddress.Insert(true);

        ContactAltAddrDateRange.Init();
        ContactAltAddrDateRange."Contact No." := Contact."No.";
        ContactAltAddrDateRange.Insert(true);

        ContactBusinessRelation.Init();
        ContactBusinessRelation."Contact No." := Contact."No.";
        ContactBusinessRelation.Insert(true);
    end;

    local procedure MockContactWithName(var Contact: Record Contact; ContactName: Text[100])
    begin
        Contact.Init();
        Contact.Name := ContactName;
        Contact.Insert(true);
    end;

    local procedure CleanUserPersonalizationTable()
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.DeleteAll();
    end;

    local procedure SetTimeZoneInUserPersonalizationTable(TimeZone: Text[180])
    var
        UserPersonalization: Record "User Personalization";
    begin
        UserPersonalization.Init();
        UserPersonalization."User SID" := UserSecurityId();
        UserPersonalization."Time Zone" := TimeZone;
        if not UserPersonalization.Insert() then
            UserPersonalization.Modify();
    end;

    local procedure GetStandardTimeZone(): Text[180]
    begin
        exit('');
    end;

    local procedure GetCustomTimeZone(): Text[180]
    begin
        exit('Yakutsk Standard Time');
    end;

    local procedure VerifyContactRelatedRecordsDeleted(ContactNo: Code[20])
    var
        ContactMailingGroup: Record "Contact Mailing Group";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
        ContactAltAddress: Record "Contact Alt. Address";
        ContactAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactMailingGroup.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactMailingGroup);

        RlshpMgtCommentLine.SetRange("No.", ContactNo);
        Assert.RecordIsEmpty(RlshpMgtCommentLine);

        ContactAltAddress.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactAltAddress);

        ContactAltAddrDateRange.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactAltAddrDateRange);

        ContactBusinessRelation.SetRange("Contact No.", ContactNo);
        Assert.RecordIsEmpty(ContactBusinessRelation);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
