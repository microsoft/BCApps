codeunit 138695 "Resolving Caption Class"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryUtility: Codeunit "Library - Utility";


    [Test]
    procedure CaptionClassResolution()
    var
        Dimension: Record Dimension;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ResolvingCaptionClass: Codeunit "Resolving Caption Class";
        CaptionClassesTestPage: TestPage "Caption Classes Test Page";
        ShortCutDim3NameTranslation: Text[30];
        ShortCutDim3CodeCaptionTranslation: Text[30];
        ShortCutDim3FilterCaptionTranslation: Text[30];
    begin
        // [SCENARIO 409618] Unsupported caption classes return Resolved as false.
        GeneralLedgerSetup.Get();
        // [GIVEN] Add countries with county name and blank county
        AddCountryRegion('XX', 'CountyXX');
        AddCountryRegion('BLANK', '');
        // [GIVEN] Add Dimension with translation
        LibraryDimension.CreateDimension(Dimension);
        Dimension.Rename('DIM');
        AddDimTrans(Dimension.Code, GlobalLanguage, Dimension.Name, 'xCode', 'xFilter');

        // [GIVEN] Add a new translations for Shortcut Dimension 3
        ShortCutDim3CodeCaptionTranslation := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ShortCutDim3CodeCaptionTranslation)), 1, MaxStrLen(ShortCutDim3CodeCaptionTranslation));
        ShortCutDim3NameTranslation := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ShortCutDim3NameTranslation)), 1, MaxStrLen(ShortCutDim3NameTranslation));
        ShortCutDim3FilterCaptionTranslation := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ShortCutDim3FilterCaptionTranslation)), 1, MaxStrLen(ShortCutDim3FilterCaptionTranslation));
        Dimension.Get(GeneralLedgerSetup."Shortcut Dimension 3 Code");
        Dimension.SetMLCodeCaption(ShortCutDim3CodeCaptionTranslation, GlobalLanguage());
        Dimension.SetMLName(ShortCutDim3NameTranslation, GlobalLanguage());
        Dimension.SetMLFilterCaption(ShortCutDim3FilterCaptionTranslation, GlobalLanguage());

        // [WHEN] Open page with all kinds of caption classes
        BindSubscription(ResolvingCaptionClass);
        CaptionClassesTestPage.OpenView();

        // [THEN] Resolved is true for supported caption classes only
        Assert.AreEqual('Department Code', CaptionClassesTestPage.ResolvedGlobalDim.Caption(), 'ResolvedGlobalDim');
        Assert.AreEqual('1,1,3', CaptionClassesTestPage.UnresolvedGlobalDim.Caption(), 'UnresolvedGlobalDim');
        Assert.AreEqual(ShortCutDim3CodeCaptionTranslation, CaptionClassesTestPage.ResolvedShortcutDim.Caption(), 'ResolvedShortcutDim');
        Assert.AreEqual('1,2,9', CaptionClassesTestPage.UnresolvedShortcutDim.Caption(), 'UnresolvedShortcutDim');
        Assert.AreEqual('Project Filter', CaptionClassesTestPage.ResolvedFilterGlobalDim.Caption(), 'ResolvedFilterGlobalDim');
        Assert.AreEqual('1,3,3', CaptionClassesTestPage.UnresolvedFilterGlobalDim.Caption(), 'UnresolvedFilterGlobalDim');
        Assert.AreEqual(ShortCutDim3FilterCaptionTranslation, CaptionClassesTestPage.ResolvedFilterShortcutDim.Caption(), 'ResolvedFilterShortcutDim');
        Assert.AreEqual('1,4,9', CaptionClassesTestPage.UnresolvedFilterShortcutDim.Caption(), 'UnresolvedFilterShortcutDim');
        Assert.AreEqual('xCode', CaptionClassesTestPage.ResolvedCodeCaptionDim.Caption(), 'ResolvedCodeCaptionDim');
        Assert.AreEqual('DIM', CaptionClassesTestPage.ResolvedFilterCaptionDim.Caption(), 'ResolvedFilterCaptionDim');
        Assert.AreEqual(ShortCutDim3NameTranslation, CaptionClassesTestPage.ResolvedShortcutDimName.Caption(), 'ResolvedShortcutDimName');
        Assert.AreEqual('1,8', CaptionClassesTestPage.UnresolvedDim.Caption(), 'UnresolvedDim');
        Assert.AreEqual(StrSubstNo('Amount (%1)', GeneralLedgerSetup."LCY Code"), CaptionClassesTestPage.ResolvedCurrency.Caption(), 'ResolvedCurrency');
        Assert.AreEqual('101,4,Amount (%1)', CaptionClassesTestPage.UnresolvedCurrency.Caption(), 'UnresolvedCurrency');
        Assert.AreEqual('Amount Incl. VAT', CaptionClassesTestPage.ResolvedInclVAT.Caption(), 'ResolvedInclVAT');
        Assert.AreEqual('Amount Excl. VAT', CaptionClassesTestPage.ResolvedExclVAT.Caption(), 'ResolvedExclVAT');
        Assert.AreEqual('2,2,Amount', CaptionClassesTestPage.UnresolvedVAT.Caption(), 'UnresolvedVAT');
        Assert.AreEqual('1', CaptionClassesTestPage.UnresolvedCaptionArea.Caption(), 'UnresolvedCaptionArea');
        Assert.AreEqual('County', CaptionClassesTestPage.EmptyCountry.Caption(), 'EmptyCountry');
        Assert.AreEqual('County', CaptionClassesTestPage.EmptyCounty.Caption(), 'EmptyCounty');
        Assert.AreEqual('5,122,XX', CaptionClassesTestPage.UnresolvedCounty.Caption(), 'UnresolvedCounty');
        Assert.AreEqual('52', CaptionClassesTestPage.MissingCommaCounty.Caption(), 'MissingCommaCounty');
        Assert.AreEqual('CountyXX', CaptionClassesTestPage.ResolvedCounty.Caption(), 'ResolvedCounty');
        Assert.AreEqual('Package No.', CaptionClassesTestPage.ResolvedItemTracking.Caption(), 'ResolvedItemTracking');
        Assert.AreEqual('6,0', CaptionClassesTestPage.UnresolvedItemTracking.Caption(), 'UnresolvedItemTracking');
    end;

    local procedure AddCountryRegion(CountryRegionCode: Code[10]; CountyName: Text[30])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := CountryRegionCode;
        CountryRegion."County Name" := CountyName;
        CountryRegion.Insert();
    end;

    local procedure AddDimTrans(DimCode: Code[20]; LanguageID: Integer; Name: Text[30]; CodeCaption: Text[80]; FilterCaption: Text[80])
    var
        DimTrans: Record "Dimension Translation";
    begin
        DimTrans.Init();
        DimTrans.Code := DimCode;
        DimTrans."Language ID" := LanguageID;
        DimTrans.Name := Name;
        DimTrans."Code Caption" := CodeCaption;
        DimTrans."Filter Caption" := FilterCaption;
        DimTrans.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]
    local procedure ResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    begin
        case CaptionArea of
            '1':
                Assert.AreEqual(CaptionExpr in ['1,1', '2,3', '3,2', '4,3', '5,DIM', '6,,DIM', '7,3'], Resolved, CaptionExpr);
            '101':
                Assert.AreEqual(CaptionExpr = '1,Amount (%1)', Resolved, CaptionExpr);
            '2':
                Assert.AreEqual(CaptionExpr in ['1,Amount', '0,Amount'], Resolved, CaptionExpr);
            '3':
                Assert.IsFalse(Resolved, CaptionArea);
            '5':
                Assert.AreEqual(CaptionExpr in ['1,', '1,XX', '1,BLANK'], Resolved, CaptionExpr);
            '6':
                Assert.AreEqual(CaptionExpr = '1', Resolved, CaptionExpr);
        end;
    end;

}