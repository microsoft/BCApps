codeunit 144040 "UT Address Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAddressFormatFromBlankLinePostCodeCityToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 298365] Custom address format lines created properly when Address Format changed from "Blank Line+Post Code+City" to "Custom"

        // [GIVEN] Country with Address Format = "Blank Line+Post Code+City"
        CreateCountryRegion(CountryRegion, CountryRegion."Address Format"::"Blank Line+Post Code+City");

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Last Custom Address Format line has "Line Format" = "[Post Code] [City]"
        VerifyLineFormatCustomAddressFormat(CountryRegion.Code, '[Post Code] [City] ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAddressFormatFromCityCountyNewLinePostCodeToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 298365] Custom address format lines created properly when Address Format changed from "City+County+New Line+Post Code" to "Custom"

        // [GIVEN] Country with Address Format = "City+County+New Line+Post Code"
        CreateCountryRegion(CountryRegion, CountryRegion."Address Format"::"City+County+New Line+Post Code");

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Last Custom Address Format line has "Line Format" = "[City] [County] [Post Code]"
        VerifyLineFormatCustomAddressFormat(CountryRegion.Code, '[City] [County] [Post Code] ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeAddressFormatFromPostCodeCityCountyToCustom()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 298365] Custom address format lines created properly when Address Format changed from "Post Code+City+County" to "Custom"

        // [GIVEN] Country with Address Format = "Post Code+City+County"
        CreateCountryRegion(CountryRegion, CountryRegion."Address Format"::"Post Code+City+County");

        // [WHEN] Address Format is being changed to Custom
        CountryRegion.Validate("Address Format", CountryRegion."Address Format"::Custom);

        // [THEN] Last Custom Address Format line has "Line Format" = "[Post Code] [City] [County]"
        VerifyLineFormatCustomAddressFormat(CountryRegion.Code, '[Post Code] [City] [County] ');
    end;

    local procedure CreateCountryRegion(var CountryRegion: Record "Country/Region"; AddressFormat: Enum "Country/Region Address Format")
    begin
        CountryRegion.Init();
        CountryRegion.Code := LibraryUtility.GenerateRandomCode(CountryRegion.FieldNo(Code), DATABASE::"Country/Region");
        CountryRegion."Address Format" := AddressFormat;
        CountryRegion.Insert();
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
}

