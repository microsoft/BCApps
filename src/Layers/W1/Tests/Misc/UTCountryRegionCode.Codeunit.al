codeunit 134995 "UT Country/Region Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Country/Region Code] [UT]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForCustomer()
    var
        Customer: Record Customer;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Customer, Customer.FieldNo(City),
              Customer.FieldNo("Post Code"), Customer.FieldNo(County), Customer.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForVendor()
    var
        Vendor: Record Vendor;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Vendor, Vendor.FieldNo(City),
              Vendor.FieldNo("Post Code"), Vendor.FieldNo(County), Vendor.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForContact()
    var
        Contact: Record Contact;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Contact, Contact.FieldNo(City),
              Contact.FieldNo("Post Code"), Contact.FieldNo(County), Contact.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateSellToCountryRegionForSalesHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        CheckFieldsAreNotBlankAfterValidation(DATABASE::"Sales Header",
              SalesHeader.FieldNo("Sell-to City"), SalesHeader.FieldNo("Sell-to Post Code"), SalesHeader.FieldNo("Sell-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBuyFromCountryRegionForPurchHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CheckFieldsAreNotBlankAfterValidation(DATABASE::"Purchase Header",
              PurchaseHeader.FieldNo("Buy-from City"), PurchaseHeader.FieldNo("Buy-from Post Code"), PurchaseHeader.FieldNo("Buy-from Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForShipToAddress()
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Ship-to Address",
              ShipToAddress.FieldNo(City), ShipToAddress.FieldNo("Post Code"), ShipToAddress.FieldNo(County), ShipToAddress.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForLocation()
    var
        Location: Record Location;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Location,
              Location.FieldNo(City), Location.FieldNo("Post Code"), Location.FieldNo(County), Location.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForResource()
    var
        Resource: Record Resource;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Resource,
              Resource.FieldNo(City), Resource.FieldNo("Post Code"), Resource.FieldNo(County), Resource.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForJob()
    var
        Job: Record Job;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Job,
              Job.FieldNo("Bill-to City"), Job.FieldNo("Bill-to Post Code"), Job.FieldNo("Bill-to County"), Job.FieldNo("Bill-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Bank Account",
              BankAccount.FieldNo(City), BankAccount.FieldNo("Post Code"), BankAccount.FieldNo(County), BankAccount.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForReminderHeader()
    var
        ReminderHeader: Record "Reminder Header";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Reminder Header",
              ReminderHeader.FieldNo(City), ReminderHeader.FieldNo("Post Code"), ReminderHeader.FieldNo(County), ReminderHeader.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForFinChargeMemoHeader()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Finance Charge Memo Header",
              FinanceChargeMemoHeader.FieldNo(City), FinanceChargeMemoHeader.FieldNo("Post Code"), FinanceChargeMemoHeader.FieldNo(County), FinanceChargeMemoHeader.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForContactAltAddress()
    var
        ContactAltAddress: Record "Contact Alt. Address";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Contact Alt. Address",
              ContactAltAddress.FieldNo(City), ContactAltAddress.FieldNo("Post Code"), ContactAltAddress.FieldNo(County), ContactAltAddress.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForEmployee()
    var
        Employee: Record Employee;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Employee,
              Employee.FieldNo(City), Employee.FieldNo("Post Code"), Employee.FieldNo(County), Employee.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForAlternativeAddress()
    var
        AlternativeAddress: Record "Alternative Address";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Alternative Address", AlternativeAddress.FieldNo(City),
              AlternativeAddress.FieldNo("Post Code"), AlternativeAddress.FieldNo(County), AlternativeAddress.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForUnion()
    var
        Union: Record Union;
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::Union,
              Union.FieldNo(City), Union.FieldNo("Post Code"), Union.FieldNo(County), Union.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForResponsibilityCenter()
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Responsibility Center",
              ResponsibilityCenter.FieldNo(City), ResponsibilityCenter.FieldNo("Post Code"), ResponsibilityCenter.FieldNo(County), ResponsibilityCenter.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransferFromCountryRegionForTransferHeader()
    var
        TransferHeader: Record "Transfer Header";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Transfer Header", TransferHeader.FieldNo("Transfer-from City"),
              TransferHeader.FieldNo("Transfer-from Post Code"), TransferHeader.FieldNo("Transfer-from County"), TransferHeader.FieldNo("Trsf.-from Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateTransferToCountryRegionForTransferHeader()
    var
        TransferHeader: Record "Transfer Header";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Transfer Header", TransferHeader.FieldNo("Transfer-to City"),
              TransferHeader.FieldNo("Transfer-to Post Code"), TransferHeader.FieldNo("Transfer-to County"), TransferHeader.FieldNo("Trsf.-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBillToCountryRegionForServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        CheckFieldsAreNotBlankAfterValidation(DATABASE::"Service Header", ServiceHeader.FieldNo("Bill-to City"),
              ServiceHeader.FieldNo("Bill-to Post Code"), ServiceHeader.FieldNo("Bill-to Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePayToCountryRegionForServiceHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        CheckFieldsAreNotBlankAfterValidation(DATABASE::"Service Header", ServiceHeader.FieldNo(City), ServiceHeader.FieldNo("Post Code"),
              ServiceHeader.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForWorkCenter()
    var
        WorkCenter: Record "Work Center";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Work Center", WorkCenter.FieldNo(City),
              WorkCenter.FieldNo("Post Code"), WorkCenter.FieldNo(County), WorkCenter.FieldNo("Country/Region Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCountryRegionForMachineCenter()
    var
        MachineCenter: Record "Machine Center";
    begin
        CheckFieldsAreBlankAfterValidation(DATABASE::"Machine Center", MachineCenter.FieldNo(City),
              MachineCenter.FieldNo("Post Code"), MachineCenter.FieldNo(County), MachineCenter.FieldNo("Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCountryCodeAfterValidatingPostCodeSameForTwoCitiesUT()
    var
        Customer: Record Customer;
        CityName: Text[30];
        CountryCode: array[2] of Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 235201] If there are two cities in different countries with the same "Post Code", then when set Customer's "Post Code", City must be picked according to Customer's "Country/Region Code"
        CountryCode[1] := LibraryUTUtility.GetNewCode10();
        CountryCode[2] := LibraryUTUtility.GetNewCode10();

        InitTwoCountries(CountryCode);
        PostCode := LibraryUTUtility.GetNewCode10();
        InitPostCode(CountryCode[2], 'A' + LibraryUTUtility.GetNewCode10(), PostCode);
        CityName := 'Z' + LibraryUTUtility.GetNewCode();
        InitPostCode(CountryCode[1], CityName, PostCode);

        Customer.Init();
        Customer.Validate(Name, LibraryUTUtility.GetNewCode());
        Customer.Validate("Country/Region Code", CountryCode[1]);
        Customer.Insert(true);

        Customer.Get(Customer."No.");
        Customer.Validate("Post Code", PostCode);
        Customer.Modify(true);

        Customer.TestField("Country/Region Code", CountryCode[1]);
        Customer.TestField(City, CityName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCountryCodeAfterValidatingCitySameForTwoCountriesUT()
    var
        Customer: Record Customer;
        CityName: Text[30];
        CountryCode: array[2] of Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 235201] If there are two cities in different countries with the same name, then when set Customer's "City", "Post Code" must be picked according to Customer's "Country/Region Code"
        CountryCode[1] := 'B';
        CountryCode[2] := 'A';
        InitTwoCountries(CountryCode);

        CityName := LibraryUTUtility.GetNewCode();
        InitPostCode(CountryCode[2], CityName, LibraryUTUtility.GetNewCode10());
        PostCode := LibraryUTUtility.GetNewCode10();
        InitPostCode(CountryCode[1], CityName, PostCode);

        Customer.Init();
        Customer.Validate(Name, LibraryUTUtility.GetNewCode());
        Customer.Validate("Country/Region Code", CountryCode[1]);
        Customer.Insert(true);

        Customer.Get(Customer."No.");
        Customer.Validate(City, CityName);
        Customer.Modify(true);

        // [THEN] Post Code was filled during validation 
        Customer.TestField("Country/Region Code", CountryCode[1]);
        Customer.TestField("Post Code", PostCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressUsesCustomerCityIfTwoCitiesWithSamePostCode()
    var
        Customer: Record Customer;
        ShipToAddressPage: TestPage "Ship-to Address";
        CityName: Text[30];
        CountryCode: Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 295922] If there are two cities in same country with the same "Post Code", then when Ship-to Address is created it uses Customer's city

        // [GIVEN] One country Code, One Post Code
        CountryCode := LibraryUtility.GenerateGUID();
        PostCode := LibraryUtility.GenerateGUID();
        InitCountry(CountryCode);

        // [GIVEN] Two Post Code setups, with 2 different City Names, "City1" and "City2"
        InitPostCode(CountryCode, 'A-' + LibraryUtility.GenerateGUID(), PostCode);
        CityName := 'Z-' + LibraryUtility.GenerateGUID();
        InitPostCode(CountryCode, CityName, PostCode);

        // [GIVEN] A Customer with Country Code, Post Code and City Name = "City2"
        CreateCustomerWithAddressInfo(Customer, CountryCode, PostCode, CityName);

        // [WHEN] Create a new Ship-to Address for this Customer via Ship-to Address page
        ShipToAddressPage.OpenNew();
        ShipToAddressPage.FILTER.SetFilter("Customer No.", Customer."No.");
        ShipToAddressPage.New();

        // [THEN] Ship-to Address City = Customer.City
        ShipToAddressPage.City.AssertEquals(Customer.City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressUsesCustomerPostCodeIfTwoPostCodesForSameCity()
    var
        Customer: Record Customer;
        ShipToAddressPage: TestPage "Ship-to Address";
        CityName: Text[30];
        CountryCode: Code[10];
        PostCode: Code[20];
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 295922] If there are two post codes for same city in the same country, then when Ship-to Address is created it uses Customer's city

        // [GIVEN] One country Code, One City Name
        CountryCode := LibraryUtility.GenerateGUID();
        CityName := LibraryUtility.GenerateGUID();
        InitCountry(CountryCode);

        // [GIVEN] Two Post Code setups, with same City Name, 2 different postcodes "Code1" and "Code2"
        InitPostCode(CountryCode, CityName, LibraryUtility.GenerateGUID());
        PostCode := LibraryUtility.GenerateGUID();
        InitPostCode(CountryCode, CityName, PostCode);

        // [GIVEN] A Customer with Country Code, City Name and Post Code = "Code2"
        CreateCustomerWithAddressInfo(Customer, CountryCode, PostCode, CityName);

        // [WHEN] Create a new Ship-to Address for this Customer via Ship-to Address page
        ShipToAddressPage.OpenNew();
        ShipToAddressPage.FILTER.SetFilter("Customer No.", Customer."No.");
        ShipToAddressPage.New();

        // [THEN] Ship-to Address Post Code = Customer."Post Code"
        ShipToAddressPage."Post Code".AssertEquals(Customer."Post Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToAddressCountyVisibility()
    var
        CountryWithoutCounty: Record "Country/Region";
        CountryWithCounty: Record "Country/Region";
        ShiptoAddress: TestPage "Ship-to Address";
    begin
        // [FEATURE] [Address] [County] [UI]
        // [SCENARIO 311818] Page "Ship-to Address" has field "County/State" visible for countries with Address Format "City+County+Post Code"
        InitializeCountriesDifferentFormat(CountryWithoutCounty, CountryWithCounty);

        ShiptoAddress.OpenNew();
        ShiptoAddress."Country/Region Code".Value := CountryWithoutCounty.Code;
        Assert.IsFalse(ShiptoAddress.County.Visible(), 'County field should not be visible');
        ShiptoAddress."Country/Region Code".Value := CountryWithCounty.Code;
        Assert.IsTrue(ShiptoAddress.County.Visible(), 'County field should be visible');
    end;

    local procedure CheckFieldsAreBlankAfterValidation(TableNo: Integer; City: Integer; PostCode: Integer; County: Integer; CountryRegionCode: Integer)
    var
        RecRef: RecordRef;
        CityFieldRef: FieldRef;
        PostCodeFieldRef: FieldRef;
        CountyFieldRef: FieldRef;
        CountryRegionFieldRef: FieldRef;
        NewCode: Code[20];
    begin
        // Setup: Assign PostCode,City,County and Country/Region Code.
        NewCode := LibraryUTUtility.GetNewCode();
        RecRef.Open(TableNo);
        CityFieldRef := RecRef.Field(City);
        CityFieldRef.Value := NewCode;
        PostCodeFieldRef := RecRef.Field(PostCode);
        PostCodeFieldRef.Value := NewCode;
        CountyFieldRef := RecRef.Field(County);
        CountyFieldRef.Value := NewCode;
        CountryRegionFieldRef := RecRef.Field(CountryRegionCode);
        CountryRegionFieldRef.Value := LibraryUTUtility.GetNewCode10();
        RecRef.Insert();

        // Exercise: Validate Country/Region Code as blank.
        CountryRegionFieldRef.Validate('');

        // Verify: Verify PostCode,City and County are blank.
        CityFieldRef.TestField('');
        PostCodeFieldRef.TestField('');
        CountyFieldRef.TestField('');
    end;

    local procedure CheckFieldsAreNotBlankAfterValidation(TableNo: Integer; City: Integer; PostCode: Integer; CountryRegionCode: Integer)
    var
        RecRef: RecordRef;
        CityFieldRef: FieldRef;
        PostCodeFieldRef: FieldRef;
        CountryRegionFieldRef: FieldRef;
        NewCode: Code[20];
    begin
        // Setup: Assign PostCode,City and Country/Region Code.
        NewCode := LibraryUTUtility.GetNewCode();
        RecRef.Open(TableNo);
        CityFieldRef := RecRef.Field(City);
        CityFieldRef.Value := NewCode;
        PostCodeFieldRef := RecRef.Field(PostCode);
        PostCodeFieldRef.Value := NewCode;
        CountryRegionFieldRef := RecRef.Field(CountryRegionCode);
        CountryRegionFieldRef.Value := LibraryUTUtility.GetNewCode10();
        RecRef.Insert();

        // Exercise: Validate Country/Region Code as blank.
        CountryRegionFieldRef.Validate('');

        // Verify: Verify PostCode andCity are not blank.
        CityFieldRef.TestField(NewCode);
        PostCodeFieldRef.TestField(NewCode);
    end;

    local procedure InitCountry(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := CountryCode;
        CountryRegion.Insert(true);
    end;

    local procedure InitTwoCountries(CountryCode: array[2] of Code[10])
    begin
        InitCountry(CountryCode[1]);
        InitCountry(CountryCode[2]);
    end;

    local procedure InitializeCountriesDifferentFormat(var CountryWithoutCounty: Record "Country/Region"; var CountryWithCounty: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryWithoutCounty);
        CountryWithoutCounty."Address Format" := CountryWithCounty."Address Format"::"City+Post Code";
        CountryWithoutCounty.Modify();

        LibraryERM.CreateCountryRegion(CountryWithCounty);
        CountryWithCounty."Address Format" := CountryWithCounty."Address Format"::"City+County+Post Code";
        CountryWithCounty.Modify();
    end;

    local procedure InitPostCode(CountryCode: Code[10]; CityName: Text[30]; PostCodeValue: Code[20])
    var
        PostCode: Record "Post Code";
    begin
        PostCode.Reset();
        PostCode.Init();
        PostCode.Validate(Code, PostCodeValue);
        PostCode.Validate(City, CityName);
        PostCode.Validate("Country/Region Code", CountryCode);
        PostCode.Insert(true);
    end;

    local procedure CreateCustomerWithAddressInfo(var Customer: Record Customer; CountryCode: Code[10]; PostCode: Code[20]; CityName: Text[30])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CountryCode;
        Customer."Post Code" := PostCode;
        Customer.City := CityName;
        Customer.Modify(true);
    end;
}

