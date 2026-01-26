codeunit 141066 "UT Address Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Address] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ValidationErr: Label 'Validation';
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePostCodeCustomer()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO] verify if post code is entered manually on the Customer.

        // Setup.
        Initialize();

        // Exercise.
        CustomerNo := CreateCustomer();

        // Verify.
        Customer.Get(CustomerNo);
        Customer.TestField("No.");
        Customer.TestField("Post Code");
        Customer.TestField(City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePostCodeVendor()
    var
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // [SCENARIO] verify if post code is entered manually on the Vendor.

        // Setup.
        Initialize();

        // Exercise.
        VendorNo := CreateVendor();

        // Verify.
        Vendor.Get(VendorNo);
        Vendor.TestField("No.");
        Vendor.TestField("Post Code");
        Vendor.TestField(City);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCityContactCard()
    var
        ContactCard: TestPage "Contact Card";
    begin
        // [SCENARIO] verify whether the user misspells the City Name or enters the City Name on the Contact Card that does not exist in the post codes list.
        // [SCENARIO] Actual Error msg is,"Validation error for Field:City, Message = 'There is no Post Code within the filter.Filters: Search City: XXXXXX' ".

        // Setup.
        Initialize();
        ContactCard.OpenNew();
        ContactCard."No.".SetValue(LibraryUTUtility.GetNewCode());

        // Exercise.
        asserterror ContactCard.City.SetValue(LibraryUTUtility.GetNewCode());

        // Verify.
        Assert.ExpectedErrorCode(ValidationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StateFieldIsRelatedToCountiesNegative()
    var
        PostCode: Record "Post Code";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 377569] "County" ("State" in translation) field on Post Codes page should be related to County table, so not existing State can not be inserted

        Initialize();
        asserterror PostCode.Validate(County, LibraryUTUtility.GetNewCode10());
        Assert.ExpectedErrorCode('DB');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StateFieldIsRelatedToCountiesPositive()
    var
        County: Record County;
        PostCode: Record "Post Code";
    begin
        // [FEATURE] [Post Code]
        // [SCENARIO 377569] "County" ("State" in translation) field on Post Codes page should be related to County table, so State included in County table may be inserted

        Initialize();
        County.Init();
        County.Name := LibraryUtility.GenerateRandomCode(County.FieldNo(Name), DATABASE::County);
        County.Insert();
        PostCode.Code := LibraryUTUtility.GetNewCode10();
        PostCode.Insert();
        PostCode.Validate(County, County.Name);
        PostCode.Modify();
        PostCode.TestField(County, County.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAddressFormatFromCityCountyPostCodeNoCommaToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 298365] Custom address format lines created properly when Address Format changed from City+County+Post Code (no comma) to Custom
        Initialize();

        // [GIVEN] Country with Address Format = City+County+Post Code (no comma)
        CountryRegion.Get(
          CreateCountryRegion(CountryRegion."Address Format"::"City+County+Post Code (no comma)"));

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Last Custom Address Format line has "Line Format" = "[City] [County] [Post Code]"
        VerifyLineFormatCustomAddressFormat(CountryRegion.Code, '[City] [County] [Post Code] ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAddressFormatFromCityPostCodeNoCommaToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 298365] Custom address format lines created properly when Address Format changed from City+Post Code (no comma) to Custom
        Initialize();

        // [GIVEN] Country with Address Format = City+Post Code (no comma)
        CountryRegion.Get(
          CreateCountryRegion(CountryRegion."Address Format"::"City+Post Code (no comma)"));

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Last Custom Address Format line has "Line Format" = "[City] [Post Code]"
        VerifyLineFormatCustomAddressFormat(CountryRegion.Code, '[City] [Post Code] ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryCodeOnValidatePostCode()
    var
        PostCode: Record "Post Code";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 303244] Country/Region code field is filled in when user enter Post Code
        Initialize();

        // [GIVEN] Post Code record with Post Code = "1234" and "Country/Region Code" = "XX"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] New Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Customer."Post Code" is being chanaged to "1234"
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard."Post Code".SetValue(PostCode.Code);

        // [THEN] Customer."Country/Region Code" = "XX"
        CustomerCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('PostCodeModaPageHandler')]
    [Scope('OnPrem')]
    procedure CountryCodeOnValidatePostCodeSeveralRecords()
    var
        PostCode: Record "Post Code";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 303244] Country/Region code field is filled in when user enter Post Code and pick one of post codes records
        Initialize();

        // [GIVEN] Post Code record with Post Code = "1234", City = "ABC" and "Country/Region Code" = "XX"
        LibraryERM.CreatePostCode(PostCode);
        // [GIVEN] Post Code record with Post Code = "1234", City = "XYZ" and "Country/Region Code" = "YY"
        CreatePostCode(PostCode, PostCode.Code);

        // [GIVEN] New Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Customer."Post Code" is being chanaged to "1234" and picked the post code with City = "XYZ"
        EnqueuePostCodeAndCity(PostCode.Code, PostCode.City);
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard."Post Code".SetValue(PostCode.Code);

        // [THEN] Customer."Country/Region Code" = "YY"
        CustomerCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('PostCodeModaPageHandler')]
    [Scope('OnPrem')]
    procedure CountryCodeOnLookupPostCode()
    var
        PostCode: Record "Post Code";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 303244] Country/Region code field is filled in when user lookup Post Code
        Initialize();

        // [GIVEN] Post Code record with Post Code = "1234", City = "ABC" and "Country/Region Code" = "XX"
        LibraryERM.CreatePostCode(PostCode);
        // [GIVEN] Post Code record with Post Code = "1234", City = "XYZ" and "Country/Region Code" = "YY"
        CreatePostCode(PostCode, PostCode.Code);

        // [GIVEN] New Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Lookup Customer."Post Code" and picked the post code with City = "XYZ"
        EnqueuePostCodeAndCity(PostCode.Code, PostCode.City);
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard."Post Code".Lookup();

        // [THEN] Customer."Country/Region Code" = "YY"
        CustomerCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountryCodeOnValidateCity()
    var
        PostCode: Record "Post Code";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 303244] Country/Region code field is filled in when user enter City
        Initialize();

        // [GIVEN] Post Code record with City = "1234" and "Country/Region Code" = "XX"
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] New Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Customer.City is being chanaged to "1234"
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard.City.SetValue(PostCode.City);

        // [THEN] Customer."Country/Region Code" = "XX"
        CustomerCard."Country/Region Code".AssertEquals(PostCode."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('PostCodeModaPageHandler')]
    [Scope('OnPrem')]
    procedure CountryCodeOnValidateCitySeveralRecords()
    var
        PostCode: array[2] of Record "Post Code";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 303244] Country/Region code field is filled in when user enter City and pick one of post codes records
        Initialize();

        // [GIVEN] Post Code record with Post Code = "1234", City = "ABC" and "Country/Region Code" = "XX"
        LibraryERM.CreatePostCode(PostCode[1]);
        // [GIVEN] Post Code record with Post Code = "5678", City = "ABC" and "Country/Region Code" = "YY"
        CreatePostCodeWithCity(PostCode[2], PostCode[1].City);

        // [GIVEN] New Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Customer.City is being chanaged to "ABC" and picked the post code with Post Code = "5678"
        EnqueuePostCodeAndCity(PostCode[2].Code, PostCode[2].City);
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard.City.SetValue(PostCode[2].City);

        // [THEN] Customer."Country/Region Code" = "YY"
        CustomerCard."Country/Region Code".AssertEquals(PostCode[2]."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('PostCodeModaPageHandler')]
    [Scope('OnPrem')]
    procedure CountryCodeOnLookupCity()
    var
        PostCode: array[2] of Record "Post Code";
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 303244] Country/Region code field is filled in when user lookup City
        Initialize();

        // [GIVEN] Post Code record with Post Code = "1234", City = "ABC" and "Country/Region Code" = "XX"
        LibraryERM.CreatePostCode(PostCode[1]);
        // [GIVEN] Post Code record with Post Code = "5678", City = "ABC" and "Country/Region Code" = "YY"
        CreatePostCodeWithCity(PostCode[2], PostCode[1].City);

        // [GIVEN] New Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Lookup Customer.City and pick the post code with City = "XYZ"
        EnqueuePostCodeAndCity(PostCode[2].Code, PostCode[2].City);
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard.City.Lookup();

        // [THEN] Customer."Country/Region Code" = "YY"
        CustomerCard."Country/Region Code".AssertEquals(PostCode[2]."Country/Region Code");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.City := LibraryUTUtility.GetNewCode();
        Customer."Post Code" := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("No."), DATABASE::Vendor);
        Vendor.City := LibraryUTUtility.GetNewCode();
        Vendor."Post Code" := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateCountryRegion(AddressFormat: Enum "Country/Region Address Format"): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), DATABASE::"Country/Region");
        CountryRegion."Address Format" := AddressFormat;
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code"; "Code": Code[20])
    var
        CountryRegion: Record "Country/Region";
    begin
        PostCode.Init();
        PostCode.Validate(Code, Code);
        PostCode.Validate(
          City,
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(City))));
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PostCode.Validate("Country/Region Code", CountryRegion.Code);
        PostCode.Insert(true);
    end;

    local procedure CreatePostCodeWithCity(var PostCode: Record "Post Code"; City: Text[30])
    var
        CountryRegion: Record "Country/Region";
    begin
        PostCode.Init();
        PostCode.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(Code), DATABASE::"Post Code"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(Code))));
        PostCode.Validate(City, City);
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        PostCode.Validate("Country/Region Code", CountryRegion.Code);
        PostCode.Insert(true);
    end;

    local procedure EnqueuePostCodeAndCity(PostCode: Code[20]; City: Text)
    begin
        LibraryVariableStorage.Enqueue(PostCode);
        LibraryVariableStorage.Enqueue(City);
    end;

    local procedure VerifyLineFormatCustomAddressFormat(CountryRegionCode: Code[10]; ExpectedLineFormat: Text)
    var
        CustomAddressFormat: Record "Custom Address Format";
    begin
        CustomAddressFormat.SetRange("Country/Region Code", CountryRegionCode);
        CustomAddressFormat.Find('+');
        CustomAddressFormat.Next(-1);
        CustomAddressFormat.TestField("Line Format", ExpectedLineFormat);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodeModaPageHandler(var PostCodes: TestPage "Post Codes")
    var
        PostCode: Code[20];
        City: Text;
    begin
        PostCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PostCode));
        City := LibraryVariableStorage.DequeueText();
        if PostCode <> '' then
            PostCodes.FILTER.SetFilter(Code, PostCode);
        if City <> '' then
            PostCodes.FILTER.SetFilter(City, City);
        PostCodes.OK().Invoke();
    end;
}
