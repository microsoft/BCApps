codeunit 144122 "PostCodesTable UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Post Code]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure PostCodeTableCreateNewPostcodeWithExistingCityAllowed()
    var
        PostCode: Record "Post Code";
        City: Text[30];
    begin
        City := 'ArbitraryCityName';
        PostCode.Init();

        CreateNewPostCode(PostCode, City);

        // Creating new post code with same city should be allowed
        CreateNewPostCode(PostCode, City);

        Assert.AreEqual(City, PostCode.City, 'Expected City to be unchanged after validation');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCodeTableRenamePostcodeWithExistingCityAllowed()
    var
        PostCode: Record "Post Code";
        City: Text[30];
    begin
        City := 'ArbitraryCityName';
        PostCode.Init();

        CreateNewPostCode(PostCode, City);

        CreateNewPostCode(PostCode, City);

        // Renaming should also be allowed with non-unique city
        PostCode.Rename(LibraryUTUtility.GetNewCode(), City);

        Assert.AreEqual(City, PostCode.City, 'Expected the City field to remain unchanged when renaming to an existing city name');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCodeTableModifyPostCodeToExistingCityAllowed()
    var
        PostCode: Record "Post Code";
        City: Text[30];
    begin
        City := 'ArbitraryCityName';
        PostCode.Init();

        CreateNewPostCode(PostCode, City);

        CreateNewPostCode(PostCode, 'OtherArbitraryCity');

        // Changing an existing post code record to a non-unique city should also be allowed
        PostCode.Get(PostCode.Code, 'OtherArbitraryCity');
        PostCode.Validate(City, City);

        Assert.AreEqual(City, PostCode.City, 'Expected the City field to remain unchanged when changing to an existing city name');
    end;

    local procedure CreateNewPostCode(var PostCode: Record "Post Code"; City: Text[30])
    begin
        Clear(PostCode);
        PostCode.Validate(Code, LibraryUTUtility.GetNewCode());
        PostCode.Validate(City, City);
        PostCode.Insert(true);
    end;
}

