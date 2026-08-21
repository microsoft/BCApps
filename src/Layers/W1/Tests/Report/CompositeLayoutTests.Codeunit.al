// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 134619 "Composite Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report Layout] [Composite Layout]
    end;

    var
        Assert: Codeunit Assert;
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NoneTok: Label 'None', Locked = true;
        ThisLayoutSourceTok: Label 'This layout', Locked = true;
        ReportDefaultSourceTok: Label 'Report default', Locked = true;
        CompanySourceTok: Label 'Company', Locked = true;
        GlobalDefaultSourceTok: Label 'Global default', Locked = true;
        DocumentReportExperienceTok: Label 'DocumentReportExperience', Locked = true;
        InternalDefaultTok: Label 'Internal Default', Locked = true;
        SystemAppIdTok: Label '8874ed3a-0643-4247-9ced-7a7002f7135d', Locked = true;
        UnseedablePartTok: Label 'Test Unseedable Part', Locked = true;
        UnseedablePartDescTok: Label 'A part a test seeds from a layout file that is not in the app.', Locked = true;
        MissingResourceTok: Label 'ReportParts/HeaderFooterDesign/ThisResourceIsNotInTheApp.docx', Locked = true;
        ScenarioErrorTok: Label '%1', Comment = '%1 = the error the scenario failed with', Locked = true;
        TestReportID: Integer;
        DocReportExpWasEnabled: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NoConfigurationResolvesToNone()
    var
        HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource : Text;
    begin
        // [SCENARIO] With no Tenant Report Layout Cfg rows, both parts resolve to None with a blank source.
        Initialize();

        // [WHEN] Resolving the parts for a report layout with no configuration.
        LookupHelper.GetResolvedPartDisplays(TestReportID, 'Body', HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

        // [THEN] Both display None and carry no source.
        Assert.AreEqual(NoneTok, HeaderDisplay, 'Header should resolve to None.');
        Assert.AreEqual(NoneTok, ThemeDisplay, 'Theme should resolve to None.');
        Assert.AreEqual('', HeaderSource, 'Header source should be blank.');
        Assert.AreEqual('', ThemeSource, 'Theme source should be blank.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EncodeCompositeNameLowercasesGuid()
    var
        AppId: Guid;
        Composite: Text;
    begin
        // [SCENARIO] The composite reference uses the lowercase dashed GUID so it matches the value the platform stores.
        Evaluate(AppId, '{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}');

        // [WHEN] Encoding a part reference.
        Composite := LookupHelper.EncodeCompositeName(AppId, 'My Layout');

        // [THEN] The GUID is lowercased and separated from the name by '::'.
        Assert.AreEqual('a1b2c3d4-e5f6-7890-abcd-ef1234567890::My Layout', Composite, 'Composite should use the lowercase dashed GUID.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DecodeLayoutNameReturnsNameAfterSeparator()
    var
        AppId: Guid;
        LayoutName: Text;
    begin
        // [SCENARIO] Decoding an encoded reference returns the plain layout name (round-trip with the encoder).
        Evaluate(AppId, '{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}');

        // [WHEN] Decoding the encoded composite reference.
        LayoutName := LookupHelper.DecodeLayoutName(LookupHelper.EncodeCompositeName(AppId, 'My Layout'));

        // [THEN] The plain layout name is returned.
        Assert.AreEqual('My Layout', LayoutName, 'Decoded name should match the original.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DecodeLayoutNameWithoutSeparatorReturnsInput()
    var
        LayoutName: Text;
    begin
        // [SCENARIO] A value without a '::' separator is returned unchanged so legacy or hand-edited values still display.
        // [WHEN] Decoding a value that has no '::' separator.
        LayoutName := LookupHelper.DecodeLayoutName('Plain Layout Name');

        // [THEN] The input is returned unchanged.
        Assert.AreEqual('Plain Layout Name', LayoutName, 'Value without a separator should be returned unchanged.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LayoutLevelAssignmentResolvesAsThisLayout()
    var
        HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource : Text;
    begin
        // [SCENARIO] Parts assigned at the report+layout level resolve with source 'This layout'.
        Initialize();
        InsertCfg(TestReportID, 'Body', '', CreatePart('MyHF', Enum::"Report Layout Subtype"::HeaderFooter), CreatePart('MyTheme', Enum::"Report Layout Subtype"::Theme));

        // [WHEN] Resolving the parts for that layout.
        LookupHelper.GetResolvedPartDisplays(TestReportID, 'Body', HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

        // [THEN] The decoded part names and the 'This layout' source are returned.
        Assert.AreEqual('MyHF', HeaderDisplay, 'Header part name.');
        Assert.AreEqual(ThisLayoutSourceTok, HeaderSource, 'Header source.');
        Assert.AreEqual('MyTheme', ThemeDisplay, 'Theme part name.');
        Assert.AreEqual(ThisLayoutSourceTok, ThemeSource, 'Theme source.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportDefaultResolvesAsReportDefault()
    var
        HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource : Text;
    begin
        // [SCENARIO] A report-level default (empty layout, empty company) resolves with source 'Report default'.
        Initialize();
        InsertCfg(TestReportID, '', '', CreatePart('RepHF', Enum::"Report Layout Subtype"::HeaderFooter), CreatePart('RepTheme', Enum::"Report Layout Subtype"::Theme));

        // [WHEN] Resolving the parts for any layout of that report.
        LookupHelper.GetResolvedPartDisplays(TestReportID, 'Body', HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

        // [THEN] The report default applies.
        Assert.AreEqual('RepHF', HeaderDisplay, 'Header part name.');
        Assert.AreEqual(ReportDefaultSourceTok, HeaderSource, 'Header source.');
        Assert.AreEqual('RepTheme', ThemeDisplay, 'Theme part name.');
        Assert.AreEqual(ReportDefaultSourceTok, ThemeSource, 'Theme source.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyDefaultResolvesAsCompany()
    var
        HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource : Text;
    begin
        // [SCENARIO] A company default (report 0, empty layout, current company) resolves with source 'Company'.
        Initialize();
        InsertCfg(0, '', CopyStr(CompanyName(), 1, 30), CreatePart('CoHF', Enum::"Report Layout Subtype"::HeaderFooter), CreatePart('CoTheme', Enum::"Report Layout Subtype"::Theme));

        // [WHEN] Resolving the parts for a report with no more specific configuration.
        LookupHelper.GetResolvedPartDisplays(TestReportID, 'Body', HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

        // [THEN] The company default applies.
        Assert.AreEqual('CoHF', HeaderDisplay, 'Header part name.');
        Assert.AreEqual(CompanySourceTok, HeaderSource, 'Header source.');
        Assert.AreEqual('CoTheme', ThemeDisplay, 'Theme part name.');
        Assert.AreEqual(CompanySourceTok, ThemeSource, 'Theme source.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDefaultResolvesAsGlobalDefault()
    var
        HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource : Text;
    begin
        // [SCENARIO] A global default (report 0, empty layout, empty company) resolves with source 'Global default'.
        Initialize();
        InsertCfg(0, '', '', CreatePart('GlobHF', Enum::"Report Layout Subtype"::HeaderFooter), CreatePart('GlobTheme', Enum::"Report Layout Subtype"::Theme));

        // [WHEN] Resolving the parts for a report with no more specific configuration.
        LookupHelper.GetResolvedPartDisplays(TestReportID, 'Body', HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

        // [THEN] The global default applies.
        Assert.AreEqual('GlobHF', HeaderDisplay, 'Header part name.');
        Assert.AreEqual(GlobalDefaultSourceTok, HeaderSource, 'Header source.');
        Assert.AreEqual('GlobTheme', ThemeDisplay, 'Theme part name.');
        Assert.AreEqual(GlobalDefaultSourceTok, ThemeSource, 'Theme source.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HeaderAndThemeResolveIndependently()
    var
        HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource : Text;
    begin
        // [SCENARIO] The header and theme are resolved independently, so each can come from a different level.
        Initialize();
        // Header only at the layout level; theme only at the global level.
        InsertCfg(TestReportID, 'Body', '', CreatePart('LayoutHF', Enum::"Report Layout Subtype"::HeaderFooter), '');
        InsertCfg(0, '', '', '', CreatePart('GlobalTheme', Enum::"Report Layout Subtype"::Theme));

        // [WHEN] Resolving the parts.
        LookupHelper.GetResolvedPartDisplays(TestReportID, 'Body', HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

        // [THEN] The header resolves from the layout level and the theme from the global level.
        Assert.AreEqual('LayoutHF', HeaderDisplay, 'Header part name.');
        Assert.AreEqual(ThisLayoutSourceTok, HeaderSource, 'Header source.');
        Assert.AreEqual('GlobalTheme', ThemeDisplay, 'Theme part name.');
        Assert.AreEqual(GlobalDefaultSourceTok, ThemeSource, 'Theme source.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoreSpecificLevelWinsOverGlobal()
    var
        HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource : Text;
    begin
        // [SCENARIO] When a part is configured at both the layout level and globally, the layout level wins.
        Initialize();
        InsertCfg(0, '', '', CreatePart('GlobalHF', Enum::"Report Layout Subtype"::HeaderFooter), '');
        InsertCfg(TestReportID, 'Body', '', CreatePart('LayoutHF', Enum::"Report Layout Subtype"::HeaderFooter), '');

        // [WHEN] Resolving the parts.
        LookupHelper.GetResolvedPartDisplays(TestReportID, 'Body', HeaderDisplay, HeaderSource, ThemeDisplay, ThemeSource);

        // [THEN] The more specific (layout) configuration is used.
        Assert.AreEqual('LayoutHF', HeaderDisplay, 'The layout-level part should win over the global default.');
        Assert.AreEqual(ThisLayoutSourceTok, HeaderSource, 'Header source should be the layout level.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageShowsDecodedPartNamesNotComposite()
    var
        ScenarioError: Text;
    begin
        // [SCENARIO 645022] The Tenant Report Layout Configuration page displays the plain header/footer and theme part
        // names, not the raw <guid>::<name> composite reference stored in the Header/Theme Part Name columns.
        Initialize();

        EnableDocumentReportExperience();
        if not DecodedPartNamesScenario() then
            ScenarioError := GetLastErrorText();
        RestoreDocumentReportExperience();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure DecodedPartNamesScenario()
    var
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
        HeaderComposite: Text;
    begin
        // [GIVEN] A configuration row whose parts are stored as composite references (<guid>::<name>).
        HeaderComposite := CreatePart('PageHF', Enum::"Report Layout Subtype"::HeaderFooter);
        InsertCfg(TestReportID, 'Body', '', HeaderComposite, CreatePart('PageTheme', Enum::"Report Layout Subtype"::Theme));

        // [WHEN] Opening the page on that row.
        TenantReportLayoutCfgPage.OpenView();
        TenantReportLayoutCfgPage.Filter.SetFilter("Report ID", Format(TestReportID));
        Assert.IsTrue(TenantReportLayoutCfgPage.First(), 'The configured row should be shown on the page.');

        // [THEN] The columns show the decoded part names, not the stored composite value.
        Assert.AreEqual('PageHF', TenantReportLayoutCfgPage.HeaderPartDisplay.Value(), 'Header column should show the decoded part name.');
        Assert.AreEqual('PageTheme', TenantReportLayoutCfgPage.ThemePartDisplay.Value(), 'Theme column should show the decoded part name.');

        // [THEN] The stored value is still the composite reference, but the displayed value must not carry the '::' separator.
        Assert.IsTrue(StrPos(HeaderComposite, '::') > 0, 'The stored value should be a composite reference.');
        Assert.AreEqual(0, StrPos(TenantReportLayoutCfgPage.HeaderPartDisplay.Value(), '::'), 'The displayed value should not contain the composite separator.');

        TenantReportLayoutCfgPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartDescriptionShowsOnThemeHeaderFooterList()
    var
        ScenarioError: Text;
    begin
        // [SCENARIO 645022] Report themes and header-footer setup shows the part's description in the list.
        Initialize();

        EnableDocumentReportExperience();
        if not PartDescriptionScenario() then
            ScenarioError := GetLastErrorText();
        RestoreDocumentReportExperience();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure PartDescriptionScenario()
    var
        ReportThemePage: TestPage "Report Theme and Header/Footer";
        PartName: Text;
    begin
        // [GIVEN] A tenant part created with a description (CreatePart stores Description = name).
        PartName := 'HFWithDesc';
        CreatePart(PartName, Enum::"Report Layout Subtype"::HeaderFooter);

        // [WHEN] Opening the page on that part.
        ReportThemePage.OpenView();
        ReportThemePage.Filter.SetFilter(Name, PartName);
        Assert.IsTrue(ReportThemePage.First(), 'The created part should be shown on the page.');

        // [THEN] The Description column shows the part's description.
        Assert.AreEqual(PartName, ReportThemePage.Description.Value(), 'The Description column should show the part description.');

        ReportThemePage.Close();
    end;

    [Test]
    [HandlerFunctions('PartInfoMessageHandler')]
    [Scope('OnPrem')]
    procedure ShowInfoReportsPartDetailsAndUsage()
    var
        ScenarioError: Text;
    begin
        // [SCENARIO 645022] Show info reports the part details and how many report configurations use it.
        Initialize();

        EnableDocumentReportExperience();
        if not ShowInfoScenario() then
            ScenarioError := GetLastErrorText();
        RestoreDocumentReportExperience();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure ShowInfoScenario()
    var
        ReportThemePage: TestPage "Report Theme and Header/Footer";
        Composite: Text;
        ActualMessage: Text;
    begin
        // [GIVEN] A tenant theme part assigned in exactly one report configuration.
        Composite := CreatePart('ThemeInfo', Enum::"Report Layout Subtype"::Theme);
        InsertCfg(TestReportID, 'Body', '', '', Composite);

        // [WHEN] Invoking Show info on that part.
        ReportThemePage.OpenView();
        ReportThemePage.Filter.SetFilter(Name, 'ThemeInfo');
        Assert.IsTrue(ReportThemePage.First(), 'The created part should be shown on the page.');
        ReportThemePage.ShowInfo.Invoke();
        ReportThemePage.Close();

        // [THEN] Exactly one info message fired, naming the part, its type, and the used-in count.
        ActualMessage := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage('ThemeInfo', ActualMessage);
        Assert.ExpectedMessage('Theme', ActualMessage);
        Assert.ExpectedMessage('Used in 1 report configuration', ActualMessage);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeededPartsAreStoredUnderTheSystemAppId()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [SCENARIO] The shipped parts are stored under the platform's System application rather than under no app at
        // all. That App ID is part of the Tenant Report Layout key and of the composite reference an assignment stores,
        // and it is what attributes the parts to Microsoft instead of showing them as parts added on this tenant.
        Initialize();

        // [GIVEN] The shipped parts are seeded. No cleanup follows: this scenario only adds to the pool.
        CompositeReportPartsMgt.SeedDefaultParts();

        // [THEN] A shipped part is stored under the App ID the seeding names, and so can be fetched on that key.
        Assert.IsTrue(
            TenantReportLayout.Get(
                LookupHelper.GetTenantReportDefaultsReportID(),
                CopyStr(InternalDefaultTok, 1, MaxStrLen(TenantReportLayout.Name)),
                CompositeReportPartsMgt.GetShippedPartAppId()),
            'A shipped part should be stored under the App ID the seeding pass writes.');

        // [THEN] That App ID is the platform System application's, spelled out here so changing the constant is a
        // deliberate act - every assignment of a shipped part encodes it into its composite reference.
        Assert.AreEqual(
            SystemAppIdTok, LowerCase(Format(CompositeReportPartsMgt.GetShippedPartAppId(), 0, 4)),
            'The shipped parts should be stored under the platform System application App ID.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedingRemovesThePartCopySeededWithNoAppId()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        ScenarioError: Text;
    begin
        // [SCENARIO] An earlier version seeded the shipped parts with no App ID. The App ID is part of the key, so the
        // part written now does not replace that copy - the pass has to take it out, or the pool shows the part twice.
        Initialize();

        // In a try function so the pool is put back even when an assertion fails - see SeedDefaultPartsCreatesShippedParts.
        if not LegacyPartRemovalScenario() then
            ScenarioError := GetLastErrorText();
        CompositeReportPartsMgt.SeedDefaultParts();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure LegacyPartRemovalScenario()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        EmptyAppId: Guid;
        PartName: Text[250];
    begin
        // [GIVEN] One copy of a shipped part in the pool, moved onto the key the earlier seeding wrote: no App ID. Moved
        // rather than built, so the row carries the real layout file - the platform validates a layout's type and content.
        PartName := CopyStr(InternalDefaultTok, 1, MaxStrLen(TenantReportLayout.Name));
        RemoveShippedPart(PartName);
        CompositeReportPartsMgt.SeedDefaultParts();
        TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), PartName, CompositeReportPartsMgt.GetShippedPartAppId());
        TenantReportLayout.Rename(LookupHelper.GetTenantReportDefaultsReportID(), PartName, EmptyAppId);
        Assert.AreEqual(1, ShippedPartCount(PartName), 'The old copy should be the only one before the pass.');

        // [WHEN] Seeding runs again.
        CompositeReportPartsMgt.SeedDefaultParts();

        // [THEN] The part is in the pool exactly once, under the App ID the pass writes.
        Assert.AreEqual(1, ShippedPartCount(PartName), 'The pass should leave the part in the pool exactly once.');
        Assert.IsTrue(
            TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), PartName, CompositeReportPartsMgt.GetShippedPartAppId()),
            'The remaining part should be the one stored under the App ID the pass writes.');

        // [THEN] The copy that carried no App ID is gone.
        Assert.IsFalse(
            TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), PartName, EmptyAppId),
            'The copy seeded with no App ID should have been removed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedDefaultPartsCreatesShippedParts()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        ScenarioError: Text;
    begin
        // [SCENARIO] Seeding writes the shipped theme and header/footer parts into the shared pool.
        Initialize();

        // The scenario removes parts from the shared pool, so it runs in a try function: the reseed below has to happen
        // even when an assertion fails, or the pool stays incomplete for every test that runs afterwards.
        if not SeedShippedPartsScenario() then
            ScenarioError := GetLastErrorText();
        CompositeReportPartsMgt.SeedDefaultParts();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure SeedShippedPartsScenario()
    var
        ReportLayoutList: Record "Report Layout List";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [GIVEN] Neither part is in the pool. The suite shares a company and is not rolled back between methods, so an
        // earlier run leaves the shipped parts behind - without removing them first these assertions would pass on rows
        // this call never wrote.
        RemoveShippedPart('Internal Default');
        RemoveShippedPart('Default');
        Assert.IsFalse(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The header/footer part should be gone before seeding, or the test proves nothing.');
        Assert.IsFalse(
            ShippedPartExists('Default', Enum::"Report Layout Subtype"::Theme),
            'The theme part should be gone before seeding, or the test proves nothing.');

        // [WHEN] Seeding the shipped parts, as install and upgrade do.
        CompositeReportPartsMgt.SeedDefaultParts();

        // [THEN] A shipped header/footer part is in the pool under Tenant Report Defaults, with the header/footer subtype.
        Assert.IsTrue(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The shipped header/footer part should be in the shared pool after seeding.');

        // [THEN] So is a shipped theme part, with the theme subtype.
        Assert.IsTrue(
            ShippedPartExists('Default', Enum::"Report Layout Subtype"::Theme),
            'The shipped theme part should be in the shared pool after seeding.');

        // [THEN] Themes ship as .dotx templates, so the stored MIME type is the template one, not the document one.
        ReportLayoutList.SetRange("Report ID", LookupHelper.GetTenantReportDefaultsReportID());
        ReportLayoutList.SetRange(Name, 'Default');
        ReportLayoutList.FindFirst();
        Assert.AreEqual(
            'application/vnd.openxmlformats-officedocument.wordprocessingml.template', ReportLayoutList."MIME Type",
            'Themes ship as .dotx templates, so the stored MIME type should be the template one, not the document one.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedDefaultPartsIsIdempotentOnRerun()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        ScenarioError: Text;
    begin
        // [SCENARIO] Re-seeding replaces a part rather than adding a second copy, so repeated upgrades do not duplicate.
        Initialize();

        // In a try function so the reseed below runs even when an assertion fails - see SeedDefaultPartsCreatesShippedParts.
        if not SeedIdempotentScenario() then
            ScenarioError := GetLastErrorText();
        CompositeReportPartsMgt.SeedDefaultParts();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure SeedIdempotentScenario()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [GIVEN] The part is not in the pool, so the first pass below is the one that creates it. The suite shares a
        // company and is not rolled back between methods, so an earlier run would otherwise have seeded it already.
        RemoveShippedPart('Internal Default');
        Assert.AreEqual(0, ShippedPartCount('Internal Default'), 'The part should be gone before the first pass.');

        // [GIVEN] A first pass creates it.
        CompositeReportPartsMgt.SeedDefaultParts();
        Assert.AreEqual(1, ShippedPartCount('Internal Default'), 'The first pass should create the shipped part.');

        // [WHEN] Seeding again, as a later upgrade would.
        CompositeReportPartsMgt.SeedDefaultParts();

        // [THEN] The part is still there exactly once.
        Assert.AreEqual(
            1, ShippedPartCount('Internal Default'),
            'Re-seeding should replace the shipped part, not add another copy of it.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompositeReportPartsUpgradeTagIsRegisteredPerDatabase()
    var
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        PerDatabaseTags: List of [Code[250]];
    begin
        // [SCENARIO] The tag that guards the seeding upgrade is registered per database. Without registration the guard
        // never records as complete and the pass replays on every later upgrade.
        Initialize();

        // [WHEN] Collecting the registered per-database upgrade tags.
        UpgradeTag.GetPerDatabaseUpgradeTags(PerDatabaseTags);

        // [THEN] The composite report parts tag is among them.
        Assert.IsTrue(
            PerDatabaseTags.Contains(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'The composite report parts upgrade tag should be registered as a per-database tag.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompositeReportPartsUpgradeTagGatesRerun()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        ScenarioError: Text;
    begin
        // [SCENARIO] The upgrade seeds on its first run and records its tag; a second run exits on the guard instead of
        // re-seeding, which is what stops it re-writing parts over anything the tenant changed.
        Initialize();

        // In a try function so the part is put back even when an assertion fails: this scenario deliberately leaves the
        // pool short of a part behind the pass's back, and the rest of the suite expects a complete pool.
        if not TagGatesRerunScenario() then
            ScenarioError := GetLastErrorText();
        CompositeReportPartsMgt.SeedDefaultParts();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure TagGatesRerunScenario()
    var
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // [GIVEN] No tag, and one shipped part missing, so the first run has work to do and is not gated. The delete is
        // guarded because the library helper does a bare Get and throws when the tag is not there - which is the state on
        // a fresh database, and after anything else has cleared it.
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag(), '');
        RemoveShippedPart('Internal Default');
        Assert.IsFalse(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The part should be missing before the first upgrade, or the seeding assertion below proves nothing.');

        // [WHEN] The upgrade runs with the tag absent.
        UpgradeCompositeReportParts.RunUpgrade();

        // [THEN] It seeded the missing part, and recorded its database tag.
        Assert.IsTrue(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The first upgrade should seed the shipped parts.');
        Assert.IsTrue(
            UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'A completed seeding pass should record its database upgrade tag.');

        // [GIVEN] That part is removed again, behind the pass's back.
        RemoveShippedPart('Internal Default');

        // [WHEN] The upgrade runs a second time, now with the tag present.
        UpgradeCompositeReportParts.RunUpgrade();

        // [THEN] It exited on the guard, so the removed part was not written again.
        Assert.IsFalse(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The second upgrade should exit on the tag instead of re-seeding the parts.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedPartReportsFailureWhenTheResourceIsMissing()
    var
        ScenarioError: Text;
    begin
        // [SCENARIO] A part whose layout file cannot be read is reported as not seeded instead of throwing: the seeding
        // pass runs during install and upgrade, where an uncaught error would abort the whole operation. This false is
        // also the only thing that makes the pass report itself incomplete - SeedDefaultParts counts these results - and
        // an incomplete pass is what leaves the upgrade tag unset.
        Initialize();

        // In a try function so the part name this test owns is taken back out of the pool even when an assertion fails:
        // the assertions expect nothing to have been written, and if one of them is what fails, something was.
        if not MissingResourceScenario() then
            ScenarioError := GetLastErrorText();
        RemoveShippedPart(UnseedablePartTok);

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure MissingResourceScenario()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        PartName: Text[250];
        PartSeeded: Boolean;
    begin
        // [GIVEN] The part is not in the pool, so the count below cannot pass on a row from an earlier run.
        PartName := CopyStr(UnseedablePartTok, 1, MaxStrLen(PartName));
        RemoveShippedPart(PartName);
        Assert.AreEqual(0, ShippedPartCount(PartName), 'The part should not be in the pool before the call.');

        // [WHEN] Seeding a part whose layout file is not a resource of the app.
        PartSeeded := CompositeReportPartsMgt.SeedPart(PartName, MissingResourceTok, Enum::"Report Layout Subtype"::HeaderFooter, UnseedablePartDescTok);

        // [THEN] It reported the failure rather than raising it.
        Assert.IsFalse(PartSeeded, 'A part whose layout file cannot be read should be reported as not seeded.');

        // [THEN] Nothing was written for it, so a failure leaves no half-seeded part behind.
        Assert.AreEqual(0, ShippedPartCount(PartName), 'A part that could not be written should leave no row in the pool.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeLeavesTagUnsetAfterFailedSeedSoNextRunRetries()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        ScenarioError: Text;
    begin
        // [SCENARIO] A seeding pass that could not write every part must not record the upgrade tag. The tag is what stops
        // the pass from running again, so stamping it after a partial seed would leave the skipped parts missing for good.
        // Left unset, the next upgrade runs the pass again and seeds them.
        Initialize();

        // In a try function so the part is put back even when an assertion fails - the scenario deliberately leaves the
        // pool short of one until the retry seeds it, and an assertion failing before that would leave it short.
        if not FailedSeedRetryScenario() then
            ScenarioError := GetLastErrorText();
        CompositeReportPartsMgt.SeedDefaultParts();

        FailOnScenarioError(ScenarioError);
    end;

    [TryFunction]
    local procedure FailedSeedRetryScenario()
    var
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // [GIVEN] No tag, and one shipped part missing, so a retry has visible work to do. The delete is guarded because
        // the library helper does a bare Get and throws when the tag is not there.
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag(), '');
        RemoveShippedPart(InternalDefaultTok);
        Assert.IsFalse(
            ShippedPartExists(InternalDefaultTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'The part should be missing before the failed pass, or the retry assertion below proves nothing.');

        // [WHEN] A seeding pass reports that it could not write every part.
        UpgradeCompositeReportParts.RecordSeedOutcome(false);

        // [THEN] The tag was not recorded, so nothing gates a later attempt.
        Assert.IsFalse(
            UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'A pass that did not seed every part must not record its upgrade tag.');

        // [THEN] The failed pass wrote nothing on its own behalf either - the part is still missing.
        Assert.IsFalse(
            ShippedPartExists(InternalDefaultTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'Recording the outcome of a failed pass should not seed anything.');

        // [WHEN] The next upgrade runs.
        UpgradeCompositeReportParts.RunUpgrade();

        // [THEN] It was not gated: it retried the pass and seeded the part that was missing.
        Assert.IsTrue(
            ShippedPartExists(InternalDefaultTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'With the tag unset, the next upgrade should retry the seeding and write the missing part.');

        // [THEN] That pass wrote every part, so this time it recorded the tag.
        Assert.IsTrue(
            UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'A retry that seeded every part should record the upgrade tag.');
    end;

    [MessageHandler]
    procedure PartInfoMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    /// <summary>
    /// Re-raises the failure a scenario reported, after the cleanup that follows it has already run. Does nothing when
    /// the scenario passed.
    /// </summary>
    /// <remarks>
    /// This is the closing half of the pattern the mutating tests below use in place of a finally block, which AL does
    /// not have: the scenario runs in a try function, the cleanup runs unconditionally after it, and the failure is
    /// raised here. Every one of those tests writes state that is neither company-scoped nor rolled back between test
    /// methods - the shared part pool, the preview feature key - so a failed assertion that skipped the cleanup would
    /// leave that state contaminated for every test that runs after it, in the same session and in whatever order the
    /// runner picked.
    ///
    /// The message is passed as a placeholder rather than as the format string, so a percent sign in an assertion
    /// message is reported literally instead of being read as a placeholder of its own.
    /// </remarks>
    local procedure FailOnScenarioError(ScenarioError: Text)
    begin
        if ScenarioError = '' then
            exit;

        Error(ScenarioErrorTok, ScenarioError);
    end;

    /// <summary>
    /// Removes one shipped part from the shared pool so a seeding assertion proves the call under test wrote it. The
    /// suite runs in a non-isolated bucket against a shared company, so rows an earlier run seeded are still there.
    /// </summary>
    local procedure RemoveShippedPart(PartName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        // Filtered on Report ID + Name rather than fetched on the full key: the seeded parts are stored under the
        // platform System app's App ID and a part a test creates under none, and this has to take out whichever is there.
        TenantReportLayout.SetRange("Report ID", LookupHelper.GetTenantReportDefaultsReportID());
        TenantReportLayout.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(TenantReportLayout.Name)));
        TenantReportLayout.DeleteAll(true);
    end;

    local procedure ShippedPartExists(PartName: Text; Subtype: Enum "Report Layout Subtype"): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", LookupHelper.GetTenantReportDefaultsReportID());
        ReportLayoutList.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(ReportLayoutList.Name)));
        ReportLayoutList.SetRange("Layout Subtype", Subtype);
        exit(not ReportLayoutList.IsEmpty());
    end;

    local procedure ShippedPartCount(PartName: Text): Integer
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", LookupHelper.GetTenantReportDefaultsReportID());
        ReportLayoutList.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(ReportLayoutList.Name)));
        exit(ReportLayoutList.Count());
    end;

    local procedure Initialize()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        LibraryVariableStorage.Clear();
        TestReportID := 50000;

        // These tests run in a non-isolated (Legacy) bucket against a shared company, so rows are not rolled back
        // between test methods. Clear every configuration row this suite can create before each test. Without this,
        // the layout-level row left by LayoutLevelAssignmentResolvesAsThisLayout (report 50000, layout 'Body') leaks
        // into the report/company/global-default tests and wins resolution ahead of the row they set up, and the
        // report-0 wildcard rows leak out as global/company defaults that affect other tests sharing the company.
        TenantReportLayoutCfg.SetRange("Report ID", TestReportID);
        TenantReportLayoutCfg.DeleteAll(true);
        ClearWildcardCfg('');                                                                     // global default: report 0, all companies
        ClearWildcardCfg(CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutCfg."Company Name"))); // company default: report 0, this company
    end;

    local procedure ClearWildcardCfg(CompanyFilter: Text)
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        // Report 0 with an empty layout name is the wildcard key the company/global-default tests use; remove only
        // that exact key so the suite cleans up after itself without touching any unrelated configuration.
        if TenantReportLayoutCfg.Get(0, '', CopyStr(CompanyFilter, 1, MaxStrLen(TenantReportLayoutCfg."Company Name"))) then
            TenantReportLayoutCfg.Delete(true);
    end;

    local procedure EnableDocumentReportExperience()
    var
        FeatureKey: Record "Feature Key";
    begin
        // Page 9663 gates its OnOpenPage on the Document Report Experience preview; enable it so the page can be opened.
        // Capture the original state so RestoreDocumentReportExperience can put it back and not contaminate other tests.
        if FeatureKey.Get(DocumentReportExperienceTok) then begin
            DocReportExpWasEnabled := FeatureKey.Enabled = FeatureKey.Enabled::"All Users";
            FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
            FeatureKey.Modify();
        end;
    end;

    local procedure RestoreDocumentReportExperience()
    var
        FeatureKey: Record "Feature Key";
    begin
        // Restore the feature key to its pre-test state (the suite runs in a non-isolated bucket).
        if not FeatureKey.Get(DocumentReportExperienceTok) then
            exit;
        if DocReportExpWasEnabled then
            FeatureKey.Enabled := FeatureKey.Enabled::"All Users"
        else
            FeatureKey.Enabled := FeatureKey.Enabled::None;
        FeatureKey.Modify();
    end;

    local procedure CreatePart(PartName: Text; Subtype: Enum "Report Layout Subtype"): Text
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        ExcelSheetConfiguration: Enum "Excel Sheet Configuration";
        ReturnReportID: Integer;
        ReturnLayoutName: Text;
    begin
        // Remove only this specific part if a previous run left it behind, then create it fresh. The part name is unique
        // per test, so (Report ID, Name) identifies exactly this layout. CreateEmptyLayout generates a valid empty Word
        // document under Tenant Report Defaults (report 2000000001), so the part is a real layout that the Tenant Report
        // Layout Cfg validation accepts when it is referenced.
        TenantReportLayout.SetRange("Report ID", 2000000001);
        TenantReportLayout.SetRange("Name", CopyStr(PartName, 1, 250));
        if TenantReportLayout.FindFirst() then
            ReportLayoutsImpl.DeleteReportLayout(TenantReportLayout);

        ReportLayoutsImpl.InsertNewLayout(2000000001, CopyStr(PartName, 1, 250), CopyStr(PartName, 1, 250), ReportLayoutList."Layout Format"::Word, true, true, ExcelSheetConfiguration::Default, Subtype, ReturnReportID, ReturnLayoutName);

        ReportLayoutList.SetRange("Report ID", 2000000001);
        ReportLayoutList.SetRange("Name", CopyStr(PartName, 1, 250));
        ReportLayoutList.SetRange("Layout Subtype", Subtype);
        ReportLayoutList.FindFirst();
        exit(LookupHelper.EncodeCompositeName(ReportLayoutList."Application ID", ReportLayoutList.Name));
    end;

    local procedure InsertCfg(ReportID: Integer; LayoutName: Text; CompanyFilter: Text; HeaderComposite: Text; ThemeComposite: Text)
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        // Replace only this exact configuration key if it already exists, so the test owns the row without touching
        // any other tenant configuration.
        if TenantReportLayoutCfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), CopyStr(CompanyFilter, 1, MaxStrLen(TenantReportLayoutCfg."Company Name"))) then
            TenantReportLayoutCfg.Delete();

        TenantReportLayoutCfg.Init();
        TenantReportLayoutCfg."Report ID" := ReportID;
        TenantReportLayoutCfg."Layout Name" := CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name"));
        TenantReportLayoutCfg."Company Name" := CopyStr(CompanyFilter, 1, MaxStrLen(TenantReportLayoutCfg."Company Name"));
        TenantReportLayoutCfg."Header Part Name" := CopyStr(HeaderComposite, 1, MaxStrLen(TenantReportLayoutCfg."Header Part Name"));
        TenantReportLayoutCfg."Theme Part Name" := CopyStr(ThemeComposite, 1, MaxStrLen(TenantReportLayoutCfg."Theme Part Name"));
        TenantReportLayoutCfg.Insert(true);
    end;
}
