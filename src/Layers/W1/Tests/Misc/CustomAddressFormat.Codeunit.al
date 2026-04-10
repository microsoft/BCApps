codeunit 134448 "Custom Address Format"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Custom Address Format]
    end;

    var
        CompanyInformation: Record "Company Information";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        InvalidValueErr: Label 'Invalid array element %1 value.';
        LimitExceededErr: Label 'You cannot create more than three Custom Address Format Lines.';
        MultyCompositePartsErr: Label 'Only one composite custom address line format can be used.';
        CompositeFieldErr: Label 'Only the City, Post Code, and County fields can be used.';

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressFormatActionEnabled()
    var
        CountryRegion: Record "Country/Region";
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 279413] Action Custom Address Format is enabled for country with Address Format = Custom
        Initialize();

        // [GIVEN] Create country with custom address format
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [WHEN] Open Country/Regions page with created country
        CountriesRegions.OpenEdit();
        CountriesRegions.GotoRecord(CountryRegion);

        // [THEN] Action Custom Address Format is enabled
        Assert.IsTrue(CountriesRegions.CustomAddressFormat.Enabled(), 'Action must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressFormatActionDisabled()
    var
        CountryRegion: Record "Country/Region";
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 279413] Action Custom Address Format is disabled for country with Address Format <> Custom
        Initialize();

        // [GIVEN] Create country with default address format
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [WHEN] Open Country/Regions page with created country
        CountriesRegions.OpenEdit();
        CountriesRegions.GotoRecord(CountryRegion);

        // [THEN] Action Custom Address Format is enabled
        Assert.IsFalse(CountriesRegions.CustomAddressFormat.Enabled(), 'Action must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddressFormatValidateCityPostCodeToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] Custom Address Format initialized when user change Address Format to Custom
        Initialize();

        // [GIVEN] Create country with default Address Format = City+Post Code
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Custom Address Format initiated for City+Post Code
        VerifyInitAddressFormatFromCityPostCode(CountryRegion.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddressFormatValidateCityCountyPostCodeToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] Custom Address Format initialized when user chage Address Format from City+County+Post Code to Custom
        Initialize();

        // [GIVEN] Create country with Address Format = City+County+Post Code
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::"City+County+Post Code");
        CountryRegion.Modify();

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Custom Address Format initiated for City+County+Post Code
        VerifyInitAddressFormatFromCityCountyPostCode(CountryRegion.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddressFormatValidateCustomToCityPostCode()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] Custom Address Format records should be deleted when user change Address Format from Custom to another value
        Initialize();

        // [GIVEN] Create country with default Address Format = City+Post Code
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [GIVEN] Address Format changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::"City+Post Code");

        // [THEN] Custom Address Format records deleted
        CustomAddressFormat.SetRange("Country/Region Code", CountryRegion.Code);
        Assert.RecordIsEmpty(CustomAddressFormat);
    end;

    [Test]
    [HandlerFunctions('FieldsLookupModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomAddressFormatLookupFieldId()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormatPage: TestPage "Custom Address Format";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 279413] "Field Id" field of Custom Address Format page uses page 9806 for lookup
        Initialize();

        // [GIVEN] Create country with custom address format
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Open Custom Address Format page for created country
        CustomAddressFormatPage.OpenEdit();
        CustomAddressFormatPage.FILTER.SetFilter("Country/Region Code", CountryRegion.Code);

        // [WHEN] Lookup for Field Id and pick field 51 Contact Person
        LibraryVariableStorage.Enqueue(CompanyInformation.FieldNo("Contact Person"));
        CustomAddressFormatPage."Field ID".Lookup();

        // [THEN] Field Id is changed to 51
        CustomAddressFormatPage."Field ID".AssertEquals(CompanyInformation.FieldNo("Contact Person"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunSetupCustomAddressFormatWhenLineNoIsZero()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] When Line No. field of table Custom Address Format is 0 then user is not able to setup Custom Address Format lines
        Initialize();

        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Mock Custom Address Format line with Line No. = 0
        CustomAddressFormat."Country/Region Code" := CountryRegion.Code;
        CustomAddressFormat."Line No." := 0;

        // [WHEN] Function CustomAddressFormat.ShowCustomAddressFormatLines is being run
        asserterror CustomAddressFormat.ShowCustomAddressFormatLines();

        // [THEN] Error "Line No. must have a value..."
        Assert.ExpectedError('Line No. must have a value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitCustomAddressFormatFieldIDZero()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] When Field ID field of Custom Address Format record updated with 0 value then linked Custom Address Format Line records deleted
        Initialize();

        // [GIVEN] Create new country with Address Format = Custom
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Find defalut CustomAddressFormat wiht Field ID <> 0
        CustomAddressFormat.SetRange("Field ID", 0);
        CustomAddressFormat.FindFirst();
        CustomAddressFormat.Validate("Field ID", 2); // Name
        CustomAddressFormat.Modify();

        // [WHEN] Field ID is being updated to 0
        CustomAddressFormat.Validate("Field ID", 0);

        // [THEN] Related CustomAddressFormatLine records deleted
        CustomAddressFormatLine.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        Assert.RecordIsEmpty(CustomAddressFormatLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitCustomAddressFormatFieldIDNonZero()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] When Field ID field of Custom Address Format record updated with nonzero value then linked Custom Address Format Line records deleted and created new one
        Initialize();

        // [GIVEN] Create new country with Address Format = Custom
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Create new CustomAddressFormat line with Field ID = 0
        CustomAddressFormat."Country/Region Code" := CountryRegion.Code;
        CustomAddressFormat."Field ID" := 0;
        CustomAddressFormat.Insert(true);
        // [GIVEN] Create related CustomAddressFormatLine records with Address and Address 2 values
        CreateCustomFormatAddressLine(
          CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo(Address));
        CreateCustomFormatAddressLine(
          CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo("Address 2"));

        // [WHEN] Field ID is being updated to 2 (Name)
        CustomAddressFormat.Validate("Field ID", CompanyInformation.FieldNo(Name));

        // [THEN] Related old CustomAddressFormatLine records deleted
        CustomAddressFormatLine.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        Assert.AreEqual(1, CustomAddressFormatLine.Count, 'There must be 1 CustomAddressFormatLine record');

        // [THEN] Related new CustomAddressFormatLine record with Field ID = 2 created
        CustomAddressFormatLine.FindFirst();
        CustomAddressFormatLine.TestField("Field ID", CompanyInformation.FieldNo(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitFieldPositionForFirstCustomAddressFormatLine()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] When user creates first Custom Address Format Line it has Field Position = 1
        Initialize();

        // [GIVEN] Create new country with Address Format = Custom
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Create new CustomAddressFormat record with Field ID = 0
        CustomAddressFormat."Country/Region Code" := CountryRegion.Code;
        CustomAddressFormat."Field ID" := 0;
        CustomAddressFormat.Insert(true);

        // [WHEN] New CustomAddressFormatLine record is being inserted
        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, 0);

        // [THEN] CustomAddressFormatLine."Field Position" = 1;
        CustomAddressFormatLine.TestField("Field Position", CustomAddressFormatLine."Field Position"::"1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitFieldPositionForNextCustomAddressFormatLine()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] When user creates next Custom Address Format Line it has Field Position greater then previous one
        Initialize();

        // [GIVEN] Create new country with Address Format = Custom
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Create new CustomAddressFormat record with Field ID = 0
        CustomAddressFormat."Country/Region Code" := CountryRegion.Code;
        CustomAddressFormat."Field ID" := 0;
        CustomAddressFormat.Insert(true);

        // [GIVEN] Create new CustomAddressFormatLine record for field "City"
        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo(City));

        // [WHEN] Second CustomAddressFormatLine record is being inserted
        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo("Post Code"));

        // [THEN] CustomAddressFormatLine."Field Position" = 2;
        CustomAddressFormatLine.TestField("Field Position", CustomAddressFormatLine."Field Position"::"2");

        // [WHEN] Third CustomAddressFormatLine record is being inserted
        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo(County));

        // [THEN] CustomAddressFormatLine."Field Position" = 3;
        CustomAddressFormatLine.TestField("Field Position", CustomAddressFormatLine."Field Position"::"3");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCustomAddressFormatValues()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
        FormatAddress: Codeunit "Format Address";
        AddrArray: array[8] of Text[90];
        Name: Text[90];
        Name2: Text[90];
        Contact: Text[90];
        Addr: Text[50];
        Addr2: Text[50];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] Function FormatAddress.FormatAddr formats address accordingly custom address format setup
        Initialize();

        // [GIVEN] Create new country COUNTRY with Address Format = Custom
        // [Name]
        // [Name 2]
        // [Contact Person]
        // [Address]
        // [Address 2]
        // [City] [Post Code] [County]
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        CustomAddressFormat.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormat.SetRange("Field ID", 0);
        CustomAddressFormat.FindFirst();
        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo(County));

        // [WHEN] Function FormatAddress.FormatAddr is being run with parameters NAME, NAME2, ADDRESS, ADDRESS2, CONTACTPERSON, CITY, POSTCODE, COUNTY, COUNTRY
        Name := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation.Name)), 1, MaxStrLen(Name));
        Name2 := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation."Name 2")), 1, MaxStrLen(Name2));
        Addr := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation.Address)), 1, MaxStrLen(Addr));
        Addr2 := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation."Address 2")), 1, MaxStrLen(Addr2));
        Contact := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation."Contact Person")), 1, MaxStrLen(Contact));
        City := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation.City)), 1, MaxStrLen(City));
        PostCode := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation."Post Code")), 1, MaxStrLen(PostCode));
        County := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation.County)), 1, MaxStrLen(County));
        FormatAddress.FormatAddr(AddrArray, Name, Name2, Contact, Addr, Addr2, City, PostCode, County, CountryRegion.Code);

        // [THEN] AddrArray[1] = NAME
        VerifyAddrArrayElementValue(AddrArray, 1, Name);
        // [THEN] AddrArray[2] = NAME2
        VerifyAddrArrayElementValue(AddrArray, 2, Name2);
        // [THEN] AddrArray[3] = CONTACTPERSON
        VerifyAddrArrayElementValue(AddrArray, 3, Contact);
        // [THEN] AddrArray[4] = ADDRESS
        VerifyAddrArrayElementValue(AddrArray, 4, Addr);
        // [THEN] AddrArray[5] = ADDRESS2
        VerifyAddrArrayElementValue(AddrArray, 5, Addr2);
        // [THEN] AddrArray[6] = CITY POSTCODE COUNTY
        VerifyAddrArrayElementValue(AddrArray, 6, StrSubstNo('%1 %2 %3', City, PostCode, County));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressFormatLineSeparator()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
        FormatAddress: Codeunit "Format Address";
        AddrArray: array[8] of Text[90];
        City: Text[50];
        PostCode: Code[20];
        County: Text[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] Function FormatAddress.FormatAddr properly applies CustomAddressFormatLine.Separator
        Initialize();

        // [GIVEN] Create new country COUNTRY with Address Format = Custom
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Setup first CustomAddressFormat record with different separators as [City]-[Post Code]+[County]
        CustomAddressFormat.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormat.SetRange("Field ID", 0);
        CustomAddressFormat.FindFirst();
        CustomAddressFormatLine.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        CustomAddressFormatLine.DeleteAll();

        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo(City));
        CustomAddressFormatLine.Validate(Separator, '-');
        CustomAddressFormatLine.Modify();

        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo("Post Code"));
        CustomAddressFormatLine.Validate(Separator, '+');
        CustomAddressFormatLine.Modify();

        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo(County));

        // [WHEN] Function FormatAddress.FormatAddr is being run with parameters CITY, POSTCODE, COUNTY
        City := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation.City)), 1, MaxStrLen(City));
        PostCode := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation."Post Code")), 1, MaxStrLen(PostCode));
        County := CopyStr(LibraryRandom.RandText(MaxStrLen(CompanyInformation.County)), 1, MaxStrLen(County));
        FormatAddress.FormatAddr(AddrArray, '', '', '', '', '', City, PostCode, County, CountryRegion.Code);

        // [THEN] AddrArray[1] = CITY-POSTCODE+COUNTY
        VerifyAddrArrayElementValue(AddrArray, 1, StrSubstNo('%1-%2+%3', City, PostCode, County));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaxNoOfCustomAddressFormatLines()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 279417] User is not able to setup more than three fields per CustomAddressFormat records
        Initialize();

        // [GIVEN] Create new country COUNTRY with Address Format = Custom
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Setup three fields for last custom address format record as [City] [Post Code] [County]
        CustomAddressFormat.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormat.SetRange("Field ID", 0);
        CustomAddressFormat.FindFirst();
        CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, CompanyInformation.FieldNo(County));

        // [WHEN] Forth field is being added
        asserterror CreateCustomFormatAddressLine(CustomAddressFormat, CustomAddressFormatLine, 0);

        // [THEN] Error "You cannot create more than three..."
        Assert.ExpectedError(LimitExceededErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddressFormatValidateNonExistingValueToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 298365] Custom Address Format initialized without error when user change non-exising Address Format value to Custom
        Initialize();

        // [GIVEN] Create country with non-exiting Address Format value
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."Address Format" := "Country/Region Address Format".FromInteger(99);
        CountryRegion.Modify();

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Custom Address Format initiated for fields Name, Name 2, Address, Address 2, Contact Person
        VerifyCommonCustomAddressFormatPart(CountryRegion.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecondCompsiteCustomAddressFieldIsNotAllowed()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 431391] User is not able to create second custom composite address format
        Initialize();

        // [GIVEN] Create country with custom address format
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [WHEN] Try to change "Field Id" of Custom Address Format to 0 from nonzero value
        CustomAddressFormat.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormat.FindFirst();
        CustomAddressFormat.TestField("Field ID");
        asserterror CustomAddressFormat.Validate("Field ID", 0);

        // [THEN] Error "Only one composite custom address line format can be used."
        Assert.ExpectedError(MultyCompositePartsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomAddressFormatLineAllowedFields()
    var
        CountryRegion: Record "Country/Region";
        CustomAddressFormat: Record "Custom Address Format";
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 431391] User is able to use only City, Post Code and County fields for composite custom address format line
        Initialize();

        // [GIVEN] Create country with custom address format
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);
        CountryRegion.Modify();

        // [GIVEN] Find composite custom addres format line
        CustomAddressFormat.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormat.SetRange("Field ID", 0);
        CustomAddressFormat.FindFirst();

        CustomAddressFormatLine.SetRange("Country/Region Code", CountryRegion.Code);
        CustomAddressFormatLine.SetRange("Line No.", CustomAddressFormat."Line No.");
        // [GIVEN] No errors when "Field Id" changed manually to City, Post Code and County
        SetCustomAddressFormatLinesNewFieldId(CustomAddressFormatLine, CustomAddressFormat, CompanyInformation.FieldNo(City));
        SetCustomAddressFormatLinesNewFieldId(CustomAddressFormatLine, CustomAddressFormat, CompanyInformation.FieldNo(County));
        SetCustomAddressFormatLinesNewFieldId(CustomAddressFormatLine, CustomAddressFormat, CompanyInformation.FieldNo("Post Code"));

        // [WHEN] Try to change "Field Id" to Country/Region Code
        asserterror SetCustomAddressFormatLinesNewFieldId(CustomAddressFormatLine, CustomAddressFormat, CompanyInformation.FieldNo("Country/Region Code"));

        // [THEN] Error "Only City, Post Code and County can be used."
        Assert.ExpectedError(CompositeFieldErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure SetCustomAddressFormatLinesNewFieldId(var CustomAddressFormatLine: Record "Custom Address Format Line"; CustomAddressFormat: Record "Custom Address Format"; FieldId: Integer)
    var
        CustomAddressFormatLines: TestPage "Custom Address Format Lines";
    begin
        CustomAddressFormatLine.DeleteAll();
        CustomAddressFormatLines.OpenEdit();
        CustomAddressFormatLines.Filter.SetFilter("Country/Region Code", CustomAddressFormat."Country/Region Code");
        CustomAddressFormatLines.Filter.SetFilter("Line No.", Format(CustomAddressFormat."Line No."));
        CustomAddressFormatLines."Field ID".SetValue(FieldId);
    end;

    local procedure CreateCustomFormatAddressLine(CustomAddressFormat: Record "Custom Address Format"; var CustomAddressFormatLine: Record "Custom Address Format Line"; FieldID: Integer)
    begin
        CustomAddressFormatLine.Init();
        CustomAddressFormatLine."Country/Region Code" := CustomAddressFormat."Country/Region Code";
        CustomAddressFormatLine."Line No." := CustomAddressFormat."Line No.";
        CustomAddressFormatLine.Validate("Field ID", FieldID);
        CustomAddressFormatLine.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FieldsLookupModalPageHandler(var FieldsLookup: TestPage "Fields Lookup")
    var
        "Field": Record "Field";
    begin
        Field.Get(DATABASE::"Company Information", LibraryVariableStorage.DequeueInteger());
        FieldsLookup.GotoRecord(Field);
        FieldsLookup.OK().Invoke();
    end;

    local procedure VerifyInitAddressFormatFromCityPostCode(CountryCode: Code[10])
    begin
        VerifyCommonCustomAddressFormatPart(CountryCode);

        AssertCustomAddressFormatExist(CountryCode, 0);
        AssertCustomAddressFormatLineExist(CountryCode, CompanyInformation.FieldNo(City));
        AssertCustomAddressFormatLineExist(CountryCode, CompanyInformation.FieldNo("Post Code"));
    end;

    local procedure VerifyInitAddressFormatFromCityCountyPostCode(CountryCode: Code[10])
    begin
        VerifyCommonCustomAddressFormatPart(CountryCode);

        AssertCustomAddressFormatExist(CountryCode, 0);
        AssertCustomAddressFormatLineExist(CountryCode, CompanyInformation.FieldNo(City));
        AssertCustomAddressFormatLineExist(CountryCode, CompanyInformation.FieldNo(County));
        AssertCustomAddressFormatLineExist(CountryCode, CompanyInformation.FieldNo("Post Code"));
    end;

    local procedure VerifyCommonCustomAddressFormatPart(CountryCode: Code[10])
    begin
        AssertCustomAddressFormatExist(CountryCode, CompanyInformation.FieldNo(Name));
        AssertCustomAddressFormatExist(CountryCode, CompanyInformation.FieldNo("Name 2"));
        AssertCustomAddressFormatExist(CountryCode, CompanyInformation.FieldNo(Address));
        AssertCustomAddressFormatExist(CountryCode, CompanyInformation.FieldNo("Address 2"));
        AssertCustomAddressFormatExist(CountryCode, CompanyInformation.FieldNo("Contact Person"));
    end;

    local procedure VerifyAddrArrayElementValue(AddrArray: array[8] of Text[90]; index: Integer; ExpectedValue: Text[90])
    begin
        Assert.AreEqual(ExpectedValue, AddrArray[index], StrSubstNo(InvalidValueErr, index));
    end;

    local procedure AssertCustomAddressFormatExist(CountryCode: Code[10]; FieldId: Integer)
    var
        CustomAddressFormat: Record "Custom Address Format";
    begin
        CustomAddressFormat.SetRange("Country/Region Code", CountryCode);
        CustomAddressFormat.SetRange("Field ID", FieldId);
        Assert.RecordIsNotEmpty(CustomAddressFormat);
    end;

    local procedure AssertCustomAddressFormatLineExist(CountryCode: Code[10]; FieldId: Integer)
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        CustomAddressFormatLine.SetRange("Country/Region Code", CountryCode);
        CustomAddressFormatLine.SetRange("Field ID", FieldId);
        Assert.RecordIsNotEmpty(CustomAddressFormatLine);
    end;
}

