codeunit 139302 "Test Report Request Failure"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Request Page] [XML]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('HandleReportRequestPage')]
    [Scope('OnPrem')]
    procedure VerifyRequestPageValidateDoesNotCauseStackoverflowException()
    var
        TestReport: Report TestReport;
    begin
        // [SCENARIO] The user invokes an XML Port which has a date filter on the request page.
        // [GIVEN] There is an error in the filter values given.
        // [WHEN] The user clicks ok to run the XML Port.
        // [THEN] The server does not crash with a StackOverflowException due to metadata load failures.
        TestReport.UseRequestPage := true;
        TestReport.Run();

        LibraryReportDataset.LoadDataSetFile();
        Assert.AreNotEqual(0, LibraryReportDataset.RowCount(), 'A positive count is expected');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure HandleReportRequestPage(var handler: TestRequestPage TestReport)
    begin
        handler.Datefilter.SetValue('010110..011110');
        handler.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

