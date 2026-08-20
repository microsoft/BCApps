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
        Assert.ExpectedMessage('wordprocessingml.template', ReportLayoutList."MIME Type");
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
    procedure AssignDefaultPartsIsIdempotentOnRerun()
    var
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        SecondPassCount: Integer;
    begin
        // [SCENARIO] Assigning the shipped designs a second time writes nothing: a layout that already has a part keeps
        // it, which is what makes the install/upgrade pass safe to repeat.
        Initialize();

        // [GIVEN] The parts are in the pool and the shipped designs have been assigned once.
        CompositeReportPartsMgt.SeedDefaultParts();
        CompositeLayoutAssignMgt.AssignDefaultParts();

        // [WHEN] Assigning again.
        SecondPassCount := CompositeLayoutAssignMgt.AssignDefaultParts();

        // [THEN] Nothing was written the second time.
        Assert.AreEqual(0, SecondPassCount, 'A repeated assignment pass should leave every existing assignment alone.');
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
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // [SCENARIO] The upgrade tag makes the seeding pass run once per database: a second upgrade exits on the guard
        // instead of re-seeding, which is what stops it re-writing parts over anything the tenant changed.
        Initialize();
        UpgradeTagLibrary.DeleteUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag(), '');

        // [GIVEN] The upgrade has run once, so the parts are seeded and the database tag is recorded.
        UpgradeCompositeReportParts.RunUpgrade();
        Assert.IsTrue(
            UpgradeTag.HasDatabaseUpgradeTag(UpgradeTagDefinitions.GetCompositeReportPartsUpgradeTag()),
            'A completed seeding pass should record its database upgrade tag.');

        // [GIVEN] One seeded part is removed behind the pass's back.
        RemoveShippedPart('Internal Default');

        // [WHEN] The upgrade runs a second time.
        UpgradeCompositeReportParts.RunUpgrade();

        // [THEN] It exited on the guard, so the removed part was not written again.
        Assert.IsFalse(
            ShippedPartExists('Internal Default', Enum::"Report Layout Subtype"::HeaderFooter),
            'The second upgrade should exit on the tag instead of re-seeding the parts.');

        // Put the part back so the rest of the suite sees a complete pool.
        CompositeReportPartsMgt.SeedDefaultParts();
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
    begin
        if TenantReportLayout.Get(LookupHelper.GetTenantReportDefaultsReportID(), CopyStr(PartName, 1, MaxStrLen(TenantReportLayout.Name)), EmptyGuidValue()) then
            TenantReportLayout.Delete(true);
    end;

    local procedure EmptyGuidValue(): Guid
    var
        EmptyGuid: Guid;
    begin
        exit(EmptyGuid);
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
