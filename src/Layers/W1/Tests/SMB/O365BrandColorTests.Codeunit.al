codeunit 138931 "O365 Brand Color Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Brand Color]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestFindColorRGB()
    var
        O365BrandColor1: Record "O365 Brand Color";
        O365BrandColor2: Record "O365 Brand Color";
        ColorValue: Code[10];
    begin
        // Setup
        ColorValue := RandomColor();
        CreateO365BrandColor(O365BrandColor1, ColorValue);

        // Exercise
        O365BrandColor2.FindColor(O365BrandColor2, ColorValue);

        // Verify
        O365BrandColor2.TestField(Code, O365BrandColor1.Code);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestFindColorRGBA()
    var
        O365BrandColor1: Record "O365 Brand Color";
        O365BrandColor2: Record "O365 Brand Color";
        ColorValue: Code[10];
    begin
        // Setup
        ColorValue := RandomColor();
        CreateO365BrandColor(O365BrandColor1, ColorValue);

        // Exercise
        O365BrandColor2.FindColor(O365BrandColor2, '#FF' + CopyStr(ColorValue, 2, 6));

        // Verify
        O365BrandColor2.TestField(Code, O365BrandColor1.Code);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestCreateCustomColor()
    var
        O365BrandColor: Record "O365 Brand Color";
        ColorValue: Code[10];
    begin
        // Setup
        ColorValue := RandomColor();
        O365BrandColor.DeleteAll();

        // Exercise
        O365BrandColor.CreateOrUpdateCustomColor(O365BrandColor, ColorValue);

        // Verify
        O365BrandColor.Get('CUSTOM');
        O365BrandColor.TestField("Color Value", ColorValue);
        Assert.IsTrue(O365BrandColor."Sample Picture".HasValue, 'Sample picture did not get created.');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestUpdateCustomColor()
    var
        O365BrandColor: Record "O365 Brand Color";
        ColorValue: Code[10];
    begin
        // Setup
        O365BrandColor.CreateOrUpdateCustomColor(O365BrandColor, RandomColor());
        ColorValue := RandomColor();

        // Exercise
        O365BrandColor.CreateOrUpdateCustomColor(O365BrandColor, ColorValue);

        // Verify
        O365BrandColor.Get('CUSTOM');
        O365BrandColor.TestField("Color Value", ColorValue);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetKnownBrandColorRGB()
    var
        CompanyInformation: Record "Company Information";
        O365BrandColor: Record "O365 Brand Color";
    begin
        // Setup
        CreateO365BrandColor(O365BrandColor, RandomColor());

        // Exercise
        CompanyInformation.Get();
        CompanyInformation.Validate("Brand Color Value", O365BrandColor."Color Value");

        // Verify
        CompanyInformation.TestField("Brand Color Code", O365BrandColor.Code);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetKnownBrandColorRGBA()
    var
        CompanyInformation: Record "Company Information";
        O365BrandColor: Record "O365 Brand Color";
        ColorValue: Code[10];
    begin
        // Setup
        ColorValue := RandomColor();
        CreateO365BrandColor(O365BrandColor, ColorValue);
        ColorValue := '#FF' + CopyStr(ColorValue, 2, 6);

        // Exercise
        CompanyInformation.Get();
        CompanyInformation.Validate("Brand Color Value", ColorValue);

        // Verify
        CompanyInformation.TestField("Brand Color Code", O365BrandColor.Code);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetUnknownBrandColorRGB()
    var
        CompanyInformation: Record "Company Information";
        O365BrandColor: Record "O365 Brand Color";
        ColorValue: Code[10];
    begin
        // Setup
        O365BrandColor.DeleteAll();
        ColorValue := RandomColor();

        // Exercise
        CompanyInformation.Get();
        CompanyInformation.Validate("Brand Color Value", ColorValue);

        // Verify
        O365BrandColor.Get('CUSTOM');
        O365BrandColor.TestField("Color Value", ColorValue);
        Assert.IsTrue(O365BrandColor."Sample Picture".HasValue, 'Sample picture did not get created.');
        CompanyInformation.TestField("Brand Color Code", 'CUSTOM');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetUnknownBrandColorRGBA()
    var
        CompanyInformation: Record "Company Information";
        O365BrandColor: Record "O365 Brand Color";
        ColorValue: Code[10];
        ColorValueRGBA: Code[10];
    begin
        // Setup
        O365BrandColor.DeleteAll();
        ColorValue := RandomColor();
        ColorValueRGBA := '#FF' + CopyStr(ColorValue, 2, 6);

        // Exercise
        CompanyInformation.Get();
        CompanyInformation.Validate("Brand Color Value", ColorValueRGBA);

        // Verify
        O365BrandColor.Get('CUSTOM');
        O365BrandColor.TestField("Color Value", ColorValue);
        CompanyInformation.TestField("Brand Color Code", 'CUSTOM');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetUnknownBrandColorWithExistingCustomRecord()
    var
        CompanyInformation: Record "Company Information";
        O365BrandColor: Record "O365 Brand Color";
        ColorValue: Code[10];
    begin
        // Setup
        ColorValue := RandomColor();
        O365BrandColor.DeleteAll();
        O365BrandColor.CreateOrUpdateCustomColor(O365BrandColor, ColorValue);

        // Exercise
        CompanyInformation.Get();
        CompanyInformation.Validate("Brand Color Value", ColorValue);

        // Verify
        O365BrandColor.Get('CUSTOM');
        O365BrandColor.TestField("Color Value", ColorValue);
        CompanyInformation.TestField("Brand Color Code", 'CUSTOM');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestConvertARGBtoRGB_FullyOpaque()
    var
        O365BrandColor: Record "O365 Brand Color";
        ARGBColorValue: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217061] Fully opaque ARGB color convertation

        // [GIVEN] Fully opaque ARGB color #FF1B0EE8
        ARGBColorValue := '#FF1B0EE8';

        // [WHEN] Function O365BrandColor.FindColor is being run
        O365BrandColor.FindColor(O365BrandColor, ARGBColorValue);

        // [THEN] Color value converted to #1B0EE8
        O365BrandColor.TestField("Color Value", '#1B0EE8');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestConvertARGBtoRGB_PartlyOpaque()
    var
        O365BrandColor: Record "O365 Brand Color";
        ARGBColorValue: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217061] Partly opaque ARGB color convertation

        // [GIVEN] Fully opaque ARGB color #7DEF12A0
        ARGBColorValue := '#7DEF12A0';

        // [WHEN] Function O365BrandColor.FindColor is being run
        O365BrandColor.FindColor(O365BrandColor, ARGBColorValue);

        // [THEN] Color value converted to ##F78BD0
        O365BrandColor.TestField("Color Value", '#F78BD0');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestConvertARGBtoRGB_FullyTransparent()
    var
        O365BrandColor: Record "O365 Brand Color";
        ARGBColorValue: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 217061] Fully transparent ARGB color convertation

        // [GIVEN] Fully transparent ARGB color #00EF12A0
        ARGBColorValue := '#00EF12A0';

        // [WHEN] Function O365BrandColor.FindColor is being run
        O365BrandColor.FindColor(O365BrandColor, ARGBColorValue);

        // [THEN] Color value converted to pure white #FFFFFF
        O365BrandColor.TestField("Color Value", '#FFFFFF');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestFindBlankColorReturnsBlue()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222331] When validating a blank color value, default to blue.

        // [GIVEN] Default brand colors exist.
        O365BrandColor.DeleteAll();
        O365BrandColor.CreateDefaultBrandColors();

        // [WHEN] We try to find an empty color from the O365 Brand Color table.
        O365BrandColor.FindColor(O365BrandColor, '');

        // [THEN] Color value is defaulted to Blue.
        O365BrandColor.TestField(Code, 'BLUE');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestSetDefaultColorWhenBlank()
    var
        CompanyInformation: Record "Company Information";
        O365BrandColor: Record "O365 Brand Color";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222331] When validating a blank color value, default to blue.

        // [GIVEN] Default brand colors exist.
        O365BrandColor.DeleteAll();
        O365BrandColor.CreateDefaultBrandColors();

        // [WHEN] We try to find an empty color from the O365 Brand Color table.
        CompanyInformation.Get();
        CompanyInformation.Validate("Brand Color Value", '');

        // [THEN] Color value is defaulted to Blue.
        CompanyInformation.TestField("Brand Color Code", 'BLUE');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure CreatingDefaultColorsOnOpenBrandColorsPage()
    var
        O365BrandColor: Record "O365 Brand Color";
        O365BrandColors: TestPage "O365 Brand Colors";
    begin
        // [SCENARIO] Default colors created when page Brand Colors is being opened if O 365 Brand Color table is empty

        // [GIVEN] Empty O365 Brand Color table
        O365BrandColor.DeleteAll();

        // [WHEN] Page O365 Brand Colros is being opened
        O365BrandColors.OpenView();

        // [THEN] 12 colors have been created
        Assert.RecordCount(O365BrandColor, 12);
    end;

    local procedure CreateO365BrandColor(var O365BrandColor: Record "O365 Brand Color"; ColorValue: Code[10])
    begin
        O365BrandColor.DeleteAll();
        O365BrandColor.Init();
        O365BrandColor.Code := LibraryUtility.GenerateGUID();
        O365BrandColor."Color Value" := ColorValue;
        O365BrandColor.Insert();
    end;

    local procedure RandomColor() ColorValue: Code[10]
    var
        i: Integer;
    begin
        for i := 1 to 6 do begin
            ColorValue[i] := LibraryRandom.RandIntInRange(48, 63);
            if ColorValue[i] > 57 then
                ColorValue[i] := ColorValue[i] + 7;
        end;
        ColorValue := '#' + ColorValue;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

