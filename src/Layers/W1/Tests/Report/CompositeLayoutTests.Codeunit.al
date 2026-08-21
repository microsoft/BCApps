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
        ExternalDefaultDetailedTok: Label 'External Default Detailed', Locked = true;
        InternalDefaultTok: Label 'Internal Default', Locked = true;
        SalesInvoiceBodyLayoutTok: Label 'StandardSalesInvoiceBody.docx', Locked = true;
        MissingBodyLayoutTok: Label 'ThisBodyLayoutIsNotInstalled.docx', Locked = true;
        UnseedablePartTok: Label 'Test Unseedable Part', Locked = true;
        UnseedablePartDescTok: Label 'A part a test seeds from a layout file that is not in the app.', Locked = true;
        MissingResourceTok: Label 'ReportParts/HeaderFooterDesign/ThisResourceIsNotInTheApp.docx', Locked = true;
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
        Assert.AreEqual(
            'application/vnd.openxmlformats-officedocument.wordprocessingml.template', ReportLayoutList."MIME Type",
            'Themes ship as .dotx templates, so the stored MIME type should be the template one, not the document one.');
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
    procedure AssignDefaultPartsAssignsThenIsIdempotentOnRerun()
    var
        BodyLayout: Record "Report Layout List";
        TempCfgBefore: Record "Tenant Report Layout Cfg" temporary;
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        FirstPassCount: Integer;
        SecondPassCount: Integer;
    begin
        // [SCENARIO] The first pass assigns the shipped designs; a second writes nothing, because a layout that already
        // has a part keeps it. That is what makes the install/upgrade pass safe to repeat.
        Initialize();

        // [GIVEN] The parts are in the pool, and one body layout has no configuration row. The suite shares a company
        // and is not rolled back, so without clearing a row an earlier run would leave everything already assigned and
        // the first pass would legitimately write nothing - making the assertions below vacuous.
        // AssignDefaultParts configures every shipped report and every body layout on the tenant, so record the
        // all-companies configuration first and put it back at the end - this suite shares a company and is not rolled
        // back between methods, and leaving those rows behind would make later tests depend on execution order.
        SnapshotLayoutCfg(TempCfgBefore);

        CompositeReportPartsMgt.SeedDefaultParts();
        Assert.IsTrue(FindAnyBodyLayout(BodyLayout), 'The tenant should have at least one Word body layout to assign to.');
        RemoveLayoutCfg(BodyLayout."Report ID", BodyLayout.Name);
        RemoveLayoutCfg(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok);

        // [WHEN] Assigning the shipped designs.
        FirstPassCount := CompositeLayoutAssignMgt.AssignDefaultParts();

        // [THEN] The pass wrote something, and both halves of it ran: the blanket theme reached the arbitrary layout, and
        // the curated header/footer list reached the layout it names. Asserting only the theme would stay green with the
        // whole header/footer pass broken, since the theme pass alone can satisfy the count.
        Assert.IsTrue(FirstPassCount > 0, 'The first assignment pass should write at least the rows that were cleared.');
        Assert.IsTrue(
            LayoutCfgHasThemePart(BodyLayout."Report ID", BodyLayout.Name),
            'The cleared body layout should have been given the default theme.');
        Assert.AreEqual(
            ExternalDefaultDetailedTok,
            LayoutCfgHeaderPartName(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok),
            'The curated header/footer mapping should have been applied on the first pass.');

        // [WHEN] Assigning again.
        SecondPassCount := CompositeLayoutAssignMgt.AssignDefaultParts();

        // [THEN] Nothing was written the second time.
        Assert.AreEqual(0, SecondPassCount, 'A repeated assignment pass should leave every existing assignment alone.');

        RestoreLayoutCfg(TempCfgBefore);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignDefaultPartsAppliesCuratedHeaderFooterMapping()
    var
        TempCfgBefore: Record "Tenant Report Layout Cfg" temporary;
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [SCENARIO] The curated report-to-part list is applied, not just the blanket theme: the shipped body layout of
        // the posted sales invoice gets the header/footer design the list names for it.
        Initialize();
        SnapshotLayoutCfg(TempCfgBefore);

        // [GIVEN] The parts are seeded and this layout has no configuration row.
        CompositeReportPartsMgt.SeedDefaultParts();
        Assert.IsTrue(
            ShippedPartExists(ExternalDefaultDetailedTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'The header/footer part the curated list names should be in the pool.');
        RemoveLayoutCfg(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok);

        // [WHEN] Assigning the shipped designs.
        CompositeLayoutAssignMgt.AssignDefaultParts();

        // [THEN] The layout carries exactly the part the curated list maps it to.
        Assert.AreEqual(
            ExternalDefaultDetailedTok,
            LayoutCfgHeaderPartName(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok),
            'The curated mapping for the posted sales invoice body layout should have been applied.');

        RestoreLayoutCfg(TempCfgBefore);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignDefaultPartsSkipsLayoutWhenNamedPartIsMissing()
    var
        TempCfgBefore: Record "Tenant Report Layout Cfg" temporary;
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        // [SCENARIO] When the part a curated mapping names is not in the pool, that one assignment is skipped and no
        // header/footer row is written for it - the pass degrades rather than failing or writing a bad reference.
        Initialize();
        SnapshotLayoutCfg(TempCfgBefore);

        // [GIVEN] The pool is seeded, then the part this mapping needs is removed, and the layout has no row.
        CompositeReportPartsMgt.SeedDefaultParts();
        RemoveShippedPart(ExternalDefaultDetailedTok);
        Assert.IsFalse(
            ShippedPartExists(ExternalDefaultDetailedTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'The part should be out of the pool, or this test proves nothing.');
        RemoveLayoutCfg(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok);

        // [WHEN] Assigning the shipped designs.
        CompositeLayoutAssignMgt.AssignDefaultParts();

        // [THEN] No header/footer was recorded for that layout.
        Assert.AreEqual(
            '', LayoutCfgHeaderPartName(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok),
            'With the named part missing, the pass should skip that assignment rather than write one.');

        // [THEN] The theme still applied, so the skip was contained to the one unresolved mapping.
        Assert.IsTrue(
            LayoutCfgHasThemePart(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok),
            'The theme is a different part, so it should still have been assigned.');

        CompositeReportPartsMgt.SeedDefaultParts();
        RestoreLayoutCfg(TempCfgBefore);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignHeaderFooterSkipsLayoutThatIsNotInstalled()
    var
        TempCfgBefore: Record "Tenant Report Layout Cfg" temporary;
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        AssignmentWritten: Boolean;
        AssignedCount: Integer;
    begin
        // [SCENARIO] When a curated mapping names a body layout that is not installed on the tenant - the report does not
        // ship it, or the app that does is not installed - that one assignment is skipped: it writes no configuration row
        // and reports the layout through telemetry instead of failing. The curated list only names layouts that ship with
        // an app, so this branch is driven through the single assignment step rather than the whole pass.
        Initialize();
        SnapshotLayoutCfg(TempCfgBefore);

        // [GIVEN] The part the mapping names is in the shared pool, so a skip can only be down to the missing layout and
        // not to an unresolved part - those are separate branches with separate telemetry.
        CompositeReportPartsMgt.SeedDefaultParts();
        Assert.IsTrue(
            ShippedPartExists(InternalDefaultTok, Enum::"Report Layout Subtype"::HeaderFooter),
            'The part the mapping names should be in the pool, or this test would prove the wrong skip.');

        // [GIVEN] No Word body layout of that name is installed on the report.
        Assert.IsFalse(
            BodyLayoutInstalled(TestReportID, MissingBodyLayoutTok),
            'The layout should not be installed, or this test proves nothing.');

        // [WHEN] Assigning the header/footer for that report and layout.
        AssignmentWritten := CompositeLayoutAssignMgt.AssignHeaderFooter(TestReportID, MissingBodyLayoutTok, InternalDefaultTok);

        // [THEN] The assignment reports that it wrote nothing.
        Assert.IsFalse(AssignmentWritten, 'An assignment to a layout that is not installed should report that it wrote nothing.');

        // [THEN] No configuration row was written for it at all - not a row carrying a blank or a dangling part name.
        Assert.IsFalse(
            LayoutCfgExists(TestReportID, MissingBodyLayoutTok),
            'The skipped assignment should leave no configuration row behind for the layout.');

        // [WHEN] The full pass runs afterwards, with one curated layout cleared.
        RemoveLayoutCfg(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok);
        AssignedCount := CompositeLayoutAssignMgt.AssignDefaultParts();

        // [THEN] It still assigns, so an unresolved layout is skipped per entry and does not stop the assignments that
        // can be resolved.
        Assert.IsTrue(AssignedCount > 0, 'The pass should still write the assignments whose layouts are installed.');
        Assert.AreEqual(
            ExternalDefaultDetailedTok,
            LayoutCfgHeaderPartName(SalesInvoiceReportID(), SalesInvoiceBodyLayoutTok),
            'The curated mapping for an installed layout should still have been applied.');

        RestoreLayoutCfg(TempCfgBefore);
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
        // [SCENARIO] The upgrade seeds on its first run and records its tag; a second run exits on the guard instead of
        // re-seeding, which is what stops it re-writing parts over anything the tenant changed.
        Initialize();

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

        // Put the part back so the rest of the suite sees a complete pool.
        CompositeReportPartsMgt.SeedDefaultParts();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeedPartReportsFailureWhenTheResourceIsMissing()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        PartName: Text[250];
        PartSeeded: Boolean;
    begin
        // [SCENARIO] A part whose layout file cannot be read is reported as not seeded instead of throwing: the seeding
        // pass runs during install and upgrade, where an uncaught error would abort the whole operation. This false is
        // also the only thing that makes the pass report itself incomplete - SeedDefaultParts counts these results - and
        // an incomplete pass is what leaves the upgrade tag unset.
        Initialize();

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
        UpgradeCompositeReportParts: Codeunit "Upgrade Composite Report Parts";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        // [SCENARIO] A seeding pass that could not write every part must not record the upgrade tag. The tag is what stops
        // the pass from running again, so stamping it after a partial seed would leave the skipped parts missing for good.
        // Left unset, the next upgrade runs the pass again and seeds them.
        Initialize();

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

    /// <summary>
    /// Finds any Word body layout installed on the tenant. Used instead of a hard-coded report and layout name so the
    /// test does not depend on which apps the test tenant happens to have.
    /// </summary>
    local procedure FindAnyBodyLayout(var BodyLayout: Record "Report Layout List"): Boolean
    begin
        BodyLayout.Reset();
        BodyLayout.SetRange("Layout Format", BodyLayout."Layout Format"::Word);
        BodyLayout.SetRange("Layout Subtype", BodyLayout."Layout Subtype"::Body);
        exit(BodyLayout.FindFirst());
    end;

    /// <summary>
    /// Copies every all-companies Tenant Report Layout Cfg row into a temporary record, so RestoreLayoutCfg can put the
    /// table back exactly as it was.
    /// </summary>
    local procedure SnapshotLayoutCfg(var TempCfgBefore: Record "Tenant Report Layout Cfg" temporary)
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        TempCfgBefore.Reset();
        TempCfgBefore.DeleteAll();

        TenantReportLayoutCfg.SetRange("Company Name", '');
        if not TenantReportLayoutCfg.FindSet() then
            exit;
        repeat
            TempCfgBefore := TenantReportLayoutCfg;
            TempCfgBefore.Insert();
        until TenantReportLayoutCfg.Next() = 0;
    end;

    /// <summary>
    /// Undoes what an assignment pass wrote: deletes the all-companies rows that were not in the snapshot, and puts the
    /// part columns of the rows that were back to their recorded values. The assignment pass only fills empty columns,
    /// so a row that already existed can still have gained a part.
    /// </summary>
    local procedure RestoreLayoutCfg(var TempCfgBefore: Record "Tenant Report Layout Cfg" temporary)
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        TempAddedRows: Record "Tenant Report Layout Cfg" temporary;
    begin
        // Stage the rows to remove first: deleting while iterating the live set invalidates the cursor.
        TenantReportLayoutCfg.SetRange("Company Name", '');
        if TenantReportLayoutCfg.FindSet() then
            repeat
                if not TempCfgBefore.Get(TenantReportLayoutCfg."Report ID", TenantReportLayoutCfg."Layout Name", TenantReportLayoutCfg."Company Name") then begin
                    TempAddedRows := TenantReportLayoutCfg;
                    TempAddedRows.Insert();
                end;
            until TenantReportLayoutCfg.Next() = 0;

        if TempAddedRows.FindSet() then
            repeat
                if TenantReportLayoutCfg.Get(TempAddedRows."Report ID", TempAddedRows."Layout Name", TempAddedRows."Company Name") then
                    TenantReportLayoutCfg.Delete(true);
            until TempAddedRows.Next() = 0;

        TempCfgBefore.Reset();
        if not TempCfgBefore.FindSet() then
            exit;
        repeat
            if TenantReportLayoutCfg.Get(TempCfgBefore."Report ID", TempCfgBefore."Layout Name", TempCfgBefore."Company Name") then
                if (TenantReportLayoutCfg."Header Part Name" <> TempCfgBefore."Header Part Name") or
                   (TenantReportLayoutCfg."Theme Part Name" <> TempCfgBefore."Theme Part Name")
                then begin
                    TenantReportLayoutCfg."Header Part Name" := TempCfgBefore."Header Part Name";
                    TenantReportLayoutCfg."Theme Part Name" := TempCfgBefore."Theme Part Name";
                    TenantReportLayoutCfg.Modify(true);
                end;
        until TempCfgBefore.Next() = 0;
    end;

    local procedure RemoveLayoutCfg(ReportID: Integer; LayoutName: Text)
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        if TenantReportLayoutCfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), '') then
            TenantReportLayoutCfg.Delete(true);
    end;

    /// <summary>
    /// The plain name of the header/footer part assigned to a layout, or blank when none is. The stored value is the
    /// composite reference, so it is decoded before being returned.
    /// </summary>
    local procedure LayoutCfgHeaderPartName(ReportID: Integer; LayoutName: Text): Text
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        if not TenantReportLayoutCfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), '') then
            exit('');
        exit(LookupHelper.DecodeLayoutName(TenantReportLayoutCfg."Header Part Name"));
    end;

    /// <summary>
    /// The posted sales invoice, used as the anchor for the curated-mapping tests: both the report and its body layout
    /// ship with the Base Application, which this test app depends on, so they are present on any tenant running it.
    /// </summary>
    local procedure SalesInvoiceReportID(): Integer
    begin
        exit(1306);
    end;

    /// <summary>
    /// Whether a Word body layout of that name is installed on the report. Mirrors the predicate the assignment pass
    /// uses to decide whether a curated mapping can be applied, so a test can assert the precondition for the skip.
    /// </summary>
    local procedure BodyLayoutInstalled(ReportID: Integer; LayoutName: Text): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange(Name, CopyStr(LayoutName, 1, MaxStrLen(ReportLayoutList.Name)));
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.SetRange("Layout Subtype", ReportLayoutList."Layout Subtype"::Body);
        exit(not ReportLayoutList.IsEmpty());
    end;

    /// <summary>
    /// Whether an all-companies configuration row exists for a layout at all, regardless of which parts it carries.
    /// A blank header part cannot tell a skipped assignment from one that wrote an empty row.
    /// </summary>
    local procedure LayoutCfgExists(ReportID: Integer; LayoutName: Text): Boolean
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        exit(TenantReportLayoutCfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), ''));
    end;

    local procedure LayoutCfgHasThemePart(ReportID: Integer; LayoutName: Text): Boolean
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
    begin
        if not TenantReportLayoutCfg.Get(ReportID, CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name")), '') then
            exit(false);
        exit(TenantReportLayoutCfg."Theme Part Name" <> '');
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
