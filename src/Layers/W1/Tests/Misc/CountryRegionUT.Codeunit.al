codeunit 134277 "Country/Region UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Country/Region]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        ASCIILetterErr: Label 'must contain ASCII letters only';
        NumericErr: Label 'must contain numbers only';

    [Test]
    [Scope('OnPrem')]
    procedure T100_ISOCodeIs2ASCIIChars()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Code" can be blank or must contain 2 ASCII letters
        asserterror CountryRegion.Validate("ISO Code", CopyStr('EUR', 1, 3));
        Assert.ExpectedError('is 3, but it must be less than or equal to 2 characters');

        asserterror CountryRegion.Validate("ISO Code", 'E');
        Assert.ExpectedError('is 1, but it must be equal to 2 characters');

        asserterror CountryRegion.Validate("ISO Code", 'E1');
        Assert.ExpectedError(ASCIILetterErr);

        CountryRegion.Validate("ISO Code", 'eU');
        CountryRegion.TestField("ISO Code", 'EU');

        CountryRegion.Validate("ISO Code", '');
        CountryRegion.TestField("ISO Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T110_ISONumericCodeIs3Numbers()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [FEATURE] [ISO Code]
        // [SCENARIO] Allowed "ISO Numeric Code" can be blank or must contain 2 ASCII letters
        asserterror CountryRegion.Validate("ISO Numeric Code", CopyStr('1234', 1, 4));
        Assert.ExpectedError('is 4, but it must be less than or equal to 3 characters');

        asserterror CountryRegion.Validate("ISO Numeric Code", '01');
        Assert.ExpectedError('is 2, but it must be equal to 3 characters');

        asserterror CountryRegion.Validate("ISO Numeric Code", 'EU1');
        Assert.ExpectedError(NumericErr);

        CountryRegion.Validate("ISO Numeric Code", '001');
        CountryRegion.TestField("ISO Numeric Code", '001');

        CountryRegion.Validate("ISO Numeric Code", '');
        CountryRegion.TestField("ISO Numeric Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure T120_ISOCodesEditableInCountryList()
    var
        CountryRegion: Record "Country/Region";
        CountriesRegions: TestPage "Countries/Regions";
    begin
        // [FEATURE] [ISO Code] [UI]
        // [SCENARIO] "ISO Code" and "ISO Numeric Code" are editable on the Countries\Regions page
        LibraryApplicationArea.EnableFoundationSetup();
        // [GIVEN] Country 'XX', where "ISO Code" is 'YY', "ISO Numeric Code" is '001'
        CountryRegion.Init();
        CountryRegion.Code := 'XX';
        CountryRegion."ISO Code" := 'YY';
        CountryRegion."ISO Numeric Code" := '001';
        CountryRegion.Insert();

        // [GIVEN] Open Country/Region list page, where both "ISO Code" and "ISO Numeric Code" are editable
        CountriesRegions.OpenEdit();
        CountriesRegions.FILTER.SetFilter(Code, 'XX');
        Assert.IsTrue(CountriesRegions."ISO Code".Editable(), 'ISO Code.EDITABLE');
        Assert.IsTrue(CountriesRegions."ISO Numeric Code".Editable(), 'ISO Numeric Code.EDITABLE');
        // [WHEN] set "ISO Code" is 'ZZ', "ISO Numeric Code" is '999' on the page
        CountriesRegions."ISO Code".SetValue('ZZ');
        CountriesRegions."ISO Numeric Code".SetValue('999');
        CountriesRegions.Close();

        // [THEN] Country 'XX', where "ISO Code" is 'ZZ', "ISO Numeric Code" is '999'
        CountryRegion.Find();
        CountryRegion.TestField("ISO Code", 'ZZ');
        CountryRegion.TestField("ISO Numeric Code", '999');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCountryNameTranslationTest()
    var
        CountryRegion: Record "Country/Region";
        CountryRegionTranslation: Record "Country/Region Translation";
        ActualTranslation: Text[50];
    begin
        // [FEATURE] [Country/Region Translation]
        // [SCENARIO] The procedure GetTranslatedName in Country/Region table returns the translation of the name in the given language

        // [GIVEN] One Country/Region with one specific translation
        CreateCountryRegion(CountryRegion);
        LibraryERM.CreateCountryRegionTranslation(CountryRegion.Code, CountryRegionTranslation);

        // [WHEN] Translation is calculated
        ActualTranslation := CountryRegion.GetTranslatedName(CountryRegionTranslation."Language Code");

        // [THEN] Verify Translation
        Assert.AreEqual(CountryRegionTranslation.Name, ActualTranslation, CountryRegionTranslation.FieldCaption(Name));
    end;



    [Test]
    [Scope('OnPrem')]
    procedure GetTranslatedNameWithNoTranslationSetupTest()
    var
        CountryRegion: Record "Country/Region";
        ActualTranslation: Text[50];
    begin
        // [FEATURE] [Country/Region Translation]
        // [SCENARIO] The procedure GetTranslatedName in Country/Region table returns name if no translation is setup

        // [GIVEN] One Country/Region with no translation
        CreateCountryRegion(CountryRegion);

        // [WHEN] GetTranslatedName is called for language with not translation
        ActualTranslation := CountryRegion.GetTranslatedName(LibraryERM.GetAnyLanguageDifferentFromCurrent());

        // [THEN] Verify that the name of the country/region is returned
        Assert.AreEqual(CountryRegion.Name, ActualTranslation, CountryRegion.FieldCaption(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TranslateCountryRegionNameTest()
    var
        CountryRegion: Record "Country/Region";
        CountryRegionTranslation: Record "Country/Region Translation";
    begin
        // [FEATURE] [Country/Region Translation]
        // [SCENARIO] The procedure TranslateName in Country/Region table updates the name with the translation in the given language

        // [GIVEN] One Country/Region with one specific translation
        CreateCountryRegion(CountryRegion);
        LibraryERM.CreateCountryRegionTranslation(CountryRegion.Code, CountryRegionTranslation);

        // [WHEN] Translation is calculated
        CountryRegion.TranslateName(CountryRegionTranslation."Language Code");

        // [THEN] The name of the Country/Region record is updated to the translation value
        Assert.AreEqual(CountryRegionTranslation.Name, CountryRegion.Name, CountryRegion.FieldCaption(Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatAddressWithCountryRegionTranslationTest()
    var
        CountryRegion: Record "Country/Region";
        CountryRegionTranslation: Record "Country/Region Translation";
        FormatAddress: Codeunit "Format Address";
        CountryLineNo: Integer;
        AddrArray: array[8] of Text[100];
        WrongValueInAddressArrayErr: Label 'Address Array at position %1', Comment = '%1 = Country/Region Position';
    begin
        // [FEATURE] [Country/Region Translation]
        // [SCENARIO] Test Country/Region Translation is used for address formatting in codeunit "Format Address"

        // [GIVEN] One Country/Region with one specific translation
        CreateCountryRegion(CountryRegion);
        LibraryERM.CreateCountryRegionTranslation(CountryRegion.Code, CountryRegionTranslation);

        // [WHEN] FormatAddress is initialized with one language where a country/region translation exists
        FormatAddress.SetLanguageCode(CountryRegionTranslation."Language Code");
        FormatAddress.FormatAddr(AddrArray, 'Name', 'Name2', 'Contact', 'Addr', 'Addr2', 'City', 'PostCode', 'County', CountryRegion.Code);

        // [THEN] Verify that the translation of the country/region name is used
        CountryLineNo := 8; // Country Name should be at position 8 of the array, since everything is filled
        Assert.AreEqual(CountryRegionTranslation.Name, AddrArray[CountryLineNo], StrSubstNo(WrongValueInAddressArrayErr, CountryLineNo));
    end;

    local procedure CreateCountryRegion(var CountryRegion: Record "Country/Region")
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate(Name, CopyStr(LibraryRandom.RandText(MaxStrLen(CountryRegion.Name)), 1, MaxStrLen(CountryRegion.Name)));
        CountryRegion.Modify(true);
    end;
}

