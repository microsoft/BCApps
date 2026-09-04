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
        BaseAppIdTok: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        UnseedablePartTok: Label 'Test Unseedable Part', Locked = true;
        UnseedablePartDescTok: Label 'A part a test seeds from a layout file that is not in the app.', Locked = true;
        MissingResourceTok: Label 'ReportParts/HeaderFooterDesign/ThisResourceIsNotInTheApp.docx', Locked = true;
        RetiredPartTok: Label 'Test Retired Part', Locked = true;
        RetiredPartDescTok: Label 'A part a test seeds under a name this version of the app does not ship.', Locked = true;
        ShippedThemeResourceTok: Label 'ReportParts/ReportTheme/Default.dotx', Locked = true;
        ThemeMimeTypeTok: Label 'reportlayout/dotx', Locked = true;
        TestReportID: Integer;
        BodyReportID: Integer;
        PartsReportID: Integer;
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
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
        HeaderComposite: Text;
    begin
        // [SCENARIO 645022] The Tenant Report Layout Configuration page displays the plain header/footer and theme part
        // names, not the raw <guid>::<name> composite reference stored in the Header/Theme Part Name columns.
        Initialize();
        EnableDocumentReportExperience();

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
        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartDescriptionShowsOnThemeHeaderFooterList()
    var
        ReportThemePage: TestPage "Report Theme and Header/Footer";
        PartName: Text;
    begin
        // [SCENARIO 645022] Report themes and header-footer setup shows the part's description in the list.
        Initialize();
        EnableDocumentReportExperience();

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
        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('PartInfoMessageHandler')]
    [Scope('OnPrem')]
    procedure ShowInfoReportsPartDetailsAndUsage()
    var
        ReportThemePage: TestPage "Report Theme and Header/Footer";
        Composite: Text;
        ActualMessage: Text;
    begin
        // [SCENARIO 645022] Show info reports the part details and how many report configurations use it.
        Initialize();
        EnableDocumentReportExperience();

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

        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeededPartsAreStoredUnderThisAppId()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [SCENARIO] The shipped parts are stored under the App ID of the app that ships them rather than under no app
        // at all. That App ID is part of the Tenant Report Layout key and of the composite reference an assignment
        // stores, and it is what attributes the parts to Microsoft instead of showing them as parts added on this tenant.
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

        // [THEN] That App ID is this app's own, spelled out here so changing it is a deliberate act - every assignment
        // of a shipped part encodes it into its composite reference.
        Assert.AreEqual(
            BaseAppIdTok, LowerCase(Format(CompositeReportPartsMgt.GetShippedPartAppId(), 0, 4)),
            'The shipped parts should be stored under the App ID of the app that ships them.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedingKeepsATenantPartNamedAfterAShippedPart()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        EmptyAppId: Guid;
        PartName: Text[250];
    begin
        // [SCENARIO] A part the tenant authored carries no App ID, and nothing stops it being named after a shipped part.
        // The seeding pass must leave it alone: it writes under its own App ID, so a row on the no-App-ID key is not a
        // stale copy of a shipped part to clean up - it is customer content, and deleting it would be silent data loss.
        Initialize();

        // [GIVEN] A part on the no-App-ID key carrying the name of a shipped part. Moved rather than built, so the row
        // carries a real layout file - the platform validates a layout's type and content.
        PartName := CopyStr(InternalDefaultTok, 1, MaxStrLen(TenantReportLayout.Name));
        RemoveShippedPart(PartName);
        CompositeReportPartsMgt.SeedDefaultParts();
        TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), PartName, CompositeReportPartsMgt.GetShippedPartAppId());
        TenantReportLayout.Rename(LookupHelper.GetTenantReportDefaultsReportID(), PartName, EmptyAppId);

        // [WHEN] Seeding runs again.
        CompositeReportPartsMgt.SeedDefaultParts();

        // [THEN] The tenant's row is still there, untouched.
        Assert.IsTrue(
            TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), PartName, EmptyAppId),
            'A part on the no-App-ID key belongs to the tenant and must survive the seeding pass.');

        // [THEN] The shipped part was written alongside it, under the App ID the pass owns.
        Assert.IsTrue(
            TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), PartName, CompositeReportPartsMgt.GetShippedPartAppId()),
            'The shipped part should be written under the App ID the pass owns.');

        // [THEN] The pass owns exactly one row, so the two are kept apart by App ID rather than one overwriting the other.
        Assert.AreEqual(1, ShippedPartCount(PartName), 'The pass should own exactly one row under its own App ID.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedDefaultPartsCreatesShippedParts()
    var
        ReportLayoutList: Record "Report Layout List";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [SCENARIO] Seeding writes the shipped theme and header/footer parts into the shared pool.
        Initialize();

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
            ThemeMimeTypeTok, ReportLayoutList."MIME Type",
            'Themes ship as .dotx templates, so the stored MIME type should carry the dotx extension, not docx.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedDefaultPartsIsIdempotentOnRerun()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [SCENARIO] Re-seeding replaces a part rather than adding a second copy, so repeated upgrades do not duplicate.
        Initialize();

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
    procedure SeedingShippedPartsRecordsTheTagAndExitsOnRerun()
    var
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        // [SCENARIO] SeedShippedParts is the entry point the per-database install uses: it seeds and records the tag,
        // and a rerun exits on the tag guard so install cannot insert the tag twice when the company-open
        // subscriber already seeded in the same install.
        Initialize();

        // [GIVEN] One shipped part missing. Initialize already cleared the tag.
        RemoveShippedPart(InternalDefaultTok);
        Assert.IsFalse(
            ShippedPartExists(InternalDefaultTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'The part should be missing before install, or the seeding assertion below proves nothing.');
        Assert.IsFalse(
            UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'The tag should be absent before install, or the tag assertion below proves nothing.');

        // [WHEN] The entry point the install trigger calls runs.
        UpgradeCompositeReportParts.SeedShippedParts();

        // [THEN] It seeded the missing part.
        Assert.IsTrue(
            ShippedPartExists(InternalDefaultTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'Seeding should write the shipped parts.');

        // [THEN] And recorded the tag, so a later upgrade exits on the guard instead of seeding again.
        Assert.IsTrue(
            UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'Seeding should record the composite report parts upgrade tag.');

        // [GIVEN] The part is removed again while the tag stays in place.
        RemoveShippedPart(InternalDefaultTok);

        // [WHEN] The install entry point runs a second time, as it does when the company-open subscriber
        // already seeded earlier in the same install.
        UpgradeCompositeReportParts.SeedShippedParts();

        // [THEN] The tag guard exits before seeding, so the removed part stays absent and no second tag insert happens.
        Assert.IsFalse(
            ShippedPartExists(InternalDefaultTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'A rerun of SeedShippedParts should exit on the tag guard instead of seeding again.');

        // Cleared again so the suite does not hand the tag on to whatever runs next in this database.
        ClearCompositeReportPartsUpgradeTag();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedingRemovesAPartThisVersionNoLongerShips()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        RetiredPartName: Text[250];
    begin
        // [SCENARIO] Dropping a part from the shipped list - by deleting its layout file or its SeedPart call - has to
        // take the part out of the shared pool too. Seeding only writes the names it still ships, so without a pass that
        // removes the rest a retired part would stay in the pool for good.
        Initialize();

        // [GIVEN] A part in the pool under the shipped App ID, carrying a name this version does not ship.
        RetiredPartName := CopyStr(RetiredPartTok, 1, MaxStrLen(RetiredPartName));
        CompositeReportPartsMgt.SeedPart(RetiredPartName, ShippedThemeResourceTok, Enum::"Report Layout Subtype"::Theme, RetiredPartDescTok);
        Assert.AreEqual(1, ShippedPartCount(RetiredPartName), 'The retired part should be in the pool before the pass.');

        // [WHEN] Seeding runs, as install and upgrade do.
        CompositeReportPartsMgt.SeedDefaultParts();

        // [THEN] It is gone, because its name is not one this version ships.
        Assert.AreEqual(
            0, ShippedPartCount(RetiredPartName),
            'A part this version no longer ships should be removed from the shared pool.');

        // [THEN] A part the version does ship is untouched, so the pass removes the retired names and nothing more.
        Assert.IsTrue(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'Pruning must not take out a part the version still ships.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PruningARetiredPartClearsItsAssignments()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        RetiredPartLayout: Record "Report Layout List";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        RetiredPartName: Text[250];
        BodyKey: Text;
    begin
        // [SCENARIO] A configuration row that assigned a retired part must not be left pointing at it: the reference is
        // cleared as the part goes, the same way deleting a part from the page clears its assignments.
        Initialize();

        // [GIVEN] A body layout the configuration row can legally name. The platform validates that Layout Name
        // resolves to a Body-subtype layout, so a plain name on a report that does not exist is rejected on insert.
        BodyKey := CreateLayoutOnReport(BodyReportID, 'PruneBody', Enum::"Report Layout Subtype"::Body);

        // [GIVEN] A retired part assigned as the theme of a report configuration row.
        RetiredPartName := CopyStr(RetiredPartTok, 1, MaxStrLen(RetiredPartName));
        CompositeReportPartsMgt.SeedPart(RetiredPartName, ShippedThemeResourceTok, Enum::"Report Layout Subtype"::Theme, RetiredPartDescTok);
        FindLayout(LookupHelper.GetTenantReportDefaultsReportID(), RetiredPartName, RetiredPartLayout);
        InsertCfg(BodyReportID, BodyKey, '', '', LookupHelper.EncodeCompositeName(RetiredPartLayout."Application ID", RetiredPartLayout.Name));

        // [WHEN] Seeding runs and prunes the retired part.
        CompositeReportPartsMgt.SeedDefaultParts();

        // [THEN] The configuration row survives with the reference cleared, rather than pointing at a part that is gone.
        Assert.IsTrue(
            TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), ''),
            'The configuration row should survive the pruning.');
        Assert.AreEqual('', TenantReportLayoutCfg."Theme Part Name", 'Pruning the part should clear the assignment that referenced it.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompositeReportPartsUpgradeTagIsRegisteredPerDatabase()
    var
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
        PerDatabaseTags: List of [Code[250]];
    begin
        // [SCENARIO] The tag that gates the seeding pass is registered for OnGetPerDatabaseUpgradeTags, so a new
        // tenant gets it stamped at deployment (SetAllUpgradeTags at company initialization) instead of waiting for
        // the first upgrade or company open. The data itself ships with the deployment: OnInstallAppPerDatabase seeds
        // the parts and raises on failure, so the tag cannot be stamped for a database the install left unseeded.
        Initialize();

        // [WHEN] Collecting the registered per-database upgrade tags.
        UpgradeTag.GetPerDatabaseUpgradeTags(PerDatabaseTags);

        // [THEN] The composite report parts tag is among them.
        Assert.IsTrue(
            PerDatabaseTags.Contains(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'The composite report parts tag should be registered per database so new tenants get it at deployment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompositeReportPartsUpgradeTagGatesRerun()
    var
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        // [SCENARIO] The upgrade seeds on its first run and records its tag; a second run exits on the guard at entry
        // instead of re-seeding. Shipping changed layout files takes a new dated tag, not an ungated pass.
        Initialize();

        // [GIVEN] One shipped part missing, so the first run has work to do. Initialize already cleared the tag, so the
        // pass is not gated.
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

        // Cleared again so the suite does not hand the tag on to whatever runs next in this database.
        ClearCompositeReportPartsUpgradeTag();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedPartRaisesWhenTheResourceIsMissing()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        PartName: Text[250];
    begin
        // [SCENARIO] Every shipped part is a resource of this app, so a layout file that cannot be read is a build
        // defect, not a tenant condition. The pass raises rather than skipping the part, so the failure is loud instead
        // of leaving a tenant silently short of a theme.
        Initialize();

        // [GIVEN] The part is not in the pool, so the count below cannot pass on a row from an earlier run.
        PartName := CopyStr(UnseedablePartTok, 1, MaxStrLen(PartName));
        RemoveShippedPart(PartName);
        Assert.AreEqual(0, ShippedPartCount(PartName), 'The part should not be in the pool before the call.');

        // [WHEN] Seeding a part whose layout file is not a resource of the app.
        asserterror CompositeReportPartsMgt.SeedPart(PartName, MissingResourceTok, Enum::"Report Layout Subtype"::HeaderFooter, UnseedablePartDescTok);

        // [THEN] It raised rather than skipping the part.

        // [THEN] Nothing was written for it, so the failure leaves no half-seeded part behind.
        Assert.AreEqual(0, ShippedPartCount(PartName), 'A part that could not be read should leave no row in the pool.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompositeLayoutKeyUsesTheOwningApplicationId()
    var
        TenantLayout: Record "Report Layout List";
        AppOwnedLayout: Record "Report Layout List";
        EmptyGuid: Guid;
    begin
        // [SCENARIO] The configuration key is built from the Application ID of the layout it refers to, so an
        // app-owned layout is not keyed as if it were tenant-defined. Keying it with the empty GUID is what makes
        // the platform reject the configuration row as not referencing a Body-subtype layout.
        Initialize();

        // [GIVEN] A tenant-defined layout and a layout shipped by an extension.
        CreatePart('KeyTenantPart', Enum::"Report Layout Subtype"::HeaderFooter);
        FindLayout(PartsReportID, 'KeyTenantPart', TenantLayout);
        Assert.IsTrue(FindAppOwnedWordLayout(AppOwnedLayout), 'The container should ship at least one app-owned Word layout.');

        // [THEN] Each key carries the Application ID of its own layout.
        Assert.AreEqual(
            LookupHelper.EncodeCompositeName(EmptyGuid, TenantLayout.Name),
            LookupHelper.CompositeLayoutKey(TenantLayout),
            'A tenant-defined layout should be keyed with the empty GUID.');
        Assert.AreEqual(
            LookupHelper.EncodeCompositeName(AppOwnedLayout."Application ID", AppOwnedLayout.Name),
            LookupHelper.CompositeLayoutKey(AppOwnedLayout),
            'An app-owned layout should be keyed with the Application ID of the owning extension.');

        // [THEN] The app-owned layout is not keyed as tenant-defined.
        Assert.AreNotEqual(
            LookupHelper.EncodeCompositeName(EmptyGuid, AppOwnedLayout.Name),
            LookupHelper.CompositeLayoutKey(AppOwnedLayout),
            'An app-owned layout must not be keyed with the empty GUID.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsBodyLayoutAcceptsOnlyTheBodySubtype()
    var
        BodyKey: Text;
        DefaultKey: Text;
    begin
        // [SCENARIO] Only a Word layout with the Body subtype can carry a theme and header/footer, so the guard
        // accepts a body layout of the report and rejects everything else.
        Initialize();

        // [GIVEN] One body layout and one default layout on the same report.
        BodyKey := CreateLayoutOnReport(BodyReportID, 'GuardBody', Enum::"Report Layout Subtype"::Body);
        DefaultKey := CreateLayoutOnReport(BodyReportID, 'GuardDefault', Enum::"Report Layout Subtype"::Default);

        // [THEN] The body layout is accepted, by composite key and by plain name.
        Assert.IsTrue(LookupHelper.IsBodyLayout(BodyReportID, BodyKey), 'A body layout referenced by its composite key should be accepted.');
        Assert.IsTrue(LookupHelper.IsBodyLayout(BodyReportID, 'GuardBody'), 'A body layout referenced by its plain name should be accepted.');

        // [THEN] A layout of the report that is not a body layout is rejected.
        Assert.IsFalse(LookupHelper.IsBodyLayout(BodyReportID, DefaultKey), 'A default-subtype layout should not be accepted as a body layout.');

        // [THEN] A body layout belonging to a different report is rejected.
        Assert.IsFalse(LookupHelper.IsBodyLayout(PartsReportID, BodyKey), 'A body layout of another report should not be accepted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingReportIdIsRejectedWhenTheLayoutDoesNotBelong()
    var
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
        BodyKey: Text;
    begin
        // [SCENARIO] Typing a different report on a layout-scoped row would leave the layout name of the previous
        // report behind. The page rejects the change instead of letting the row reach the platform unresolvable.
        Initialize();
        EnableDocumentReportExperience();

        // [GIVEN] A configuration row scoped to one body layout of a report.
        BodyKey := CreateLayoutOnReport(BodyReportID, 'ScopedBody', Enum::"Report Layout Subtype"::Body);
        InsertCfg(BodyReportID, BodyKey, '', CreatePart('ScopedHF', Enum::"Report Layout Subtype"::HeaderFooter), '');

        TenantReportLayoutCfgPage.OpenEdit();
        TenantReportLayoutCfgPage.Filter.SetFilter("Report ID", Format(BodyReportID));
        Assert.IsTrue(TenantReportLayoutCfgPage.First(), 'The configured row should be shown on the page.');

        // [WHEN] Pointing the row at a report the layout does not belong to.
        asserterror TenantReportLayoutCfgPage."Report ID".SetValue(PartsReportID);

        // [THEN] The change is refused and names the layout that does not fit.
        Assert.ExpectedError('is not a body layout of');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearPartAssignmentsClearsEveryReferencingRow()
    var
        PartLayout: Record "Report Layout List";
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        HeaderComposite: Text;
        BodyKey: Text;
    begin
        // [SCENARIO] Deleting a part first clears it from every configuration row that references it, at any level,
        // and leaves those rows in place.
        Initialize();

        // [GIVEN] One header/footer part assigned both at the report level and at the layout level.
        HeaderComposite := CreatePart('SharedHF', Enum::"Report Layout Subtype"::HeaderFooter);
        BodyKey := CreateLayoutOnReport(BodyReportID, 'AssignedBody', Enum::"Report Layout Subtype"::Body);
        InsertCfg(BodyReportID, '', '', HeaderComposite, '');
        InsertCfg(BodyReportID, BodyKey, '', HeaderComposite, '');
        FindLayout(PartsReportID, 'SharedHF', PartLayout);

        // [THEN] Both rows are counted as assignments.
        Assert.AreEqual(2, LookupHelper.CountPartAssignments(PartLayout), 'Both configuration rows should count as assignments.');

        // [WHEN] Clearing the assignments of that part.
        Assert.AreEqual(2, LookupHelper.ClearPartAssignments(PartLayout), 'Both configuration rows should be reported as cleared.');

        // [THEN] Nothing references the part any more.
        Assert.AreEqual(0, LookupHelper.CountPartAssignments(PartLayout), 'No assignment should remain after clearing.');

        // [THEN] The configuration rows still exist, with the reference removed rather than the row.
        Assert.IsTrue(TenantReportLayoutCfg.Get(BodyReportID, '', ''), 'The report-level row should still exist.');
        Assert.AreEqual('', TenantReportLayoutCfg."Header Part Name", 'The report-level reference should be cleared.');
        Assert.IsTrue(TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), ''), 'The layout-level row should still exist.');
        Assert.AreEqual('', TenantReportLayoutCfg."Header Part Name", 'The layout-level reference should be cleared.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignmentActionIsEnabledOnlyForBodyLayouts()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [SCENARIO] A theme and header/footer can only be set on a body layout, so the action is enabled there and
        // disabled on any other layout of the same report.
        Initialize();
        EnableDocumentReportExperience();

        // [GIVEN] One body layout and one default layout on the same report.
        CreateLayoutOnReport(BodyReportID, 'GateBody', Enum::"Report Layout Subtype"::Body);
        CreateLayoutOnReport(BodyReportID, 'GateDefault', Enum::"Report Layout Subtype"::Default);

        ReportLayoutsPage.OpenView();

        // [WHEN] The body layout is selected.
        FindLayout(BodyReportID, 'GateBody', ReportLayoutList);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // [THEN] The assignment action is available.
        Assert.IsTrue(ReportLayoutsPage.AssignReportDefaults.Enabled(), 'Setting a theme and header-footer should be enabled on a body layout.');

        // [WHEN] A layout that is not a body layout is selected.
        FindLayout(BodyReportID, 'GateDefault', ReportLayoutList);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);

        // [THEN] The assignment action is not available.
        Assert.IsFalse(ReportLayoutsPage.AssignReportDefaults.Enabled(), 'Setting a theme and header-footer should be disabled on a layout that is not a body layout.');

        ReportLayoutsPage.Close();
        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportLayoutsExcludesThemeAndHeaderFooterParts()
    var
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [SCENARIO] Themes and header/footer parts are not report layouts a user picks or prints, so they are kept
        // out of the report layout list and managed on their own page.
        Initialize();
        EnableDocumentReportExperience();

        // [GIVEN] A header/footer part, a theme part, and a body layout.
        CreatePart('HiddenHF', Enum::"Report Layout Subtype"::HeaderFooter);
        CreatePart('HiddenTheme', Enum::"Report Layout Subtype"::Theme);
        CreateLayoutOnReport(BodyReportID, 'ListedBody', Enum::"Report Layout Subtype"::Body);

        ReportLayoutsPage.OpenView();

        // [THEN] Neither part is listed.
        ReportLayoutsPage.Filter.SetFilter(Name, 'HiddenHF');
        Assert.IsFalse(ReportLayoutsPage.First(), 'A header/footer part should not be listed among report layouts.');
        ReportLayoutsPage.Filter.SetFilter(Name, 'HiddenTheme');
        Assert.IsFalse(ReportLayoutsPage.First(), 'A theme part should not be listed among report layouts.');

        // [THEN] A body layout is still listed, so the filter excludes the parts and nothing more.
        ReportLayoutsPage.Filter.SetFilter(Name, 'ListedBody');
        Assert.IsTrue(ReportLayoutsPage.First(), 'A body layout should be listed among report layouts.');

        ReportLayoutsPage.Close();
        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('AssignmentDialogCaptureAndCancel')]
    [Scope('OnPrem')]
    procedure CompanyOverrideNoticeIsShownOnTheAssignmentDialog()
    var
        Notice: Text;
    begin
        // [SCENARIO] When a company sets its own theme and header/footer for a layout, the assignment dialog says so,
        // because the company setting is more specific and keeps applying whatever is chosen for all companies.
        Initialize();
        EnableDocumentReportExperience();

        // [GIVEN] A body layout with a tenant-wide setting and a company-scoped override.
        SeedOverriddenLayout();

        // [WHEN] Opening the assignment dialog on that layout.
        OpenAssignmentDialog();

        // [THEN] The notice is shown and names the company and both of the parts it sets.
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'The company override notice should be shown when a company sets its own parts.');
        Notice := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(CompanyName(), Notice);
        Assert.ExpectedMessage('OverrideHF', Notice);
        Assert.ExpectedMessage('OverrideTheme', Notice);

        // [THEN] The dialog names the layout plainly and stages the tenant-wide part, not the company override.
        Assert.AreEqual('OverriddenBody', LibraryVariableStorage.DequeueText(), 'The dialog should name the layout without the composite prefix.');
        Assert.AreEqual('TenantWideHF', LibraryVariableStorage.DequeueText(), 'The dialog should stage the tenant-wide part, not the company override.');

        // [THEN] Nothing else was shown: exactly one dialog and no confirmation on the cancel path.
        LibraryVariableStorage.AssertEmpty();

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('AssignmentDialogClearHeader,ConfirmFromQueueHandler')]
    [Scope('OnPrem')]
    procedure ConfirmingTheOverrideWarningSavesTheTenantWideChange()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        BodyKey: Text;
    begin
        // [SCENARIO] Accepting the warning applies the change to all other companies. Clearing both parts removes the
        // tenant-wide row rather than leaving an empty one behind.
        Initialize();
        EnableDocumentReportExperience();

        // [GIVEN] A body layout with a tenant-wide setting and a company-scoped override.
        BodyKey := SeedOverriddenLayout();

        // [WHEN] Clearing the header/footer and confirming the warning, which closes the dialog.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        OpenAssignmentDialog();

        // [THEN] The warning was asked once, and still explains that the company setting keeps applying.
        Assert.ExpectedMessage('keeps applying there', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();

        // [THEN] The tenant-wide row is gone.
        Assert.IsFalse(
            TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), ''),
            'Clearing both parts should remove the tenant-wide row instead of leaving it empty.');

        // [THEN] The company override is untouched, since the warning said it keeps applying.
        Assert.IsTrue(
            TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutCfg."Company Name"))),
            'The company override should survive a tenant-wide change.');
        Assert.AreEqual('OverrideHF', LookupHelper.DecodeLayoutName(TenantReportLayoutCfg."Header Part Name"), 'The company override should keep its header/footer part.');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('AssignmentDialogClearHeader,ConfirmFromQueueHandler')]
    [Scope('OnPrem')]
    procedure DecliningTheOverrideWarningLeavesTheTenantWideSettingUnchanged()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        BodyKey: Text;
    begin
        // [SCENARIO] Declining the warning writes nothing, so the tenant-wide setting is left exactly as it was.
        Initialize();
        EnableDocumentReportExperience();

        // [GIVEN] A body layout with a tenant-wide setting and a company-scoped override.
        BodyKey := SeedOverriddenLayout();

        // [WHEN] Clearing the header/footer and declining the warning, which refuses the close.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        OpenAssignmentDialog();

        // [THEN] The warning was asked once, and still explains that the company setting keeps applying.
        Assert.ExpectedMessage('keeps applying there', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();

        // [THEN] The tenant-wide row still carries the part it started with.
        Assert.IsTrue(
            TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), ''),
            'Declining the warning should leave the tenant-wide row in place.');
        Assert.AreEqual('TenantWideHF', LookupHelper.DecodeLayoutName(TenantReportLayoutCfg."Header Part Name"), 'Declining the warning should not clear the tenant-wide header/footer part.');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddGlobalDefaultCreatesTheWildcardRowAndIsIdempotent()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
    begin
        // [SCENARIO] The global default is the row that applies when nothing more specific is set. The action creates it,
        // and goes to it when it is already there, so it can be used twice without a duplicate key.
        Initialize();
        EnableDocumentReportExperience();

        TenantReportLayoutCfgPage.OpenEdit();

        // [WHEN] Adding the global default.
        TenantReportLayoutCfgPage.SetForAllReports.Invoke();

        // [THEN] The wildcard row exists.
        Assert.IsTrue(TenantReportLayoutCfg.Get(0, '', ''), 'Add global default should create the row that covers every report.');

        // [WHEN] Adding it again.
        TenantReportLayoutCfgPage.SetForAllReports.Invoke();
        TenantReportLayoutCfgPage.Close();

        // [THEN] There is still exactly one.
        TenantReportLayoutCfg.Reset();
        TenantReportLayoutCfg.SetRange("Report ID", 0);
        TenantReportLayoutCfg.SetRange("Layout Name", '');
        TenantReportLayoutCfg.SetRange("Company Name", '');
        Assert.AreEqual(1, TenantReportLayoutCfg.Count(), 'Add global default should go to the existing row, not add a second one.');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('PickBodyLayoutHandler')]
    [Scope('OnPrem')]
    procedure SetForOneReportCoversEveryLayoutOfThatReport()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
    begin
        // [SCENARIO] The user picks a body layout to identify the report, and the row that covers all of that report's
        // layouts is created - an empty Layout Name, not the layout that was picked.
        Initialize();
        EnableDocumentReportExperience();
        CreateLayoutOnReport(BodyReportID, 'ScopeReportBody', Enum::"Report Layout Subtype"::Body);

        // [WHEN] Setting defaults for one report.
        LibraryVariableStorage.Enqueue('ScopeReportBody');
        TenantReportLayoutCfgPage.OpenEdit();
        TenantReportLayoutCfgPage.SetForOneReport.Invoke();
        TenantReportLayoutCfgPage.Close();

        // [THEN] The report-level row exists and names no layout.
        Assert.IsTrue(TenantReportLayoutCfg.Get(BodyReportID, '', ''), 'Set for one report should create the row covering every layout of the report.');
        LibraryVariableStorage.AssertEmpty();

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('PickBodyLayoutHandler')]
    [Scope('OnPrem')]
    procedure SetForOneLayoutCoversOnlyThatLayout()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
        BodyKey: Text;
    begin
        // [SCENARIO] Setting defaults for one layout keys the row to that layout's composite reference.
        Initialize();
        EnableDocumentReportExperience();
        BodyKey := CreateLayoutOnReport(BodyReportID, 'ScopeLayoutBody', Enum::"Report Layout Subtype"::Body);

        // [WHEN] Setting defaults for one layout.
        LibraryVariableStorage.Enqueue('ScopeLayoutBody');
        TenantReportLayoutCfgPage.OpenEdit();
        TenantReportLayoutCfgPage.SetForOneLayout.Invoke();
        TenantReportLayoutCfgPage.Close();

        // [THEN] The row is keyed to that layout, and the report-wide row was not created instead.
        Assert.IsTrue(
            TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), ''),
            'Set for one layout should create the row keyed to the picked layout.');
        Assert.IsFalse(TenantReportLayoutCfg.Get(BodyReportID, '', ''), 'Set for one layout should not create the report-wide row.');
        LibraryVariableStorage.AssertEmpty();

        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyToAllLayoutsWidensTheRowAndKeepsItsParts()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
        HeaderComposite: Text;
        BodyKey: Text;
    begin
        // [SCENARIO] Widening a layout-scoped row makes it cover every layout of the report, carrying its parts across
        // rather than starting a new row.
        Initialize();
        EnableDocumentReportExperience();
        BodyKey := CreateLayoutOnReport(BodyReportID, 'WidenBody', Enum::"Report Layout Subtype"::Body);
        HeaderComposite := CreatePart('WidenHF', Enum::"Report Layout Subtype"::HeaderFooter);
        InsertCfg(BodyReportID, BodyKey, '', HeaderComposite, '');

        // [WHEN] Applying the row to all layouts.
        TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), '');
        TenantReportLayoutCfgPage.OpenEdit();
        TenantReportLayoutCfgPage.GoToRecord(TenantReportLayoutCfg);
        TenantReportLayoutCfgPage.WidenToAllLayouts.Invoke();
        TenantReportLayoutCfgPage.Close();

        // [THEN] The layout-scoped row is gone and the report-wide row carries the same part.
        Assert.IsFalse(
            TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), ''),
            'The layout-scoped row should have been renamed, not left behind.');
        Assert.IsTrue(TenantReportLayoutCfg.Get(BodyReportID, '', ''), 'The row should now cover every layout of the report.');
        Assert.AreEqual('WidenHF', LookupHelper.DecodeLayoutName(TenantReportLayoutCfg."Header Part Name"), 'Widening the row should carry its parts across.');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyToAllLayoutsIsRefusedWhenTheWiderRowAlreadyExists()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        TenantReportLayoutCfgPage: TestPage "Tenant Report Layout Cfg";
        BodyKey: Text;
    begin
        // [SCENARIO] Widening onto a scope that another row already owns is refused, naming the row that owns it,
        // instead of failing on a duplicate key.
        Initialize();
        EnableDocumentReportExperience();
        BodyKey := CreateLayoutOnReport(BodyReportID, 'ClashBody', Enum::"Report Layout Subtype"::Body);
        InsertCfg(BodyReportID, BodyKey, '', CreatePart('ClashLayoutHF', Enum::"Report Layout Subtype"::HeaderFooter), '');
        InsertCfg(BodyReportID, '', '', CreatePart('ClashReportHF', Enum::"Report Layout Subtype"::HeaderFooter), '');

        TenantReportLayoutCfg.Get(BodyReportID, CopyStr(BodyKey, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), '');
        TenantReportLayoutCfgPage.OpenEdit();
        TenantReportLayoutCfgPage.GoToRecord(TenantReportLayoutCfg);

        // [WHEN] Applying the row to all layouts, where that scope is taken.
        asserterror TenantReportLayoutCfgPage.WidenToAllLayouts.Invoke();

        // [THEN] The clash is reported, naming the scope that is already taken rather than failing on a duplicate key.
        Assert.ExpectedError('already exists');
        Assert.ExpectedError('All layouts of');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('NewLayoutSubtypeDialogHandler')]
    [Scope('OnPrem')]
    procedure NewWordLayoutDefaultsToTheBodySubtype()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [SCENARIO] A theme and header/footer are merged onto a body layout, so a new Word layout is offered as Body.
        Initialize();
        EnableDocumentReportExperience();

        // [WHEN] Creating a Word layout without touching the subtype.
        LibraryVariableStorage.Enqueue('SubtypeLeftAsOffered');
        LibraryVariableStorage.Enqueue('Word');
        LibraryVariableStorage.Enqueue('');
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.NewLayout.Invoke();
        ReportLayoutsPage.Close();

        // [THEN] It is created as a body layout.
        FindLayout(BodyReportID, 'SubtypeLeftAsOffered', ReportLayoutList);
        Assert.AreEqual(
            ReportLayoutList."Layout Subtype"::Body, ReportLayoutList."Layout Subtype",
            'A new Word layout should be created as a body layout.');
        LibraryVariableStorage.AssertEmpty();

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('NewLayoutSubtypeDialogHandler')]
    [Scope('OnPrem')]
    procedure NewWordLayoutCanBeCreatedAsDefaultSubtype()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        // [SCENARIO] Body is only the offer, not the only option: a Word layout can still be a stand-alone one.
        Initialize();
        EnableDocumentReportExperience();

        // [WHEN] Creating a Word layout and choosing Default.
        LibraryVariableStorage.Enqueue('SubtypeChosenDefault');
        LibraryVariableStorage.Enqueue('Word');
        LibraryVariableStorage.Enqueue('Default');
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.NewLayout.Invoke();
        ReportLayoutsPage.Close();

        // [THEN] It is created as a default layout.
        FindLayout(BodyReportID, 'SubtypeChosenDefault', ReportLayoutList);
        Assert.AreEqual(
            ReportLayoutList."Layout Subtype"::Default, ReportLayoutList."Layout Subtype",
            'Choosing Default should create a stand-alone layout, not a body layout.');
        LibraryVariableStorage.AssertEmpty();

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('NewLayoutBodyOnNonWordHandler')]
    [Scope('OnPrem')]
    procedure BodySubtypeIsRefusedForANonWordFormat()
    begin
        // [SCENARIO] Only a Word document can carry a merged theme and header/footer, so Body is refused for any other
        // format, naming Word.
        Initialize();
        EnableDocumentReportExperience();

        // [WHEN] Choosing Body for an RDLC layout.
        ReportLayoutsNewLayout();

        // [THEN] The choice is refused and explains that it applies to Word only.
        Assert.ExpectedMessage('Only a Word layout can be a body layout', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Nothing was created.
        Assert.IsFalse(TenantLayoutExists(BodyReportID, 'SubtypeGuard'), 'A refused subtype should not leave a layout behind.');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('ConfirmFromQueueHandler')]
    [Scope('OnPrem')]
    procedure DeletingAnAssignedPartClearsItsAssignments()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        PartLayout: Record "Report Layout List";
        ReportThemePage: TestPage "Report Theme and Header/Footer";
    begin
        // [SCENARIO] Deleting a part that reports still reference warns about those assignments, then clears them so no
        // configuration row is left pointing at a part that no longer exists.
        Initialize();
        EnableDocumentReportExperience();
        InsertCfg(BodyReportID, '', '', CreatePart('DeleteAssignedHF', Enum::"Report Layout Subtype"::HeaderFooter), '');
        FindLayout(PartsReportID, 'DeleteAssignedHF', PartLayout);

        // [WHEN] Deleting the part and confirming.
        LibraryVariableStorage.Enqueue(true);
        ReportThemePage.OpenView();
        ReportThemePage.GoToRecord(PartLayout);
        ReportThemePage.DeleteArtifact.Invoke();
        ReportThemePage.Close();

        // [THEN] The question asked was the one that warns about existing assignments, not the plain delete question.
        Assert.ExpectedMessage('Deleting it will clear those assignments', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();

        // [THEN] The part is gone and the configuration row survives with the reference cleared.
        Assert.IsFalse(TenantLayoutExists(PartsReportID, 'DeleteAssignedHF'), 'The part should have been deleted.');
        Assert.IsTrue(TenantReportLayoutCfg.Get(BodyReportID, '', ''), 'The configuration row should survive the deletion.');
        Assert.AreEqual('', TenantReportLayoutCfg."Header Part Name", 'Deleting the part should clear the assignment.');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [HandlerFunctions('ConfirmFromQueueHandler')]
    [Scope('OnPrem')]
    procedure DecliningTheDeleteKeepsThePart()
    var
        PartLayout: Record "Report Layout List";
        ReportThemePage: TestPage "Report Theme and Header/Footer";
    begin
        // [SCENARIO] An unassigned part is confirmed with the plain question, and declining it deletes nothing.
        Initialize();
        EnableDocumentReportExperience();
        CreatePart('DeleteDeclinedHF', Enum::"Report Layout Subtype"::HeaderFooter);
        FindLayout(PartsReportID, 'DeleteDeclinedHF', PartLayout);

        // [WHEN] Deleting the part and declining.
        LibraryVariableStorage.Enqueue(false);
        ReportThemePage.OpenView();
        ReportThemePage.GoToRecord(PartLayout);
        ReportThemePage.DeleteArtifact.Invoke();
        ReportThemePage.Close();

        // [THEN] An unassigned part is asked about plainly, with no mention of configurations.
        Assert.ExpectedMessage('Delete the artifact', LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();

        // [THEN] The part is still there.
        Assert.IsTrue(TenantLayoutExists(PartsReportID, 'DeleteDeclinedHF'), 'Declining the confirmation should keep the part.');

        RestoreDocumentReportExperience();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCompanyOpenSeedsDefaultPartsWhenMissing()
    begin
        // [SCENARIO] On company open, the shipped parts are seeded if missing, for new tenants
        // provisioned from a pre-built database image where BaseApp is installed but OnInstallAppPerDatabase
        // may not have run.
        Initialize();

        // [GIVEN] One shipped part is missing.
        RemoveShippedPart('Internal Default');
        Assert.IsFalse(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The part should be missing before OnCompanyOpen.');

        // [WHEN] Simulating OnCompanyOpen (same logic as the event handler).
        SimulateCompanyOpenSeeding();

        // [THEN] The missing part is seeded.
        Assert.IsTrue(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'OnCompanyOpen should seed the missing shipped part.');

        // Cleared again so the suite does not hand the tag on to whatever runs next in this database.
        ClearCompositeReportPartsUpgradeTag();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnCompanyOpenIsIdempotentWhenPartsExist()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        // [SCENARIO] Running OnCompanyOpen when the database is already tagged as seeded does nothing (idempotent).
        Initialize();

        // [GIVEN] Parts are already seeded and the database carries the seeding upgrade tag.
        Assert.IsTrue(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The part should exist before OnCompanyOpen.');
        UpgradeTag.SetDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag());

        // [WHEN] Simulating OnCompanyOpen - it exits early because the database is already tagged.
        SimulateCompanyOpenSeeding();

        // [THEN] The part still exists (unchanged).
        Assert.IsTrue(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'OnCompanyOpen should be idempotent when parts already exist.');

        // Cleared again so the suite does not hand the tag on to whatever runs next in this database.
        ClearCompositeReportPartsUpgradeTag();
    end;

    /// <summary>
    /// Mirrors the company-open fallback in codeunit "Upgrade Composite Report Parts": the database upgrade tag is the
    /// guard, and seeding goes through SeedShippedParts so the tag is recorded and the seeding stays exactly-once.
    /// </summary>
    local procedure SimulateCompanyOpenSeeding()
    var
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            exit;

        UpgradeCompositeReportParts.SeedShippedParts();
    end;

    local procedure ReportLayoutsNewLayout()
    var
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        ReportLayoutsPage.OpenView();
        ReportLayoutsPage.NewLayout.Invoke();
        ReportLayoutsPage.Close();
    end;

    [ModalPageHandler]
    procedure PickBodyLayoutHandler(var ReportLayouts: TestPage "Report Layouts")
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        FindLayout(BodyReportID, LibraryVariableStorage.DequeueText(), ReportLayoutList);
        ReportLayouts.GoToRecord(ReportLayoutList);
        ReportLayouts.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewLayoutSubtypeDialogHandler(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    var
        LayoutName: Text;
        SubtypeChoice: Text;
    begin
        LayoutName := LibraryVariableStorage.DequeueText();
        ReportLayoutNewDialog.ReportID.SetValue(BodyReportID);
        ReportLayoutNewDialog.LayoutName.SetValue(LayoutName);
        ReportLayoutNewDialog.Description.SetValue(LayoutName);
        ReportLayoutNewDialog."Format Options".SetValue(LibraryVariableStorage.DequeueText());
        ReportLayoutNewDialog.CreateEmptyLayout.SetValue(true);

        SubtypeChoice := LibraryVariableStorage.DequeueText();
        if SubtypeChoice <> '' then
            ReportLayoutNewDialog.BodySubtype.SetValue(SubtypeChoice);

        ReportLayoutNewDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewLayoutBodyOnNonWordHandler(var ReportLayoutNewDialog: TestPage "Report Layout New Dialog")
    begin
        ReportLayoutNewDialog.ReportID.SetValue(BodyReportID);
        ReportLayoutNewDialog.LayoutName.SetValue('SubtypeGuard');
        ReportLayoutNewDialog.Description.SetValue('SubtypeGuard');
        ReportLayoutNewDialog."Format Options".SetValue('RDLC');

        asserterror ReportLayoutNewDialog.BodySubtype.SetValue('Body');
        LibraryVariableStorage.Enqueue(GetLastErrorText());

        ReportLayoutNewDialog.Cancel().Invoke();
    end;

    local procedure SeedOverriddenLayout() BodyKey: Text
    begin
        BodyKey := CreateLayoutOnReport(BodyReportID, 'OverriddenBody', Enum::"Report Layout Subtype"::Body);
        InsertCfg(BodyReportID, BodyKey, '', CreatePart('TenantWideHF', Enum::"Report Layout Subtype"::HeaderFooter), '');
        InsertCfg(BodyReportID, BodyKey, CopyStr(CompanyName(), 1, 30), CreatePart('OverrideHF', Enum::"Report Layout Subtype"::HeaderFooter), CreatePart('OverrideTheme', Enum::"Report Layout Subtype"::Theme));
    end;

    local procedure OpenAssignmentDialog()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutsPage: TestPage "Report Layouts";
    begin
        ReportLayoutsPage.OpenView();
        FindLayout(BodyReportID, 'OverriddenBody', ReportLayoutList);
        ReportLayoutsPage.GoToRecord(ReportLayoutList);
        ReportLayoutsPage.AssignReportDefaults.Invoke();
        ReportLayoutsPage.Close();
    end;

    [ModalPageHandler]
    procedure AssignmentDialogCaptureAndCancel(var HeaderFooterThemeAssignment: TestPage "Header/Footer Theme Assignment")
    begin
        LibraryVariableStorage.Enqueue(HeaderFooterThemeAssignment.CompanyOverrideDisplay.Visible());
        LibraryVariableStorage.Enqueue(HeaderFooterThemeAssignment.CompanyOverrideDisplay.Value());
        LibraryVariableStorage.Enqueue(HeaderFooterThemeAssignment.LayoutNameDisplay.Value());
        LibraryVariableStorage.Enqueue(HeaderFooterThemeAssignment.HeaderPartDisplay.Value());
        HeaderFooterThemeAssignment.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure AssignmentDialogClearHeader(var HeaderFooterThemeAssignment: TestPage "Header/Footer Theme Assignment")
    var
        CloseIsRefused: Boolean;
    begin
        CloseIsRefused := LibraryVariableStorage.DequeueBoolean();

        HeaderFooterThemeAssignment.HeaderPartDisplay.SetValue('');
        HeaderFooterThemeAssignment.OK().Invoke();

        if CloseIsRefused then
            HeaderFooterThemeAssignment.Cancel().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmFromQueueHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

    [MessageHandler]
    procedure PartInfoMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    /// <summary>
    /// Removes one shipped part from the shared pool so a seeding assertion proves the call under test wrote it. The
    /// suite runs in a non-isolated bucket against a shared company, so rows an earlier run seeded are still there.
    /// </summary>
    local procedure RemoveShippedPart(PartName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // Filtered on the shipped App ID: the shipped names are shared, and a tenant-authored part of the same name is
        // customer content this cleanup must not touch. RemoveTenantPart handles the clone a test owns.
        TenantReportLayout.SetRange("Report ID", LookupHelper.GetTenantReportDefaultsReportID());
        TenantReportLayout.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(TenantReportLayout.Name)));
        TenantReportLayout.SetRange("App ID", CompositeReportPartsMgt.GetShippedPartAppId());
        TenantReportLayout.DeleteAll(true);
    end;

    /// <summary>
    /// Removes the tenant-owned row for a part name, on the no-App-ID key. Used to take back the clone
    /// SeedingKeepsATenantPartNamedAfterAShippedPart creates, without reaching into rows the pass owns.
    /// </summary>
    local procedure RemoveTenantPart(PartName: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        EmptyAppId: Guid;
    begin
        if TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), CopyStr(PartName, 1, MaxStrLen(TenantReportLayout.Name)), EmptyAppId) then
            TenantReportLayout.Delete(true);
    end;

    /// <summary>
    /// Whether the seeding pass owns a row for this part. Filtered on the shipped App ID: a part the tenant authored
    /// can carry the same name, and an assertion must not be satisfied by customer content standing in for the row the
    /// pass is supposed to have written.
    /// </summary>
    local procedure ShippedPartExists(PartName: Text; Subtype: Enum "Report Layout Subtype"): Boolean
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        TenantReportLayout.SetRange("Report ID", LookupHelper.GetTenantReportDefaultsReportID());
        TenantReportLayout.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(TenantReportLayout.Name)));
        TenantReportLayout.SetRange("App ID", CompositeReportPartsMgt.GetShippedPartAppId());
        TenantReportLayout.SetRange("Layout Subtype", Subtype);
        exit(not TenantReportLayout.IsEmpty());
    end;

    /// <summary>
    /// How many rows the seeding pass owns for this part. Filtered on the shipped App ID for the same reason as
    /// ShippedPartExists, so a tenant row of the same name cannot inflate the count.
    /// </summary>
    local procedure ShippedPartCount(PartName: Text): Integer
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        TenantReportLayout.SetRange("Report ID", LookupHelper.GetTenantReportDefaultsReportID());
        TenantReportLayout.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(TenantReportLayout.Name)));
        TenantReportLayout.SetRange("App ID", CompositeReportPartsMgt.GetShippedPartAppId());
        exit(TenantReportLayout.Count());
    end;

    local procedure Initialize()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        LibraryVariableStorage.Clear();
        TestReportID := 50000;
        BodyReportID := Report::TestReportLayoutsReport;
        PartsReportID := 2000000001;

        // These tests run in a non-isolated (Legacy) bucket against a shared company, so rows are not rolled back
        // between test methods. Clear every configuration row this suite can create before each test. Without this,
        // the layout-level row left by LayoutLevelAssignmentResolvesAsThisLayout (report 50000, layout 'Body') leaks
        // into the report/company/global-default tests and wins resolution ahead of the row they set up, and the
        // report-0 wildcard rows leak out as global/company defaults that affect other tests sharing the company.
        TenantReportLayoutCfg.SetRange("Report ID", TestReportID);
        TenantReportLayoutCfg.DeleteAll(true);
        TenantReportLayoutCfg.SetRange("Report ID", BodyReportID);
        TenantReportLayoutCfg.DeleteAll(true);
        ClearTestReportLayouts();
        ClearAdHocParts();
        ClearWildcardCfg('');                                                                     // global default: report 0, all companies
        ClearWildcardCfg(CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutCfg."Company Name"))); // company default: report 0, this company

        RestoreShippedPartPool();
        ClearCompositeReportPartsUpgradeTag();
    end;

    local procedure RestoreShippedPartPool()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // Takes out the tenant-owned clone SeedingKeepsATenantPartNamedAfterAShippedPart leaves on the no-App-ID key,
        // here rather than relying on another test's GIVEN step happening to clean it.
        RemoveTenantPart(InternalDefaultTok);

        CompositeReportPartsMgt.SeedDefaultParts();

        // The part name the missing-resource test owns is deliberately not seedable, so seeding never puts it back.
        RemoveShippedPart(UnseedablePartTok);
    end;

    /// <summary>
    /// Takes the seeding upgrade tag back out before each test. It is per-database state this suite mutates, so leaving
    /// it behind would make any test that reads it - here or in another suite sharing the database - depend on the order
    /// the runner picked. Absent is the safe state to land on: it only means a later pass reseeds, which is idempotent.
    /// </summary>
    local procedure ClearCompositeReportPartsUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // Guarded because the library helper does a bare Get and throws when the tag is not there.
        if UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag(), '');
    end;

    local procedure ClearTestReportLayouts()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TempLayoutsToDelete: Record "Tenant Report Layout" temporary;
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        EmptyGuid: Guid;
    begin
        TenantReportLayout.SetRange("Report ID", BodyReportID);
        if TenantReportLayout.FindSet() then
            repeat
                TempLayoutsToDelete.Init();
                TempLayoutsToDelete."Report ID" := TenantReportLayout."Report ID";
                TempLayoutsToDelete.Name := TenantReportLayout.Name;
                TempLayoutsToDelete.Insert();
            until TenantReportLayout.Next() = 0;

        if TempLayoutsToDelete.FindSet() then
            repeat
                if TenantReportLayout.Get(TempLayoutsToDelete."Report ID", TempLayoutsToDelete.Name, EmptyGuid) then
                    ReportLayoutsImpl.DeleteReportLayout(TenantReportLayout);
            until TempLayoutsToDelete.Next() = 0;
    end;

    /// <summary>
    /// Takes out every tenant-owned part this suite can leave on the Tenant Report Defaults report. The tests create
    /// ad-hoc parts on that report with no App ID and the bucket is not isolated, so the rows outlive the test method
    /// that made them and would otherwise pollute the shared part pool for the rest of the run. Only the no-App-ID key
    /// is touched: the shipped rows carry the app's App ID and RestoreShippedPartPool owns those.
    /// </summary>
    local procedure ClearAdHocParts()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TempPartsToDelete: Record "Tenant Report Layout" temporary;
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        EmptyAppId: Guid;
    begin
        TenantReportLayout.SetRange("Report ID", PartsReportID);
        TenantReportLayout.SetRange("App ID", EmptyAppId);
        if TenantReportLayout.FindSet() then
            repeat
                TempPartsToDelete.Init();
                TempPartsToDelete."Report ID" := TenantReportLayout."Report ID";
                TempPartsToDelete.Name := TenantReportLayout.Name;
                TempPartsToDelete.Insert();
            until TenantReportLayout.Next() = 0;

        if TempPartsToDelete.FindSet() then
            repeat
                if TenantReportLayout.Get(TempPartsToDelete."Report ID", TempPartsToDelete.Name, EmptyAppId) then
                    ReportLayoutsImpl.DeleteReportLayout(TenantReportLayout);
            until TempPartsToDelete.Next() = 0;
    end;

    local procedure TenantLayoutExists(ReportID: Integer; LayoutName: Text): Boolean
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        TenantReportLayout.SetRange("Report ID", ReportID);
        TenantReportLayout.SetRange(Name, CopyStr(LayoutName, 1, 250));
        exit(not TenantReportLayout.IsEmpty());
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
    begin
        exit(CreateLayoutOnReport(PartsReportID, PartName, Subtype));
    end;

    local procedure CreateLayoutOnReport(ReportID: Integer; LayoutName: Text; Subtype: Enum "Report Layout Subtype"): Text
    var
        ReportLayoutList: Record "Report Layout List";
        TenantReportLayout: Record "Tenant Report Layout";
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        ExcelSheetConfiguration: Enum "Excel Sheet Configuration";
        ReturnReportID: Integer;
        ReturnLayoutName: Text;
    begin
        // Remove only this specific layout if a previous run left it behind, then create it fresh. The name is unique
        // per test, so (Report ID, Name) identifies exactly this layout. CreateEmptyLayout generates a valid empty Word
        // document, so the result is a real layout that the Tenant Report Layout Cfg validation accepts when it is
        // referenced.
        TenantReportLayout.SetRange("Report ID", ReportID);
        TenantReportLayout.SetRange("Name", CopyStr(LayoutName, 1, 250));
        if TenantReportLayout.FindFirst() then
            ReportLayoutsImpl.DeleteReportLayout(TenantReportLayout);

        ReportLayoutsImpl.InsertNewLayout(ReportID, CopyStr(LayoutName, 1, 250), CopyStr(LayoutName, 1, 250), ReportLayoutList."Layout Format"::Word, true, true, ExcelSheetConfiguration::Default, Subtype, ReturnReportID, ReturnLayoutName);

        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange("Name", CopyStr(LayoutName, 1, 250));
        ReportLayoutList.SetRange("Layout Subtype", Subtype);
        ReportLayoutList.FindFirst();
        exit(LookupHelper.EncodeCompositeName(ReportLayoutList."Application ID", ReportLayoutList.Name));
    end;

    local procedure FindLayout(ReportID: Integer; LayoutName: Text; var FoundLayout: Record "Report Layout List")
    begin
        FoundLayout.Reset();
        FoundLayout.SetRange("Report ID", ReportID);
        FoundLayout.SetRange("Name", CopyStr(LayoutName, 1, 250));
        FoundLayout.FindFirst();
    end;

    local procedure FindAppOwnedWordLayout(var AppOwnedLayout: Record "Report Layout List"): Boolean
    var
        EmptyGuid: Guid;
    begin
        AppOwnedLayout.Reset();
        AppOwnedLayout.SetRange("Layout Format", AppOwnedLayout."Layout Format"::Word);
        AppOwnedLayout.SetRange("User Defined", false);
        AppOwnedLayout.SetFilter("Application ID", '<>%1', EmptyGuid);
        exit(AppOwnedLayout.FindFirst());
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
