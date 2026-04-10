codeunit 138005 "O365 ExtendedTexts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Extended Text] [SMB]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        EntendedTableNameTextType: Option "Standard Text","G/L Account",Item,Resource;
        ExtendedLineTextTxt: Label 'Text';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure RenameWhenLanguageRecordIsUnique()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        Language: Record Language;
        Item: Record Item;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();

        CreateItem(Item);

        CreateLanguageSpecificExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::Item, Item."No.");
        NumberOfLines := LibraryRandom.RandIntInRange(1, 100);
        CreateExtendedTextLines(ExtendedTextHeader, NumberOfLines);

        Language.SetFilter(Code, '<>%1', ExtendedTextHeader."Language Code");
        Language.FindFirst();

        ExtendedTextHeader.Rename(
          ExtendedTextHeader."Table Name",
          ExtendedTextHeader."No.",
          Language.Code,
          ExtendedTextHeader."Text No.");

        Assert.AreEqual(1, ExtendedTextHeader."Text No.", 'Text No. was not updated correctly');

        VerifyLines(ExtendedTextHeader, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameWhenSameLanguageRecordExists()
    var
        AllLanguagesExtendedTextHeader: Record "Extended Text Header";
        SpecificLanguageExtendedTextHeader: Record "Extended Text Header";
        Item: Record Item;
        NumberOfLines: Integer;
    begin
        // Setup
        Initialize();

        CreateItem(Item);

        CreateAllLanguageCodesExtendedTextHeader(AllLanguagesExtendedTextHeader, EntendedTableNameTextType::Item, Item."No.");
        CreateLanguageSpecificExtendedTextHeader(SpecificLanguageExtendedTextHeader, EntendedTableNameTextType::Item, Item."No.");

        NumberOfLines := LibraryRandom.RandIntInRange(1, 100);
        CreateExtendedTextLines(AllLanguagesExtendedTextHeader, NumberOfLines);
        CreateExtendedTextLines(SpecificLanguageExtendedTextHeader, NumberOfLines);

        SpecificLanguageExtendedTextHeader.Rename(
          SpecificLanguageExtendedTextHeader."Table Name",
          SpecificLanguageExtendedTextHeader."No.",
          '',
          SpecificLanguageExtendedTextHeader."Text No.");

        Assert.AreEqual(
          AllLanguagesExtendedTextHeader."Text No." + 1, SpecificLanguageExtendedTextHeader."Text No.",
          'Text No. was not updated correctly');

        VerifyLines(AllLanguagesExtendedTextHeader, NumberOfLines);
        VerifyLines(SpecificLanguageExtendedTextHeader, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SettingLanguageCodeRemovesAllLanguageCodes()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        Item: Record Item;
        Language: Record Language;
    begin
        // Setup
        Initialize();

        CreateItem(Item);

        CreateAllLanguageCodesExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::Item, Item."No.");
        Language.FindFirst();
        ExtendedTextHeader.Validate("Language Code", Language.Code);
        Assert.AreEqual(false, ExtendedTextHeader."All Language Codes", 'All Language codes should be removed once language is set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SettingAllLanguageCodesRemovesLanguageCode()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        Item: Record Item;
    begin
        // Setup
        Initialize();

        CreateItem(Item);

        CreateLanguageSpecificExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::Item, Item."No.");

        ExtendedTextHeader.Validate("All Language Codes", true);
        Assert.AreEqual('', ExtendedTextHeader."Language Code", 'Language code was not deleted by setting All Language Codes');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAllLanguagesFalseLanguageCodeBlankSetup()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        Item: Record Item;
    begin
        // Some customers do not have language code set to Customer and Vendor
        // Thus their rules will have All Languages Codes = FALSE and Language Code = ''
        // This test case covers that this setup is still possible
        // Setup
        Initialize();

        CreateItem(Item);
        CreateAllLanguageCodesExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::Item, Item."No.");

        // Execute
        ExtendedTextHeader.Validate("All Language Codes", false);
        ExtendedTextHeader.Modify();

        // Verify
        ExtendedTextHeader.Get(
          ExtendedTextHeader."Table Name", ExtendedTextHeader."No.", ExtendedTextHeader."Language Code", ExtendedTextHeader."Text No.");
        Assert.AreEqual(false, ExtendedTextHeader."All Language Codes", 'Wrong value for All Language Codes');
        Assert.AreEqual('', ExtendedTextHeader."Language Code", 'Wrong value for Language Code');
    end;

    local procedure CreateLanguageSpecificExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; TableName: Option "Standard Text","G/L Account",Item,Resource; No: Code[20])
    var
        Language: Record Language;
    begin
        SetDefaultValuesToExtendedTextHeader(ExtendedTextHeader, TableName, No);
        Language.FindFirst();
        ExtendedTextHeader.Validate("Language Code", Language.Code);
        ExtendedTextHeader.Insert(true);
    end;

    local procedure CreateAllLanguageCodesExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; TableName: Option "Standard Text","G/L Account",Item,Resource; No: Code[20])
    begin
        SetDefaultValuesToExtendedTextHeader(ExtendedTextHeader, TableName, No);
        ExtendedTextHeader.Insert(true);
    end;

    local procedure SetDefaultValuesToExtendedTextHeader(var ExtendedTextHeader: Record "Extended Text Header"; TableName: Option "Standard Text","G/L Account",Item,Resource; No: Code[20])
    begin
        ExtendedTextHeader.Init();
        ExtendedTextHeader.Validate("Table Name", TableName);
        ExtendedTextHeader.Validate("No.", No);
    end;

    local procedure CreateExtendedTextLines(var ExtendedTextHeader: Record "Extended Text Header"; NumberOfLines: Integer)
    var
        ExtendedTextLine: Record "Extended Text Line";
        I: Integer;
    begin
        for I := 1 to NumberOfLines do begin
            LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
            ExtendedTextLine.Text := ExtendedLineTextTxt + Format(I);
            ExtendedTextLine.Modify();
        end;
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibrarySmallBusiness.CreateItem(Item);
    end;

    local procedure VerifyLines(var ExtendedTextHeader: Record "Extended Text Header"; NumberOfLines: Integer)
    var
        ExtendedTextLine: Record "Extended Text Line";
    begin
        ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
        ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
        ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
        ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");

        ExtendedTextLine.Find('-');
        Assert.AreEqual(NumberOfLines, ExtendedTextLine.Count, 'Wrong number of lines');

        repeat
            Assert.AreEqual(1, StrPos(ExtendedTextLine.Text, ExtendedLineTextTxt), 'Text value was lost');
        until ExtendedTextLine.Next() = 0;
    end;

    local procedure CalculateCaption(No: Code[20]; Description: Text[100]; LanguageCode: Code[20]; TxtNo: Integer): Text
    begin
        exit(
          Format(No) + ' ' +
          Description + ' ' +
          Format(LanguageCode) + ' ' +
          Format(TxtNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCaption()
    var
        ExtendedTextHeader: Record "Extended Text Header";
        Item: Record Item;
        Resource: Record Resource;
        GLAccount: Record "G/L Account";
        Language: Record Language;
    begin
        // Setup
        Initialize();

        CreateItem(Item);
        Language.FindFirst();
        CreateLanguageSpecificExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::Item, Item."No.");
        Assert.AreEqual(
          ExtendedTextHeader.GetCaption(),
          CalculateCaption(Item."No.", Item.Description, Language.Code, ExtendedTextHeader."Text No."),
          'Caption is broken');

        LibraryResource.CreateResourceNew(Resource);
        CreateLanguageSpecificExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::Resource, Resource."No.");
        Assert.AreEqual(
          ExtendedTextHeader.GetCaption(),
          CalculateCaption(Resource."No.", Resource.Name, Language.Code, ExtendedTextHeader."Text No."),
          'Caption is broken');

        LibraryERM.CreateGLAccount(GLAccount);
        CreateLanguageSpecificExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::"G/L Account", GLAccount."No.");
        Assert.AreEqual(
          ExtendedTextHeader.GetCaption(),
          CalculateCaption(GLAccount."No.", GLAccount.Name, Language.Code, ExtendedTextHeader."Text No."),
          'Caption is broken');

        // Blank std txt
        CreateLanguageSpecificExtendedTextHeader(ExtendedTextHeader, EntendedTableNameTextType::"Standard Text", '');
        Assert.AreEqual(
          ExtendedTextHeader.GetCaption(),
          CalculateCaption('', '', Language.Code, ExtendedTextHeader."Text No."),
          'Caption is broken');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 ExtendedTexts");
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 ExtendedTexts");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 ExtendedTexts");
    end;
}

