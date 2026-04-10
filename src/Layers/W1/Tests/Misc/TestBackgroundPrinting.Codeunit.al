codeunit 139030 "Test Background Printing"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Job Queue Entry]
    end;

    var
        Assert: Codeunit Assert;
        WrongToReportInboxValErr: Label 'Wrong IsToReportInbox value.';
        ScheduleActionNotFoundErr: Label 'The built-in action = Schedule is not found on the page.';

    [Test]
    [HandlerFunctions('DetailTrialBalanceRequestpageHandler')]
    [Scope('OnPrem')]
    procedure TestJobQueueEntryReportSetup()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCard: TestPage "Job Queue Entry Card";
    begin
        JobQueueEntry.Init();
        JobQueueEntryCard.OpenNew();
        JobQueueEntryCard."Object Type to Run".SetValue(JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntryCard."Object ID to Run".SetValue(REPORT::"Detail Trial Balance");
        Commit();
        JobQueueEntryCard."Report Request Page Options".SetValue(true);

        // Verify that the field has been filled with an xml value.
        Assert.IsTrue(JobQueueEntryCard."Report Request Page Options".AsBoolean(), '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CustomerTop10RequestHandler,ScheduleAReportHandler')]
    [Scope('OnPrem')]
    procedure TestScheduleReport()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ExpectedID: Guid;
    begin
        // [SCENARIO] "Schedule" action should be disabled if the report is already scheduled.
        // [GIVEN] No Job Queue Entries
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", REPORT::"Detail Trial Balance");
        JobQueueEntry.DeleteAll();
        Commit();
        Assert.IsTrue(JobQueueEntry.IsEmpty, '');

        BindSubscription(LibraryJobQueue);
        // [GIVEN] First run of report "Detail Trial Balance" inserts one Job Queue Entry with ID = 'X'
        REPORT.Run(REPORT::"Detail Trial Balance");
        Assert.IsTrue(JobQueueEntry.FindFirst(), 'Job Queue Entry should be inserted.');
        ExpectedID := JobQueueEntry.ID;
        // [WHEN] run Report "Detail Trial Balance" again
        asserterror REPORT.RunModal(REPORT::"Detail Trial Balance");

        // [THEN] "Schedule" action is not available.
        Assert.ExpectedError(ScheduleActionNotFoundErr);
        // [THEN] Exists one Job Queue Entry, where ID = 'X'
        Assert.AreEqual(1, JobQueueEntry.Count, 'Should be just one Job Queue Entry');
        JobQueueEntry.FindFirst();
        Assert.AreEqual(ExpectedID, JobQueueEntry.ID, 'Job ID should not be changed.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,DetailTrialBalanceRequestpageHandler')]
    [Scope('OnPrem')]
    procedure TestScheduleAReportPage()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ScheduleaReport: TestPage "Schedule a Report";
    begin
        // [FEATURE] [UI]
        JobQueueEntry.DeleteAll();
        Commit();

        // [GIVEN] Open "Schedule A Report" page, set "Object ID to Run" as 'Detail Trial Balance'
        BindSubscription(LibraryJobQueue);
        ScheduleaReport.OpenEdit();
        ScheduleaReport."Object ID to Run".SetValue(REPORT::"Detail Trial Balance");
        // [WHEN] Push OK
        ScheduleaReport.OK().Invoke();

        // [THEN] The job queue entry, where "Run in User Session" is 'Yes', "Recurring Job" is 'No'
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField("Run in User Session");
        JobQueueEntry.TestField("Recurring Job", false);
        JobQueueEntry.TestField("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.TestField("Object ID to Run", REPORT::"Detail Trial Balance");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,DetailTrialBalanceRequestpageHandler')]
    [Scope('OnPrem')]
    procedure TestScheduleAReportPageByDateFormula()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ScheduleaReport: TestPage "Schedule a Report";
        DateFormula: DateFormula;
        DateTime: DateTime;
        ExpectedDateTime: DateTime;
    begin
        // [FEATURE] [Date Formula] [UI]
        JobQueueEntry.DeleteAll();
        Commit();
        // [GIVEN] Current datetime is '10.01.19 15:00'
        Evaluate(DateFormula, '<1M+CM>');
        ExpectedDateTime := CreateDateTime(CalcDate(DateFormula, Today), 0T);
        // [GIVEN] Open "Schedule A Report" page, set "Object ID to Run" as 'Detail Trial Balance'
        BindSubscription(LibraryJobQueue);
        ScheduleaReport.OpenEdit();
        ScheduleaReport."Object ID to Run".SetValue(REPORT::"Detail Trial Balance");
        // [GIVEN] "Earliest Start Date/Time" is blank
        Assert.AreEqual(
          '', Format(ScheduleaReport."Earliest Start Date/Time".Value), 'Earliest Start Date/Time should be blank');

        // [WHEN] Set "Next Run Date Formula" as '<1M+CM>'
        ScheduleaReport."Next Run Date Formula".SetValue(DateFormula);

        // [THEN] "Earliest Start Date/Time" is '28.02.19 00:00'
        Assert.IsTrue(
          Evaluate(DateTime, ScheduleaReport."Earliest Start Date/Time".Value),
          'cannot evaluate Earliest Start Date/Time');
        Assert.AreEqual(ExpectedDateTime, DateTime, 'wrong Earliest Start Date/Time');

        ScheduleaReport.OK().Invoke();

        // [THEN] The job queue entry, where "Next Run Date Formula" is '<1M+CM>',"Recurring Job" is 'Yes', "Run in User Session" is 'No'.
        Assert.RecordCount(JobQueueEntry, 1);
        JobQueueEntry.FindFirst();
        JobQueueEntry.TestField("Recurring Job");
        JobQueueEntry.TestField("Run in User Session", false);
        JobQueueEntry.TestField("Next Run Date Formula", DateFormula);
        JobQueueEntry.TestField("Earliest Start Date/Time", ExpectedDateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTReportInboxJobQueueEntryNotReport()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Schedule a Report] [Report Inbox]
        // [SCENARIO 164896] "Job Queue Entry".IsToReportInbox = FALSE for "Object Type to Run" <> Report
        ReportInboxJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Codeunit, JobQueueEntry."Report Output Type"::Word,
          false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTReportInboxJobQueueEntryWord()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Schedule a Report] [Report Inbox]
        // [SCENARIO 164896] "Job Queue Entry".IsToReportInbox = TRUE for "Object Type to Run" = Report and "Report Output Type" = Word
        ReportInboxJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Report, JobQueueEntry."Report Output Type"::Word,
          true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTReportInboxJobQueueEntryExcel()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Schedule a Report] [Report Inbox]
        // [SCENARIO 164896] "Job Queue Entry".IsToReportInbox = TRUE for "Object Type to Run" = Report and "Report Output Type" = Excel
        ReportInboxJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Report, JobQueueEntry."Report Output Type"::Excel,
          true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTReportInboxJobQueueEntryPDF()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Schedule a Report] [Report Inbox]
        // [SCENARIO 164896] "Job Queue Entry".IsToReportInbox = TRUE for "Object Type to Run" = Report and "Report Output Type" = PDF
        ReportInboxJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Report, JobQueueEntry."Report Output Type"::PDF,
          true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTReportInboxJobQueueEntryPrint()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Schedule a Report] [Report Inbox]
        // [SCENARIO 164896] "Job Queue Entry".IsToReportInbox = FALSE for "Object Type to Run" = Report and "Report Output Type" = Print
        ReportInboxJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Report, JobQueueEntry."Report Output Type"::Print,
          false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UTReportInboxJobQueueEntryProcessingOnly()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // [FEATURE] [Schedule a Report] [Report Inbox]
        // [SCENARIO 164896] "Job Queue Entry".IsToReportInbox = FALSE for "Object Type to Run" = Report and "Report Output Type" = "None (Processing only)"
        ReportInboxJobQueueEntry(
          JobQueueEntry."Object Type to Run"::Report, JobQueueEntry."Report Output Type"::"None (Processing only)",
          false);
    end;

    local procedure ReportInboxJobQueueEntry(ObjectType: Option; ReportOutputType: Enum "Job Queue Report Output Type"; Expected: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := ObjectType;
        JobQueueEntry."Report Output Type" := ReportOutputType;
        Assert.AreEqual(Expected, JobQueueEntry.IsToReportInbox(), WrongToReportInboxValErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportExecutionSaveAsExcel()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportInbox: Record "Report Inbox";
        NoOfReports: Integer;
    begin
        NoOfReports := ReportInbox.Count();
        JobQueueEntry.Init();
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.Validate("Object ID to Run", REPORT::"Detail Trial Balance");
        JobQueueEntry.Validate("Report Output Type", JobQueueEntry."Report Output Type"::Excel);
        JobQueueEntry.Insert(true);
        Commit();
        CODEUNIT.Run(CODEUNIT::"Job Queue Start Codeunit", JobQueueEntry);

        ReportInbox.FindLast();
        Assert.AreEqual(NoOfReports + 1, ReportInbox.Count, '');
        Assert.AreEqual(REPORT::"Detail Trial Balance", ReportInbox."Report ID", '');
        Assert.AreEqual(ReportInbox."Output Type"::Excel, ReportInbox."Output Type", '');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceRequestpageHandler(var DetailTrialBalance: TestRequestPage "Detail Trial Balance")
    begin
        DetailTrialBalance.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTop10RequestHandler(var DetailTrialBalance: TestRequestPage "Detail Trial Balance")
    begin
        DetailTrialBalance.Schedule().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ScheduleAReportHandler(var ScheduleaReport: TestPage "Schedule a Report")
    begin
        Assert.AreEqual(REPORT::"Detail Trial Balance", ScheduleaReport."Object ID to Run".AsInteger(), '');
        Assert.IsFalse(ScheduleaReport."Object ID to Run".Editable(), '');
        Assert.IsFalse(ScheduleaReport."Report Request Page Options".Visible(), '');
        ScheduleaReport.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

