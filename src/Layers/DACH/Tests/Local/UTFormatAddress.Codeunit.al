codeunit 142079 "UT Format Address"
{
    // Purpose of the test is to validate Method FormatPostCodeCity for Codeunit 365 - Format Address.
    // For DACH countries the County text should not be returned even if County is specified
    // For non-DACH countries it should be dependent on the Country & Address Format

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure FormatPostCodeCityCH()
    var
        CountryRegion: Record "Country/Region";
    begin
        // No County expected for CH addresses.
        CountryRegion.Get('CH');
        CountryRegion."Address Format" := CountryRegion."Address Format"::"Post Code+City";
        CountryRegion.Modify();
        VerifyFormatPostCodeCityCountyText(CountryRegion, GetRandomCounty(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatPostCodeCityAT()
    var
        CountryRegion: Record "Country/Region";
    begin
        // No County expected for AT addresses.
        CountryRegion.Get('AT');
        CountryRegion."Address Format" := CountryRegion."Address Format"::"Post Code+City";
        CountryRegion.Modify();
        VerifyFormatPostCodeCityCountyText(CountryRegion, GetRandomCounty(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatPostCodeCityDE()
    var
        CountryRegion: Record "Country/Region";
    begin
        // No County expected for DE addresses.
        CountryRegion.Get('DE');
        CountryRegion."Address Format" := CountryRegion."Address Format"::"Post Code+City";
        CountryRegion.Modify();
        VerifyFormatPostCodeCityCountyText(CountryRegion, GetRandomCounty(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatPostCodeCityNoCountry()
    var
        CountryRegion: Record "Country/Region";
        GLSetup: Record "General Ledger Setup";
    begin
        // No County expected for address if Country not specified
        GLSetup.FindFirst();
        GLSetup."Local Address Format" := GLSetup."Local Address Format"::"Post Code+City";
        GLSetup.Modify();
        CountryRegion.Init();
        VerifyFormatPostCodeCityCountyText(CountryRegion, GetRandomCounty(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatPostCodeCityES()
    var
        CountryRegion: Record "Country/Region";
        County: Text[50];
    begin
        // County expected for ES addresses.
        CountryRegion.Get('ES');
        CountryRegion."Address Format" := CountryRegion."Address Format"::"Post Code+City";
        CountryRegion.Modify();
        County := GetRandomCounty();
        VerifyFormatPostCodeCityCountyText(CountryRegion, County, County);
    end;

    local procedure VerifyFormatPostCodeCityCountyText(CountryRegion: Record "Country/Region"; County: Text[50]; ExpectedCountyText: Text[50])
    var
        FormatAddress: Codeunit "Format Address";
        City: Text[50];
        PostCode: Code[20];
        ActualCountyText: Text[50];
        PostCodeCityText: Text[90];
    begin
        // Setup.
        City := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
        PostCode := CopyStr(LibraryUtility.GenerateRandomText(20), 1, 20);

        // Exercise
        FormatAddress.FormatPostCodeCity(PostCodeCityText, ActualCountyText, City, PostCode, County, CountryRegion.Code);

        // Verify.
        Assert.AreEqual(ExpectedCountyText, ActualCountyText, 'Unexpected County Text');
    end;

    local procedure GetRandomCounty() County: Text[50]
    begin
        County := CopyStr(LibraryUtility.GenerateRandomText(50), 1, 50);
    end;
}

