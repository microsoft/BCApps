codeunit 139089 "Power BI Unit Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [Scope('OnPrem')]
    procedure TestDisplayedElementReportKey()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        Assert: Codeunit Assert;
        ReportIdBefore: Guid;
        ReportIdAfter: Guid;
    begin
        ReportIdBefore := CreateGuid();

        PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::Report;
        PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportKey(ReportIdBefore);
        PowerBIDisplayedElement.ParseReportKey(ReportIdAfter);

        Assert.AreEqual(ReportIdBefore, ReportIdAfter, 'Wrong report ID after parsing.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDisplayedElementReportVisualKey()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        ReportIdBefore: Guid;
        PageNameBefore: Text[200];
        ReportVisualBefore: Text[200];
        ReportIdAfter: Guid;
        PageNameAfter: Text[200];
        ReportVisualAfter: Text[200];
    begin
        ReportIdBefore := CreateGuid();
        PageNameBefore := CopyStr(LibraryRandom.RandText(200), 1, 200);
        ReportVisualBefore := CopyStr(LibraryRandom.RandText(200), 1, 200);

        PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::"Report Visual";
        PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportVisualKey(ReportIdBefore, PageNameBefore, ReportVisualBefore);
        PowerBIDisplayedElement.ParseReportVisualKey(ReportIdAfter, PageNameAfter, ReportVisualAfter);

        Assert.AreEqual(ReportIdBefore, ReportIdAfter, 'Wrong report ID after parsing.');
        Assert.AreEqual(PageNameBefore, PageNameAfter, 'Wrong page name after parsing.');
        Assert.AreEqual(ReportVisualBefore, ReportVisualAfter, 'Wrong visual name after parsing.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDisplayedElementDashboardKey()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        Assert: Codeunit Assert;
        DashboardIdBefore: Guid;
        DashboardIdAfter: Guid;
    begin
        DashboardIdBefore := CreateGuid();

        PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::Dashboard;
        PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeDashboardKey(DashboardIdBefore);
        PowerBIDisplayedElement.ParseDashboardKey(DashboardIdAfter);

        Assert.AreEqual(DashboardIdBefore, DashboardIdAfter, 'Wrong dashboard ID after parsing.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDisplayedElementDashboardTileKey()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        Assert: Codeunit Assert;
        DashboardIdBefore: Guid;
        DashboardTileIdBefore: Guid;
        DashboardIdAfter: Guid;
        DashboardTileIdAfter: Guid;
    begin
        DashboardIdBefore := CreateGuid();
        DashboardTileIdBefore := CreateGuid();

        PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::"Dashboard Tile";
        PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeDashboardTileKey(DashboardIdBefore, DashboardTileIdBefore);
        PowerBIDisplayedElement.ParseDashboardTileKey(DashboardIdAfter, DashboardTileIdAfter);

        Assert.AreEqual(DashboardIdBefore, DashboardIdAfter, 'Wrong dashboard ID after parsing.');
        Assert.AreEqual(DashboardTileIdBefore, DashboardTileIdAfter, 'Wrong dashboard tile ID after parsing.');
    end;
}